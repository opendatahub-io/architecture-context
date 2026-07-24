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
	Dependencies map[string]any `toml:"dependencies"`
}

func extractCargo(root, path string) (model.SourceComponent, []model.LanguagePackage, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return model.SourceComponent{}, nil, fmt.Errorf("read Cargo.toml: %w", err)
	}
	var manifest cargoManifest
	if err := toml.Unmarshal(content, &manifest); err != nil {
		return model.SourceComponent{}, nil, fmt.Errorf("parse Cargo.toml: %w", err)
	}
	if manifest.Package.Name == "" {
		return model.SourceComponent{}, nil, fmt.Errorf("parse Cargo.toml: missing package.name")
	}
	relative, _ := filepath.Rel(root, path)
	sourcePath := filepath.ToSlash(relative)
	componentType := "Rust Service"
	if manifest.Dependencies["axum"] != nil && manifest.Dependencies["tonic"] != nil {
		componentType = "Rust Service (axum + tonic)"
	}
	component := model.SourceComponent{
		Name:    manifest.Package.Name,
		Type:    componentType,
		Purpose: valueOr(manifest.Package.Description, "Rust application service"),
		Source:  sourcePath + ":1",
	}

	dependencies := make([]model.LanguagePackage, 0, len(manifest.Dependencies))
	for name, raw := range manifest.Dependencies {
		dependencies = append(dependencies, model.LanguagePackage{
			Name:      name,
			Version:   cargoDependencyVersion(raw),
			Ecosystem: "Cargo",
			Source:    fmt.Sprintf("%s:%d", sourcePath, sourceLine(string(content), name+" =")),
		})
	}
	sort.Slice(dependencies, func(i, j int) bool { return dependencies[i].Name < dependencies[j].Name })
	return component, dependencies, nil
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
