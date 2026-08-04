package gosource

import (
	"go/ast"
	"go/token"
	"sort"
	"strings"
	"unicode"

	"github.com/jctanner/arch-analyzer/internal/model"
)

type repositoryFunction struct {
	file     sourceFile
	function *ast.FuncDecl
}

type repositoryRoute struct {
	method  string
	path    string
	handler string
}

type routeProvider struct {
	routes   []repositoryRoute
	complete bool
}

type registrationHelper struct {
	muxIndex        int
	handlerIndex    int
	middlewareIndex int
	provider        bool
	complete        bool
}

type repositoryGoIndex struct {
	functions map[runtimeFunctionKey][]repositoryFunction
	constants map[string]map[string]repositoryConstant
	providers map[runtimeFunctionKey]routeProvider
	helpers   map[runtimeFunctionKey]registrationHelper
}

type repositoryConstant struct {
	file       sourceFile
	expression ast.Expr
}

type muxRegistrationGroup struct {
	routes      []repositoryRoute
	middlewares []ast.Expr
	file        sourceFile
	position    token.Pos
}

type middlewareSlice struct {
	values   []ast.Expr
	complete bool
}

// extractRepositoryHTTPAuthentication handles muxes whose route registration,
// middleware, and serving lifecycle span packages or receiver methods. It emits
// only when each boundary is closed; unsupported calls keep the mux unresolved.
func extractRepositoryHTTPAuthentication(files []sourceFile) []model.AuthenticationFact {
	index := buildRepositoryGoIndex(files)
	var result []model.AuthenticationFact
	for _, file := range files {
		if !importsPackage(file, netHTTPPackage) {
			continue
		}
		for _, declaration := range file.file.Decls {
			function, ok := declaration.(*ast.FuncDecl)
			if !ok || function.Body == nil || function.Recv != nil {
				continue
			}
			result = append(result, repositoryMuxAuthentication(files, index, file, function)...)
		}
	}
	return dedupeServerAuthentication(result)
}

func buildRepositoryGoIndex(files []sourceFile) repositoryGoIndex {
	index := repositoryGoIndex{
		functions: map[runtimeFunctionKey][]repositoryFunction{},
		constants: map[string]map[string]repositoryConstant{},
		providers: map[runtimeFunctionKey]routeProvider{},
		helpers:   map[runtimeFunctionKey]registrationHelper{},
	}
	for _, file := range files {
		pkg := packagePath(file)
		if index.constants[pkg] == nil {
			index.constants[pkg] = map[string]repositoryConstant{}
		}
		for _, declaration := range file.file.Decls {
			switch typed := declaration.(type) {
			case *ast.FuncDecl:
				if typed.Body != nil {
					key := runtimeFunction(file, typed)
					index.functions[key] = append(index.functions[key], repositoryFunction{file: file, function: typed})
				}
			case *ast.GenDecl:
				if typed.Tok != token.CONST {
					continue
				}
				for _, raw := range typed.Specs {
					spec, ok := raw.(*ast.ValueSpec)
					if !ok {
						continue
					}
					for i, name := range spec.Names {
						if i < len(spec.Values) {
							index.constants[pkg][name.Name] = repositoryConstant{file: file, expression: spec.Values[i]}
						}
					}
				}
			}
		}
	}
	for key, declarations := range index.functions {
		if len(declarations) != 1 {
			continue
		}
		entry := declarations[0]
		if key.receiver != "" && key.name == "GetRoutes" {
			index.providers[key] = extractRouteProvider(index, entry)
		}
		if key.receiver == "" {
			if helper, ok := inspectRegistrationHelper(entry); ok {
				index.helpers[key] = helper
			}
		}
	}
	return index
}

func inspectRegistrationHelper(entry repositoryFunction) (registrationHelper, bool) {
	function := entry.function
	muxIndex, muxName := serveMuxParameter(entry.file, function)
	if muxIndex < 0 {
		return registrationHelper{}, false
	}
	helper := registrationHelper{muxIndex: muxIndex, handlerIndex: -1, middlewareIndex: -1}
	params := flattenedParameters(function.Type.Params)
	for i, parameter := range params {
		if parameter.name == "" {
			continue
		}
		if function.Type.Params != nil && function.Type.Params.NumFields() > 0 && isEllipsisType(parameter.typ) {
			helper.middlewareIndex = i
		}
	}
	registered := false
	providerName := ""
	ast.Inspect(function.Body, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok {
			return true
		}
		selector, ok := call.Fun.(*ast.SelectorExpr)
		if !ok {
			return true
		}
		if receiver, ok := selector.X.(*ast.Ident); ok && receiver.Name == muxName &&
			(selector.Sel.Name == "Handle" || selector.Sel.Name == "HandleFunc") {
			registered = true
		}
		if selector.Sel.Name == "GetRoutes" {
			if receiver, ok := selector.X.(*ast.Ident); ok {
				providerName = receiver.Name
			}
		}
		return true
	})
	if !registered {
		return registrationHelper{}, false
	}
	if providerName != "" {
		for i, parameter := range params {
			if parameter.name == providerName {
				helper.handlerIndex = i
				helper.provider = true
				break
			}
		}
		if helper.handlerIndex < 0 || !helperRegistersRouteFields(function.Body, muxName) {
			return registrationHelper{}, false
		}
	}
	if helper.middlewareIndex >= 0 && !helperAppliesMiddleware(function.Body, params[helper.middlewareIndex].name) {
		return registrationHelper{}, false
	}
	helper.complete = true
	return helper, true
}

type namedParameter struct {
	name string
	typ  ast.Expr
}

func flattenedParameters(fields *ast.FieldList) []namedParameter {
	if fields == nil {
		return nil
	}
	var result []namedParameter
	for _, field := range fields.List {
		if len(field.Names) == 0 {
			result = append(result, namedParameter{typ: field.Type})
			continue
		}
		for _, name := range field.Names {
			result = append(result, namedParameter{name: name.Name, typ: field.Type})
		}
	}
	return result
}

func serveMuxParameter(file sourceFile, function *ast.FuncDecl) (int, string) {
	for i, parameter := range flattenedParameters(function.Type.Params) {
		star, ok := parameter.typ.(*ast.StarExpr)
		if ok && isImportedType(file, star.X, netHTTPPackage, "ServeMux") {
			return i, parameter.name
		}
	}
	return -1, ""
}

func isEllipsisType(expression ast.Expr) bool {
	_, ok := expression.(*ast.Ellipsis)
	return ok
}

func helperRegistersRouteFields(body *ast.BlockStmt, muxName string) bool {
	method, pattern := false, false
	registered := false
	ast.Inspect(body, func(node ast.Node) bool {
		switch typed := node.(type) {
		case *ast.SelectorExpr:
			method = method || typed.Sel.Name == "Method"
			pattern = pattern || typed.Sel.Name == "Pattern" || typed.Sel.Name == "Path"
		case *ast.CallExpr:
			selector, ok := typed.Fun.(*ast.SelectorExpr)
			if !ok {
				return true
			}
			receiver, receiverOK := selector.X.(*ast.Ident)
			if receiverOK && receiver.Name == muxName &&
				(selector.Sel.Name == "Handle" || selector.Sel.Name == "HandleFunc") {
				registered = true
			}
		}
		return true
	})
	return method && pattern && registered
}

func helperAppliesMiddleware(body *ast.BlockStmt, middlewareName string) bool {
	applied := false
	ast.Inspect(body, func(node ast.Node) bool {
		index, ok := node.(*ast.IndexExpr)
		if !ok {
			return true
		}
		identifier, identifierOK := index.X.(*ast.Ident)
		if !identifierOK || identifier.Name != middlewareName {
			return true
		}
		parentCall := false
		ast.Inspect(body, func(candidate ast.Node) bool {
			call, ok := candidate.(*ast.CallExpr)
			if ok && call.Fun == index {
				parentCall = true
				return false
			}
			return true
		})
		applied = applied || parentCall
		return true
	})
	return applied
}

func extractRouteProvider(index repositoryGoIndex, entry repositoryFunction) routeProvider {
	provider := routeProvider{complete: true}
	foundReturn := false
	ast.Inspect(entry.function.Body, func(node ast.Node) bool {
		returned, ok := node.(*ast.ReturnStmt)
		if !ok {
			return true
		}
		if len(returned.Results) != 1 {
			provider.complete = false
			return false
		}
		collection, ok := returned.Results[0].(*ast.CompositeLit)
		if !ok {
			provider.complete = false
			return false
		}
		foundReturn = true
		for _, element := range collection.Elts {
			literal, ok := element.(*ast.CompositeLit)
			if !ok {
				provider.complete = false
				continue
			}
			route := repositoryRoute{}
			for _, raw := range literal.Elts {
				field, ok := raw.(*ast.KeyValueExpr)
				if !ok {
					provider.complete = false
					continue
				}
				name, nameOK := field.Key.(*ast.Ident)
				if !nameOK {
					continue
				}
				switch name.Name {
				case "Method":
					route.method = resolveRepositoryString(index, entry.file, field.Value, map[string]bool{})
				case "Pattern", "Path":
					route.path = resolveRepositoryString(index, entry.file, field.Value, map[string]bool{})
				case "Handler", "HandlerFunc":
					route.handler = calledFunctionName(field.Value)
				}
			}
			if route.method == "" || !strings.HasPrefix(route.path, "/") || route.handler == "" ||
				!boundedRouteHandler(index, entry, route.handler) {
				provider.complete = false
				continue
			}
			provider.routes = append(provider.routes, route)
		}
		return false
	})
	provider.complete = provider.complete && foundReturn && len(provider.routes) > 0
	return provider
}

func resolveRepositoryString(index repositoryGoIndex, file sourceFile, expression ast.Expr, visiting map[string]bool) string {
	if value := stringLiteral(expression); value != "" {
		return value
	}
	switch typed := expression.(type) {
	case *ast.Ident:
		key := packagePath(file) + "\x00" + typed.Name
		if visiting[key] {
			return ""
		}
		constant, ok := index.constants[packagePath(file)][typed.Name]
		if !ok {
			return ""
		}
		visiting[key] = true
		return resolveRepositoryString(index, constant.file, constant.expression, visiting)
	case *ast.SelectorExpr:
		alias, ok := typed.X.(*ast.Ident)
		if !ok {
			return ""
		}
		path := file.imports[alias.Name]
		if path == netHTTPPackage && strings.HasPrefix(typed.Sel.Name, "Method") {
			return strings.ToUpper(strings.TrimPrefix(typed.Sel.Name, "Method"))
		}
		constant, ok := index.constants[path][typed.Sel.Name]
		if !ok {
			return ""
		}
		key := path + "\x00" + typed.Sel.Name
		if visiting[key] {
			return ""
		}
		visiting[key] = true
		return resolveRepositoryString(index, constant.file, constant.expression, visiting)
	}
	return ""
}

func boundedRouteHandler(index repositoryGoIndex, provider repositoryFunction, name string) bool {
	key := runtimeFunctionKey{packagePath: packagePath(provider.file), receiver: runtimeReceiverType(provider.function), name: name}
	declarations := index.functions[key]
	return len(declarations) == 1 && !hasAuthenticationEnforcement(declarations[0].function.Body)
}

func repositoryMuxAuthentication(files []sourceFile, index repositoryGoIndex, file sourceFile, function *ast.FuncDecl) []model.AuthenticationFact {
	muxes := constructedMuxes(file, function)
	if len(muxes) == 0 {
		return nil
	}
	types := constructedVariableTypes(index, file, function)
	middlewareSlices := middlewareSliceValues(function)
	bindings := returnedMuxBindings(function, muxes)
	var result []model.AuthenticationFact
	for mux := range muxes {
		binding, bound := bindings[mux]
		if !bound || !serverConstructorInvoked(files, index, file, function, binding.receiver, binding.field) {
			continue
		}
		groups, closed := collectMuxGroups(index, file, function, mux, types, middlewareSlices)
		if !closed {
			continue
		}
		for _, group := range groups {
			if len(group.routes) == 0 || !boundedMiddlewareSet(index, group.file, group.middlewares) {
				continue
			}
			result = append(result, authenticationFactForMux(mux, group))
		}
	}
	return result
}

func constructedMuxes(file sourceFile, function *ast.FuncDecl) map[string]bool {
	result := map[string]bool{}
	ast.Inspect(function.Body, func(node ast.Node) bool {
		assignment, ok := node.(*ast.AssignStmt)
		if !ok {
			return true
		}
		for i, raw := range assignment.Rhs {
			if i >= len(assignment.Lhs) || !isImportedCall(file, raw, netHTTPPackage, "NewServeMux") {
				continue
			}
			if name, ok := assignment.Lhs[i].(*ast.Ident); ok {
				result[name.Name] = true
			}
		}
		return true
	})
	return result
}

func constructedVariableTypes(index repositoryGoIndex, file sourceFile, function *ast.FuncDecl) map[string][]runtimeFunctionKey {
	result := map[string][]runtimeFunctionKey{}
	ast.Inspect(function.Body, func(node ast.Node) bool {
		assignment, ok := node.(*ast.AssignStmt)
		if !ok {
			return true
		}
		for i, raw := range assignment.Rhs {
			if i >= len(assignment.Lhs) {
				continue
			}
			name, ok := assignment.Lhs[i].(*ast.Ident)
			call, callOK := raw.(*ast.CallExpr)
			if !ok || !callOK {
				continue
			}
			key := repositoryCallKey(file, call)
			declarations := index.functions[key]
			if len(declarations) != 1 {
				continue
			}
			receiver := firstReturnedType(declarations[0].function)
			if receiver != "" {
				result[name.Name] = appendUniqueRuntimeKey(result[name.Name], runtimeFunctionKey{packagePath: key.packagePath, receiver: receiver})
			}
		}
		return true
	})
	return result
}

func firstReturnedType(function *ast.FuncDecl) string {
	if function.Type.Results == nil || len(function.Type.Results.List) == 0 {
		return ""
	}
	return runtimeTypeName(function.Type.Results.List[0].Type)
}

func rangedVariableTypesAt(function *ast.FuncDecl, name string, position token.Pos, types map[string][]runtimeFunctionKey) []runtimeFunctionKey {
	var result []runtimeFunctionKey
	ast.Inspect(function.Body, func(node ast.Node) bool {
		rangeStatement, ok := node.(*ast.RangeStmt)
		if !ok || rangeStatement.Body == nil || position < rangeStatement.Body.Pos() || position > rangeStatement.Body.End() {
			return true
		}
		value, ok := rangeStatement.Value.(*ast.Ident)
		collection, collectionOK := rangeStatement.X.(*ast.CompositeLit)
		if !ok || value.Name != name || !collectionOK {
			return true
		}
		for _, raw := range collection.Elts {
			identifier, ok := raw.(*ast.Ident)
			if !ok {
				return true
			}
			for _, candidate := range types[identifier.Name] {
				result = appendUniqueRuntimeKey(result, candidate)
			}
		}
		return true
	})
	return result
}

func appendUniqueRuntimeKey(values []runtimeFunctionKey, value runtimeFunctionKey) []runtimeFunctionKey {
	for _, current := range values {
		if current == value {
			return values
		}
	}
	return append(values, value)
}

func middlewareSliceValues(function *ast.FuncDecl) map[string]middlewareSlice {
	result := map[string]middlewareSlice{}
	ast.Inspect(function.Body, func(node ast.Node) bool {
		assignment, ok := node.(*ast.AssignStmt)
		if !ok {
			return true
		}
		for i, raw := range assignment.Rhs {
			if i >= len(assignment.Lhs) {
				continue
			}
			name, nameOK := assignment.Lhs[i].(*ast.Ident)
			if !nameOK {
				continue
			}
			literal, literalOK := raw.(*ast.CompositeLit)
			current, exists := result[name.Name]
			if literalOK && len(literal.Elts) > 0 && !exists {
				result[name.Name] = middlewareSlice{values: append([]ast.Expr{}, literal.Elts...), complete: true}
			} else if exists {
				current.complete = false
				result[name.Name] = current
			}
		}
		return true
	})
	return result
}

type muxFieldBinding struct {
	receiver string
	field    string
}

func returnedMuxBindings(function *ast.FuncDecl, muxes map[string]bool) map[string]muxFieldBinding {
	result := map[string]muxFieldBinding{}
	ast.Inspect(function.Body, func(node ast.Node) bool {
		literal, ok := node.(*ast.CompositeLit)
		if !ok {
			return true
		}
		receiver := astTypeName(literal.Type)
		if receiver == "" {
			return true
		}
		for _, raw := range literal.Elts {
			field, ok := raw.(*ast.KeyValueExpr)
			if !ok {
				continue
			}
			name, nameOK := field.Key.(*ast.Ident)
			value, valueOK := field.Value.(*ast.Ident)
			if nameOK && valueOK && muxes[value.Name] {
				result[value.Name] = muxFieldBinding{receiver: receiver, field: name.Name}
			}
		}
		return true
	})
	return result
}

func astTypeName(expression ast.Expr) string {
	switch typed := expression.(type) {
	case *ast.Ident:
		return typed.Name
	case *ast.SelectorExpr:
		return typed.Sel.Name
	case *ast.StarExpr:
		return astTypeName(typed.X)
	case *ast.ArrayType:
		return astTypeName(typed.Elt)
	}
	return ""
}

func serverConstructorInvoked(files []sourceFile, index repositoryGoIndex, constructorFile sourceFile, constructor *ast.FuncDecl, receiver, field string) bool {
	servedMethods := serverFieldMethods(index, constructorFile, receiver, field)
	if len(servedMethods) == 0 {
		return false
	}
	constructorKey := runtimeFunction(constructorFile, constructor)
	for _, file := range files {
		for _, declaration := range file.file.Decls {
			function, ok := declaration.(*ast.FuncDecl)
			if !ok || function.Body == nil {
				continue
			}
			variables := map[string]bool{}
			ast.Inspect(function.Body, func(node ast.Node) bool {
				assignment, ok := node.(*ast.AssignStmt)
				if !ok {
					return true
				}
				for i, raw := range assignment.Rhs {
					if i >= len(assignment.Lhs) {
						continue
					}
					call, callOK := raw.(*ast.CallExpr)
					name, nameOK := assignment.Lhs[i].(*ast.Ident)
					if callOK && nameOK && repositoryCallKey(file, call) == constructorKey {
						variables[name.Name] = true
					}
				}
				return true
			})
			invoked := false
			ast.Inspect(function.Body, func(node ast.Node) bool {
				call, ok := node.(*ast.CallExpr)
				if !ok {
					return true
				}
				selector, selectorOK := call.Fun.(*ast.SelectorExpr)
				if !selectorOK {
					return true
				}
				variable, variableOK := selector.X.(*ast.Ident)
				if variableOK && variables[variable.Name] && servedMethods[selector.Sel.Name] {
					invoked = true
					return false
				}
				return true
			})
			if invoked {
				return true
			}
		}
	}
	return false
}

func serverFieldMethods(index repositoryGoIndex, file sourceFile, receiver, field string) map[string]bool {
	result := map[string]bool{}
	pkg := packagePath(file)
	for key, declarations := range index.functions {
		if key.packagePath != pkg || key.receiver != receiver || len(declarations) != 1 {
			continue
		}
		function := declarations[0].function
		receiverVariable := receiverName(function)
		servers := map[string]bool{}
		ast.Inspect(function.Body, func(node ast.Node) bool {
			assignment, ok := node.(*ast.AssignStmt)
			if !ok {
				return true
			}
			for i, raw := range assignment.Rhs {
				if i >= len(assignment.Lhs) {
					continue
				}
				literal := dereferencedComposite(raw)
				if literal == nil || !isImportedType(declarations[0].file, literal.Type, netHTTPPackage, "Server") {
					continue
				}
				handler := compositeFieldExpression(literal, "Handler")
				selector, selectorOK := handler.(*ast.SelectorExpr)
				if !selectorOK {
					continue
				}
				owner, ownerOK := selector.X.(*ast.Ident)
				name, nameOK := assignment.Lhs[i].(*ast.Ident)
				if ownerOK && nameOK && owner.Name == receiverVariable && selector.Sel.Name == field {
					servers[name.Name] = true
				}
			}
			return true
		})
		served := false
		ast.Inspect(function.Body, func(node ast.Node) bool {
			call, ok := node.(*ast.CallExpr)
			if !ok {
				return true
			}
			selector, selectorOK := call.Fun.(*ast.SelectorExpr)
			if !selectorOK {
				return true
			}
			server, serverOK := selector.X.(*ast.Ident)
			if serverOK && servers[server.Name] &&
				(selector.Sel.Name == "ListenAndServe" || selector.Sel.Name == "ListenAndServeTLS" ||
					selector.Sel.Name == "Serve" || selector.Sel.Name == "ServeTLS") {
				served = true
				return false
			}
			return true
		})
		if served {
			result[key.name] = true
		}
	}
	return result
}

func dereferencedComposite(expression ast.Expr) *ast.CompositeLit {
	switch typed := expression.(type) {
	case *ast.CompositeLit:
		return typed
	case *ast.UnaryExpr:
		if typed.Op == token.AND {
			return dereferencedComposite(typed.X)
		}
	}
	return nil
}

func collectMuxGroups(index repositoryGoIndex, file sourceFile, function *ast.FuncDecl, mux string, types map[string][]runtimeFunctionKey, middlewareSlices map[string]middlewareSlice) ([]muxRegistrationGroup, bool) {
	var groups []muxRegistrationGroup
	closed := true
	ast.Inspect(function.Body, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok {
			return true
		}
		selector, selectorOK := call.Fun.(*ast.SelectorExpr)
		if selectorOK {
			if receiver, receiverOK := selector.X.(*ast.Ident); receiverOK && receiver.Name == mux {
				if selector.Sel.Name != "Handle" && selector.Sel.Name != "HandleFunc" {
					closed = false
					return true
				}
				if len(call.Args) < 2 || directMuxRegistrationUnsafe(file, call) {
					closed = false
				}
				return true
			}
		}
		muxArgument := -1
		for i, argument := range call.Args {
			if identifier, ok := argument.(*ast.Ident); ok && identifier.Name == mux {
				muxArgument = i
				break
			}
		}
		if muxArgument < 0 {
			return true
		}
		key := repositoryCallKey(file, call)
		helper, exists := index.helpers[key]
		if !exists || !helper.complete || helper.muxIndex != muxArgument {
			closed = false
			return true
		}
		middlewares, ok := callMiddlewares(call, helper, middlewareSlices)
		if !ok || !boundedMiddlewareSet(index, file, middlewares) {
			closed = false
			return true
		}
		if !helper.provider {
			return true
		}
		if helper.handlerIndex >= len(call.Args) {
			closed = false
			return true
		}
		handler, ok := call.Args[helper.handlerIndex].(*ast.Ident)
		if !ok {
			closed = false
			return true
		}
		providerTypes := append([]runtimeFunctionKey{}, types[handler.Name]...)
		providerTypes = append(providerTypes, rangedVariableTypesAt(function, handler.Name, call.Pos(), types)...)
		if len(providerTypes) == 0 {
			closed = false
			return true
		}
		group := muxRegistrationGroup{middlewares: middlewares, file: file, position: call.Pos()}
		for _, providerType := range providerTypes {
			provider := index.providers[runtimeFunctionKey{packagePath: providerType.packagePath, receiver: providerType.receiver, name: "GetRoutes"}]
			if !provider.complete {
				closed = false
				return true
			}
			group.routes = append(group.routes, provider.routes...)
		}
		groups = append(groups, group)
		return true
	})
	return groups, closed && len(groups) > 0
}

func directMuxRegistrationUnsafe(file sourceFile, call *ast.CallExpr) bool {
	path := resolveServeMuxPattern(call.Args[0])
	if !strings.HasPrefix(path, "/") {
		return true
	}
	if selector, ok := call.Args[1].(*ast.SelectorExpr); ok {
		alias, aliasOK := selector.X.(*ast.Ident)
		return !aliasOK || file.imports[alias.Name] != "net/http/pprof"
	}
	return true
}

func resolveServeMuxPattern(expression ast.Expr) string {
	value := stringLiteral(expression)
	if value == "" {
		return ""
	}
	parts := strings.SplitN(value, " ", 2)
	if len(parts) == 2 && strings.HasPrefix(parts[1], "/") {
		return parts[1]
	}
	return value
}

func callMiddlewares(call *ast.CallExpr, helper registrationHelper, slices map[string]middlewareSlice) ([]ast.Expr, bool) {
	if helper.middlewareIndex < 0 {
		return nil, true
	}
	if len(call.Args) == helper.middlewareIndex {
		return nil, true
	}
	if len(call.Args) < helper.middlewareIndex {
		return nil, false
	}
	if call.Ellipsis != token.NoPos {
		if len(call.Args) != helper.middlewareIndex+1 {
			return nil, false
		}
		name, ok := call.Args[helper.middlewareIndex].(*ast.Ident)
		set, exists := slices[name.Name]
		return set.values, ok && exists && set.complete && len(set.values) > 0
	}
	return append([]ast.Expr{}, call.Args[helper.middlewareIndex:]...), true
}

func boundedMiddlewareSet(index repositoryGoIndex, file sourceFile, expressions []ast.Expr) bool {
	for _, expression := range expressions {
		if !boundedRepositoryMiddleware(index, file, expression) {
			return false
		}
	}
	return true
}

func boundedRepositoryMiddleware(index repositoryGoIndex, file sourceFile, expression ast.Expr) bool {
	if call, ok := expression.(*ast.CallExpr); ok {
		expression = call.Fun
	}
	key := repositoryFunctionExpression(file, expression)
	declarations := index.functions[key]
	if len(declarations) != 1 {
		return false
	}
	function := declarations[0].function
	return !hasAuthenticationEnforcement(function.Body) && invokesHandlerParameter(function)
}

func repositoryFunctionExpression(file sourceFile, expression ast.Expr) runtimeFunctionKey {
	switch typed := expression.(type) {
	case *ast.Ident:
		return runtimeFunctionKey{packagePath: packagePath(file), name: typed.Name}
	case *ast.SelectorExpr:
		if alias, ok := typed.X.(*ast.Ident); ok {
			return runtimeFunctionKey{packagePath: file.imports[alias.Name], name: typed.Sel.Name}
		}
	}
	return runtimeFunctionKey{}
}

func repositoryCallKey(file sourceFile, call *ast.CallExpr) runtimeFunctionKey {
	return repositoryFunctionExpression(file, call.Fun)
}

func invokesHandlerParameter(function *ast.FuncDecl) bool {
	invoked := false
	inspectFunction := func(fields *ast.FieldList, body *ast.BlockStmt) {
		handlers := map[string]bool{}
		for _, parameter := range flattenedParameters(fields) {
			if strings.Contains(strings.ToLower(astTypeName(parameter.typ)), "handler") {
				handlers[parameter.name] = true
			}
		}
		ast.Inspect(body, func(node ast.Node) bool {
			call, ok := node.(*ast.CallExpr)
			if !ok {
				return true
			}
			if name, ok := call.Fun.(*ast.Ident); ok && handlers[name.Name] {
				invoked = true
			}
			if selector, ok := call.Fun.(*ast.SelectorExpr); ok {
				if name, ok := selector.X.(*ast.Ident); ok && handlers[name.Name] && selector.Sel.Name == "ServeHTTP" {
					invoked = true
				}
			}
			return !invoked
		})
	}
	inspectFunction(function.Type.Params, function.Body)
	ast.Inspect(function.Body, func(node ast.Node) bool {
		literal, ok := node.(*ast.FuncLit)
		if ok {
			inspectFunction(literal.Type.Params, literal.Body)
		}
		return !invoked
	})
	return invoked
}

func hasAuthenticationEnforcement(node ast.Node) bool {
	found := false
	ast.Inspect(node, func(candidate ast.Node) bool {
		switch typed := candidate.(type) {
		case *ast.Ident:
			name := strings.ToLower(typed.Name)
			for _, fragment := range []string{"authorization", "authenticate", "credential", "bearer", "apikey", "api_key", "password", "tokenreview", "subjectaccess", "oidc", "jwt", "rbac"} {
				if strings.Contains(name, fragment) {
					found = true
					return false
				}
			}
		case *ast.BasicLit:
			value := strings.ToLower(typed.Value)
			for _, fragment := range []string{"authorization", "bearer ", "x-api-key", "api key"} {
				if strings.Contains(value, fragment) {
					found = true
					return false
				}
			}
		case *ast.SelectorExpr:
			if typed.Sel.Name == "StatusUnauthorized" || typed.Sel.Name == "StatusForbidden" {
				found = true
				return false
			}
		}
		return !found
	})
	return found
}

func authenticationFactForMux(mux string, group muxRegistrationGroup) model.AuthenticationFact {
	methods := uniqueRouteValues(group.routes, func(route repositoryRoute) string { return strings.ToUpper(route.method) })
	paths := uniqueRouteValues(group.routes, func(route repositoryRoute) string { return route.path })
	endpoint := muxSurfaceName(mux, paths)
	policy := "Closed route inventory has no authentication or authorization enforcement"
	if len(group.middlewares) == 0 {
		policy += "; no middleware is applied"
	} else {
		policy += "; every local middleware wrapper was inspected"
	}
	return model.AuthenticationFact{
		Endpoint: endpoint, Methods: strings.Join(methods, ", "), Mechanism: "None",
		EnforcementPoint: "N/A", Policy: policy, Source: sourceAt(group.file, group.position),
	}
}

func uniqueRouteValues(routes []repositoryRoute, value func(repositoryRoute) string) []string {
	seen := map[string]bool{}
	var result []string
	for _, route := range routes {
		candidate := value(route)
		if candidate != "" && !seen[candidate] {
			seen[candidate] = true
			result = append(result, candidate)
		}
	}
	return result
}

func muxSurfaceName(mux string, paths []string) string {
	observability := len(paths) > 0
	for _, path := range paths {
		if path != "/health" && path != "/ready" && path != "/readyz" && path != "/metrics" {
			observability = false
			break
		}
	}
	if observability {
		return "Observability endpoints (" + strings.Join(paths, ", ") + ")"
	}
	words := splitIdentifierWords(strings.TrimSuffix(strings.TrimSuffix(mux, "Mux"), "mux"))
	for i, word := range words {
		if strings.EqualFold(word, "api") {
			words[i] = "API"
		}
	}
	if len(words) == 0 {
		return "HTTP server routes"
	}
	return strings.Join(words, " ") + " server routes"
}

func splitIdentifierWords(value string) []string {
	var words []string
	start := 0
	for i, current := range value {
		if i > 0 && unicode.IsUpper(current) {
			words = append(words, value[start:i])
			start = i
		}
	}
	if start < len(value) {
		words = append(words, value[start:])
	}
	for i, word := range words {
		lower := strings.ToLower(word)
		if lower == "obs" {
			words[i] = "Observability"
		} else if lower != "api" && word != "" {
			words[i] = strings.ToUpper(word[:1]) + word[1:]
		}
	}
	return words
}

func sortRepositoryRoutes(routes []repositoryRoute) {
	sort.Slice(routes, func(i, j int) bool {
		return routes[i].path+routes[i].method < routes[j].path+routes[j].method
	})
}
