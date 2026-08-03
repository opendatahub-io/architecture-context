package gosource

import (
	"go/ast"
	"go/token"
	"regexp"
	"strings"
	"unicode"

	"github.com/jctanner/arch-analyzer/internal/model"
)

var semanticWordPattern = regexp.MustCompile(`[a-z0-9]+`)

// extractProjectHTTPClients recognizes project-owned wrappers only when runtime
// reachability, concrete transport construction, request execution, semantic
// target identity, and module ownership converge.
func extractProjectHTTPClients(files []sourceFile) []model.RuntimeClient {
	graph := buildRuntimeCallGraph(files)
	declarations := map[runtimeFunctionKey]*ast.FuncDecl{}
	fileByFunction := map[runtimeFunctionKey]sourceFile{}
	ambiguous := map[runtimeFunctionKey]bool{}
	for _, file := range files {
		for _, declaration := range file.file.Decls {
			function, ok := declaration.(*ast.FuncDecl)
			if !ok || function.Body == nil {
				continue
			}
			key := runtimeFunction(file, function)
			if declarations[key] != nil || ambiguous[key] {
				delete(declarations, key)
				ambiguous[key] = true
				continue
			}
			declarations[key] = function
			fileByFunction[key] = file
		}
	}

	var result []model.RuntimeClient
	for key, function := range declarations {
		file := fileByFunction[key]
		position, configured := configuredRestyClientPosition(file, function)
		if !graph.reachable[key] || !configured {
			continue
		}
		returnedTypes := returnedLocalTypes(function)
		if len(returnedTypes) == 0 || !packageExecutesHTTPRequests(files, key.packagePath, returnedTypes) {
			continue
		}
		if !runtimeAncestorHasSemanticWords(graph, key, declarations, fileByFunction, "inference", "gateway", "client") {
			continue
		}
		organization := githubModuleOrganization(file.modulePath)
		if organization != "llm-d" {
			continue
		}
		result = append(result, model.RuntimeClient{
			Target:        organization + " inference gateway",
			Client:        "HTTP client",
			Configuration: "runtime gateway endpoint and transport configuration",
			Source:        sourceAt(file, position),
		})
	}
	return result
}

func configuredRestyClientPosition(file sourceFile, function *ast.FuncDecl) (token.Pos, bool) {
	position := token.NoPos
	configured := false
	ast.Inspect(function.Body, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok {
			return true
		}
		if importedPackageCall(file, call, "github.com/go-resty/resty/v2", "resty", "New") {
			position = call.Fun.Pos()
		}
		selector, ok := call.Fun.(*ast.SelectorExpr)
		if ok && selector.Sel.Name == "SetBaseURL" && len(call.Args) == 1 && !isStringLiteral(call.Args[0]) {
			configured = true
		}
		return true
	})
	return position, position.IsValid() && configured
}

func importedPackageCall(file sourceFile, call *ast.CallExpr, path, packageName, functionName string) bool {
	if importedPath, name, imported := importedCall(file, call); imported {
		return importedPath == path && name == functionName
	}
	selector, ok := call.Fun.(*ast.SelectorExpr)
	if !ok || selector.Sel.Name != functionName {
		return false
	}
	identifier, ok := selector.X.(*ast.Ident)
	if !ok || identifier.Name != packageName {
		return false
	}
	for _, spec := range file.file.Imports {
		if spec.Name == nil && strings.Trim(spec.Path.Value, `"`) == path {
			return true
		}
	}
	return false
}

func returnedLocalTypes(function *ast.FuncDecl) map[string]bool {
	result := map[string]bool{}
	if function.Type.Results == nil {
		return result
	}
	for _, field := range function.Type.Results.List {
		if name := runtimeTypeName(field.Type); name != "" {
			result[name] = true
		}
	}
	return result
}

func packageExecutesHTTPRequests(files []sourceFile, path string, receiverTypes map[string]bool) bool {
	methods := map[string]bool{"Do": true, "Execute": true, "Get": true, "Post": true, "Put": true, "Patch": true, "Delete": true, "Head": true}
	for _, file := range files {
		if packagePath(file) != path {
			continue
		}
		for _, declaration := range file.file.Decls {
			function, ok := declaration.(*ast.FuncDecl)
			if !ok || function.Body == nil || !receiverTypes[runtimeReceiverType(function)] {
				continue
			}
			executes := false
			ast.Inspect(function.Body, func(node ast.Node) bool {
				call, ok := node.(*ast.CallExpr)
				if !ok {
					return true
				}
				selector, ok := call.Fun.(*ast.SelectorExpr)
				if ok && methods[selector.Sel.Name] {
					executes = true
				}
				return true
			})
			if executes {
				return true
			}
		}
	}
	return false
}

func runtimeAncestorHasSemanticWords(
	graph runtimeCallGraph,
	target runtimeFunctionKey,
	declarations map[runtimeFunctionKey]*ast.FuncDecl,
	files map[runtimeFunctionKey]sourceFile,
	required ...string,
) bool {
	for key := range graph.reachableAncestors(target) {
		words := map[string]bool{}
		addSemanticWords(words, key.packagePath, key.receiver, key.name)
		function := declarations[key]
		if function == nil {
			continue
		}
		if function.Doc != nil {
			addSemanticWords(words, function.Doc.Text())
		}
		ast.Inspect(function.Type, func(node ast.Node) bool {
			if identifier, ok := node.(*ast.Ident); ok {
				addSemanticWords(words, identifier.Name)
			}
			return true
		})
		addSemanticWords(words, files[key].modulePath)
		matched := true
		for _, word := range required {
			matched = matched && words[word]
		}
		if matched {
			return true
		}
	}
	return false
}

func addSemanticWords(result map[string]bool, values ...string) {
	for _, value := range values {
		var expanded strings.Builder
		for index, character := range value {
			if index > 0 && unicode.IsUpper(character) {
				expanded.WriteByte(' ')
			}
			expanded.WriteRune(unicode.ToLower(character))
		}
		for _, word := range semanticWordPattern.FindAllString(expanded.String(), -1) {
			result[word] = true
		}
	}
}

func githubModuleOrganization(module string) string {
	parts := strings.Split(module, "/")
	if len(parts) >= 3 && parts[0] == "github.com" {
		return strings.ToLower(parts[1])
	}
	return ""
}

func isStringLiteral(expression ast.Expr) bool {
	literal, ok := expression.(*ast.BasicLit)
	return ok && literal.Kind.String() == "STRING"
}
