package extractor

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func collectSupplementalServingRuntimes(root string, input *model.Input) string {
	before := len(input.ServingRuntimes)
	if before > 0 {
		input.ServingRuntimes = dedupeServingRuntimeDefinitions(input.ServingRuntimes)
		return fmt.Sprintf("complete: %d serving runtime definition(s) extracted from selected manifests", len(input.ServingRuntimes))
	}
	var warnings []string
	for _, directory := range servingRuntimeKustomizationDirs(root) {
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
			case "ServingRuntime", "ClusterServingRuntime":
				collectServingRuntime(item, input)
			}
		}
	}
	input.ServingRuntimes = dedupeServingRuntimeDefinitions(input.ServingRuntimes)
	added := len(input.ServingRuntimes) - before
	switch {
	case len(warnings) > 0 && len(input.ServingRuntimes) > 0:
		sort.Strings(warnings)
		return fmt.Sprintf("partial: %d serving runtime definition(s) extracted; %s", len(input.ServingRuntimes), strings.Join(warnings, "; "))
	case len(warnings) > 0:
		sort.Strings(warnings)
		return "partial: " + strings.Join(warnings, "; ")
	case added > 0:
		return fmt.Sprintf("complete: %d serving runtime definition(s) extracted from runtime kustomizations", len(input.ServingRuntimes))
	case len(input.ServingRuntimes) > 0:
		return fmt.Sprintf("complete: %d serving runtime definition(s) extracted from selected manifests", len(input.ServingRuntimes))
	default:
		return "not_found"
	}
}

func servingRuntimeKustomizationDirs(root string) []string {
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
		if filepath.Base(directory) != "runtimes" || excludedRuntimeDirectory(root, directory) {
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

func excludedRuntimeDirectory(root, directory string) bool {
	relative, err := filepath.Rel(root, directory)
	if err != nil {
		relative = directory
	}
	relative = filepath.ToSlash(relative)
	for _, segment := range strings.Split(relative, "/") {
		switch segment {
		case "scripts", "test", "tests", "testdata", "samples", "examples", "fvt":
			return true
		}
	}
	return false
}

func dedupeServingRuntimeDefinitions(runtimes []model.ServingRuntimeDefinition) []model.ServingRuntimeDefinition {
	seen := map[string]bool{}
	result := make([]model.ServingRuntimeDefinition, 0, len(runtimes))
	for _, runtime := range runtimes {
		key := runtime.APIGroup + "\x00" + runtime.Version + "\x00" + runtime.Kind + "\x00" + runtime.Name
		if seen[key] {
			continue
		}
		seen[key] = true
		result = append(result, runtime)
	}
	return result
}
