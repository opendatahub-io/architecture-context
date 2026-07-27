package gosource

import (
	"go/ast"
	"path"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func extractGoEntrypoints(files []sourceFile) []model.Entrypoint {
	seen := map[string]bool{}
	var result []model.Entrypoint
	for _, file := range files {
		if file.file.Name.Name != "main" {
			continue
		}
		for _, declaration := range file.file.Decls {
			function, ok := declaration.(*ast.FuncDecl)
			if !ok || function.Recv != nil || function.Name.Name != "main" || function.Body == nil {
				continue
			}
			name := path.Base(file.packageDir)
			if name == "." || name == "" {
				parts := strings.Split(file.modulePath, "/")
				if len(parts) > 0 {
					name = parts[len(parts)-1]
				}
			}
			if name == "" || seen[name] {
				continue
			}
			seen[name] = true
			entryType := "Go executable"
			if importsPackage(file, "sigs.k8s.io/controller-runtime") {
				entryType = "Go controller-runtime operator"
			} else if importsPackage(file, "github.com/spf13/cobra") {
				entryType = "Go CLI application"
			}
			result = append(result, model.Entrypoint{
				Name:    name,
				Type:    entryType,
				Runtime: "Go",
				Command: file.packageDir,
				Source:  sourceAt(file, function.Name.Pos()),
			})
		}
	}
	return result
}
