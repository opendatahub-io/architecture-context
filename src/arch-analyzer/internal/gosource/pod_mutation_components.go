package gosource

import (
	"go/ast"
	"path/filepath"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

// extractPodMutationComponents records source-backed pod mutation utilities.
// The role is derived from source location and syntax rather than a repository
// or component name.
func extractPodMutationComponents(files []sourceFile) []model.SourceComponent {
	var sources []string
	for _, file := range files {
		path := filepath.ToSlash(file.path)
		lowerPath := strings.ToLower(path)
		if !strings.Contains(lowerPath, "/pod/") || !strings.Contains(lowerPath, "/webhook/") {
			continue
		}
		if !containsPodMutationEvidence(file) {
			continue
		}
		sources = append(sources, sourceAt(file, file.file.Package))
	}
	if len(sources) == 0 {
		return nil
	}
	sort.Strings(sources)
	return []model.SourceComponent{{
		Name:    "Pod mutation utilities",
		Type:    "Sidecar / Init Container Utility",
		Purpose: "Pod mutation source injects or configures additional runtime containers",
		Source:  sources[0],
	}}
}

func containsPodMutationEvidence(file sourceFile) bool {
	for _, comments := range file.file.Comments {
		text := strings.ToLower(comments.Text())
		if (strings.Contains(text, "inject") || strings.Contains(text, "mutat")) &&
			(strings.Contains(text, "container") || strings.Contains(text, "sidecar") || strings.Contains(text, "pod")) {
			return true
		}
	}
	for _, declaration := range file.file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok {
			continue
		}
		lowerName := strings.ToLower(function.Name.Name)
		if strings.Contains(lowerName, "inject") || strings.Contains(lowerName, "mutat") {
			return true
		}
	}
	return false
}
