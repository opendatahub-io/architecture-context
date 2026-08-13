package gosource

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"go/version"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
	"golang.org/x/mod/modfile"
	"golang.org/x/mod/semver"
)

type Result struct {
	Dependencies          model.Dependencies
	GoVersionSource       string
	Components            []model.SourceComponent
	CRDs                  []model.CRD
	APIReferenceContracts []model.APIReferenceContract
	CRDCoverage           string
	ControllerWatches     []model.ControllerWatch
	HTTPEndpoints         []model.HTTPEndpoint
	GRPCServices          []model.GRPCService
	Authentication        []model.AuthenticationFact
	RuntimeClients        []model.RuntimeClient
	RuntimeModuleUses     []model.RuntimeModuleUse
	RuntimeManagedUses    []model.RuntimeManagedComponent
	RuntimeServers        []model.RuntimeServer
	RuntimeSecurity       []model.RuntimeSecurityControl
	RuntimeProxies        []model.RuntimeProxyControl
	RuntimeWebhooks       []model.RuntimeWebhookServer
	AccessPolicies        []model.AccessPolicy
	ComponentRefs         []model.ComponentRef
	Entrypoints           []model.Entrypoint
	SecurityEvidence      []model.SecurityEvidence
	EmbeddedManifests     []string
	TemplateDefaults      map[string]model.SourceDefault
	ConstructedSecrets    []model.Secret
	ConstructedBindings   []model.Binding
	Coverage              string
}

type sourceFile struct {
	path       string
	file       *ast.File
	fileSet    *token.FileSet
	imports    map[string]string
	modulePath string
	packageDir string
}

func Extract(root string) (Result, error) {
	moduleRoots, err := discoverModules(root)
	if err != nil {
		return Result{}, err
	}
	if len(moduleRoots) == 0 {
		return Result{Coverage: "not_applicable", CRDCoverage: "not_applicable"}, nil
	}

	result := Result{
		Coverage: "partial: all repository Go modules; dynamic routes and watched expressions not resolved; lightweight constant propagation only; Go type checking not performed",
	}
	var files []sourceFile
	for _, moduleRoot := range moduleRoots {
		modulePath, dependencies, moduleSource, err := readModule(root, moduleRoot)
		if err != nil {
			return Result{}, err
		}
		if mergeDependencies(&result.Dependencies, dependencies) {
			result.GoVersionSource = moduleSource
		}
		moduleFiles, err := parseFiles(root, moduleRoot, modulePath, moduleRoots)
		if err != nil {
			return Result{}, err
		}
		files = append(files, moduleFiles...)
	}
	repositoryOptions := discoverRepositoryOptionBindings(files)
	for _, file := range files {
		result.ControllerWatches = append(result.ControllerWatches, extractWatches(file)...)
		result.HTTPEndpoints = append(result.HTTPEndpoints, extractRoutes(file)...)
		result.GRPCServices = append(result.GRPCServices, extractRegisteredGRPCServices(file)...)
		result.Authentication = append(result.Authentication, extractControllerRuntimeAuthentication(file, repositoryOptions)...)
		result.Authentication = append(result.Authentication, extractBoundedServerAuthentication(file)...)
		result.Authentication = append(result.Authentication, extractBoundedProxyHandlerAuthentication(file)...)
		result.Authentication = append(result.Authentication, extractConfigurableCRDAuthorization(file)...)
		result.Authentication = append(result.Authentication, extractDefaultMuxHealthAuthentication(file)...)
		result.Authentication = append(result.Authentication, extractK8sClientAuthentication(file)...)
		result.RuntimeClients = append(result.RuntimeClients, extractRuntimeClients(file)...)
		result.RuntimeSecurity = append(result.RuntimeSecurity, extractControllerRuntimeSecurityControls(file, repositoryOptions)...)
		result.RuntimeWebhooks = append(result.RuntimeWebhooks, extractRuntimeWebhookServers(file)...)
		result.AccessPolicies = append(result.AccessPolicies, extractConstructedAccessPolicies(file)...)
		result.ComponentRefs = append(result.ComponentRefs, extractResourceOperations(file)...)
		result.ConstructedSecrets = append(result.ConstructedSecrets, extractConstructedSecrets(file)...)
		result.EmbeddedManifests = append(result.EmbeddedManifests, embeddedManifests(root, file)...)
	}
	result.ConstructedBindings = extractConstructedClusterRoleBindings(files)
	applyConditionalControllerRegistrations(result.ControllerWatches, conditionalControllerRegistrations(files))
	result.RuntimeProxies = extractConstructedKubeRBACProxyControls(files, result.ConstructedBindings)
	result.CRDs, result.CRDCoverage = extractKubebuilderCRDs(files)
	result.APIReferenceContracts = extractKubebuilderReferenceContracts(files)
	result.TemplateDefaults = extractKubebuilderDefaults(files)
	result.RuntimeModuleUses = extractRuntimeModuleUses(files, result.Dependencies.GoModules)
	result.RuntimeManagedUses = extractRuntimeManagedComponents(files)
	result.Components = extractShippedCommandComponents(root, files)
	if len(result.Components) == 0 {
		result.Components = extractCobraCLIComponents(files)
	}
	result.Components = append(result.Components, extractControllerComponents(result.ControllerWatches)...)
	result.Components = append(result.Components, extractPodMutationComponents(files)...)
	result.Entrypoints = extractGoEntrypoints(files)
	result.SecurityEvidence = extractGoSecurityEvidence(files)
	result.RuntimeClients = append(result.RuntimeClients, extractEndpointMetricsClients(files)...)
	result.RuntimeClients = append(result.RuntimeClients, extractRuntimeServiceClients(files)...)
	result.RuntimeClients = append(result.RuntimeClients, extractOutboundGRPCClients(files)...)
	result.RuntimeClients = append(result.RuntimeClients, extractProjectHTTPClients(files)...)
	cliClients, cliAuthentication := extractCLIKubernetesRuntimeBoundaries(files)
	result.RuntimeClients = append(result.RuntimeClients, cliClients...)
	result.Authentication = append(result.Authentication, cliAuthentication...)
	result.Authentication = append(result.Authentication, extractRepositoryHTTPAuthentication(files)...)
	result.Authentication = append(result.Authentication, extractConditionalIdentityEnforcement(files)...)
	result.Authentication = append(result.Authentication, extractEnumBasedCRDAuthentication(files)...)
	runtimeReachable := runtimeReachableFunctions(files)
	for _, file := range files {
		result.RuntimeServers = append(result.RuntimeServers, extractStandaloneRuntimeServers(file, runtimeReachable)...)
		result.GRPCServices = append(result.GRPCServices, extractRegisteredGRPCServices(file, runtimeReachable)...)
	}
	result.ControllerWatches = dedupeWatches(result.ControllerWatches)
	result.HTTPEndpoints = dedupeRoutes(result.HTTPEndpoints)
	result.GRPCServices = preferStandaloneGRPCServices(result.GRPCServices, result.RuntimeServers)
	result.GRPCServices = dedupeRegisteredGRPCServices(result.GRPCServices)
	result.Authentication = append(result.Authentication, registeredGRPCAuthentication(result.GRPCServices)...)
	result.Authentication = dedupeAuthentication(result.Authentication)
	result.RuntimeClients = dedupeRuntimeClients(result.RuntimeClients)
	result.RuntimeServers = dedupeRuntimeServers(result.RuntimeServers)
	result.RuntimeSecurity = dedupeRuntimeSecurityControls(result.RuntimeSecurity)
	result.RuntimeWebhooks = dedupeRuntimeWebhookServers(result.RuntimeWebhooks)
	result.RuntimeProxies = dedupeRuntimeProxyControls(result.RuntimeProxies)
	result.AccessPolicies = dedupeAccessPolicies(result.AccessPolicies)
	result.ComponentRefs = append(result.ComponentRefs, extractGVRDynamicResourceOperations(files)...)
	result.ComponentRefs = mergeResourceOperations(result.ComponentRefs)
	result.ConstructedSecrets = dedupeConstructedSecrets(result.ConstructedSecrets)
	result.EmbeddedManifests = uniqueSorted(result.EmbeddedManifests)
	if len(result.GRPCServices) == 0 && !hasGRPCRuntimeServer(result.RuntimeServers) {
		result.Coverage += "; literal gRPC server registration scan: no runtime registration detected"
	}
	return result, nil
}

func hasGRPCRuntimeServer(servers []model.RuntimeServer) bool {
	for _, server := range servers {
		if strings.Contains(strings.ToLower(server.Protocol), "grpc") {
			return true
		}
	}
	return false
}

func discoverModules(root string) ([]string, error) {
	var roots []string
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
		if entry.Name() == "go.mod" {
			roots = append(roots, filepath.Dir(path))
		}
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("discover Go modules: %w", err)
	}
	sort.Strings(roots)
	return roots, nil
}

func mergeDependencies(target *model.Dependencies, candidate model.Dependencies) bool {
	selectedVersion := false
	if candidate.GoVersion != "" && (target.GoVersion == "" || version.Compare("go"+candidate.GoVersion, "go"+target.GoVersion) > 0) {
		target.GoVersion = candidate.GoVersion
		selectedVersion = true
	}
	modules := make(map[string]model.GoModule, len(target.GoModules)+len(candidate.GoModules))
	for _, dependency := range target.GoModules {
		modules[dependency.Module] = dependency
	}
	for _, dependency := range candidate.GoModules {
		current, exists := modules[dependency.Module]
		if !exists || preferModuleDependency(current, dependency) {
			modules[dependency.Module] = dependency
		}
	}
	target.GoModules = target.GoModules[:0]
	for _, dependency := range modules {
		target.GoModules = append(target.GoModules, dependency)
	}
	sort.Slice(target.GoModules, func(i, j int) bool {
		return target.GoModules[i].Module < target.GoModules[j].Module
	})
	return selectedVersion
}

func preferModuleDependency(current, candidate model.GoModule) bool {
	currentOperator := strings.Contains(strings.ToLower(current.Source), "operator")
	candidateOperator := strings.Contains(strings.ToLower(candidate.Source), "operator")
	if currentOperator != candidateOperator {
		return candidateOperator
	}
	return semver.Compare(current.Version, candidate.Version) < 0
}

func embeddedManifests(root string, file sourceFile) []string {
	var paths []string
	for _, group := range file.file.Comments {
		for _, comment := range group.List {
			text := strings.TrimSpace(comment.Text)
			if !strings.HasPrefix(text, "//go:embed ") {
				continue
			}
			for _, pattern := range strings.Fields(strings.TrimPrefix(text, "//go:embed ")) {
				if unquoted, err := strconv.Unquote(pattern); err == nil {
					pattern = unquoted
				}
				absolutePattern := filepath.Join(root, filepath.Dir(filepath.FromSlash(file.path)), pattern)
				matches, err := filepath.Glob(absolutePattern)
				if err != nil {
					continue
				}
				for _, match := range matches {
					info, statErr := os.Stat(match)
					if statErr != nil {
						continue
					}
					if info.IsDir() {
						_ = filepath.WalkDir(match, func(path string, entry fs.DirEntry, walkErr error) error {
							if walkErr != nil || entry.IsDir() {
								return walkErr
							}
							if embeddedManifestFile(path) {
								paths = append(paths, filepath.Clean(path))
							}
							return nil
						})
					} else if embeddedManifestFile(match) {
						paths = append(paths, filepath.Clean(match))
					}
				}
			}
		}
	}
	return paths
}

func embeddedManifestFile(path string) bool {
	lower := strings.ToLower(path)
	return strings.HasSuffix(lower, ".yaml.tmpl") || strings.HasSuffix(lower, ".yml.tmpl") ||
		strings.HasSuffix(lower, ".tmpl.yaml") || strings.HasSuffix(lower, ".tmpl.yml") ||
		strings.HasSuffix(lower, ".yaml") || strings.HasSuffix(lower, ".yml")
}

func uniqueSorted(values []string) []string {
	seen := make(map[string]bool, len(values))
	result := make([]string, 0, len(values))
	for _, value := range values {
		if !seen[value] {
			seen[value] = true
			result = append(result, value)
		}
	}
	sort.Strings(result)
	return result
}

func readModule(repoRoot, moduleRoot string) (string, model.Dependencies, string, error) {
	path := filepath.Join(moduleRoot, "go.mod")
	content, err := os.ReadFile(path)
	if os.IsNotExist(err) {
		return "", model.Dependencies{}, "", nil
	}
	if err != nil {
		return "", model.Dependencies{}, "", fmt.Errorf("read go.mod: %w", err)
	}
	parsed, err := modfile.Parse(path, content, nil)
	if err != nil {
		return "", model.Dependencies{}, "", fmt.Errorf("parse go.mod: %w", err)
	}
	dependencies := model.Dependencies{}
	source, relErr := filepath.Rel(repoRoot, path)
	if relErr != nil {
		source = path
	}
	source = filepath.ToSlash(source)
	if parsed.Go != nil {
		dependencies.GoVersion = parsed.Go.Version
	}
	for _, requirement := range parsed.Require {
		if requirement.Indirect {
			continue
		}
		dependencies.GoModules = append(dependencies.GoModules, model.GoModule{
			Module:  requirement.Mod.Path,
			Version: requirement.Mod.Version,
			Source:  source,
		})
	}
	sort.Slice(dependencies.GoModules, func(i, j int) bool {
		return dependencies.GoModules[i].Module < dependencies.GoModules[j].Module
	})
	modulePath := ""
	if parsed.Module != nil {
		modulePath = parsed.Module.Mod.Path
	}
	return modulePath, dependencies, source, nil
}

func parseFiles(repoRoot, moduleRoot, modulePath string, moduleRoots []string) ([]sourceFile, error) {
	nestedModules := make(map[string]bool, len(moduleRoots))
	for _, candidate := range moduleRoots {
		if candidate != moduleRoot {
			nestedModules[filepath.Clean(candidate)] = true
		}
	}
	var files []sourceFile
	err := filepath.WalkDir(moduleRoot, func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() {
			if path != moduleRoot && (ignoredDirectory(entry.Name()) || nestedModules[filepath.Clean(path)]) {
				return filepath.SkipDir
			}
			return nil
		}
		if !strings.HasSuffix(entry.Name(), ".go") || strings.HasSuffix(entry.Name(), "_test.go") || generatedFile(entry.Name()) {
			return nil
		}
		fileSet := token.NewFileSet()
		parsed, err := parser.ParseFile(fileSet, path, nil, parser.SkipObjectResolution|parser.ParseComments)
		if err != nil {
			return fmt.Errorf("parse Go source %s: %w", path, err)
		}
		if ast.IsGenerated(parsed) {
			return nil
		}
		relative, err := filepath.Rel(repoRoot, path)
		if err != nil {
			relative = path
		}
		moduleRelative, err := filepath.Rel(moduleRoot, path)
		if err != nil {
			moduleRelative = path
		}
		packageDir := filepath.ToSlash(filepath.Dir(moduleRelative))
		if packageDir == "." {
			packageDir = ""
		}
		files = append(files, sourceFile{
			path:       filepath.ToSlash(relative),
			file:       parsed,
			fileSet:    fileSet,
			imports:    importAliases(parsed),
			modulePath: modulePath,
			packageDir: packageDir,
		})
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("scan Go source: %w", err)
	}
	return files, nil
}

func importAliases(file *ast.File) map[string]string {
	aliases := make(map[string]string, len(file.Imports))
	for _, spec := range file.Imports {
		path := strings.Trim(spec.Path.Value, `"`)
		alias := filepath.Base(path)
		if spec.Name != nil {
			alias = spec.Name.Name
		}
		if alias != "_" && alias != "." {
			aliases[alias] = path
		}
	}
	return aliases
}

func ignoredDirectory(name string) bool {
	switch name {
	case ".git", ".hg", ".svn", "vendor", "test", "tests", "testing", "testdata", "hack", "third_party", "node_modules",
		"mock", "mocks", "k8mocks", "fake", "fakes", "fixture", "fixtures", "testutil", "testutils":
		return true
	default:
		return false
	}
}

func generatedFile(name string) bool {
	return strings.HasPrefix(name, "zz_generated.") || strings.HasSuffix(name, ".generated.go")
}

func sourceAt(file sourceFile, position token.Pos) string {
	return fmt.Sprintf("%s:%d", file.path, file.fileSet.Position(position).Line)
}

func dedupeWatches(watches []model.ControllerWatch) []model.ControllerWatch {
	seen := make(map[string]bool, len(watches))
	result := make([]model.ControllerWatch, 0, len(watches))
	for _, watch := range watches {
		key := watch.Type + "\x00" + watch.GVK + "\x00" + watch.Controller + "\x00" + watch.Source
		if !seen[key] {
			seen[key] = true
			result = append(result, watch)
		}
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].GVK+result[i].Type+result[i].Source < result[j].GVK+result[j].Type+result[j].Source
	})
	return result
}

func dedupeRoutes(routes []model.HTTPEndpoint) []model.HTTPEndpoint {
	seen := make(map[string]bool, len(routes))
	result := make([]model.HTTPEndpoint, 0, len(routes))
	for _, route := range routes {
		key := route.Method + "\x00" + route.Path + "\x00" + route.Source
		if !seen[key] {
			seen[key] = true
			result = append(result, route)
		}
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].Path+result[i].Method < result[j].Path+result[j].Method
	})
	return result
}
