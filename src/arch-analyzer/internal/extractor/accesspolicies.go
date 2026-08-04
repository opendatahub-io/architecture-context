package extractor

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func collectSupplementalIstioAccessPolicies(root string, input *model.Input) string {
	beforePolicies := len(input.AccessPolicies)
	beforeRoutes := len(input.IngressRouting)
	var warnings []string
	for _, directory := range istioAccessKustomizationDirs(root) {
		resolver := &loader{root: root, visiting: map[string]bool{}}
		objects, err := resolver.load(directory)
		if err != nil {
			relative, relErr := filepath.Rel(root, directory)
			if relErr != nil {
				relative = directory
			}
			warnings = append(warnings, filepath.ToSlash(relative)+": "+err.Error())
			continue
		}
		for _, item := range objects {
			switch stringValue(item.data, "kind") {
			case "AuthorizationPolicy":
				apiGroup, _ := splitAPIVersion(stringValue(item.data, "apiVersion"))
				if apiGroup == "security.istio.io" {
					policy := collectIstioAuthorizationPolicy(item)
					if policy.Name != "" && len(policy.Authentication) > 0 {
						input.AccessPolicies = append(input.AccessPolicies, policy)
					}
				}
			case "VirtualService":
				input.IngressRouting = append(input.IngressRouting, collectIngress(item))
			}
		}
	}
	input.AccessPolicies = dedupeAccessPolicies(input.AccessPolicies)
	input.IngressRouting = dedupeIngressRouting(input.IngressRouting)
	addedPolicies := len(input.AccessPolicies) - beforePolicies
	addedRoutes := len(input.IngressRouting) - beforeRoutes
	switch {
	case len(warnings) > 0 && (addedPolicies > 0 || addedRoutes > 0):
		sort.Strings(warnings)
		return fmt.Sprintf("partial: %d Istio access policy/policies, %d Istio route(s) extracted; %s", addedPolicies, addedRoutes, strings.Join(warnings, "; "))
	case len(warnings) > 0:
		sort.Strings(warnings)
		return "partial: " + strings.Join(warnings, "; ")
	case addedPolicies > 0 || addedRoutes > 0:
		return fmt.Sprintf("complete: %d Istio access policy/policies, %d Istio route(s) extracted from supplemental kustomizations", addedPolicies, addedRoutes)
	default:
		return "not_found"
	}
}

func istioAccessKustomizationDirs(root string) []string {
	seen := map[string]bool{}
	var directories []string
	_ = filepath.WalkDir(root, func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() && path != root && ignoredDir(entry.Name()) {
			return filepath.SkipDir
		}
		if entry.IsDir() || !isKustomization(entry.Name()) {
			return nil
		}
		directory := filepath.Dir(path)
		if !isIstioAccessDirectory(root, directory) {
			return nil
		}
		if !seen[directory] {
			seen[directory] = true
			directories = append(directories, directory)
		}
		return nil
	})
	sort.Slice(directories, func(i, j int) bool {
		left := filepath.ToSlash(directories[i])
		right := filepath.ToSlash(directories[j])
		if strings.Count(left, "/") == strings.Count(right, "/") {
			return left < right
		}
		return strings.Count(left, "/") < strings.Count(right, "/")
	})
	return directories
}

func isIstioAccessDirectory(root, directory string) bool {
	relative, err := filepath.Rel(root, directory)
	if err != nil {
		relative = directory
	}
	parts := strings.Split(filepath.ToSlash(relative), "/")
	for _, part := range parts {
		switch part {
		case "scripts", "test", "tests", "testdata", "samples", "examples", "fvt":
			return false
		}
	}
	if len(parts) >= 2 && parts[len(parts)-2] == "options" && parts[len(parts)-1] == "istio" {
		return true
	}
	if len(parts) >= 4 && parts[len(parts)-4] == "options" && parts[len(parts)-2] == "overlays" && parts[len(parts)-1] == "istio" {
		return true
	}
	return false
}

func dedupeAccessPolicies(policies []model.AccessPolicy) []model.AccessPolicy {
	seen := map[string]bool{}
	result := make([]model.AccessPolicy, 0, len(policies))
	for _, policy := range policies {
		key := policy.Kind + "\x00" + policy.Name + "\x00" + policy.TargetKind + "\x00" + policy.TargetName
		if seen[key] {
			continue
		}
		seen[key] = true
		result = append(result, policy)
	}
	return result
}

func dedupeIngressRouting(routes []model.Ingress) []model.Ingress {
	seen := map[string]bool{}
	result := make([]model.Ingress, 0, len(routes))
	for _, route := range routes {
		key := route.Kind + "\x00" + route.Name + "\x00" + route.Host + "\x00" + strings.Join(route.Paths, ",") + "\x00" + route.Backend
		if seen[key] {
			continue
		}
		seen[key] = true
		result = append(result, route)
	}
	return result
}
