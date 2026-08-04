package pythonsource

import (
	"fmt"
	"regexp"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

var decoratorRoute = regexp.MustCompile(`(?m)@(?:[A-Za-z_][A-Za-z0-9_]*\.)*(get|post|put|patch|delete|options|head|websocket)\(\s*["']([^"']+)["']`)
var genericRoute = regexp.MustCompile(`(?ms)@(?:[A-Za-z_][A-Za-z0-9_]*\.)*(?:route|api_route)\(\s*["']([^"']+)["'](.{0,400}?)\)\s*(?:\n|\r)`)
var routeMethods = regexp.MustCompile(`(?i)methods\s*=\s*\[([^]]+)]`)
var quotedWord = regexp.MustCompile(`["']([A-Za-z]+)["']`)
var routerPrefix = regexp.MustCompile(`APIRouter\s*\([^)]*?prefix\s*=\s*["']([^"']+)["']`)
var literalHTTPCall = regexp.MustCompile(`(?i)(?:requests|httpx|aiohttp|client|session)\.(?:get|post|put|patch|delete|request)\(\s*["'](https?://[^"']+)["']`)
var environmentRead = regexp.MustCompile(`(?:os\.(?:getenv|environ\.get)|getenv)\(\s*["']([A-Za-z_][A-Za-z0-9_]*)["']`)
var uvicornPort = regexp.MustCompile(`(?s)uvicorn\.run\(.{0,500}?\bport\s*=\s*(\d{2,5})`)
var authMarker = regexp.MustCompile(`\b(?:APIKeyHeader|OAuth2PasswordBearer|HTTPBearer|Security)\s*\(` +
	`|\bDepends\s*\(\s*(?:get_current_user|verify_token|authenticate|require_auth)\b`)

func extractPythonSource(root string, components []model.SourceComponent) (
	[]model.HTTPEndpoint,
	[]model.Service,
	[]model.ExternalConnection,
	[]model.Secret,
	[]model.AuthenticationFact,
	error,
) {
	var endpoints []model.HTTPEndpoint
	var connections []model.ExternalConnection
	var secrets []model.Secret
	var authentication []model.AuthenticationFact
	port := ""
	err := walkPythonFiles(root, func(relative, content string) error {
		prefix := ""
		if match := routerPrefix.FindStringSubmatch(content); len(match) > 1 {
			prefix = match[1]
		}
		if match := uvicornPort.FindStringSubmatch(content); len(match) > 1 && port == "" {
			port = match[1]
		}
		for _, match := range decoratorRoute.FindAllStringSubmatchIndex(content, -1) {
			method := strings.ToUpper(content[match[2]:match[3]])
			path := prefix + content[match[4]:match[5]]
			endpoints = append(endpoints, pythonEndpoint(method, path, port, relative, content, content[match[0]:match[1]]))
		}
		for _, match := range genericRoute.FindAllStringSubmatchIndex(content, -1) {
			path := prefix + content[match[2]:match[3]]
			options := content[match[4]:match[5]]
			methods := []string{"Unknown"}
			if methodMatch := routeMethods.FindStringSubmatch(options); len(methodMatch) > 1 {
				methods = nil
				for _, quoted := range quotedWord.FindAllStringSubmatch(methodMatch[1], -1) {
					methods = append(methods, strings.ToUpper(quoted[1]))
				}
			}
			for _, method := range methods {
				endpoints = append(endpoints, pythonEndpoint(method, path, port, relative, content, content[match[0]:match[1]]))
			}
		}
		for _, match := range literalHTTPCall.FindAllStringSubmatchIndex(content, -1) {
			raw := content[match[2]:match[3]]
			host, scheme, connectionPort := connectionTarget(raw)
			if host == "" {
				continue
			}
			connections = append(connections, model.ExternalConnection{
				Type: "HTTP client", Service: host, Target: host,
				Protocol: strings.ToUpper(scheme), Port: connectionPort,
				Encryption: map[bool]string{true: "TLS", false: "None"}[scheme == "https"],
				Source:     sourceRef(relative, content, raw), Function: "Literal outbound HTTP endpoint",
			})
		}
		for _, match := range environmentRead.FindAllStringSubmatchIndex(content, -1) {
			name := content[match[2]:match[3]]
			upper := strings.ToUpper(name)
			if !strings.Contains(upper, "TOKEN") && !strings.Contains(upper, "SECRET") &&
				!strings.Contains(upper, "PASSWORD") && !strings.Contains(upper, "API_KEY") &&
				!strings.Contains(upper, "PRIVATE_KEY") {
				continue
			}
			secrets = append(secrets, model.Secret{
				Name: name, Type: "environment variable", ReferencedBy: []string{"Python application"},
				ProvisionedBy: "runtime environment", Source: sourceRef(relative, content, content[match[0]:match[1]]),
			})
		}
		if authMarker.MatchString(content) {
			authentication = append(authentication, model.AuthenticationFact{
				Endpoint: "HTTP API", Methods: "All", Mechanism: "Bearer token or API key",
				EnforcementPoint: "Python API dependency or middleware", Policy: "Source-defined authentication",
				Source: sourceRef(relative, content, authMarker.FindString(content)),
			})
		}
		connections = append(connections, extractSDKClientConnections(relative, content)...)
		return nil
	})
	if err != nil {
		return nil, nil, nil, nil, nil, fmt.Errorf("extract Python routes: %w", err)
	}
	authFacts, authErr := extractPythonAuthentication(root)
	if authErr != nil {
		return nil, nil, nil, nil, nil, fmt.Errorf("extract Python authentication: %w", authErr)
	}
	authentication = append(authentication, authFacts...)
	endpoints = dedupeEndpoints(endpoints)
	connections = dedupeConnections(connections)
	secrets = dedupeSecrets(secrets)
	authentication = dedupeAuthentication(authentication)
	authentication = append(authentication, resolveAuthPosture(endpoints, authentication)...)
	var services []model.Service
	if len(endpoints) > 0 {
		name := "python-api"
		source := endpoints[0].Source
		if len(components) > 0 && components[0].Name != "" {
			name = components[0].Name
		}
		service := model.Service{Name: name, Type: "N/A (source server)", Source: source, Exposure: "Internal"}
		if port != "" {
			service.Ports = []model.ServicePort{{Port: port, TargetPort: port, Protocol: "TCP", AppProtocol: "http"}}
		}
		services = append(services, service)
	}
	return endpoints, services, connections, secrets, authentication, nil
}

func connectionTarget(raw string) (string, string, string) {
	withoutScheme := strings.SplitN(raw, "://", 2)
	if len(withoutScheme) != 2 {
		return "", "", ""
	}
	scheme := strings.ToLower(withoutScheme[0])
	authority := strings.SplitN(withoutScheme[1], "/", 2)[0]
	host := strings.SplitN(authority, ":", 2)[0]
	port := "80"
	if scheme == "https" {
		port = "443"
	}
	if parts := strings.SplitN(authority, ":", 2); len(parts) == 2 && parts[1] != "" {
		port = parts[1]
	}
	return host, scheme, port
}

func pythonEndpoint(method, path, port, relative, content, evidence string) model.HTTPEndpoint {
	var endpointPort any
	if port != "" {
		endpointPort = port + "/TCP"
	}
	protocol := "HTTP/HTTPS"
	if method == "WEBSOCKET" {
		protocol = "WS/WSS"
	}
	return model.HTTPEndpoint{
		Method: method, Path: path, Port: endpointPort, Protocol: protocol,
		Encryption: "Configurable", Auth: "Unknown", Description: "Python API route",
		Source: sourceRef(relative, content, evidence),
	}
}

func dedupeEndpoints(items []model.HTTPEndpoint) []model.HTTPEndpoint {
	seen := map[string]bool{}
	var result []model.HTTPEndpoint
	for _, item := range items {
		key := strings.ToUpper(item.Method) + "\x00" + item.Path
		if item.Path == "" || seen[key] {
			continue
		}
		seen[key] = true
		result = append(result, item)
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Path+result[i].Method < result[j].Path+result[j].Method })
	return result
}

func dedupeConnections(items []model.ExternalConnection) []model.ExternalConnection {
	seen := map[string]bool{}
	var result []model.ExternalConnection
	for _, item := range items {
		key := item.Target + "\x00" + fmt.Sprint(item.Port)
		if seen[key] {
			continue
		}
		seen[key] = true
		result = append(result, item)
	}
	return result
}

func dedupeSecrets(items []model.Secret) []model.Secret {
	seen := map[string]bool{}
	var result []model.Secret
	for _, item := range items {
		if seen[item.Name] {
			continue
		}
		seen[item.Name] = true
		result = append(result, item)
	}
	return result
}

func dedupeAuthentication(items []model.AuthenticationFact) []model.AuthenticationFact {
	if len(items) == 0 {
		return nil
	}
	seen := map[string]bool{}
	var result []model.AuthenticationFact
	for _, item := range items {
		key := item.EnforcementPoint + "\x00" + item.Mechanism
		if seen[key] {
			continue
		}
		seen[key] = true
		result = append(result, item)
	}
	sort.Slice(result, func(i, j int) bool {
		if result[i].Endpoint != result[j].Endpoint {
			return result[i].Endpoint < result[j].Endpoint
		}
		if result[i].EnforcementPoint != result[j].EnforcementPoint {
			return result[i].EnforcementPoint < result[j].EnforcementPoint
		}
		return result[i].Mechanism < result[j].Mechanism
	})
	return result
}
