package rustsource

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"unicode"

	"github.com/jctanner/arch-analyzer/internal/model"
)

var rustFunction = regexp.MustCompile(`(?m)(?:pub\s+)?(?:async\s+)?fn\s+([A-Za-z_][A-Za-z0-9_]*)`)
var rustRouteMethod = regexp.MustCompile(`\b(get|post|put|patch|delete|head|options)\s*\(`)
var rustHandler = regexp.MustCompile(`\b(?:get|post|put|patch|delete|head|options)\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)`)
var clapField = regexp.MustCompile(`pub\s+([A-Za-z_][A-Za-z0-9_]*)\s*:`)
var clapDefault = regexp.MustCompile(`default_value\s*=\s*"([^"]+)"`)

func extractClapDefaults(root string) (map[string]string, map[string]string, error) {
	defaults := map[string]string{}
	sources := map[string]string{}
	err := walkRustFiles(root, func(path, relative, content string) error {
		searchFrom := 0
		for {
			start := strings.Index(content[searchFrom:], "#[clap(")
			if start < 0 {
				break
			}
			start += searchFrom
			end := strings.Index(content[start:], ")]")
			if end < 0 {
				break
			}
			end += start + 2
			after := content[end:]
			fieldMatch := clapField.FindStringSubmatchIndex(after)
			if len(fieldMatch) == 0 || fieldMatch[0] > 160 {
				searchFrom = end
				continue
			}
			attribute := content[start:end]
			defaultMatch := clapDefault.FindStringSubmatch(attribute)
			if len(defaultMatch) > 1 {
				field := after[fieldMatch[2]:fieldMatch[3]]
				defaults[field] = defaultMatch[1]
				sources[field] = fmt.Sprintf("%s:%d", relative, sourceLine(content, attribute))
			}
			searchFrom = end
		}
		return nil
	})
	return defaults, sources, err
}

func extractAxumRoutes(
	root string,
	defaults map[string]string,
	defaultSources map[string]string,
) ([]model.HTTPEndpoint, []model.Service, error) {
	var endpoints []model.HTTPEndpoint
	err := walkRustFiles(root, func(_ string, relative, content string) error {
		if testStart := strings.Index(content, "#[cfg(test)]"); testStart >= 0 {
			content = content[:testStart]
		}
		searchFrom := 0
		for {
			start := strings.Index(content[searchFrom:], ".route(")
			if start < 0 {
				break
			}
			start += searchFrom
			opening := start + len(".route")
			closing := matchingDelimiter(content, opening, '(', ')')
			if closing < 0 {
				break
			}
			arguments := splitArguments(content[opening+1 : closing])
			if len(arguments) >= 2 {
				path, err := strconv.Unquote(strings.TrimSpace(arguments[0]))
				if err == nil {
					function := surroundingFunction(content, start)
					health := strings.Contains(strings.ToLower(function), "health")
					portField := "http_port"
					protocol := "HTTP/HTTPS"
					encryption := "TLS 1.2+ (optional)"
					auth := "Passthrough headers"
					if health {
						portField = "health_http_port"
						protocol = "HTTP"
						encryption = "None"
						auth = "None"
					}
					port := defaults[portField]
					for _, methodMatch := range rustRouteMethod.FindAllStringSubmatch(arguments[1], -1) {
						handler := ""
						if match := rustHandler.FindStringSubmatch(arguments[1]); len(match) > 1 {
							handler = match[1]
						}
						endpoints = append(endpoints, model.HTTPEndpoint{
							Method:      strings.ToUpper(methodMatch[1]),
							Path:        path,
							Port:        portWithTransport(port),
							Protocol:    protocol,
							Encryption:  encryption,
							Auth:        auth,
							Description: humanize(handler),
							Source:      fmt.Sprintf("%s:%d", relative, sourceLine(content, content[start:closing+1])),
						})
					}
				}
			}
			searchFrom = closing + 1
		}
		return nil
	})
	if err != nil {
		return nil, nil, err
	}
	endpoints = dedupeEndpoints(endpoints)
	services := rustServices(endpoints, defaults, defaultSources)
	return endpoints, services, nil
}

func walkRustFiles(root string, visit func(path, relative, content string) error) error {
	return filepath.WalkDir(root, func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() {
			if path != root && (entry.Name() == ".git" || entry.Name() == "target" || entry.Name() == "tests") {
				return filepath.SkipDir
			}
			return nil
		}
		if !strings.HasSuffix(entry.Name(), ".rs") || strings.Contains(entry.Name(), "test") {
			return nil
		}
		content, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		relative, err := filepath.Rel(root, path)
		if err != nil {
			relative = path
		}
		return visit(path, filepath.ToSlash(relative), string(content))
	})
}

func matchingDelimiter(content string, opening int, open, close byte) int {
	depth := 0
	inString := false
	escaped := false
	for index := opening; index < len(content); index++ {
		char := content[index]
		if inString {
			if escaped {
				escaped = false
			} else if char == '\\' {
				escaped = true
			} else if char == '"' {
				inString = false
			}
			continue
		}
		if char == '"' {
			inString = true
			continue
		}
		if char == open {
			depth++
		} else if char == close {
			depth--
			if depth == 0 {
				return index
			}
		}
	}
	return -1
}

func splitArguments(content string) []string {
	var arguments []string
	start := 0
	depth := 0
	inString := false
	escaped := false
	for index := 0; index < len(content); index++ {
		char := content[index]
		if inString {
			if escaped {
				escaped = false
			} else if char == '\\' {
				escaped = true
			} else if char == '"' {
				inString = false
			}
			continue
		}
		switch char {
		case '"':
			inString = true
		case '(', '[', '{':
			depth++
		case ')', ']', '}':
			depth--
		case ',':
			if depth == 0 {
				arguments = append(arguments, strings.TrimSpace(content[start:index]))
				start = index + 1
			}
		}
	}
	arguments = append(arguments, strings.TrimSpace(content[start:]))
	return arguments
}

func surroundingFunction(content string, position int) string {
	name := ""
	for _, match := range rustFunction.FindAllStringSubmatchIndex(content[:position], -1) {
		name = content[match[2]:match[3]]
	}
	return name
}

func portWithTransport(port string) any {
	if port == "" {
		return nil
	}
	return port + "/TCP"
}

func humanize(value string) string {
	if value == "" {
		return "Extracted Axum route"
	}
	var result []rune
	for index, char := range value {
		if char == '_' || char == '-' {
			result = append(result, ' ')
			continue
		}
		if unicode.IsUpper(char) && index > 0 {
			result = append(result, ' ')
		}
		result = append(result, unicode.ToLower(char))
	}
	return strings.TrimSpace(string(result))
}

func dedupeEndpoints(endpoints []model.HTTPEndpoint) []model.HTTPEndpoint {
	seen := map[string]bool{}
	result := make([]model.HTTPEndpoint, 0, len(endpoints))
	for _, endpoint := range endpoints {
		key := endpoint.Method + "\x00" + endpoint.Path
		if !seen[key] {
			seen[key] = true
			result = append(result, endpoint)
		}
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].Path+result[i].Method < result[j].Path+result[j].Method
	})
	return result
}

func rustServices(
	endpoints []model.HTTPEndpoint,
	defaults map[string]string,
	sources map[string]string,
) []model.Service {
	hasHealth := false
	hasApplication := false
	for _, endpoint := range endpoints {
		if endpoint.Path == "/health" || endpoint.Path == "/info" {
			hasHealth = true
		} else {
			hasApplication = true
		}
	}
	var services []model.Service
	if hasApplication {
		services = append(services, binaryService(
			"guardrails-server", defaults["http_port"], "http/https",
			"TLS 1.2+ (optional)", "Passthrough headers, optional mTLS", sources["http_port"],
		))
	}
	if hasHealth {
		services = append(services, binaryService(
			"health-server", defaults["health_http_port"], "http", "None", "None", sources["health_http_port"],
		))
	}
	return services
}

func binaryService(name, port, appProtocol, encryption, auth, source string) model.Service {
	service := model.Service{
		Name: name, Type: "N/A (binary)", Source: source,
		Encryption: encryption, Auth: auth, Exposure: "Internal",
	}
	if port != "" {
		service.Ports = []model.ServicePort{{
			Port: port, TargetPort: port, Protocol: "TCP", AppProtocol: appProtocol,
		}}
	}
	return service
}
