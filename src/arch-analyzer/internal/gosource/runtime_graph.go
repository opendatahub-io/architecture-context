package gosource

import (
	"go/ast"
	"go/token"
	"strings"
)

type runtimeFunctionKey struct {
	packagePath string
	receiver    string
	name        string
}

type runtimeMethodName struct {
	packagePath string
	name        string
}

type runtimeReceiverRef struct {
	packagePath string
	receiver    string
}

type runtimeVariableReceiver struct {
	receiver runtimeReceiverRef
	boundAt  token.Pos
}

type runtimeCallGraph struct {
	reachable map[runtimeFunctionKey]bool
	edges     map[runtimeFunctionKey]map[runtimeFunctionKey]bool
}

func (graph runtimeCallGraph) withAdditionalRoots(roots []runtimeFunctionKey) runtimeCallGraph {
	queue := append([]runtimeFunctionKey{}, roots...)
	for len(queue) > 0 {
		key := queue[0]
		queue = queue[1:]
		if graph.reachable[key] {
			continue
		}
		graph.reachable[key] = true
		for target := range graph.edges[key] {
			if !graph.reachable[target] {
				queue = append(queue, target)
			}
		}
	}
	return graph
}

// runtimeReachableFunctions follows statically named calls across repository
// packages. Functions and methods are package-qualified, and methods are also
// receiver-qualified so common lifecycle names cannot connect unrelated types.
// Dynamic interfaces and reflection remain deliberately unresolved.
//
// Blank-imported packages extend reachability: when a reachable file contains
// a blank import, all functions in the imported package become additional roots.
func runtimeReachableFunctions(files []sourceFile) map[runtimeFunctionKey]bool {
	graph := buildRuntimeCallGraph(files)
	roots := blankImportRoots(files, graph)
	if len(roots) > 0 {
		graph = graph.withAdditionalRoots(roots)
	}
	return graph.reachable
}

func buildRuntimeCallGraph(files []sourceFile) runtimeCallGraph {
	return buildRuntimeCallGraphWithRootFilter(files, func(sourceFile) bool { return true })
}

// buildProductRuntimeCallGraph excludes support, example, and test command
// entrypoints. It is used when a fact must belong to a shipped application
// lifecycle rather than merely to an executable somewhere in the repository.
func buildProductRuntimeCallGraph(files []sourceFile) runtimeCallGraph {
	return buildRuntimeCallGraphWithRootFilter(files, func(file sourceFile) bool {
		return !excludedCommandPath(file.packageDir)
	})
}

func buildRuntimeCallGraphWithRootFilter(files []sourceFile, includeRoot func(sourceFile) bool) runtimeCallGraph {
	declarations := map[runtimeFunctionKey][]*ast.FuncDecl{}
	methods := map[runtimeMethodName][]runtimeFunctionKey{}
	fileByFunction := map[*ast.FuncDecl]sourceFile{}
	var roots []runtimeFunctionKey
	for _, file := range files {
		for _, declaration := range file.file.Decls {
			function, ok := declaration.(*ast.FuncDecl)
			if !ok || function.Body == nil {
				continue
			}
			key := runtimeFunction(file, function)
			declarations[key] = append(declarations[key], function)
			fileByFunction[function] = file
			if key.receiver != "" {
				method := runtimeMethodName{packagePath: key.packagePath, name: key.name}
				methods[method] = append(methods[method], key)
			}
			if file.file.Name.Name == "main" && key.receiver == "" && key.name == "main" && includeRoot(file) {
				roots = append(roots, key)
			}
		}
	}
	returnTypes := runtimeDeclaredReturnTypes(declarations, fileByFunction)

	edges := map[runtimeFunctionKey]map[runtimeFunctionKey]bool{}
	for key, functions := range declarations {
		for _, function := range functions {
			file := fileByFunction[function]
			variables := runtimeVariableReceivers(file, function, returnTypes)
			ast.Inspect(function.Body, func(node ast.Node) bool {
				call, ok := node.(*ast.CallExpr)
				if !ok {
					return true
				}
				target := runtimeCallTarget(file, function, call, methods, variables)
				if len(declarations[target]) != 1 {
					return true
				}
				if edges[key] == nil {
					edges[key] = map[runtimeFunctionKey]bool{}
				}
				edges[key][target] = true
				return true
			})
		}
	}

	reachable := map[runtimeFunctionKey]bool{}
	queue := append([]runtimeFunctionKey{}, roots...)
	for len(queue) > 0 {
		key := queue[0]
		queue = queue[1:]
		if reachable[key] {
			continue
		}
		reachable[key] = true
		for target := range edges[key] {
			if !reachable[target] {
				queue = append(queue, target)
			}
		}
	}
	return runtimeCallGraph{reachable: reachable, edges: edges}
}

func runtimeDeclaredReturnTypes(
	declarations map[runtimeFunctionKey][]*ast.FuncDecl,
	fileByFunction map[*ast.FuncDecl]sourceFile,
) map[runtimeFunctionKey]runtimeReceiverRef {
	result := map[runtimeFunctionKey]runtimeReceiverRef{}
	for key, functions := range declarations {
		if len(functions) != 1 {
			continue
		}
		function := functions[0]
		if function.Type.Results == nil || len(function.Type.Results.List) == 0 {
			continue
		}
		if receiver := runtimeQualifiedReceiver(fileByFunction[function], function.Type.Results.List[0].Type); receiver.receiver != "" {
			result[key] = receiver
		}
	}
	return result
}

func runtimeVariableReceivers(
	file sourceFile,
	function *ast.FuncDecl,
	returnTypes map[runtimeFunctionKey]runtimeReceiverRef,
) map[string]runtimeVariableReceiver {
	result := map[string]runtimeVariableReceiver{}
	if function.Type.Params != nil {
		for _, field := range function.Type.Params.List {
			receiver := runtimeQualifiedReceiver(file, field.Type)
			for _, name := range field.Names {
				if receiver.receiver != "" {
					result[name.Name] = runtimeVariableReceiver{receiver: receiver}
				}
			}
		}
	}
	ast.Inspect(function.Body, func(node ast.Node) bool {
		switch statement := node.(type) {
		case *ast.AssignStmt:
			if len(statement.Lhs) == 0 || len(statement.Rhs) == 0 {
				return true
			}
			identifier, ok := statement.Lhs[0].(*ast.Ident)
			call, callOK := statement.Rhs[0].(*ast.CallExpr)
			if !ok || !callOK {
				return true
			}
			target := runtimeStaticCallTarget(file, call)
			if receiver := returnTypes[target]; receiver.receiver != "" {
				result[identifier.Name] = runtimeVariableReceiver{receiver: receiver, boundAt: statement.End()}
			}
		case *ast.DeclStmt:
			declaration, ok := statement.Decl.(*ast.GenDecl)
			if !ok {
				return true
			}
			for _, spec := range declaration.Specs {
				value, ok := spec.(*ast.ValueSpec)
				if !ok || value.Type == nil {
					continue
				}
				receiver := runtimeQualifiedReceiver(file, value.Type)
				for _, name := range value.Names {
					if receiver.receiver != "" {
						result[name.Name] = runtimeVariableReceiver{receiver: receiver, boundAt: value.End()}
					}
				}
			}
		}
		return true
	})
	return result
}

func runtimeStaticCallTarget(file sourceFile, call *ast.CallExpr) runtimeFunctionKey {
	if path, name, imported := importedCall(file, call); imported {
		return runtimeFunctionKey{packagePath: path, name: name}
	}
	if identifier, ok := call.Fun.(*ast.Ident); ok {
		return runtimeFunctionKey{packagePath: packagePath(file), name: identifier.Name}
	}
	return runtimeFunctionKey{}
}

func runtimeQualifiedReceiver(file sourceFile, expression ast.Expr) runtimeReceiverRef {
	switch value := expression.(type) {
	case *ast.ParenExpr:
		return runtimeQualifiedReceiver(file, value.X)
	case *ast.StarExpr:
		return runtimeQualifiedReceiver(file, value.X)
	case *ast.Ident:
		return runtimeReceiverRef{packagePath: packagePath(file), receiver: value.Name}
	case *ast.SelectorExpr:
		alias, ok := value.X.(*ast.Ident)
		if ok && file.imports[alias.Name] != "" {
			return runtimeReceiverRef{packagePath: file.imports[alias.Name], receiver: value.Sel.Name}
		}
	}
	return runtimeReceiverRef{}
}

func (graph runtimeCallGraph) reachableAncestors(target runtimeFunctionKey) map[runtimeFunctionKey]bool {
	ancestors := map[runtimeFunctionKey]bool{target: true}
	queue := []runtimeFunctionKey{target}
	for len(queue) > 0 {
		callee := queue[0]
		queue = queue[1:]
		for caller, targets := range graph.edges {
			if !graph.reachable[caller] || !targets[callee] || ancestors[caller] {
				continue
			}
			ancestors[caller] = true
			queue = append(queue, caller)
		}
	}
	return ancestors
}

func runtimeCallTarget(
	file sourceFile,
	caller *ast.FuncDecl,
	call *ast.CallExpr,
	methods map[runtimeMethodName][]runtimeFunctionKey,
	variables map[string]runtimeVariableReceiver,
) runtimeFunctionKey {
	if selector, ok := call.Fun.(*ast.SelectorExpr); ok {
		if identifier, ok := selector.X.(*ast.Ident); ok {
			variable := variables[identifier.Name]
			if variable.receiver.receiver != "" && variable.boundAt < call.Pos() {
				return runtimeFunctionKey{
					packagePath: variable.receiver.packagePath, receiver: variable.receiver.receiver, name: selector.Sel.Name,
				}
			}
		}
	}
	if path, name, imported := importedCall(file, call); imported {
		return runtimeFunctionKey{packagePath: path, name: name}
	}
	switch function := call.Fun.(type) {
	case *ast.Ident:
		return runtimeFunctionKey{packagePath: packagePath(file), name: function.Name}
	case *ast.SelectorExpr:
		receiver := runtimeReceiverFromExpression(function.X)
		if identifier, ok := function.X.(*ast.Ident); ok && receiverName(caller) == identifier.Name {
			receiver = runtimeReceiverType(caller)
		}
		if receiver != "" {
			return runtimeFunctionKey{packagePath: packagePath(file), receiver: receiver, name: function.Sel.Name}
		}
		candidates := methods[runtimeMethodName{packagePath: packagePath(file), name: function.Sel.Name}]
		if len(candidates) == 1 {
			return candidates[0]
		}
	}
	return runtimeFunctionKey{}
}

func runtimeFunction(file sourceFile, function *ast.FuncDecl) runtimeFunctionKey {
	return runtimeFunctionKey{
		packagePath: packagePath(file), receiver: runtimeReceiverType(function), name: function.Name.Name,
	}
}

func runtimeReceiverType(function *ast.FuncDecl) string {
	if function.Recv == nil || len(function.Recv.List) != 1 {
		return ""
	}
	return runtimeTypeName(function.Recv.List[0].Type)
}

func receiverName(function *ast.FuncDecl) string {
	if function.Recv == nil || len(function.Recv.List) != 1 || len(function.Recv.List[0].Names) != 1 {
		return ""
	}
	return function.Recv.List[0].Names[0].Name
}

func runtimeReceiverFromExpression(expression ast.Expr) string {
	switch value := expression.(type) {
	case *ast.CompositeLit:
		return runtimeTypeName(value.Type)
	case *ast.ParenExpr:
		return runtimeReceiverFromExpression(value.X)
	case *ast.UnaryExpr:
		return runtimeReceiverFromExpression(value.X)
	case *ast.CallExpr:
		if ident, ok := value.Fun.(*ast.Ident); ok && ident.Name == "new" && len(value.Args) == 1 {
			return runtimeTypeName(value.Args[0])
		}
	}
	return ""
}

func runtimeTypeName(expression ast.Expr) string {
	switch value := expression.(type) {
	case *ast.Ident:
		return value.Name
	case *ast.StarExpr:
		return runtimeTypeName(value.X)
	}
	return ""
}

func blankImportRoots(files []sourceFile, graph runtimeCallGraph) []runtimeFunctionKey {
	filesByPackage := map[string][]sourceFile{}
	functionsByPackage := map[string][]runtimeFunctionKey{}
	for _, file := range files {
		pkg := packagePath(file)
		filesByPackage[pkg] = append(filesByPackage[pkg], file)
		for _, declaration := range file.file.Decls {
			function, ok := declaration.(*ast.FuncDecl)
			if !ok || function.Body == nil {
				continue
			}
			functionsByPackage[pkg] = append(functionsByPackage[pkg], runtimeFunction(file, function))
		}
	}

	reachablePackages := map[string]bool{}
	for key := range graph.reachable {
		reachablePackages[key.packagePath] = true
	}

	imported := map[string]bool{}
	queue := make([]string, 0, len(reachablePackages))
	for pkg := range reachablePackages {
		queue = append(queue, pkg)
	}

	for len(queue) > 0 {
		pkg := queue[0]
		queue = queue[1:]
		for _, file := range filesByPackage[pkg] {
			for _, spec := range file.file.Imports {
				if spec.Name == nil || spec.Name.Name != "_" {
					continue
				}
				blankPath := strings.Trim(spec.Path.Value, `"`)
				if imported[blankPath] {
					continue
				}
				imported[blankPath] = true
				if len(filesByPackage[blankPath]) > 0 {
					queue = append(queue, blankPath)
				}
			}
		}
	}

	var roots []runtimeFunctionKey
	for pkg := range imported {
		roots = append(roots, functionsByPackage[pkg]...)
	}
	return roots
}
