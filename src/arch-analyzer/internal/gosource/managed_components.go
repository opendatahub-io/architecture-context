package gosource

import (
	"go/ast"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

// extractRuntimeManagedComponents requires a registered reconciliation callback
// whose Managed branch appends manifests. A field comparison or manifest variable
// alone is not runtime lifecycle evidence.
func extractRuntimeManagedComponents(files []sourceFile) []model.RuntimeManagedComponent {
	registered := registeredActionCallbacks(files)
	values := repositoryStringConstants(files)
	var result []model.RuntimeManagedComponent
	for _, file := range files {
		for _, declaration := range file.file.Decls {
			function, ok := declaration.(*ast.FuncDecl)
			if !ok || function.Body == nil || !registered[packagePath(file)+"\x00"+function.Name.Name] {
				continue
			}
			ast.Inspect(function.Body, func(node ast.Node) bool {
				statement, ok := node.(*ast.IfStmt)
				if !ok || statement.Body == nil || !appendsReconciliationManifests(statement.Body) {
					return true
				}
				field, position := managedStateCondition(statement.Cond, values[packagePath(file)])
				if field == "" {
					return true
				}
				result = append(result, model.RuntimeManagedComponent{
					Field: field, Action: function.Name.Name, Lifecycle: "Manifest reconciliation",
					Source: sourceAt(file, position.Pos()),
				})
				return true
			})
		}
	}
	return dedupeRuntimeManagedComponents(result)
}

func registeredActionCallbacks(files []sourceFile) map[string]bool {
	result := map[string]bool{}
	for _, file := range files {
		ast.Inspect(file.file, func(node ast.Node) bool {
			call, ok := node.(*ast.CallExpr)
			if !ok || calledFunctionName(call.Fun) != "WithAction" {
				return true
			}
			for _, argument := range call.Args {
				name := calledFunctionName(argument)
				if name != "" {
					result[packagePath(file)+"\x00"+name] = true
				}
			}
			return true
		})
	}
	return result
}

func repositoryStringConstants(files []sourceFile) map[string]map[string]string {
	values := map[string]map[string]string{}
	conflicts := map[string]map[string]bool{}
	for _, file := range files {
		key := packagePath(file)
		if values[key] == nil {
			values[key] = map[string]string{}
			conflicts[key] = map[string]bool{}
		}
		for _, declaration := range file.file.Decls {
			general, ok := declaration.(*ast.GenDecl)
			if !ok || general.Tok.String() != "const" {
				continue
			}
			for _, raw := range general.Specs {
				spec, ok := raw.(*ast.ValueSpec)
				if !ok {
					continue
				}
				for index, name := range spec.Names {
					if index >= len(spec.Values) {
						continue
					}
					value, resolved := staticStringLiteral(spec.Values[index])
					if !resolved || conflicts[key][name.Name] {
						continue
					}
					if existing, exists := values[key][name.Name]; exists && existing != value {
						delete(values[key], name.Name)
						conflicts[key][name.Name] = true
						continue
					}
					values[key][name.Name] = value
				}
			}
		}
	}
	return values
}

func managedStateCondition(expression ast.Expr, values map[string]string) (string, ast.Node) {
	binary, ok := expression.(*ast.BinaryExpr)
	if !ok || binary.Op.String() != "==" {
		return "", nil
	}
	for _, candidate := range []struct {
		field ast.Expr
		state ast.Expr
	}{{binary.X, binary.Y}, {binary.Y, binary.X}} {
		value, resolved := staticString(candidate.state, values)
		if !resolved || value != "Managed" {
			continue
		}
		path := selectorSegments(candidate.field)
		if len(path) < 3 || !strings.EqualFold(path[len(path)-1], "ManagementState") {
			continue
		}
		path = path[1:]
		for index := range path {
			path[index] = lowerFirst(path[index])
		}
		return strings.Join(path, "."), binary
	}
	return "", nil
}

func selectorSegments(expression ast.Expr) []string {
	switch typed := expression.(type) {
	case *ast.Ident:
		return []string{typed.Name}
	case *ast.SelectorExpr:
		return append(selectorSegments(typed.X), typed.Sel.Name)
	case *ast.ParenExpr:
		return selectorSegments(typed.X)
	}
	return nil
}

func lowerFirst(value string) string {
	if value == "" {
		return value
	}
	return strings.ToLower(value[:1]) + value[1:]
}

func appendsReconciliationManifests(body *ast.BlockStmt) bool {
	found := false
	ast.Inspect(body, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok || calledFunctionName(call.Fun) != "append" || len(call.Args) < 2 {
			return true
		}
		path := selectorSegments(call.Args[0])
		if len(path) > 0 && path[len(path)-1] == "Manifests" {
			found = true
			return false
		}
		return true
	})
	return found
}

func dedupeRuntimeManagedComponents(uses []model.RuntimeManagedComponent) []model.RuntimeManagedComponent {
	sort.Slice(uses, func(i, j int) bool {
		return uses[i].Field+uses[i].Source < uses[j].Field+uses[j].Source
	})
	seen := map[string]bool{}
	result := make([]model.RuntimeManagedComponent, 0, len(uses))
	for _, use := range uses {
		key := strings.ToLower(use.Field)
		if use.Source != "" && !seen[key] {
			seen[key] = true
			result = append(result, use)
		}
	}
	return result
}
