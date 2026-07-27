package rustsource

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
	"github.com/pelletier/go-toml/v2"
)

type cargoManifest struct {
	Package struct {
		Name        string `toml:"name"`
		Version     string `toml:"version"`
		Description string `toml:"description"`
	} `toml:"package"`
	Workspace struct {
		Members []string `toml:"members"`
	} `toml:"workspace"`
	Dependencies map[string]any `toml:"dependencies"`
}

func extractCargoManifests(root, path string) ([]model.SourceComponent, []model.LanguagePackage, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return nil, nil, fmt.Errorf("read Cargo.toml: %w", err)
	}
	var manifest cargoManifest
	if err := toml.Unmarshal(content, &manifest); err != nil {
		return nil, nil, fmt.Errorf("parse Cargo.toml: %w", err)
	}
	type entry struct {
		path    string
		content string
		data    cargoManifest
	}
	manifests := []entry{{path: path, content: string(content), data: manifest}}
	if manifest.Package.Name == "" {
		manifests = nil
		for _, member := range manifest.Workspace.Members {
			matches, err := filepath.Glob(filepath.Join(filepath.Dir(path), member, "Cargo.toml"))
			if err != nil {
				return nil, nil, fmt.Errorf("resolve workspace member %q: %w", member, err)
			}
			for _, match := range matches {
				memberContent, err := os.ReadFile(match)
				if err != nil {
					return nil, nil, fmt.Errorf("read workspace member Cargo.toml %q: %w", match, err)
				}
				var memberManifest cargoManifest
				if err := toml.Unmarshal(memberContent, &memberManifest); err != nil {
					return nil, nil, fmt.Errorf("parse workspace member Cargo.toml %q: %w", match, err)
				}
				if memberManifest.Package.Name != "" {
					manifests = append(manifests, entry{path: match, content: string(memberContent), data: memberManifest})
				}
			}
		}
		if len(manifests) == 0 {
			return nil, nil, fmt.Errorf("parse Cargo.toml: missing package.name and workspace package members")
		}
	}
	sort.Slice(manifests, func(i, j int) bool { return manifests[i].path < manifests[j].path })
	components := make([]model.SourceComponent, 0, len(manifests))
	dependencies := make([]model.LanguagePackage, 0)
	for _, manifest := range manifests {
		relative, _ := filepath.Rel(root, manifest.path)
		sourcePath := filepath.ToSlash(relative)
		componentType := "Rust Service"
		if manifest.data.Dependencies["axum"] != nil && manifest.data.Dependencies["tonic"] != nil {
			componentType = "Rust Service (axum + tonic)"
		}
		components = append(components, model.SourceComponent{
			Name: manifest.data.Package.Name, Type: componentType,
			Purpose: valueOr(manifest.data.Package.Description, "Rust application service"), Source: sourcePath + ":1",
		})
		for name, raw := range manifest.data.Dependencies {
			dependencies = append(dependencies, model.LanguagePackage{
				Name: name, Version: cargoDependencyVersion(raw), Ecosystem: "Cargo",
				Source: fmt.Sprintf("%s:%d", sourcePath, sourceLine(manifest.content, name+" =")),
			})
		}
	}
	sort.Slice(dependencies, func(i, j int) bool {
		if dependencies[i].Name == dependencies[j].Name {
			return dependencies[i].Source < dependencies[j].Source
		}
		return dependencies[i].Name < dependencies[j].Name
	})
	return components, dependencies, nil
}

func cargoDependencyVersion(raw any) string {
	switch value := raw.(type) {
	case string:
		return value
	case map[string]any:
		if version, ok := value["version"].(string); ok {
			return version
		}
		if revision, ok := value["rev"].(string); ok {
			if len(revision) > 12 {
				revision = revision[:12]
			}
			return "git@" + revision
		}
		if git, ok := value["git"].(string); ok {
			return git
		}
	}
	return "Unknown"
}

func sourceLine(content, needle string) int {
	index := strings.Index(content, needle)
	if index < 0 {
		return 1
	}
	return strings.Count(content[:index], "\n") + 1
}

func valueOr(value, fallback string) string {
	if strings.TrimSpace(value) == "" {
		return fallback
	}
	return value
}
