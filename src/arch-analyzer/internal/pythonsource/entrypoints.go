package pythonsource

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
	"github.com/pelletier/go-toml/v2"
)

type pythonEntrypointManifest struct {
	Project struct {
		Scripts    map[string]string `toml:"scripts"`
		GUIScripts map[string]string `toml:"gui-scripts"`
	} `toml:"project"`
}

func extractPythonEntrypoints(root string, manifests []string, dependencies []model.LanguagePackage) []model.Entrypoint {
	var result []model.Entrypoint
	seen := map[string]bool{}

	for _, path := range manifests {
		content, err := os.ReadFile(path)
		if err != nil {
			continue
		}
		var manifest pythonEntrypointManifest
		if err := toml.Unmarshal(content, &manifest); err != nil {
			continue
		}
		relative, _ := filepath.Rel(root, path)
		source := filepath.ToSlash(relative)

		for name, target := range manifest.Project.Scripts {
			if seen[name] {
				continue
			}
			seen[name] = true
			result = append(result, model.Entrypoint{
				Name:    name,
				Type:    "Python console script",
				Runtime: "Python",
				Command: target,
				Source:  fmt.Sprintf("%s:%d", source, sourceLine(string(content), name)),
			})
		}
		for name, target := range manifest.Project.GUIScripts {
			if seen[name] {
				continue
			}
			seen[name] = true
			result = append(result, model.Entrypoint{
				Name:    name,
				Type:    "Python GUI script",
				Runtime: "Python",
				Command: target,
				Source:  fmt.Sprintf("%s:%d", source, sourceLine(string(content), name)),
			})
		}
	}

	for _, dep := range dependencies {
		lower := strings.ToLower(dep.Name)
		if lower == "uvicorn" || lower == "gunicorn" || lower == "hypercorn" {
			if !seen[lower] {
				seen[lower] = true
				result = append(result, model.Entrypoint{
					Name:    lower,
					Type:    "Python ASGI/WSGI server",
					Runtime: "Python",
					Source:  dep.Source,
				})
			}
		}
	}

	return result
}

func extractPythonSecurityEvidence(root string, dependencies []model.LanguagePackage) []model.SecurityEvidence {
	var result []model.SecurityEvidence
	seen := map[string]bool{}

	for _, dep := range dependencies {
		lower := strings.ToLower(dep.Name)
		kind := ""
		detail := ""
		switch {
		case lower == "cryptography" || lower == "pyopenssl":
			kind = "tls-config"
			detail = "TLS/cryptography library dependency"
		case lower == "pyjwt" || lower == "python-jose" || lower == "authlib":
			kind = "auth-middleware"
			detail = "JWT/OAuth authentication library dependency"
		case lower == "kubernetes":
			kind = "rbac-ref"
			detail = "Kubernetes client library (RBAC capable)"
		}
		if kind == "" {
			continue
		}
		key := kind + ":" + lower
		if seen[key] {
			continue
		}
		seen[key] = true
		result = append(result, model.SecurityEvidence{
			Kind:   kind,
			Target: dep.Name,
			Detail: detail,
			Status: "dependency-signal",
			Source: dep.Source,
		})
	}

	return result
}
