package extractor

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func loadGoModuleConfigObjects(root string) ([]object, []string, error) {
	var moduleRoots []string
	err := filepath.WalkDir(root, func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() {
			if path != root && ignoredDir(entry.Name()) {
				return filepath.SkipDir
			}
			return nil
		}
		if entry.Name() == "go.mod" {
			moduleRoots = append(moduleRoots, filepath.Dir(path))
		}
		return nil
	})
	if err != nil {
		return nil, nil, fmt.Errorf("discover Go module configuration: %w", err)
	}

	resolver := &loader{root: root, visiting: map[string]bool{}}
	var result []object
	var warnings []string
	for _, moduleRoot := range moduleRoots {
		for _, relative := range []string{"config/crd/bases", "config/rbac", "config/webhook"} {
			directory := filepath.Join(moduleRoot, filepath.FromSlash(relative))
			info, statErr := os.Stat(directory)
			if os.IsNotExist(statErr) || (statErr == nil && !info.IsDir()) {
				continue
			}
			if statErr != nil {
				return nil, nil, fmt.Errorf("inspect Go module configuration %s: %w", directory, statErr)
			}
			err := filepath.WalkDir(directory, func(path string, entry fs.DirEntry, err error) error {
				if err != nil {
					return err
				}
				if entry.IsDir() || !isYAML(entry.Name()) || isKustomization(entry.Name()) {
					return nil
				}
				objects, loadErr := resolver.loadYAML(path)
				if loadErr != nil {
					warnings = appendUnique(warnings, "patch-only or unparseable Go module config YAML skipped")
					return nil
				}
				for _, item := range objects {
					if moduleConfigKind(stringValue(item.data, "kind")) {
						result = append(result, item)
					}
				}
				return nil
			})
			if err != nil {
				return nil, nil, fmt.Errorf("load Go module configuration %s: %w", directory, err)
			}
		}
	}
	return dedupeObjects(result), warnings, nil
}

func moduleConfigKind(kind string) bool {
	switch kind {
	case "CustomResourceDefinition", "ClusterRole", "Role", "ClusterRoleBinding", "RoleBinding",
		"MutatingWebhookConfiguration", "ValidatingWebhookConfiguration":
		return true
	default:
		return false
	}
}

func mergeGoModuleConfigFacts(input *model.Input, objects []object) {
	if len(objects) == 0 {
		return
	}
	facts := model.Input{}
	collect(objects, &facts)
	input.CRDs = append(input.CRDs, facts.CRDs...)
	input.RBAC.ClusterRoles = append(input.RBAC.ClusterRoles, facts.RBAC.ClusterRoles...)
	input.RBAC.Roles = append(input.RBAC.Roles, facts.RBAC.Roles...)
	input.RBAC.ClusterRoleBindings = append(input.RBAC.ClusterRoleBindings, facts.RBAC.ClusterRoleBindings...)
	input.RBAC.RoleBindings = append(input.RBAC.RoleBindings, facts.RBAC.RoleBindings...)
	input.Webhooks = append(input.Webhooks, facts.Webhooks...)
}

func moduleConfigCoverage(objects []object, warnings []string) string {
	if len(objects) == 0 {
		if len(warnings) > 0 {
			return "partial: " + strings.Join(warnings, "; ")
		}
		return "not_found"
	}
	kinds := map[string]bool{}
	for _, item := range objects {
		kinds[stringValue(item.data, "kind")] = true
	}
	var names []string
	for kind := range kinds {
		names = append(names, kind)
	}
	sort.Strings(names)
	prefix := "complete"
	if len(warnings) > 0 {
		prefix = "partial"
	}
	coverage := fmt.Sprintf("%s: %d canonical Go module config objects (%s)", prefix, len(objects), strings.Join(names, ", "))
	if len(warnings) > 0 {
		coverage += "; " + strings.Join(warnings, "; ")
	}
	return coverage
}
