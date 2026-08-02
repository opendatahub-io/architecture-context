package pythonsource

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
	"github.com/pelletier/go-toml/v2"
)

type pythonManifest struct {
	Project struct {
		Name                 string              `toml:"name"`
		Version              string              `toml:"version"`
		Description          string              `toml:"description"`
		RequiresPython       string              `toml:"requires-python"`
		Dependencies         []string            `toml:"dependencies"`
		OptionalDependencies map[string][]string `toml:"optional-dependencies"`
	} `toml:"project"`
	Tool struct {
		Poetry struct {
			Name         string         `toml:"name"`
			Version      string         `toml:"version"`
			Description  string         `toml:"description"`
			Dependencies map[string]any `toml:"dependencies"`
			Group        map[string]struct {
				Dependencies map[string]any `toml:"dependencies"`
			} `toml:"group"`
		} `toml:"poetry"`
	} `toml:"tool"`
}

var requirementName = regexp.MustCompile(`^[A-Za-z0-9_.-]+`)

func extractMetadata(root string, manifests, requirementFiles []string) ([]model.SourceComponent, []model.LanguagePackage, error) {
	var components []model.SourceComponent
	var dependencies []model.LanguagePackage
	for _, path := range manifests {
		content, err := os.ReadFile(path)
		if err != nil {
			return nil, nil, fmt.Errorf("read pyproject.toml %s: %w", path, err)
		}
		var manifest pythonManifest
		if err := toml.Unmarshal(content, &manifest); err != nil {
			return nil, nil, fmt.Errorf("parse pyproject.toml %s: %w", path, err)
		}
		relative, _ := filepath.Rel(root, path)
		source := filepath.ToSlash(relative)
		name := manifest.Project.Name
		version := manifest.Project.Version
		description := manifest.Project.Description
		pythonVersion := manifest.Project.RequiresPython
		rawDependencies := append([]string{}, manifest.Project.Dependencies...)
		for _, group := range sortedOptionalGroups(manifest.Project.OptionalDependencies) {
			rawDependencies = append(rawDependencies, manifest.Project.OptionalDependencies[group]...)
		}
		if name == "" {
			name = manifest.Tool.Poetry.Name
			version = manifest.Tool.Poetry.Version
			description = manifest.Tool.Poetry.Description
			for dependency, raw := range manifest.Tool.Poetry.Dependencies {
				if strings.EqualFold(dependency, "python") {
					pythonVersion = dependencyVersion(raw)
					continue
				}
				dependencies = append(dependencies, model.LanguagePackage{
					Name: canonicalPackageName(dependency), Version: dependencyVersion(raw), Ecosystem: "PyPI",
					Purpose: "Python package dependency", Source: sourceRef(source, string(content), dependency),
				})
			}
		}
		for _, requirement := range rawDependencies {
			if dependency, ok := parseRequirement(requirement, source, string(content)); ok {
				dependencies = append(dependencies, dependency)
			}
		}
		if pythonVersion != "" {
			dependencies = append(dependencies, model.LanguagePackage{
				Name: "Python", Version: pythonVersion, Ecosystem: "Python",
				Purpose: "Python runtime", Source: sourceRef(source, string(content), pythonVersion),
			})
		}
		if name != "" {
			components = append(components, model.SourceComponent{
				Name: name, Type: pythonComponentType(rawDependencies, manifest.Tool.Poetry.Dependencies, description),
				Purpose: valueOr(description, "Python package or application"),
				Source:  sourceRef(source, string(content), name),
			})
		}
		_ = version
	}
	for _, path := range requirementFiles {
		items, err := parseRequirementsFile(root, path)
		if err != nil {
			return nil, nil, err
		}
		dependencies = append(dependencies, items...)
	}
	if len(components) == 0 {
		components = append(components, model.SourceComponent{
			Name: filepath.Base(root), Type: "Python application",
			Purpose: "Python source repository", Source: firstPythonSource(root),
		})
	}
	return dedupeComponents(components), dedupePackages(dependencies), nil
}

func sortedOptionalGroups(groups map[string][]string) []string {
	result := make([]string, 0, len(groups))
	for name := range groups {
		result = append(result, name)
	}
	sort.Strings(result)
	return result
}

func parseRequirement(raw, source, content string) (model.LanguagePackage, bool) {
	value := strings.TrimSpace(strings.SplitN(raw, ";", 2)[0])
	if value == "" || strings.HasPrefix(value, "-") || strings.Contains(value, "${") {
		return model.LanguagePackage{}, false
	}
	match := requirementName.FindString(value)
	if match == "" {
		return model.LanguagePackage{}, false
	}
	remainder := strings.TrimSpace(value[len(match):])
	if strings.HasPrefix(remainder, "[") {
		if end := strings.Index(remainder, "]"); end >= 0 {
			remainder = strings.TrimSpace(remainder[end+1:])
		}
	}
	if remainder == "" {
		remainder = "Unknown"
	}
	return model.LanguagePackage{
		Name: canonicalPackageName(match), Version: remainder, Ecosystem: "PyPI",
		Purpose: "Python package dependency", Source: sourceRef(source, content, raw),
	}, true
}

func parseRequirementsFile(root, path string) ([]model.LanguagePackage, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("read Python requirements %s: %w", path, err)
	}
	defer file.Close()
	relative, _ := filepath.Rel(root, path)
	source := filepath.ToSlash(relative)
	var result []model.LanguagePackage
	line := 0
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line++
		raw := strings.TrimSpace(strings.SplitN(scanner.Text(), "#", 2)[0])
		dependency, ok := parseRequirement(raw, source, raw)
		if !ok {
			continue
		}
		dependency.Source = fmt.Sprintf("%s:%d", source, line)
		result = append(result, dependency)
	}
	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("scan Python requirements %s: %w", path, err)
	}
	return result, nil
}

func dependencyVersion(raw any) string {
	switch value := raw.(type) {
	case string:
		if value == "" || value == "*" {
			return "Unknown"
		}
		return value
	case map[string]any:
		if version, ok := value["version"].(string); ok {
			return valueOr(version, "Unknown")
		}
		if git, ok := value["git"].(string); ok {
			return git
		}
	case []any:
		for _, item := range value {
			if version := dependencyVersion(item); version != "Unknown" {
				return version
			}
		}
	}
	return "Unknown"
}

func pythonComponentType(projectDependencies []string, poetryDependencies map[string]any, description string) string {
	var names []string
	for _, raw := range projectDependencies {
		if match := requirementName.FindString(strings.TrimSpace(raw)); match != "" {
			names = append(names, strings.ToLower(match))
		}
	}
	for name := range poetryDependencies {
		names = append(names, strings.ToLower(name))
	}
	joined := strings.Join(names, " ")
	switch {
	case strings.Contains(strings.ToLower(description), "sdk") || strings.Contains(strings.ToLower(description), "software development kit"):
		return "Python SDK"
	case strings.Contains(joined, "fastapi"):
		return "Python Service (FastAPI)"
	case strings.Contains(joined, "flask"):
		return "Python Service (Flask)"
	case strings.Contains(joined, "grpcio"):
		return "Python gRPC Service"
	default:
		return "Python Package"
	}
}

func canonicalPackageName(name string) string {
	return strings.ReplaceAll(strings.ToLower(strings.TrimSpace(name)), "_", "-")
}

func firstPythonSource(root string) string {
	result := ""
	_ = walkPythonFiles(root, func(relative, _ string) error {
		if result == "" {
			result = relative + ":1"
		}
		return nil
	})
	return result
}

func valueOr(value, fallback string) string {
	if strings.TrimSpace(value) == "" {
		return fallback
	}
	return value
}
