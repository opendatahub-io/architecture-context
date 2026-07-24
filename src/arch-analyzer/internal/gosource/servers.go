package gosource

import (
	"go/ast"
	"go/token"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

const (
	netHTTPPackage = "net/http"
	grpcPackage    = "google.golang.org/grpc"
)

type httpRouteRegistration struct {
	mux      string
	path     string
	handler  string
	wrappers []string
	position token.Pos
}

func extractBoundedServerAuthentication(file sourceFile) []model.AuthenticationFact {
	result := extractBoundedHTTPAuthentication(file)
	result = append(result, extractBoundedGRPCAuthentication(file)...)
	return result
}

func extractBoundedHTTPAuthentication(file sourceFile) []model.AuthenticationFact {
	if !importsPackage(file, netHTTPPackage) {
		return nil
	}
	functions := uniqueFunctions(file.file)
	var result []model.AuthenticationFact
	for _, declaration := range file.file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Body == nil {
			continue
		}
		muxes := map[string]bool{}
		deployed := map[string]bool{}
		var registrations []httpRouteRegistration
		ast.Inspect(function.Body, func(node ast.Node) bool {
			switch typed := node.(type) {
			case *ast.AssignStmt:
				for index, expression := range typed.Rhs {
					if index >= len(typed.Lhs) || !isImportedCall(file, expression, netHTTPPackage, "NewServeMux") {
						continue
					}
					if variable, ok := typed.Lhs[index].(*ast.Ident); ok {
						muxes[variable.Name] = true
					}
				}
			case *ast.CompositeLit:
				if !isImportedType(file, typed.Type, netHTTPPackage, "Server") {
					return true
				}
				if handler := compositeFieldExpression(typed, "Handler"); handler != nil {
					if variable, ok := handler.(*ast.Ident); ok && muxes[variable.Name] {
						deployed[variable.Name] = true
					}
				}
			case *ast.CallExpr:
				selector, ok := typed.Fun.(*ast.SelectorExpr)
				if !ok {
					return true
				}
				receiver, receiverOK := selector.X.(*ast.Ident)
				if !receiverOK || !muxes[receiver.Name] || len(typed.Args) < 2 ||
					(selector.Sel.Name != "Handle" && selector.Sel.Name != "HandleFunc") {
					return true
				}
				path := stringLiteral(typed.Args[0])
				if !strings.HasPrefix(path, "/") {
					return true
				}
				handler, wrappers, bounded := boundedHTTPHandler(file, typed.Args[1], functions)
				if bounded {
					registrations = append(registrations, httpRouteRegistration{
						mux: receiver.Name, path: path, handler: handler,
						wrappers: wrappers, position: selector.Sel.Pos(),
					})
				}
			}
			return true
		})
		if len(deployed) == 0 {
			continue
		}
		for _, registration := range registrations {
			if !deployed[registration.mux] {
				continue
			}
			method := handlerHTTPMethod(functions[registration.handler])
			if method == "" && isHealthPath(registration.path) {
				method = "GET"
			}
			if method == "" {
				continue
			}
			policy := "Bounded net/http handler chain has no authentication enforcement"
			if len(registration.wrappers) > 0 {
				policy += "; pass-through middleware: " + strings.Join(registration.wrappers, ", ")
			}
			result = append(result, model.AuthenticationFact{
				Endpoint: registration.path + " (Go HTTP)", Methods: method,
				Mechanism: "None", EnforcementPoint: "N/A", Policy: policy,
				Source: sourceAt(file, registration.position),
			})
		}
	}
	return result
}

func uniqueFunctions(file *ast.File) map[string]*ast.FuncDecl {
	result := map[string]*ast.FuncDecl{}
	duplicates := map[string]bool{}
	for _, declaration := range file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Body == nil {
			continue
		}
		name := function.Name.Name
		if result[name] != nil {
			duplicates[name] = true
		}
		result[name] = function
	}
	for name := range duplicates {
		delete(result, name)
	}
	return result
}

func boundedHTTPHandler(file sourceFile, expression ast.Expr, functions map[string]*ast.FuncDecl) (string, []string, bool) {
	call, ok := expression.(*ast.CallExpr)
	if !ok || len(call.Args) != 1 || call.Ellipsis != token.NoPos {
		return "", nil, false
	}
	if isImportedSelector(file, call.Fun, netHTTPPackage, "HandlerFunc") {
		name := calledFunctionName(call.Args[0])
		return name, nil, name != "" && functions[name] != nil
	}
	wrapper := calledFunctionName(call.Fun)
	if wrapper == "" || !boundedPassThroughMiddleware(functions[wrapper]) {
		return "", nil, false
	}
	handler, wrappers, bounded := boundedHTTPHandler(file, call.Args[0], functions)
	if !bounded {
		return "", nil, false
	}
	return handler, append([]string{wrapper}, wrappers...), true
}

func boundedPassThroughMiddleware(function *ast.FuncDecl) bool {
	if function == nil || function.Type.Params == nil || len(function.Type.Params.List) == 0 || function.Body == nil {
		return false
	}
	parameter := ""
	if len(function.Type.Params.List[0].Names) == 1 {
		parameter = function.Type.Params.List[0].Names[0].Name
	}
	if parameter == "" || containsSecurityVocabulary(function.Body) {
		return false
	}
	var closure *ast.FuncLit
	for _, statement := range function.Body.List {
		returned, ok := statement.(*ast.ReturnStmt)
		if !ok || len(returned.Results) != 1 {
			continue
		}
		call, ok := returned.Results[0].(*ast.CallExpr)
		if ok && len(call.Args) == 1 {
			closure, _ = call.Args[0].(*ast.FuncLit)
		}
	}
	if closure == nil {
		return false
	}
	for _, statement := range closure.Body.List {
		if directServeHTTPCall(statement, parameter) {
			return true
		}
		switch statement.(type) {
		case *ast.IfStmt, *ast.SwitchStmt, *ast.TypeSwitchStmt, *ast.ForStmt,
			*ast.RangeStmt, *ast.SelectStmt, *ast.ReturnStmt, *ast.BranchStmt:
			return false
		}
	}
	return false
}

func directServeHTTPCall(statement ast.Stmt, receiver string) bool {
	expression, ok := statement.(*ast.ExprStmt)
	if !ok {
		return false
	}
	call, ok := expression.X.(*ast.CallExpr)
	if !ok {
		return false
	}
	selector, ok := call.Fun.(*ast.SelectorExpr)
	identifier, identifierOK := selector.X.(*ast.Ident)
	return ok && identifierOK && identifier.Name == receiver && selector.Sel.Name == "ServeHTTP"
}

func containsSecurityVocabulary(node ast.Node) bool {
	found := false
	ast.Inspect(node, func(candidate ast.Node) bool {
		identifier, ok := candidate.(*ast.Ident)
		if !ok {
			return true
		}
		name := strings.ToLower(identifier.Name)
		for _, fragment := range []string{"auth", "token", "credential", "cookie", "session", "apikey", "permission", "subjectaccess", "jwt", "oidc", "rbac"} {
			if strings.Contains(name, fragment) {
				found = true
				return false
			}
		}
		return true
	})
	return found
}

func handlerHTTPMethod(function *ast.FuncDecl) string {
	if function == nil {
		return ""
	}
	methods := map[string]bool{}
	ast.Inspect(function.Body, func(node ast.Node) bool {
		binary, ok := node.(*ast.BinaryExpr)
		if !ok || (binary.Op != token.EQL && binary.Op != token.NEQ) {
			return true
		}
		if isMethodSelector(binary.X) {
			if value := stringLiteral(binary.Y); value != "" {
				methods[strings.ToUpper(value)] = true
			}
		}
		if isMethodSelector(binary.Y) {
			if value := stringLiteral(binary.X); value != "" {
				methods[strings.ToUpper(value)] = true
			}
		}
		return true
	})
	if len(methods) != 1 {
		return ""
	}
	for method := range methods {
		return method
	}
	return ""
}

func isMethodSelector(expression ast.Expr) bool {
	selector, ok := expression.(*ast.SelectorExpr)
	return ok && selector.Sel.Name == "Method"
}

func isHealthPath(path string) bool {
	lower := strings.ToLower(path)
	return strings.Contains(lower, "health") || strings.Contains(lower, "ready")
}

// extractConditionalIdentityEnforcement detects HTTP mux routes gated by a
// configuration method that checks identity headers. When a helper like
// canContinueRequest reads header values from a config-dependent predicate, the
// enforcement is conditional rather than unconditional. Routes that call the
// gate are emitted with mechanism "Conditional (configuration-dependent)" and
// routes that bypass it are emitted with mechanism "None".
func extractConditionalIdentityEnforcement(files []sourceFile) []model.AuthenticationFact {
	reachable := runtimeReachableFunctions(files)
	var result []model.AuthenticationFact
	for _, file := range files {
		if !importsPackage(file, netHTTPPackage) {
			continue
		}
		for _, declaration := range file.file.Decls {
			function, ok := declaration.(*ast.FuncDecl)
			if !ok || function.Body == nil || function.Recv == nil {
				continue
			}
			key := runtimeFunction(file, function)
			if !reachable[key] {
				continue
			}
			receiver := runtimeReceiverType(function)
			gateName := findIdentityGateMethod(file, receiver)
			if gateName == "" {
				continue
			}
			muxMethod := findMuxSetupMethod(file, receiver)
			if muxMethod == nil {
				continue
			}
			gatedRoutes, ungatedRoutes := classifyRoutesByGate(file, muxMethod, receiver, gateName)
			for _, route := range gatedRoutes {
				result = append(result, model.AuthenticationFact{
					Endpoint: route + " (Go HTTP)", Methods: "ALL",
					Mechanism:        "Conditional (configuration-dependent)",
					EnforcementPoint: "Identity header check gated by runtime configuration",
					Policy:           "Requires X-User and X-Tenant headers when configuration enables identity enforcement; bypassed in local/development mode",
					Source:           sourceAt(file, muxMethod.Pos()),
				})
			}
			for _, route := range ungatedRoutes {
				result = append(result, model.AuthenticationFact{
					Endpoint: route + " (Go HTTP)", Methods: "GET",
					Mechanism:        "None",
					EnforcementPoint: "N/A",
					Policy:           "Route handler does not invoke the conditional identity gate",
					Source:           sourceAt(file, muxMethod.Pos()),
				})
			}
		}
	}
	return dedupeServerAuthentication(result)
}

func findIdentityGateMethod(file sourceFile, receiver string) string {
	for _, declaration := range file.file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Body == nil || function.Recv == nil {
			continue
		}
		if runtimeReceiverType(function) != receiver {
			continue
		}
		if function.Type.Results == nil || len(function.Type.Results.List) != 1 {
			continue
		}
		resultType, ok := function.Type.Results.List[0].Type.(*ast.Ident)
		if !ok || resultType.Name != "bool" {
			continue
		}
		hasConfigCall := false
		hasHeaderGet := false
		ast.Inspect(function.Body, func(node ast.Node) bool {
			call, callOK := node.(*ast.CallExpr)
			if !callOK {
				return true
			}
			selector, selectorOK := call.Fun.(*ast.SelectorExpr)
			if !selectorOK {
				return true
			}
			name := strings.ToLower(selector.Sel.Name)
			if strings.Contains(name, "require") && strings.Contains(name, "header") {
				hasConfigCall = true
			}
			if strings.Contains(name, "identity") && strings.Contains(name, "header") {
				hasConfigCall = true
			}
			return true
		})
		ast.Inspect(function.Body, func(node ast.Node) bool {
			binary, binaryOK := node.(*ast.BinaryExpr)
			if binaryOK && binary.Op == token.EQL {
				if stringLiteral(binary.Y) == "" || stringLiteral(binary.X) == "" {
					selector, selectorOK := binary.X.(*ast.SelectorExpr)
					if selectorOK && (selector.Sel.Name == "Tenant" || selector.Sel.Name == "User") {
						hasHeaderGet = true
					}
					selector, selectorOK = binary.Y.(*ast.SelectorExpr)
					if selectorOK && (selector.Sel.Name == "Tenant" || selector.Sel.Name == "User") {
						hasHeaderGet = true
					}
				}
			}
			return true
		})
		if hasConfigCall && hasHeaderGet {
			return function.Name.Name
		}
	}
	return ""
}

func findMuxSetupMethod(file sourceFile, receiver string) *ast.FuncDecl {
	for _, declaration := range file.file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Body == nil || function.Recv == nil {
			continue
		}
		if runtimeReceiverType(function) != receiver {
			continue
		}
		createsMux := false
		ast.Inspect(function.Body, func(node ast.Node) bool {
			if isImportedCallNode(file, node, netHTTPPackage, "NewServeMux") {
				createsMux = true
				return false
			}
			return true
		})
		if createsMux {
			return function
		}
	}
	return nil
}

func isImportedCallNode(file sourceFile, node ast.Node, path, name string) bool {
	assignment, ok := node.(*ast.AssignStmt)
	if !ok {
		return false
	}
	for _, rhs := range assignment.Rhs {
		if isImportedCall(file, rhs, path, name) {
			return true
		}
	}
	return false
}

func classifyRoutesByGate(file sourceFile, muxMethod *ast.FuncDecl, receiver, gateName string) (gated []string, ungated []string) {
	receiverVar := receiverName(muxMethod)
	setupCalls := map[string]bool{}
	ast.Inspect(muxMethod.Body, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok {
			return true
		}
		selector, ok := call.Fun.(*ast.SelectorExpr)
		if !ok {
			return true
		}
		owner, ok := selector.X.(*ast.Ident)
		if !ok || owner.Name != receiverVar {
			return true
		}
		if strings.HasPrefix(selector.Sel.Name, "setup") && strings.HasSuffix(selector.Sel.Name, "Routes") {
			setupCalls[selector.Sel.Name] = true
		}
		return true
	})
	for methodName := range setupCalls {
		for _, declaration := range file.file.Decls {
			function, ok := declaration.(*ast.FuncDecl)
			if !ok || function.Body == nil || function.Recv == nil || function.Name.Name != methodName {
				continue
			}
			if runtimeReceiverType(function) != receiver {
				continue
			}
			routePath := extractRoutePathFromSetup(function)
			if routePath == "" {
				continue
			}
			if setupCallsGate(function, gateName) {
				gated = append(gated, routePath)
			} else {
				ungated = append(ungated, routePath)
			}
		}
	}
	sort.Strings(gated)
	sort.Strings(ungated)
	return
}

func extractRoutePathFromSetup(function *ast.FuncDecl) string {
	rv := receiverName(function)
	path := ""
	ast.Inspect(function.Body, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok || len(call.Args) < 2 {
			return true
		}
		selector, ok := call.Fun.(*ast.SelectorExpr)
		if !ok {
			return true
		}
		if selector.Sel.Name == "HandleFunc" || selector.Sel.Name == "Handle" {
			if p := stringLiteral(call.Args[0]); strings.HasPrefix(p, "/") {
				path = p
			}
			return true
		}
		if rv != "" {
			if owner, ok := selector.X.(*ast.Ident); ok && owner.Name == rv {
				for _, arg := range call.Args {
					if p := stringLiteral(arg); strings.HasPrefix(p, "/") {
						path = p
					}
				}
			}
		}
		return true
	})
	return path
}

func setupCallsGate(function *ast.FuncDecl, gateName string) bool {
	rv := receiverName(function)
	if rv == "" {
		return false
	}
	found := false
	ast.Inspect(function.Body, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok {
			return true
		}
		selector, ok := call.Fun.(*ast.SelectorExpr)
		if !ok {
			return true
		}
		owner, ok := selector.X.(*ast.Ident)
		if ok && owner.Name == rv && selector.Sel.Name == gateName {
			found = true
			return false
		}
		return true
	})
	return found
}

func extractBoundedGRPCAuthentication(file sourceFile) []model.AuthenticationFact {
	if !importsPackage(file, grpcPackage) {
		return nil
	}
	var result []model.AuthenticationFact
	for _, declaration := range file.file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Body == nil {
			continue
		}
		providers := observabilityProviderVariables(file, function)
		servers := map[string]*ast.CallExpr{}
		ambiguousServers := map[string]bool{}
		positions := map[string]token.Pos{}
		registrations := map[string]bool{}
		ast.Inspect(function.Body, func(node ast.Node) bool {
			switch typed := node.(type) {
			case *ast.AssignStmt:
				for index, raw := range typed.Rhs {
					if index >= len(typed.Lhs) || !isImportedCall(file, raw, grpcPackage, "NewServer") {
						continue
					}
					if variable, ok := typed.Lhs[index].(*ast.Ident); ok {
						if servers[variable.Name] != nil {
							ambiguousServers[variable.Name] = true
						}
						servers[variable.Name], _ = raw.(*ast.CallExpr)
						positions[variable.Name] = raw.Pos()
					}
				}
			case *ast.CallExpr:
				selector, ok := typed.Fun.(*ast.SelectorExpr)
				if !ok {
					return true
				}
				alias, aliasOK := selector.X.(*ast.Ident)
				if !aliasOK || len(typed.Args) < 1 || !strings.HasPrefix(selector.Sel.Name, "Register") || !strings.HasSuffix(selector.Sel.Name, "Server") {
					return true
				}
				server, serverOK := typed.Args[0].(*ast.Ident)
				if !serverOK || servers[server.Name] == nil || strings.Contains(file.imports[alias.Name], "/grpc/health") {
					return true
				}
				registrations[server.Name] = true
			}
			return true
		})
		for variable, call := range servers {
			if ambiguousServers[variable] || !registrations[variable] || !boundedObservabilityGRPCOptions(file, call, providers) {
				continue
			}
			result = append(result, model.AuthenticationFact{
				Endpoint: "gRPC services (Go)", Methods: "ALL", Mechanism: "None",
				EnforcementPoint: "N/A",
				Policy:           "Bounded grpc.NewServer option set contains only observability interceptors; no authentication interceptor configured",
				Source:           sourceAt(file, positions[variable]),
			})
		}
	}
	return result
}

func observabilityProviderVariables(file sourceFile, function *ast.FuncDecl) map[string]bool {
	result := map[string]bool{}
	ast.Inspect(function.Body, func(node ast.Node) bool {
		assignment, ok := node.(*ast.AssignStmt)
		if !ok {
			return true
		}
		for index, raw := range assignment.Rhs {
			if index >= len(assignment.Lhs) {
				continue
			}
			call, ok := raw.(*ast.CallExpr)
			if !ok {
				continue
			}
			path, _, imported := importedCall(file, call)
			variable, variableOK := assignment.Lhs[index].(*ast.Ident)
			if imported && variableOK && isObservabilityPackage(path) {
				result[variable.Name] = true
			}
		}
		return true
	})
	return result
}

func boundedObservabilityGRPCOptions(file sourceFile, server *ast.CallExpr, providers map[string]bool) bool {
	if server == nil || server.Ellipsis != token.NoPos {
		return false
	}
	for _, raw := range server.Args {
		option, ok := raw.(*ast.CallExpr)
		if !ok {
			return false
		}
		selector, selectorOK := option.Fun.(*ast.SelectorExpr)
		if !selectorOK {
			return false
		}
		alias, aliasOK := selector.X.(*ast.Ident)
		if !aliasOK || file.imports[alias.Name] != grpcPackage || len(option.Args) != 1 ||
			(selector.Sel.Name != "UnaryInterceptor" && selector.Sel.Name != "StreamInterceptor" && selector.Sel.Name != "StatsHandler") {
			return false
		}
		interceptor, ok := option.Args[0].(*ast.CallExpr)
		if !ok {
			return false
		}
		providerSelector, selectorOK := interceptor.Fun.(*ast.SelectorExpr)
		if !selectorOK {
			return false
		}
		provider, providerOK := providerSelector.X.(*ast.Ident)
		if !providerOK || !providers[provider.Name] || !strings.Contains(strings.ToLower(providerSelector.Sel.Name), "interceptor") {
			return false
		}
	}
	return true
}

func isObservabilityPackage(path string) bool {
	lower := strings.ToLower(path)
	return strings.Contains(lower, "prometheus") || strings.Contains(lower, "opentelemetry") || strings.Contains(lower, "otel")
}

func calledFunctionName(expression ast.Expr) string {
	switch typed := expression.(type) {
	case *ast.Ident:
		return typed.Name
	case *ast.SelectorExpr:
		return typed.Sel.Name
	}
	return ""
}

func isImportedCall(file sourceFile, expression ast.Expr, path, name string) bool {
	call, ok := expression.(*ast.CallExpr)
	return ok && isImportedSelector(file, call.Fun, path, name)
}

func isImportedType(file sourceFile, expression ast.Expr, path, name string) bool {
	return isImportedSelector(file, expression, path, name)
}

func extractDefaultMuxHealthAuthentication(file sourceFile) []model.AuthenticationFact {
	if !importsPackage(file, netHTTPPackage) {
		return nil
	}
	var result []model.AuthenticationFact
	for _, declaration := range file.file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Body == nil {
			continue
		}
		hasListenAndServe := false
		var healthPaths []struct {
			path     string
			position token.Pos
		}
		ast.Inspect(function.Body, func(node ast.Node) bool {
			call, ok := node.(*ast.CallExpr)
			if !ok {
				return true
			}
			if isImportedCall(file, call, netHTTPPackage, "ListenAndServe") {
				hasListenAndServe = true
				return true
			}
			path, name, imported := importedCall(file, call)
			if !imported || path != netHTTPPackage || name != "HandleFunc" || len(call.Args) < 2 {
				return true
			}
			routePath := stringLiteral(call.Args[0])
			if !isHealthPath(routePath) {
				return true
			}
			healthPaths = append(healthPaths, struct {
				path     string
				position token.Pos
			}{path: routePath, position: call.Fun.Pos()})
			return true
		})
		if !hasListenAndServe {
			continue
		}
		for _, hp := range healthPaths {
			result = append(result, model.AuthenticationFact{
				Endpoint: hp.path + " (Go HTTP default mux)", Methods: "GET",
				Mechanism: "None", EnforcementPoint: "N/A",
				Policy:  "Default mux health endpoint with no authentication enforcement",
				Source:  sourceAt(file, hp.position),
			})
		}
	}
	return result
}

func dedupeServerAuthentication(facts []model.AuthenticationFact) []model.AuthenticationFact {
	seen := map[string]bool{}
	result := make([]model.AuthenticationFact, 0, len(facts))
	for _, fact := range facts {
		key := strings.ToLower(fact.Endpoint) + "\x00" + strings.ToUpper(fact.Methods)
		if !seen[key] {
			seen[key] = true
			result = append(result, fact)
		}
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].Endpoint+result[i].Methods < result[j].Endpoint+result[j].Methods
	})
	return result
}
