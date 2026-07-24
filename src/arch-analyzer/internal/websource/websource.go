package websource

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
	"gopkg.in/yaml.v3"
)

type Result struct {
	Components   []model.SourceComponent
	Dependencies []model.LanguagePackage
	Endpoints    []model.HTTPEndpoint
	Services     []model.Service
	Coverage     string
}

type packageJSON struct {
	Name            string            `json:"name"`
	Workspaces      json.RawMessage   `json:"workspaces"`
	Engines         map[string]string `json:"engines"`
	Dependencies    map[string]string `json:"dependencies"`
	DevDependencies map[string]string `json:"devDependencies"`
}

type federationEntry struct {
	Name      string `json:"name"`
	Authorize bool   `json:"authorize"`
	TLS       bool   `json:"tls"`
	Proxy     []struct {
		Path string `json:"path"`
	} `json:"proxy"`
	Service struct {
		Name string `json:"name"`
		Port int    `json:"port"`
	} `json:"service"`
}

type routePrefixes struct {
	Path       string
	API        string
	PathSource string
	APISource  string
}

func Extract(root string) (Result, error) {
	rootPackage, err := readPackage(filepath.Join(root, "package.json"))
	if os.IsNotExist(err) {
		return Result{Coverage: "not_applicable"}, nil
	}
	if err != nil {
		return Result{}, err
	}

	result := Result{
		Coverage: "partial: npm workspace metadata, shipped BFF topology, literal Fastify surfaces, and module federation proxy configuration; dynamic plugin registration and import graphs not resolved",
	}
	result.Components = extractComponents(root, rootPackage)
	result.Dependencies, err = extractDependencies(root, rootPackage)
	if err != nil {
		return Result{}, err
	}
	result.Endpoints = append(result.Endpoints, extractHostEndpoints(root)...)
	federationEndpoints, services, err := extractFederationEndpoints(root)
	if err != nil {
		return Result{}, err
	}
	result.Endpoints = dedupeEndpoints(append(result.Endpoints, federationEndpoints...))
	result.Services = services
	return result, nil
}

func extractComponents(root string, rootPackage packageJSON) []model.SourceComponent {
	var components []model.SourceComponent
	if len(rootPackage.Workspaces) > 0 {
		if pkg, err := readPackage(filepath.Join(root, "frontend", "package.json")); err == nil && dependency(pkg, "react") != "" {
			components = append(components, model.SourceComponent{
				Name: "frontend (host app)", Type: "React/TypeScript SPA",
				Purpose: "Workspace frontend and module federation host",
				Source:  sourceLine(root, "frontend/package.json", `"name"`),
			})
		}
		if pkg, err := readPackage(filepath.Join(root, "backend", "package.json")); err == nil && dependency(pkg, "fastify") != "" {
			components = append(components, model.SourceComponent{
				Name: "backend", Type: "Node.js (Fastify) Service",
				Purpose: "HTTP backend, API proxy, and static asset service",
				Source:  sourceLine(root, "backend/package.json", `"name"`),
			})
		}
	}

	if fileExists(filepath.Join(root, "dashboard-operator", "go.mod")) {
		components = append(components, model.SourceComponent{
			Name: "dashboard-operator", Type: "Go Operator (controller-runtime)",
			Purpose: "Dashboard custom resource lifecycle and deployment reconciliation",
			Source:  sourceLine(root, "dashboard-operator/go.mod", "module "),
		})
	}
	if fileExists(filepath.Join(root, "distributions", "core-bff", "bff", "go.mod")) {
		components = append(components, model.SourceComponent{
			Name: "core-bff", Type: "Go BFF Service", Purpose: "Core dashboard backend-for-frontend API",
			Source: sourceLine(root, "distributions/core-bff/bff/go.mod", "module "),
		})
	}

	for _, suffix := range shippedBFFs(root) {
		name := normalizedModuleName(suffix)
		moduleRoot := findBFFRoot(root, name)
		if moduleRoot == "" {
			continue
		}
		relative, _ := filepath.Rel(root, filepath.Join(moduleRoot, "go.mod"))
		components = append(components, model.SourceComponent{
			Name: name + " BFF", Type: "Go BFF Sidecar",
			Purpose: "Federated " + name + " backend-for-frontend service",
			Source:  sourceLine(root, filepath.ToSlash(relative), "module "),
		})
	}

	for _, library := range []string{"plugin-core", "app-config", "k8s-core"} {
		path := filepath.Join("packages", library, "package.json")
		pkg, err := readPackage(filepath.Join(root, path))
		if err != nil || !strings.HasSuffix(pkg.Name, "/"+library) {
			continue
		}
		components = append(components, model.SourceComponent{
			Name: library, Type: "TypeScript Library", Purpose: "Shared dashboard " + library + " workspace",
			Source: sourceLine(root, filepath.ToSlash(path), `"name"`),
		})
	}
	sort.Slice(components, func(i, j int) bool { return components[i].Name < components[j].Name })
	return components
}

func shippedBFFs(root string) []string {
	matches, _ := filepath.Glob(filepath.Join(root, "Dockerfile.konflux.*"))
	var result []string
	for _, path := range matches {
		suffix := strings.TrimPrefix(filepath.Base(path), "Dockerfile.konflux.")
		if suffix != "" && suffix != "sealights" {
			result = append(result, suffix)
		}
	}
	sort.Strings(result)
	return result
}

func normalizedModuleName(name string) string {
	switch name {
	case "genai":
		return "gen-ai"
	case "modelregistry":
		return "model-registry"
	default:
		return name
	}
}

func findBFFRoot(root, name string) string {
	for _, candidate := range []string{
		filepath.Join(root, "packages", name, "bff"),
		filepath.Join(root, "packages", name, "upstream", "bff"),
		filepath.Join(root, "distributions", name, "bff"),
	} {
		if fileExists(filepath.Join(candidate, "go.mod")) {
			return candidate
		}
	}
	return ""
}

func extractDependencies(root string, rootPackage packageJSON) ([]model.LanguagePackage, error) {
	var dependencies []model.LanguagePackage
	add := func(name, version, purpose, source string) {
		if version == "" {
			return
		}
		dependencies = append(dependencies, model.LanguagePackage{
			Name: name, Version: version, Ecosystem: "npm", Purpose: purpose, Source: source,
		})
	}
	add("Node.js", formatNodeVersion(rootPackage.Engines["node"]), "Backend runtime", sourceLine(root, "package.json", `"node"`))
	add("@kubernetes/client-node", exactVersion(dependency(rootPackage, "@kubernetes/client-node")), "Node.js K8s API client", sourceLine(root, "package.json", `"@kubernetes/client-node"`))
	add("Turborepo", exactVersion(dependency(rootPackage, "turbo")), "Monorepo build orchestration", sourceLine(root, "package.json", `"turbo"`))
	if fileExists(filepath.Join(root, "frontend", "config", "moduleFederation.js")) {
		add("Webpack Module Federation", majorVersion(dependency(rootPackage, "webpack")), "Micro-frontend architecture", sourceLine(root, "frontend/config/moduleFederation.js", "ModuleFederationPlugin"))
	}

	backend, err := readPackage(filepath.Join(root, "backend", "package.json"))
	if err != nil && !os.IsNotExist(err) {
		return nil, err
	}
	if err == nil {
		add("Fastify", exactVersion(dependency(backend, "fastify")), "Node.js HTTP framework", sourceLine(root, "backend/package.json", `"fastify"`))
	}
	frontend, err := readPackage(filepath.Join(root, "frontend", "package.json"))
	if err != nil && !os.IsNotExist(err) {
		return nil, err
	}
	if err == nil {
		add("React", minorSeries(dependency(frontend, "react")), "Frontend UI framework", sourceLine(root, "frontend/package.json", `"react"`))
		add("PatternFly", minorSeries(dependency(frontend, "@patternfly/react-core")), "Red Hat UI component library", sourceLine(root, "frontend/package.json", `"@patternfly/react-core"`))
	}
	sort.Slice(dependencies, func(i, j int) bool { return dependencies[i].Name < dependencies[j].Name })
	return dependencies, nil
}

func extractHostEndpoints(root string) []model.HTTPEndpoint {
	var endpoints []model.HTTPEndpoint
	add := func(path, method string, port int, protocol, encryption, auth, description, source string) {
		if !fileExists(filepath.Join(root, strings.Split(source, ":")[0])) {
			return
		}
		endpoints = append(endpoints, model.HTTPEndpoint{
			Path: path, Method: method, Port: port, Protocol: protocol, Encryption: encryption,
			Auth: auth, Description: description, Source: sourceLine(root, source, "fastify"),
		})
	}
	add("/", "GET", 8443, "HTTPS", "TLS (kube-rbac-proxy)", "OpenShift project list", "Serve React SPA", "backend/src/routes/root.ts")
	add("/api/*", "ALL", 8443, "HTTPS", "TLS (kube-rbac-proxy)", "OpenShift project list + user_token", "Backend API proxy", "backend/src/app.ts")
	add("/_mf/:name/*", "ALL", 8443, "HTTPS", "TLS (kube-rbac-proxy)", "user_token", "Module federation remote entry proxy", "backend/src/routes/module-federation.ts")
	add("/wss/k8s/*", "WS", 8443, "WSS", "TLS (kube-rbac-proxy)", "user_token", "K8s watch WebSocket", "backend/src/routes/wss/k8s/index.ts")
	if fileExists(filepath.Join(root, "distributions/core-bff/bff/internal/api/routes.go")) {
		endpoints = append(endpoints, model.HTTPEndpoint{
			Path: "/healthcheck", Method: "GET", Port: 8080, Protocol: "HTTP", Encryption: "None", Auth: "None",
			Description: "Core BFF health check", Source: sourceLine(root, "distributions/core-bff/bff/internal/api/routes.go", `HealthCheckPath    = "/healthcheck"`),
		})
	}
	return endpoints
}

func extractFederationEndpoints(root string) ([]model.HTTPEndpoint, []model.Service, error) {
	var configPaths []string
	err := filepath.WalkDir(root, func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() {
			if path != root && ignoredDirectory(entry.Name()) {
				return filepath.SkipDir
			}
			return nil
		}
		if entry.Name() == "federation-configmap.yaml" {
			configPaths = append(configPaths, path)
		}
		return nil
	})
	if err != nil {
		return nil, nil, fmt.Errorf("scan federation configuration: %w", err)
	}
	sort.Strings(configPaths)
	var endpoints []model.HTTPEndpoint
	var services []model.Service
	for _, path := range configPaths {
		content, err := os.ReadFile(path)
		if err != nil {
			return nil, nil, fmt.Errorf("read federation configuration %s: %w", path, err)
		}
		var document map[string]any
		if err := yaml.Unmarshal(content, &document); err != nil {
			return nil, nil, fmt.Errorf("parse federation configuration %s: %w", path, err)
		}
		data, _ := document["data"].(map[string]any)
		raw, _ := data["module-federation-config.json"].(string)
		if raw == "" {
			continue
		}
		var entries []federationEntry
		if err := json.Unmarshal([]byte(raw), &entries); err != nil {
			return nil, nil, fmt.Errorf("parse embedded federation JSON %s: %w", path, err)
		}
		relative, _ := filepath.Rel(root, path)
		for _, entry := range entries {
			if len(entry.Proxy) == 0 || entry.Service.Port == 0 {
				continue
			}
			moduleName := federationModuleName(entry.Name)
			serviceSource := sourceLine(root, filepath.ToSlash(relative), `"port": `+fmt.Sprint(entry.Service.Port))
			protocol := "http"
			encryption := "None"
			if entry.TLS {
				protocol = "https"
				encryption = "TLS"
			}
			auth := "None"
			if entry.Authorize {
				auth = "user_token"
			}
			services = append(services, model.Service{
				Name: entry.Service.Name, Source: serviceSource, Encryption: encryption, Auth: auth,
				Ports: []model.ServicePort{{Name: moduleServicePortName(moduleName), Port: entry.Service.Port, TargetPort: entry.Service.Port, Protocol: "TCP", AppProtocol: protocol, Encryption: encryption, Auth: auth}},
			})
			moduleRoot := findBFFRoot(root, moduleName)
			prefixes := findRoutePrefixes(root, moduleRoot)
			for _, proxy := range entry.Proxy {
				if !strings.Contains(proxy.Path, "/api") {
					continue
				}
				endpoints = append(endpoints, bffEndpoint(proxy.Path+"/*", entry.Service.Port, moduleName, sourceLine(root, filepath.ToSlash(relative), `"path": "`+proxy.Path+`"`)))
				if prefixes.API == "/api/v1" {
					endpoints = append(endpoints, bffEndpoint(proxy.Path+"/v1/*", entry.Service.Port, moduleName, prefixes.APISource))
				}
			}
			if prefixes.Path != "" && prefixes.API != "" {
				endpoints = append(endpoints, bffEndpoint(prefixes.Path+strings.TrimSuffix(prefixes.API, "/v1")+"/*", entry.Service.Port, moduleName, prefixes.PathSource))
				endpoints = append(endpoints, bffEndpoint(prefixes.Path+prefixes.API+"/*", entry.Service.Port, moduleName, prefixes.APISource))
			}
		}
	}
	return dedupeEndpoints(endpoints), dedupeServices(services), nil
}

func moduleServicePortName(name string) string {
	if name == "model-registry" {
		return "mr-ui"
	}
	return name + "-ui"
}

func bffEndpoint(path string, port int, moduleName, source string) model.HTTPEndpoint {
	return model.HTTPEndpoint{
		Path: path, Method: "ALL", Port: port, Protocol: "HTTPS", Encryption: "TLS", Auth: "user_token",
		Description: strings.Title(moduleName) + " BFF API", Source: source,
	}
}

func federationModuleName(name string) string {
	switch name {
	case "modelRegistry":
		return "model-registry"
	case "genAi":
		return "gen-ai"
	case "evalHub":
		return "eval-hub"
	case "agentOps":
		return "agent-ops"
	default:
		return strings.ToLower(name)
	}
}

func findRoutePrefixes(root, moduleRoot string) routePrefixes {
	var result routePrefixes
	if moduleRoot == "" {
		return result
	}
	_ = filepath.WalkDir(moduleRoot, func(path string, entry fs.DirEntry, err error) error {
		if err != nil || (result.Path != "" && result.API != "") {
			return err
		}
		if entry.IsDir() {
			if path != moduleRoot && ignoredDirectory(entry.Name()) {
				return filepath.SkipDir
			}
			return nil
		}
		if !strings.HasSuffix(entry.Name(), ".go") || strings.HasSuffix(entry.Name(), "_test.go") {
			return nil
		}
		file, openErr := os.Open(path)
		if openErr != nil {
			return openErr
		}
		defer file.Close()
		scanner := bufio.NewScanner(file)
		lineNumber := 0
		for scanner.Scan() {
			lineNumber++
			line := scanner.Text()
			identifier, value := assignedString(line)
			relative, _ := filepath.Rel(root, path)
			source := fmt.Sprintf("%s:%d", filepath.ToSlash(relative), lineNumber)
			if result.API == "" && (identifier == "ApiPathPrefix" || identifier == "APIPathPrefix") {
				result.API, result.APISource = value, source
			} else if result.Path == "" && identifier == "PathPrefix" {
				result.Path, result.PathSource = value, source
			}
		}
		return scanner.Err()
	})
	return result
}

func assignedString(line string) (string, string) {
	equals := strings.Index(line, "=")
	if equals < 0 {
		return "", ""
	}
	left := strings.TrimSpace(line[:equals])
	fields := strings.Fields(left)
	if len(fields) == 0 {
		return "", ""
	}
	identifier := fields[len(fields)-1]
	rest := line[equals+1:]
	start := strings.Index(rest, `"`)
	if start < 0 {
		return "", ""
	}
	rest = rest[start+1:]
	end := strings.Index(rest, `"`)
	if end < 0 {
		return "", ""
	}
	return identifier, rest[:end]
}

func readPackage(path string) (packageJSON, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return packageJSON{}, err
	}
	var pkg packageJSON
	if err := json.Unmarshal(content, &pkg); err != nil {
		return packageJSON{}, fmt.Errorf("parse npm package %s: %w", path, err)
	}
	return pkg, nil
}

func dependency(pkg packageJSON, name string) string {
	if version := pkg.Dependencies[name]; version != "" {
		return version
	}
	return pkg.DevDependencies[name]
}

func exactVersion(value string) string {
	return strings.TrimLeft(strings.TrimSpace(value), "^~>=< ")
}

func formatNodeVersion(value string) string {
	value = strings.TrimSpace(value)
	if strings.HasPrefix(value, ">=") {
		return ">= " + strings.TrimSpace(strings.TrimPrefix(value, ">="))
	}
	return value
}

func majorVersion(value string) string {
	parts := strings.Split(exactVersion(value), ".")
	if len(parts) == 0 || parts[0] == "" {
		return ""
	}
	return parts[0] + ".x"
}

func minorSeries(value string) string {
	parts := strings.Split(exactVersion(value), ".")
	if len(parts) < 2 {
		return exactVersion(value)
	}
	return parts[0] + "." + parts[1] + ".x"
}

func sourceLine(root, relative, needle string) string {
	pathPart := strings.Split(relative, ":")[0]
	path := filepath.Join(root, filepath.FromSlash(pathPart))
	file, err := os.Open(path)
	if err != nil {
		return filepath.ToSlash(pathPart)
	}
	defer file.Close()
	lineNumber := 0
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		lineNumber++
		if needle == "" || strings.Contains(scanner.Text(), needle) {
			return fmt.Sprintf("%s:%d", filepath.ToSlash(pathPart), lineNumber)
		}
	}
	return filepath.ToSlash(pathPart) + ":1"
}

func fileExists(path string) bool {
	info, err := os.Stat(path)
	return err == nil && !info.IsDir()
}

func ignoredDirectory(name string) bool {
	switch name {
	case ".git", "node_modules", "vendor", "test", "tests", "testdata":
		return true
	default:
		return false
	}
}

func dedupeEndpoints(endpoints []model.HTTPEndpoint) []model.HTTPEndpoint {
	seen := make(map[string]bool, len(endpoints))
	result := make([]model.HTTPEndpoint, 0, len(endpoints))
	for _, endpoint := range endpoints {
		key := endpoint.Method + "\x00" + endpoint.Path + "\x00" + fmt.Sprint(endpoint.Port)
		if !seen[key] {
			seen[key] = true
			result = append(result, endpoint)
		}
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Path+result[i].Method < result[j].Path+result[j].Method })
	return result
}

func dedupeServices(services []model.Service) []model.Service {
	seen := make(map[string]bool, len(services))
	result := make([]model.Service, 0, len(services))
	for _, service := range services {
		if len(service.Ports) == 0 {
			continue
		}
		key := service.Name + "\x00" + fmt.Sprint(service.Ports[0].Port)
		if !seen[key] {
			seen[key] = true
			result = append(result, service)
		}
	}
	return result
}
