package extractor

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
	"github.com/jctanner/arch-analyzer/internal/platformfacts"
)

const (
	architectureComponentsContract = "architecture-components/v1"
	authenticationContract         = "authentication/v1"
	grpcServicesContract           = "grpc-services/v1"
	httpEndpointsContract          = "http-endpoints/v1"
	internalDependenciesContract   = "internal-platform-dependencies/v1"
	integrationPointsContract      = "integration-points/v1"
	servicesContract               = "services/v1"
)

var inboundPythonPackages = map[string]bool{
	"django": true, "fastapi": true, "flask": true,
	"sanic": true, "starlette": true, "tornado": true,
	"uvicorn": true,
}

var pythonAuthenticationSignal = regexp.MustCompile(`(?i)(["'](?:authorization|proxy-authorization|x-api-key)["']\s*:|\bbearer\s+|\b(?:apikeyheader|httpbearer|oauth2passwordbearer|security)\s*\()`)

// Product labels, image registries, repository organizations, and generic project
// names do not establish a runtime relationship and are excluded from this shared
// platform-semantic vocabulary.
var internalPlatformAliases = platformfacts.InternalDependencyDiscoveryAliases()

func categoryCoverage(root string, input model.Input) map[string]model.CategoryCoverage {
	return map[string]model.CategoryCoverage{
		"architecture_components": architectureComponentsCoverage(input),
		"authentication":          authenticationCoverage(root, input),
		"grpc_services":           transportCoverage("grpc_services", grpcServicesContract, len(input.GRPCServices), input),
		"http_endpoints":          transportCoverage("http_endpoints", httpEndpointsContract, len(input.HTTPEndpoints), input),
		"internal_dependencies":   internalDependencyCoverage(root, input),
		"integration_points":      integrationPointsCoverage(root, input),
		"services":                transportCoverage("services", servicesContract, len(input.Services), input),
	}
}

func architectureComponentsCoverage(input model.Input) model.CategoryCoverage {
	count := len(input.SourceComponents) + len(input.Entrypoints) + len(input.Deployments) + len(input.Dockerfiles)
	coverage := model.CategoryCoverage{
		Status: "complete", FactCount: count, DiscoveryContract: architectureComponentsContract,
		CompletedChecks: []string{"source-entrypoint-workload-inventory"}, Limitations: []string{}, Evidence: []string{},
	}
	if count == 0 {
		coverage.Status = "partial"
		coverage.Limitations = append(coverage.Limitations, "no deterministic runtime component or entrypoint facts extracted")
	} else {
		coverage.Evidence = append(coverage.Evidence, fmt.Sprintf("summary:%d runtime component/entrypoint/workload facts extracted", count))
	}
	return coverage
}

func transportCoverage(name, contract string, count int, input model.Input) model.CategoryCoverage {
	coverage := model.CategoryCoverage{
		Status: "complete", FactCount: count, DiscoveryContract: contract,
		CompletedChecks: []string{"literal-transport-inventory"}, Limitations: []string{}, Evidence: []string{},
	}
	if count == 0 {
		coverage.Status = "partial"
		coverage.Limitations = append(coverage.Limitations, "no deterministic "+name+" facts extracted")
	} else {
		coverage.Evidence = append(coverage.Evidence, fmt.Sprintf("summary:%d deterministic %s facts extracted", count, name))
	}
	for _, language := range []string{"source", "python", "rust", "web_workspace"} {
		if strings.Contains(strings.ToLower(input.DataCoverage[language]), "dynamic") {
			coverage.Status = "partial"
			coverage.Limitations = append(coverage.Limitations, "dynamic "+name+" construction is not fully resolved")
			break
		}
	}
	return coverage
}

func authenticationCoverage(root string, input model.Input) model.CategoryCoverage {
	coverage := model.CategoryCoverage{
		Status: "partial", FactCount: len(input.Authentication) + len(input.SecurityEvidence),
		DiscoveryContract: authenticationContract,
		CompletedChecks:   []string{"normalized-authentication-facts"},
		Limitations:       []string{},
		Evidence:          []string{},
	}
	if len(input.SecurityEvidence) > 0 {
		coverage.CompletedChecks = append(coverage.CompletedChecks, "security-evidence-inventory")
		coverage.Evidence = append(coverage.Evidence,
			fmt.Sprintf("summary:%d literal security evidence items extracted", len(input.SecurityEvidence)))
	}
	for _, service := range input.GRPCServices {
		if service.Limitation == "" {
			continue
		}
		coverage.Limitations = append(coverage.Limitations,
			"gRPC service "+service.Service+": "+service.Limitation)
		coverage.Evidence = appendUnique(coverage.Evidence, service.Source)
	}

	inbound, evidence := inboundRuntimeSurfaces(input)
	if inbound > 0 {
		coverage.Limitations = append(coverage.Limitations,
			fmt.Sprintf("%d inbound runtime surfaces are not fully accounted for by authentication facts", inbound))
		coverage.Evidence = evidence
		if len(coverage.Evidence) == 0 {
			coverage.Evidence = []string{fmt.Sprintf("summary:%d analyzer-discovered inbound runtime surfaces", inbound)}
		}
		return coverage
	}
	coverage.CompletedChecks = append(coverage.CompletedChecks, "no-inbound-runtime-surfaces")
	coverage.Evidence = append(coverage.Evidence, "summary:no analyzer-discovered inbound runtime surfaces")

	credentialEvidence := authenticationCredentialEvidence(input.Secrets)
	coverage.CompletedChecks = append(coverage.CompletedChecks, "credential-reference-inventory")
	if len(credentialEvidence) > 0 {
		coverage.Evidence = append(coverage.Evidence, credentialEvidence...)
	}

	if limitations := relevantManifestLimitations(input.DataCoverage); len(limitations) > 0 {
		coverage.Limitations = append(coverage.Limitations, limitations...)
	}
	unsupported := unsupportedRuntimeSourceSurfaces(root)
	if len(unsupported) > 0 {
		coverage.Limitations = append(coverage.Limitations,
			"unsupported runtime source languages require authentication analysis")
		coverage.Evidence = append(coverage.Evidence, unsupported...)
	} else {
		coverage.CompletedChecks = append(coverage.CompletedChecks, "supported-language-surface-inventory")
	}
	if languageLimitation := authenticationLanguageLimitation(root, input); languageLimitation != "" {
		coverage.Limitations = append(coverage.Limitations, languageLimitation)
	} else {
		coverage.CompletedChecks = append(coverage.CompletedChecks, "applicable-language-runtime-inventory")
	}
	if applicableCoverage(input.DataCoverage["python"]) {
		files, matches, limitations := scanPythonAuthenticationSignals(root)
		coverage.CompletedChecks = append(coverage.CompletedChecks, "python-authentication-signal-scan")
		coverage.Evidence = append(coverage.Evidence,
			fmt.Sprintf("summary:scanned %d Python source files for authentication constructions", files))
		coverage.Evidence = append(coverage.Evidence, matches...)
		coverage.Limitations = append(coverage.Limitations, limitations...)
		unaccounted := filterUnaccountedAuthSignals(matches, input.Authentication)
		if len(unaccounted) > 0 && inbound > 0 {
			coverage.Limitations = append(coverage.Limitations,
				"Python authentication constructions require fact-level relationship accounting")
		}
	}
	coverage.Evidence = capCoverageEvidence(coverage.Evidence, 12)
	if len(coverage.Limitations) == 0 {
		coverage.Status = "complete"
	}
	return coverage
}

func filterUnaccountedAuthSignals(matches []string, facts []model.AuthenticationFact) []string {
	accountedFiles := map[string]bool{}
	for _, fact := range facts {
		file := strings.SplitN(fact.Source, ":", 2)[0]
		accountedFiles[file] = true
	}
	var unaccounted []string
	for _, match := range matches {
		file := strings.SplitN(match, " (", 2)[0]
		if !accountedFiles[file] {
			unaccounted = append(unaccounted, match)
		}
	}
	return unaccounted
}

func hasPythonAuthFacts(facts []model.AuthenticationFact) bool {
	for _, fact := range facts {
		src := strings.SplitN(fact.Source, ":", 2)[0]
		if strings.HasSuffix(src, ".py") {
			return true
		}
	}
	return false
}

func authenticationCredentialEvidence(secrets []model.Secret) []string {
	var result []string
	for _, secret := range secrets {
		name := strings.ToUpper(strings.ReplaceAll(secret.Name, "-", "_"))
		if !containsAny(name,
			"TOKEN", "PASSWORD", "API_KEY", "APIKEY", "CREDENTIAL",
			"CLIENT_SECRET", "PRIVATE_KEY", "SECRET_ACCESS_KEY", "SECRET_KEY") {
			continue
		}
		evidence := secret.Source
		if evidence == "" {
			evidence = "secret:" + secret.Name
		}
		result = appendUnique(result, evidence+" (credential "+secret.Name+")")
	}
	sort.Strings(result)
	return result
}

func containsAny(value string, needles ...string) bool {
	for _, needle := range needles {
		if strings.Contains(value, needle) {
			return true
		}
	}
	return false
}

func scanPythonAuthenticationSignals(root string) (int, []string, []string) {
	files := 0
	matchCount := 0
	var matches, limitations []string
	err := filepath.WalkDir(root, func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			limitations = append(limitations, "unable to inspect "+filepath.ToSlash(path)+": "+err.Error())
			return nil
		}
		if entry.IsDir() {
			if path != root && ignoredCoverageDir(entry.Name()) {
				return filepath.SkipDir
			}
			return nil
		}
		relative, relativeErr := filepath.Rel(root, path)
		if relativeErr != nil {
			limitations = append(limitations, "unable to relativize "+filepath.ToSlash(path))
			return nil
		}
		relative = filepath.ToSlash(relative)
		if strings.ToLower(filepath.Ext(relative)) != ".py" || !isRuntimeCoverageFile(relative) {
			return nil
		}
		content, readErr := os.ReadFile(path)
		if readErr != nil {
			limitations = append(limitations, "unable to read "+relative+": "+readErr.Error())
			return nil
		}
		files++
		if !pythonAuthenticationSignal.Match(content) {
			return nil
		}
		matchCount++
		if len(matches) < 12 {
			matches = appendUnique(matches, relative+" (authentication construction)")
		}
		return nil
	})
	if err != nil {
		limitations = append(limitations, "Python authentication signal scan failed: "+err.Error())
	}
	if matchCount > len(matches) {
		matches = append(matches, fmt.Sprintf("summary:%d additional matching Python files omitted", matchCount-len(matches)))
	}
	sort.Strings(matches)
	sort.Strings(limitations)
	return files, matches, limitations
}

func capCoverageEvidence(items []string, maximum int) []string {
	if len(items) <= maximum {
		return items
	}
	remaining := len(items) - maximum
	result := append([]string{}, items[:maximum]...)
	return append(result, fmt.Sprintf("summary:%d additional evidence items omitted", remaining))
}

func unsupportedRuntimeSourceSurfaces(root string) []string {
	unsupportedExtensions := map[string]bool{
		".c": true, ".cc": true, ".cpp": true, ".cs": true, ".h": true,
		".hpp": true, ".java": true, ".kt": true, ".kts": true, ".php": true,
		".rb": true, ".scala": true, ".sh": true,
	}
	var evidence []string
	_ = filepath.WalkDir(root, func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			if len(evidence) < 12 {
				evidence = appendUnique(evidence, "unable to inspect "+filepath.ToSlash(path)+": "+err.Error())
			}
			return nil
		}
		if entry.IsDir() {
			if path != root && ignoredCoverageDir(entry.Name()) {
				return filepath.SkipDir
			}
			return nil
		}
		relative, relativeErr := filepath.Rel(root, path)
		if relativeErr != nil {
			return nil
		}
		relative = filepath.ToSlash(relative)
		name := strings.ToLower(filepath.Base(relative))
		if strings.Contains(name, ".test.") || strings.Contains(name, ".spec.") ||
			strings.HasPrefix(name, "test_") {
			return nil
		}
		if strings.ToLower(filepath.Ext(name)) == ".sh" && isSupportOnlyShellScript(relative) {
			return nil
		}
		ext := strings.ToLower(filepath.Ext(name))
		if (ext == ".c" || ext == ".cc" || ext == ".cpp" || ext == ".h" || ext == ".hpp") && isSupportOnlyNativeSource(relative) {
			return nil
		}
		if unsupportedExtensions[strings.ToLower(filepath.Ext(name))] && len(evidence) < 12 {
			evidence = appendUnique(evidence, relative+" (unsupported runtime source)")
		}
		return nil
	})
	sort.Strings(evidence)
	return evidence
}

func isSupportOnlyShellScript(path string) bool {
	path = strings.ToLower(filepath.ToSlash(path))
	parts := strings.Split(path, "/")
	for _, part := range parts[:len(parts)-1] {
		switch part {
		case ".devcontainer", "completions", "contrib", "documentation", "mkdocs", "packaging", "site-src":
			return true
		}
		if part == "ci" || strings.HasPrefix(part, "ci-") || strings.Contains(part, "-ci-") ||
			strings.Contains(part, "e2e") {
			return true
		}
	}
	if containsPathPart(parts[:len(parts)-1], "hack") || containsPathPart(parts[:len(parts)-1], "scripts") ||
		containsPathPart(parts[:len(parts)-1], "tasks") || containsPathPart(parts[:len(parts)-1], "tools") {
		return !runtimeShellScriptRole(parts)
	}
	basename := strings.TrimSuffix(parts[len(parts)-1], filepath.Ext(parts[len(parts)-1]))
	switch basename {
	case "build", "dist", "make", "package", "release":
		return true
	}
	if strings.HasPrefix(basename, "build_") || strings.HasPrefix(basename, "build-") {
		return true
	}
	if strings.Contains(basename, "autocomplete") || strings.Contains(basename, "completion") {
		return true
	}
	switch basename {
	case "pre-commit", "commit-msg", "pre-push", "prepare-commit-msg",
		"pre-rebase", "post-checkout", "post-merge":
		return true
	}
	return false
}

func runtimeShellScriptRole(parts []string) bool {
	for _, part := range parts {
		part = strings.TrimSuffix(part, filepath.Ext(part))
		switch part {
		case "deploy", "deployment", "deployments", "entrypoint", "hook", "hooks", "operator", "startup":
			return true
		}
		if strings.Contains(part, "entrypoint") || strings.Contains(part, "deploy-hook") ||
			strings.Contains(part, "operator-hook") || strings.HasPrefix(part, "start_") ||
			strings.HasPrefix(part, "start-") || part == "start" {
			return true
		}
	}
	return false
}

func isSupportOnlyNativeSource(path string) bool {
	path = strings.ToLower(filepath.ToSlash(path))
	parts := strings.Split(path, "/")
	for _, part := range parts[:len(parts)-1] {
		switch part {
		case ".devcontainer", "completions", "contrib", "documentation", "hack",
			"mkdocs", "packaging", "scripts", "site-src", "tasks", "tools":
			return true
		}
		if part == "ci" || strings.HasPrefix(part, "ci-") || strings.Contains(part, "-ci-") ||
			strings.Contains(part, "e2e") {
			return true
		}
	}
	return false
}

func containsPathPart(parts []string, wanted string) bool {
	for _, part := range parts {
		if part == wanted {
			return true
		}
	}
	return false
}

func inboundRuntimeSurfaces(input model.Input) (int, []string) {
	count := 0
	evidence := make([]string, 0, 6)
	add := func(source string) {
		if source != "" && len(evidence) < 6 {
			evidence = appendUnique(evidence, source)
		}
	}
	for _, item := range input.HTTPEndpoints {
		if !runtimeSurfaceSource(item.Source) {
			continue
		}
		if httpAuthenticationAccounted(item, input.Authentication) {
			continue
		}
		count++
		add(item.Source)
	}
	for _, item := range input.GRPCServices {
		if !runtimeSurfaceSource(item.Source) {
			continue
		}
		if grpcAuthenticationAccounted(item, input.Authentication) {
			continue
		}
		count++
		add(item.Source)
	}
	for _, item := range input.Webhooks {
		if len(item.Sources) > 0 && !runtimeSurfaceSource(item.Sources[0].File) {
			continue
		}
		count++
	}
	for _, item := range input.IngressRouting {
		if !runtimeSurfaceSource(item.Source) {
			continue
		}
		count++
		add(item.Source)
	}
	for _, item := range input.Services {
		if !runtimeSurfaceSource(item.Source) {
			continue
		}
		count++
		add(item.Source)
	}
	for _, deployment := range input.Deployments {
		if !runtimeSurfaceSource(deployment.Source) {
			continue
		}
		for _, container := range deployment.Containers {
			for _, probe := range []*model.Probe{container.LivenessProbe, container.ReadinessProbe} {
				if probe != nil && probe.Path != "" {
					count++
					add(deployment.Source)
				}
			}
		}
	}
	return count, evidence
}

func grpcAuthenticationAccounted(service model.GRPCService, facts []model.AuthenticationFact) bool {
	wanted := normalizeGRPCAuthenticationName(service.Service)
	for _, fact := range facts {
		if strings.EqualFold(strings.TrimSpace(fact.Methods), "gRPC") &&
			normalizeGRPCAuthenticationName(fact.Endpoint) == wanted {
			return true
		}
	}
	return false
}

func httpAuthenticationAccounted(endpoint model.HTTPEndpoint, facts []model.AuthenticationFact) bool {
	path := strings.TrimSpace(endpoint.Path)
	if path == "" {
		return false
	}
	for _, fact := range facts {
		factEndpoint := strings.TrimSpace(fact.Endpoint)
		if strings.EqualFold(factEndpoint, path) {
			return true
		}
	}
	return false
}

func normalizeGRPCAuthenticationName(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	value = strings.TrimSuffix(value, " grpc")
	return strings.NewReplacer(" ", "", "-", "", "_", "").Replace(value)
}

func runtimeSurfaceSource(source string) bool {
	if strings.TrimSpace(source) == "" {
		return true
	}
	path := strings.ToLower(strings.SplitN(filepath.ToSlash(source), ":", 2)[0])
	parts := strings.Split(strings.Trim(path, "/"), "/")
	for _, part := range parts {
		switch part {
		case "conformance", "docs", "test", "tests", "testdata", "example", "examples", "sample", "samples":
			return false
		}
	}
	return !strings.HasSuffix(path, "_test.go")
}

func authenticationLanguageLimitation(root string, input model.Input) string {
	coverage := input.DataCoverage
	if applicableCoverage(coverage["source"]) {
		return "Go source authentication constructs do not yet have a complete category-specific extractor"
	}
	if applicableCoverage(coverage["rust"]) {
		return "Rust source authentication constructs do not yet have a complete category-specific extractor"
	}
	if applicableCoverage(coverage["web_workspace"]) {
		return "web workspace authentication constructs do not yet have a complete category-specific extractor"
	}
	if applicableCoverage(coverage["python"]) && !hasPythonAuthFacts(input.Authentication) {
		for _, dependency := range input.Dependencies.Packages {
			if inboundPythonPackages[strings.ToLower(dependency.Name)] && pythonServerConstructPresent(root, dependency.Name) {
				return "Python server framework is present and dynamic authentication composition is unresolved"
			}
		}
	}
	return ""
}

func pythonServerConstructPresent(root, packageName string) bool {
	patterns := map[string][]string{
		"django":    {"django.core", "django.urls", "django.http"},
		"fastapi":   {"fastapi(", "fastapi import", "from fastapi"},
		"flask":     {"flask(", "flask import", "from flask"},
		"sanic":     {"sanic(", "from sanic"},
		"starlette": {"starlette(", "from starlette"},
		"tornado":   {"tornado.web", "application.listen("},
		"uvicorn":   {"uvicorn.run("},
	}
	wanted := patterns[strings.ToLower(packageName)]
	if len(wanted) == 0 {
		return false
	}
	found := false
	_ = filepath.WalkDir(root, func(path string, entry os.DirEntry, err error) error {
		if err != nil || found {
			return nil
		}
		if entry.IsDir() {
			if path != root && ignoredCoverageDir(entry.Name()) {
				return filepath.SkipDir
			}
			return nil
		}
		if strings.ToLower(filepath.Ext(path)) != ".py" || !isRuntimeCoverageFile(path) {
			return nil
		}
		content, readErr := os.ReadFile(path)
		if readErr != nil {
			return nil
		}
		lower := strings.ToLower(string(content))
		for _, pattern := range wanted {
			if strings.Contains(lower, pattern) {
				found = true
				break
			}
		}
		return nil
	})
	return found
}

func applicableCoverage(value string) bool {
	value = strings.TrimSpace(strings.ToLower(value))
	return value != "" && value != "not_applicable" && value != "not_analyzed" && value != "not_found"
}

func relevantManifestLimitations(coverage map[string]string) []string {
	var result []string
	if value := coverage["kustomize"]; strings.HasPrefix(strings.ToLower(value), "partial:") {
		result = append(result, "kustomize resolution is partial: "+strings.TrimSpace(strings.SplitN(value, ":", 2)[1]))
	}
	value := coverage["manifests"]
	if !strings.HasPrefix(strings.ToLower(value), "partial:") {
		return result
	}
	detail := strings.TrimSpace(strings.SplitN(value, ":", 2)[1])
	for _, item := range strings.Split(detail, ";") {
		item = strings.TrimSpace(item)
		path := item
		if index := strings.LastIndex(item, ": "); index >= 0 {
			path = strings.TrimSpace(item[index+2:])
		}
		if !isRuntimeManifestPath(path) {
			continue
		}
		result = append(result, "manifest discovery is partial: "+item)
	}
	return result
}

func relevantInternalDependencyManifestLimitations(coverage map[string]string) []string {
	var result []string
	if value := coverage["kustomize"]; strings.HasPrefix(strings.ToLower(value), "partial:") {
		detail := strings.TrimSpace(strings.SplitN(value, ":", 2)[1])
		for _, warning := range strings.Split(detail, ";") {
			warning = strings.TrimSpace(warning)
			if warning == "" || !dependencyRelevantKustomizeWarning(warning) {
				continue
			}
			result = append(result, "kustomize resolution is partial: "+warning)
		}
	}

	value := coverage["manifests"]
	if !strings.HasPrefix(strings.ToLower(value), "partial:") {
		return result
	}
	detail := strings.TrimSpace(strings.SplitN(value, ":", 2)[1])
	for _, item := range strings.Split(detail, ";") {
		item = strings.TrimSpace(item)
		path := item
		if index := strings.LastIndex(item, ": "); index >= 0 {
			path = strings.TrimSpace(item[index+2:])
		}
		if isRuntimeManifestPath(path) {
			result = append(result, "manifest discovery is partial: "+item)
		}
	}
	return result
}

func dependencyRelevantKustomizeWarning(warning string) bool {
	// Image rewrites only change the artifact used by an already selected workload.
	// They cannot add resources, API groups, watches, clients, or runtime references.
	return strings.ToLower(strings.TrimSpace(warning)) != "image transforms not resolved"
}

func internalDependencyCoverage(root string, input model.Input) model.CategoryCoverage {
	coverage := model.CategoryCoverage{
		Status: "partial", FactCount: len(input.Dependencies.Internal),
		DiscoveryContract: internalDependenciesContract,
		CompletedChecks:   []string{"normalized-platform-dependency-facts"},
		Limitations:       []string{},
		Evidence:          []string{},
	}
	files, matches, limitations := scanInternalPlatformAliases(root, input)
	coverage.CompletedChecks = append(coverage.CompletedChecks, "runtime-source-config-platform-alias-scan")
	coverage.Evidence = append(coverage.Evidence,
		fmt.Sprintf("summary:scanned %d runtime source/config files against %d platform aliases", files, len(internalPlatformAliases)))
	coverage.Evidence = append(coverage.Evidence, matches...)
	coverage.Limitations = append(coverage.Limitations, limitations...)
	manifestLimitations := relevantInternalDependencyManifestLimitations(input.DataCoverage)
	coverage.Limitations = append(coverage.Limitations, manifestLimitations...)
	if len(manifestLimitations) == 0 {
		coverage.CompletedChecks = append(coverage.CompletedChecks, "dependency-impacting-manifest-resolution")
	}
	unsupported := unsupportedRuntimeSourceSurfaces(root)
	if len(unsupported) > 0 {
		coverage.Limitations = append(coverage.Limitations,
			"unsupported runtime source languages require platform dependency analysis")
		coverage.Evidence = append(coverage.Evidence, unsupported...)
	} else {
		coverage.CompletedChecks = append(coverage.CompletedChecks, "supported-language-surface-inventory")
	}
	if len(coverage.Limitations) == 0 {
		coverage.Status = "complete"
	}
	coverage.Evidence = capCoverageEvidence(coverage.Evidence, 12)
	return coverage
}

func integrationPointsCoverage(root string, input model.Input) model.CategoryCoverage {
	coverage := model.CategoryCoverage{
		Status: "partial", FactCount: len(input.IntegrationPoints),
		DiscoveryContract: integrationPointsContract,
		CompletedChecks:   []string{"normalized-integration-point-facts"},
		Limitations:       []string{},
		Evidence:          []string{},
	}

	runtimeClients := runtimeSourcedOutboundClients(input.RuntimeClients)
	unaccountedClients := unaccountedOutboundClients(runtimeClients, input.IntegrationPoints)
	if len(unaccountedClients) > 0 {
		coverage.Limitations = append(coverage.Limitations,
			fmt.Sprintf("%d outbound runtime client constructions are not accounted for by integration point facts", len(unaccountedClients)))
		coverage.Evidence = append(coverage.Evidence, unaccountedClients...)
	} else {
		coverage.CompletedChecks = append(coverage.CompletedChecks, "outbound-runtime-client-accounting")
		if len(runtimeClients) == 0 {
			coverage.Evidence = append(coverage.Evidence, "summary:no analyzer-discovered outbound runtime clients")
		} else {
			coverage.Evidence = append(coverage.Evidence,
				fmt.Sprintf("summary:%d outbound runtime clients accounted for by integration point facts", len(runtimeClients)))
		}
	}

	externalConns := runtimeSourcedExternalConnections(input.ExternalConnections)
	unaccountedConns := unaccountedExternalConnections(externalConns, input.IntegrationPoints)
	if len(unaccountedConns) > 0 {
		coverage.Limitations = append(coverage.Limitations,
			fmt.Sprintf("%d external connections are not accounted for by integration point facts", len(unaccountedConns)))
		coverage.Evidence = append(coverage.Evidence, unaccountedConns...)
	} else {
		coverage.CompletedChecks = append(coverage.CompletedChecks, "external-connection-accounting")
		if len(externalConns) == 0 {
			coverage.Evidence = append(coverage.Evidence, "summary:no analyzer-discovered external connections")
		} else {
			coverage.Evidence = append(coverage.Evidence,
				fmt.Sprintf("summary:%d external connections accounted for by integration point facts", len(externalConns)))
		}
	}

	unsupported := unsupportedRuntimeSourceSurfaces(root)
	if len(unsupported) > 0 {
		coverage.Limitations = append(coverage.Limitations,
			"unsupported runtime source languages require integration point analysis")
		coverage.Evidence = append(coverage.Evidence, unsupported...)
	} else {
		coverage.CompletedChecks = append(coverage.CompletedChecks, "supported-language-surface-inventory")
	}

	manifestLimitations := relevantManifestLimitations(input.DataCoverage)
	if len(manifestLimitations) > 0 {
		coverage.Limitations = append(coverage.Limitations, manifestLimitations...)
	} else {
		coverage.CompletedChecks = append(coverage.CompletedChecks, "manifest-resolution-completeness")
	}

	coverage.Evidence = capCoverageEvidence(coverage.Evidence, 12)
	if len(coverage.Limitations) == 0 {
		coverage.Status = "complete"
	}
	return coverage
}

func runtimeSourcedOutboundClients(clients []model.RuntimeClient) []model.RuntimeClient {
	var result []model.RuntimeClient
	for _, client := range clients {
		if runtimeSurfaceSource(client.Source) {
			result = append(result, client)
		}
	}
	return result
}

func unaccountedOutboundClients(clients []model.RuntimeClient, facts []model.IntegrationFact) []string {
	var unaccounted []string
	for _, client := range clients {
		if integrationFactCoversClient(client, facts) {
			continue
		}
		evidence := client.Source
		if evidence == "" {
			evidence = "runtime-client:" + client.Target
		}
		unaccounted = appendUnique(unaccounted, evidence+" (unaccounted runtime client: "+client.Target+")")
	}
	return unaccounted
}

func integrationFactCoversClient(client model.RuntimeClient, facts []model.IntegrationFact) bool {
	target := strings.ToLower(strings.TrimSpace(client.Target))
	for _, fact := range facts {
		component := strings.ToLower(strings.TrimSpace(fact.Component))
		if component == target || strings.Contains(component, target) || strings.Contains(target, component) {
			return true
		}
	}
	return false
}

func runtimeSourcedExternalConnections(connections []model.ExternalConnection) []model.ExternalConnection {
	var result []model.ExternalConnection
	for _, conn := range connections {
		if runtimeSurfaceSource(conn.Source) {
			result = append(result, conn)
		}
	}
	return result
}

func unaccountedExternalConnections(connections []model.ExternalConnection, facts []model.IntegrationFact) []string {
	var unaccounted []string
	for _, conn := range connections {
		if integrationFactCoversConnection(conn, facts) {
			continue
		}
		evidence := conn.Source
		if evidence == "" {
			evidence = "external-connection:" + conn.Service
		}
		unaccounted = appendUnique(unaccounted, evidence+" (unaccounted external connection: "+conn.Service+")")
	}
	return unaccounted
}

func integrationFactCoversConnection(conn model.ExternalConnection, facts []model.IntegrationFact) bool {
	service := strings.ToLower(strings.TrimSpace(conn.Service))
	target := strings.ToLower(strings.TrimSpace(conn.Target))
	for _, fact := range facts {
		component := strings.ToLower(strings.TrimSpace(fact.Component))
		if component == service || strings.Contains(component, service) || strings.Contains(service, component) {
			return true
		}
		if target != "" && (component == target || strings.Contains(component, target) || strings.Contains(target, component)) {
			return true
		}
	}
	return false
}

func scanInternalPlatformAliases(root string, input model.Input) (int, []string, []string) {
	files := 0
	matchCount := 0
	blockingCount := 0
	unusedGVKs := unusedGoGVKDeclarations(root)
	var matches, limitations []string
	err := filepath.WalkDir(root, func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			limitations = append(limitations, "unable to inspect "+filepath.ToSlash(path)+": "+err.Error())
			return nil
		}
		if entry.IsDir() {
			if path != root && ignoredCoverageDir(entry.Name()) {
				return filepath.SkipDir
			}
			return nil
		}
		relative, relativeErr := filepath.Rel(root, path)
		if relativeErr != nil {
			limitations = append(limitations, "unable to relativize "+filepath.ToSlash(path))
			return nil
		}
		relative = filepath.ToSlash(relative)
		if !isDependencyCoverageFile(relative) {
			return nil
		}
		content, readErr := os.ReadFile(path)
		if readErr != nil {
			limitations = append(limitations, "unable to read "+relative+": "+readErr.Error())
			return nil
		}
		files++
		lower := strings.ToLower(string(content))
		for _, alias := range internalPlatformAliases {
			if !strings.Contains(lower, alias) {
				continue
			}
			classification, blocking := classifyPlatformAliasMatch(relative, content, alias, input, unusedGVKs)
			matchCount++
			if blocking {
				blockingCount++
			}
			if len(matches) < 12 {
				matches = appendUnique(matches, relative+" ("+alias+"; "+classification+")")
			}
		}
		return nil
	})
	if err != nil {
		limitations = append(limitations, "runtime source/config scan failed: "+err.Error())
	}
	if matchCount > len(matches) {
		matches = append(matches, fmt.Sprintf("summary:%d additional matching files omitted", matchCount-len(matches)))
	}
	if blockingCount > 0 {
		limitations = append(limitations,
			fmt.Sprintf("%d active platform alias references require relationship accounting", blockingCount))
	}
	sort.Strings(matches)
	sort.Strings(limitations)
	return files, matches, limitations
}

func classifyPlatformAliasMatch(
	relative string,
	content []byte,
	alias string,
	input model.Input,
	unusedGVKs map[string]bool,
) (string, bool) {
	if aliasOnlyInComments(content, alias) {
		return "commented configuration", false
	}
	if unusedGVKs[relative+"\x00"+alias] {
		return "unused GVK declaration", false
	}
	if ownedAPIGroup(alias, input.CRDs) {
		return "self-owned API", false
	}
	if aliasOnlyInDependencyDeclaration(relative, content, alias) {
		return "dependency declaration", false
	}
	if aliasOnlyAsSubdomain(content, alias) {
		return "naming convention (subdomain)", false
	}
	if aliasOnlyInGoIdentifiers(relative, content, alias) {
		return "naming convention (Go identifier)", false
	}
	if isRuntimeManifestPath(relative) && isStructuredManifest(relative) {
		if !selectedManifestSource(relative, input) {
			return "unselected manifest configuration", false
		}
		if internalDependencySource(relative, input.Dependencies.Internal) {
			return "accounted selected manifest relationship", false
		}
		return "selected manifest relationship", true
	}
	if internalDependencySource(relative, input.Dependencies.Internal) {
		return "accounted runtime relationship", false
	}
	return "runtime source/config reference", true
}

type goGVKDeclaration struct {
	path       string
	packageDir string
	packageID  string
	name       string
	alias      string
	position   token.Pos
}

type parsedCoverageGoFile struct {
	path       string
	packageDir string
	packageID  string
	file       *ast.File
}

func unusedGoGVKDeclarations(root string) map[string]bool {
	fileSet := token.NewFileSet()
	var files []parsedCoverageGoFile
	_ = filepath.WalkDir(root, func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			return nil
		}
		if entry.IsDir() {
			if path != root && ignoredCoverageDir(entry.Name()) {
				return filepath.SkipDir
			}
			return nil
		}
		relative, relativeErr := filepath.Rel(root, path)
		if relativeErr != nil {
			return nil
		}
		relative = filepath.ToSlash(relative)
		if strings.ToLower(filepath.Ext(relative)) != ".go" || !isRuntimeCoverageFile(relative) {
			return nil
		}
		parsed, parseErr := parser.ParseFile(fileSet, path, nil, 0)
		if parseErr != nil {
			return nil
		}
		packageDir := filepath.ToSlash(filepath.Dir(relative))
		files = append(files, parsedCoverageGoFile{
			path: relative, packageDir: packageDir,
			packageID: packageDir + "\x00" + parsed.Name.Name, file: parsed,
		})
		return nil
	})

	var declarations []goGVKDeclaration
	for _, file := range files {
		for _, declaration := range file.file.Decls {
			generic, ok := declaration.(*ast.GenDecl)
			if !ok || generic.Tok != token.VAR {
				continue
			}
			for _, raw := range generic.Specs {
				value, ok := raw.(*ast.ValueSpec)
				if !ok {
					continue
				}
				for index, expression := range value.Values {
					literal, ok := expression.(*ast.CompositeLit)
					if !ok || !groupVersionKindType(literal.Type) || index >= len(value.Names) {
						continue
					}
					alias := goCompositeStringField(literal, "Group")
					if alias == "" || !stringInSlice(alias, internalPlatformAliases) {
						continue
					}
					declarations = append(declarations, goGVKDeclaration{
						path: file.path, packageDir: file.packageDir, packageID: file.packageID,
						name: value.Names[index].Name, alias: alias, position: value.Names[index].Pos(),
					})
				}
			}
		}
	}

	result := map[string]bool{}
	for _, declaration := range declarations {
		used := false
		for _, file := range files {
			ast.Inspect(file.file, func(node ast.Node) bool {
				if used {
					return false
				}
				switch typed := node.(type) {
				case *ast.Ident:
					if file.packageID == declaration.packageID && typed.Name == declaration.name && typed.Pos() != declaration.position {
						used = true
					}
				case *ast.SelectorExpr:
					if file.packageID != declaration.packageID && typed.Sel.Name == declaration.name {
						used = true
					}
				}
				return !used
			})
			if used {
				break
			}
		}
		if !used {
			result[declaration.path+"\x00"+declaration.alias] = true
		}
	}
	return result
}

func groupVersionKindType(expression ast.Expr) bool {
	selector, ok := expression.(*ast.SelectorExpr)
	return ok && selector.Sel.Name == "GroupVersionKind"
}

func goCompositeStringField(literal *ast.CompositeLit, name string) string {
	for _, element := range literal.Elts {
		field, ok := element.(*ast.KeyValueExpr)
		if !ok {
			continue
		}
		identifier, ok := field.Key.(*ast.Ident)
		if !ok || identifier.Name != name {
			continue
		}
		value, ok := field.Value.(*ast.BasicLit)
		if !ok || value.Kind != token.STRING {
			return ""
		}
		unquoted, err := strconv.Unquote(value.Value)
		if err == nil {
			return strings.ToLower(unquoted)
		}
	}
	return ""
}

func stringInSlice(value string, values []string) bool {
	for _, candidate := range values {
		if value == candidate {
			return true
		}
	}
	return false
}

func aliasOnlyInComments(content []byte, alias string) bool {
	alias = strings.ToLower(alias)
	found := false
	for _, line := range strings.Split(strings.ToLower(string(content)), "\n") {
		searchFrom := 0
		for {
			index := strings.Index(line[searchFrom:], alias)
			if index < 0 {
				break
			}
			index += searchFrom
			found = true
			if !occurrenceIsCommented(line, index) {
				return false
			}
			searchFrom = index + len(alias)
		}
	}
	return found
}

func occurrenceIsCommented(line string, aliasIndex int) bool {
	trimmed := strings.TrimSpace(line[:aliasIndex])
	if strings.HasPrefix(trimmed, "#") || strings.HasPrefix(trimmed, "//") ||
		strings.HasPrefix(trimmed, "/*") || strings.HasPrefix(trimmed, "*") ||
		strings.HasPrefix(trimmed, "<!--") {
		return true
	}
	for _, marker := range []string{"#", "//", "/*", "<!--"} {
		markerIndex := strings.Index(line[:aliasIndex], marker)
		if markerIndex < 0 {
			continue
		}
		if markerIndex == 0 || line[markerIndex-1] == ' ' || line[markerIndex-1] == '\t' {
			return true
		}
	}
	return false
}

func ownedAPIGroup(alias string, crds []model.CRD) bool {
	for _, crd := range crds {
		if strings.EqualFold(strings.TrimSpace(crd.Group), alias) {
			return true
		}
	}
	return false
}

func aliasOnlyInDependencyDeclaration(relative string, content []byte, alias string) bool {
	name := strings.ToLower(filepath.Base(relative))
	switch name {
	case "go.mod", "go.sum", "cargo.toml", "cargo.lock", "package.json", "package-lock.json", "pnpm-lock.yaml", "yarn.lock", "pyproject.toml":
		return true
	}
	if strings.ToLower(filepath.Ext(name)) != ".go" {
		return false
	}

	alias = strings.ToLower(alias)
	inImportBlock := false
	found := false
	for _, line := range strings.Split(strings.ToLower(string(content)), "\n") {
		trimmed := strings.TrimSpace(line)
		if trimmed == "import (" {
			inImportBlock = true
			continue
		}
		if inImportBlock && trimmed == ")" {
			inImportBlock = false
			continue
		}
		if !strings.Contains(line, alias) || occurrenceIsCommented(line, strings.Index(line, alias)) {
			continue
		}
		found = true
		if !inImportBlock && !strings.HasPrefix(trimmed, "import ") {
			return false
		}
	}
	return found
}

func aliasOnlyAsSubdomain(content []byte, alias string) bool {
	alias = strings.ToLower(alias)
	lower := strings.ToLower(string(content))
	found := false
	searchFrom := 0
	for {
		index := strings.Index(lower[searchFrom:], alias)
		if index < 0 {
			break
		}
		index += searchFrom
		found = true
		if index == 0 || lower[index-1] != '.' {
			return false
		}
		searchFrom = index + len(alias)
	}
	return found
}

func aliasOnlyInGoIdentifiers(relative string, content []byte, alias string) bool {
	if strings.ToLower(filepath.Ext(relative)) != ".go" {
		return false
	}
	alias = strings.ToLower(alias)
	found := false
	for _, line := range strings.Split(strings.ToLower(string(content)), "\n") {
		searchFrom := 0
		for {
			index := strings.Index(line[searchFrom:], alias)
			if index < 0 {
				break
			}
			index += searchFrom
			found = true
			if !occurrenceIsCommented(line, index) && occurrenceInStringLiteral(line, index) {
				return false
			}
			searchFrom = index + len(alias)
		}
	}
	return found
}

func occurrenceInStringLiteral(line string, aliasIndex int) bool {
	quotes := 0
	for i := 0; i < aliasIndex; i++ {
		if line[i] == '"' && (i == 0 || line[i-1] != '\\') {
			quotes++
		}
	}
	return quotes%2 == 1
}

func isStructuredManifest(path string) bool {
	switch strings.ToLower(filepath.Ext(path)) {
	case ".yaml", ".yml", ".json":
		return true
	default:
		return false
	}
}

func selectedManifestSource(relative string, input model.Input) bool {
	var sources []string
	for _, crd := range input.CRDs {
		sources = append(sources, crd.Source)
	}
	for _, service := range input.Services {
		sources = append(sources, service.Source)
	}
	for _, deployment := range input.Deployments {
		sources = append(sources, deployment.Source)
	}
	for _, role := range append(append([]model.Role{}, input.RBAC.ClusterRoles...), input.RBAC.Roles...) {
		sources = append(sources, role.Source)
	}
	for _, binding := range append(append([]model.Binding{}, input.RBAC.ClusterRoleBindings...), input.RBAC.RoleBindings...) {
		sources = append(sources, binding.Source)
	}
	for _, ingress := range input.IngressRouting {
		sources = append(sources, ingress.Source)
	}
	for _, secret := range input.Secrets {
		sources = append(sources, secret.Source)
	}
	for _, webhook := range input.Webhooks {
		for _, source := range webhook.Sources {
			sources = append(sources, source.File)
		}
	}
	for _, source := range sources {
		if sourceMatchesPath(source, relative) {
			return true
		}
	}
	return false
}

func internalDependencySource(relative string, dependencies []model.InternalDependency) bool {
	for _, dependency := range dependencies {
		if sourceMatchesPath(dependency.Source, relative) {
			return true
		}
	}
	return false
}

func sourceMatchesPath(source, relative string) bool {
	source = strings.TrimPrefix(filepath.ToSlash(strings.TrimSpace(source)), "./")
	relative = strings.TrimPrefix(filepath.ToSlash(strings.TrimSpace(relative)), "./")
	return source == relative || strings.HasPrefix(source, relative+":")
}

func ignoredCoverageDir(name string) bool {
	switch strings.ToLower(name) {
	case ".buildkite", ".git", ".hg", ".svn", ".github", ".tekton",
		"__mocks__", "chaos", "contracts", "csrc", "dist", "docs", "examples",
		"fake", "fakes", "fixture", "fixtures",
		"k8mocks", "mock", "mocks", "node_modules",
		"benchmarks", "sample", "samples",
		"test", "testdata", "tests", "testutil", "testutils",
		"vendor":
		return true
	default:
		return false
	}
}

func isRuntimeCoverageFile(path string) bool {
	name := strings.ToLower(filepath.Base(path))
	if name == "component-architecture.json" {
		return false
	}
	if strings.HasSuffix(name, "_test.go") || strings.HasPrefix(name, "test_") ||
		strings.Contains(name, ".test.") || strings.Contains(name, ".spec.") ||
		strings.Contains(name, "snapshot") || strings.HasPrefix(name, "zz_generated") ||
		strings.HasSuffix(name, "_generated.go") {
		return false
	}
	switch strings.ToLower(filepath.Ext(name)) {
	case ".go", ".py", ".rs", ".ts", ".tsx", ".js", ".jsx", ".yaml", ".yml", ".json", ".toml":
		return true
	default:
		return name == "go.mod" || name == "cargo.toml" || name == "package.json" || name == "pyproject.toml"
	}
}

func isDependencyCoverageFile(path string) bool {
	if !isRuntimeCoverageFile(path) {
		return false
	}
	extension := strings.ToLower(filepath.Ext(path))
	if extension != ".yaml" && extension != ".yml" && extension != ".json" && extension != ".toml" {
		return true
	}
	parts := strings.Split(strings.ToLower(filepath.ToSlash(path)), "/")
	for _, part := range parts[:len(parts)-1] {
		switch part {
		case "benchmark", "benchmarks", "corpus", "datasets", "prompts", "tasks":
			return false
		}
	}
	return true
}

func isRuntimeManifestPath(path string) bool {
	path = strings.TrimPrefix(filepath.ToSlash(strings.TrimSpace(path)), "./")
	parts := strings.Split(strings.ToLower(path), "/")
	for _, part := range parts[:len(parts)-1] {
		switch part {
		case "chart", "charts", "config", "deploy", "deployments", "helm", "k8s", "kubernetes", "manifests", "operator":
			return true
		}
	}
	if len(parts) == 1 {
		return true
	}
	return false
}
