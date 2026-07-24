package pythonsource

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

type Result struct {
	Components     []model.SourceComponent
	Dependencies   []model.LanguagePackage
	HTTPEndpoints  []model.HTTPEndpoint
	GRPCServices   []model.GRPCService
	Services       []model.Service
	Connections    []model.ExternalConnection
	Secrets        []model.Secret
	Authentication []model.AuthenticationFact
	Internal       []model.InternalDependency
	Integrations   []model.IntegrationFact
	Imports        *ImportAnalysis
	Coverage       string
}

func Extract(root string) (Result, error) {
	manifests, requirements, err := discoverMetadata(root)
	if err != nil {
		return Result{}, err
	}
	if len(manifests) == 0 && len(requirements) == 0 &&
		!fileExists(filepath.Join(root, "setup.py")) && !fileExists(filepath.Join(root, "setup.cfg")) {
		return Result{Coverage: "not_applicable"}, nil
	}

	components, dependencies, err := extractMetadata(root, manifests, requirements)
	if err != nil {
		return Result{}, err
	}
	endpoints, services, connections, secrets, authentication, err := extractPythonSource(root, components)
	if err != nil {
		return Result{}, err
	}
	grpcServices, err := extractProtoServices(root, hasDependency(dependencies, "grpcio"))
	if err != nil {
		return Result{}, err
	}
	imports := extractImportAnalysis(root)
	grpcServices = append(grpcServices, importAnalysisGRPCServices(imports)...)
	coverage := "partial: structured Python package metadata, literal FastAPI/Flask/Starlette routes, ASGI auth middleware posture, SDK client credential construction, literal outbound URLs, environment-backed secrets, and protobuf service definitions"
	if importCov := importAnalysisCoverage(imports); importCov != "" {
		coverage += "; Python import analysis: " + importCov
	} else {
		coverage += "; imports, dynamic route composition, dependency injection, and call graphs not resolved"
	}
	return Result{
		Components: components, Dependencies: dependencies,
		HTTPEndpoints: endpoints, GRPCServices: grpcServices, Services: services,
		Connections: connections, Secrets: secrets, Authentication: authentication,
		Internal: importAnalysisInternalDependencies(imports),
		Integrations: importAnalysisIntegrationFacts(imports),
		Imports: imports, Coverage: coverage,
	}, nil
}

func discoverMetadata(root string) ([]string, []string, error) {
	var manifests, requirements []string
	rootManifest := fileExists(filepath.Join(root, "pyproject.toml"))
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
		switch entry.Name() {
		case "pyproject.toml":
			if path == filepath.Join(root, "pyproject.toml") || (rootManifest && productionMetadataPath(root, path)) {
				manifests = append(manifests, path)
			}
		default:
			name := strings.ToLower(entry.Name())
			if strings.HasPrefix(name, "requirements") && (strings.HasSuffix(name, ".txt") || strings.HasSuffix(name, ".in")) {
				if filepath.Dir(path) == root || fileExists(filepath.Join(filepath.Dir(path), "pyproject.toml")) ||
					(rootManifest && productionMetadataPath(root, path)) {
					requirements = append(requirements, path)
				}
			}
		}
		return nil
	})
	if err != nil {
		return nil, nil, fmt.Errorf("discover Python metadata: %w", err)
	}
	sort.Strings(manifests)
	sort.Strings(requirements)
	return manifests, requirements, nil
}

func productionMetadataPath(root, path string) bool {
	relative, err := filepath.Rel(root, path)
	if err != nil {
		return false
	}
	parts := strings.Split(filepath.ToSlash(relative), "/")
	if len(parts) < 2 {
		return true
	}
	switch parts[0] {
	case "runtimes", "libs", "packages", "components", "integrations", "plugins", "src":
		return true
	default:
		return false
	}
}

func walkPythonFiles(root string, visit func(relative, content string) error) error {
	return filepath.WalkDir(root, func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() {
			if path != root && ignoredDirectory(entry.Name()) {
				return filepath.SkipDir
			}
			return nil
		}
		name := strings.ToLower(entry.Name())
		if !strings.HasSuffix(name, ".py") || strings.HasSuffix(name, "_pb2.py") || strings.HasSuffix(name, "_pb2_grpc.py") {
			return nil
		}
		info, err := entry.Info()
		if err != nil {
			return err
		}
		if info.Size() > 2<<20 {
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
		return visit(filepath.ToSlash(relative), string(content))
	})
}

func ignoredDirectory(name string) bool {
	switch strings.ToLower(name) {
	case ".git", ".hg", ".svn", ".venv", "venv", "env", "site-packages", "node_modules", "vendor", "dist", "build", "target", "__pycache__", "tests", "test", "testing", "examples", "example", "dev", "docs", ".claude", ".github":
		return true
	default:
		return false
	}
}

func hasDependency(dependencies []model.LanguagePackage, name string) bool {
	for _, dependency := range dependencies {
		if strings.EqualFold(dependency.Name, name) {
			return true
		}
	}
	return false
}

func sourceLine(content, needle string) int {
	index := strings.Index(content, needle)
	if index < 0 {
		return 1
	}
	return strings.Count(content[:index], "\n") + 1
}

func sourceRef(relative, content, needle string) string {
	return fmt.Sprintf("%s:%d", relative, sourceLine(content, needle))
}

func dedupePackages(items []model.LanguagePackage) []model.LanguagePackage {
	positions := map[string]int{}
	var result []model.LanguagePackage
	for _, item := range items {
		key := strings.ToLower(item.Name)
		if key == "" {
			continue
		}
		if index, exists := positions[key]; exists {
			if result[index].Version == "Unknown" && item.Version != "Unknown" {
				result[index] = item
			}
			continue
		}
		positions[key] = len(result)
		result = append(result, item)
	}
	sort.Slice(result, func(i, j int) bool { return strings.ToLower(result[i].Name) < strings.ToLower(result[j].Name) })
	return result
}

func dedupeComponents(items []model.SourceComponent) []model.SourceComponent {
	seen := map[string]bool{}
	var result []model.SourceComponent
	for _, item := range items {
		key := strings.ToLower(item.Name)
		if key == "" || seen[key] {
			continue
		}
		seen[key] = true
		result = append(result, item)
	}
	return result
}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil || !errors.Is(err, os.ErrNotExist)
}
