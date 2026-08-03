package gosource

import (
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func extractRuntimeModuleUses(files []sourceFile, dependencies []model.GoModule) []model.RuntimeModuleUse {
	ownedComponents := map[string]bool{}
	for _, file := range files {
		if component := platformModuleComponent(file.modulePath); component != "" {
			ownedComponents[component] = true
		}
	}
	var modules []string
	for _, dependency := range dependencies {
		component := platformModuleComponent(dependency.Module)
		if component != "" && !ownedComponents[component] {
			modules = append(modules, dependency.Module)
		}
	}
	sort.Slice(modules, func(i, j int) bool { return len(modules[i]) > len(modules[j]) })
	seen := map[string]bool{}
	var result []model.RuntimeModuleUse
	for _, file := range files {
		for _, specification := range file.file.Imports {
			importPath := strings.Trim(specification.Path.Value, `"`)
			for _, module := range modules {
				if importPath != module && !strings.HasPrefix(importPath, module+"/") {
					continue
				}
				if !seen[module] {
					seen[module] = true
					result = append(result, model.RuntimeModuleUse{
						Module: module, Source: sourceAt(file, specification.Pos()),
					})
				}
				break
			}
		}
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Module < result[j].Module })
	return result
}

func platformModuleComponent(module string) string {
	for _, prefix := range []string{
		"github.com/llm-d/",
		"github.com/opendatahub-io/",
		"github.com/red-hat-data-services/",
	} {
		if !strings.HasPrefix(module, prefix) {
			continue
		}
		remainder := strings.TrimPrefix(module, prefix)
		if component, _, _ := strings.Cut(remainder, "/"); component != "" {
			return component
		}
	}
	for _, exact := range []string{
		"sigs.k8s.io/gateway-api-inference-extension",
	} {
		if module == exact || strings.HasPrefix(module, exact+"/") {
			parts := strings.Split(exact, "/")
			return parts[len(parts)-1]
		}
	}
	return ""
}
