package gosource

import (
	"go/ast"
	"sort"
	"strings"
	"unicode"

	"github.com/jctanner/arch-analyzer/internal/model"
)

type registeredGRPCServer struct {
	plain         bool
	tls           bool
	unknownOption bool
	registrations []registeredGRPCService
}

type registeredGRPCService struct {
	name   string
	source string
}

// extractRegisteredGRPCServices retains a server only when grpc.NewServer and a
// protobuf Register*Server call converge in the same function. Generated service
// declarations and imports alone therefore cannot create runtime facts.
func extractRegisteredGRPCServices(file sourceFile, reachable ...map[runtimeFunctionKey]bool) []model.GRPCService {
	if !importsPackage(file, grpcPackage) {
		return nil
	}
	var services []model.GRPCService
	for _, declaration := range file.file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Body == nil {
			continue
		}
		credentialVariables := grpcTransportCredentialVariables(file, function)
		optionVariables := grpcServerOptionVariables(file, function, credentialVariables)
		servers := map[string]*registeredGRPCServer{}
		ast.Inspect(function.Body, func(node ast.Node) bool {
			switch typed := node.(type) {
			case *ast.AssignStmt:
				for index, expression := range typed.Rhs {
					if index >= len(typed.Lhs) || !isImportedCall(file, expression, grpcPackage, "NewServer") {
						continue
					}
					variable, variableOK := typed.Lhs[index].(*ast.Ident)
					call, callOK := expression.(*ast.CallExpr)
					if !variableOK || !callOK {
						continue
					}
					server := servers[variable.Name]
					if server == nil {
						server = &registeredGRPCServer{}
						servers[variable.Name] = server
					}
					classifyGRPCServerOptions(file, call, server, optionVariables, credentialVariables)
				}
			case *ast.CallExpr:
				selector, selectorOK := typed.Fun.(*ast.SelectorExpr)
				if !selectorOK || len(typed.Args) < 1 ||
					!strings.HasPrefix(selector.Sel.Name, "Register") ||
					!strings.HasSuffix(selector.Sel.Name, "Server") {
					return true
				}
				serverName, serverOK := typed.Args[0].(*ast.Ident)
				if !serverOK {
					return true
				}
				server := servers[serverName.Name]
				if server == nil {
					return true
				}
				name := strings.TrimSuffix(strings.TrimPrefix(selector.Sel.Name, "Register"), "Server")
				if name == "" {
					return true
				}
				server.registrations = append(server.registrations, registeredGRPCService{
					name: name, source: sourceAt(file, selector.Sel.Pos()),
				})
			}
			return true
		})

		for serverName, server := range servers {
			var crossFileReachable map[runtimeFunctionKey]bool
			if len(reachable) > 0 {
				crossFileReachable = reachable[0]
			}
			if !registeredGRPCRuntimeReachable(file, function, serverName, crossFileReachable) {
				continue
			}
			for _, registration := range server.registrations {
				encryption, auth, limitation, complete := registeredGRPCSecurity(server)
				if complete {
					limitation = ""
				}
				services = append(services, model.GRPCService{
					Service: registration.name, Protocol: "gRPC", Encryption: encryption,
					Auth: auth, Purpose: "Registered " + humanizeGRPCService(registration.name) + " gRPC service",
					Owner: routeOwner(file), Transport: "HTTP/2",
					Source: registration.source, Limitation: limitation,
				})
			}
		}
	}
	return services
}

func classifyGRPCServerOptions(
	file sourceFile,
	call *ast.CallExpr,
	server *registeredGRPCServer,
	variables map[string]registeredGRPCServer,
	credentialVariables map[string]bool,
) {
	if len(call.Args) == 0 {
		server.plain = true
		return
	}
	if call.Ellipsis.IsValid() && len(call.Args) == 1 {
		if identifier, ok := call.Args[0].(*ast.Ident); ok {
			if resolved, exists := variables[identifier.Name]; exists {
				server.plain = server.plain || resolved.plain
				server.tls = server.tls || resolved.tls
				server.unknownOption = server.unknownOption || resolved.unknownOption
				return
			}
		}
		server.unknownOption = true
		return
	}
	for _, option := range call.Args {
		if isImportedCall(file, option, grpcPackage, "Creds") {
			call := option.(*ast.CallExpr)
			if len(call.Args) == 1 && grpcTransportCredentialExpression(file, call.Args[0], credentialVariables) {
				server.tls = true
			} else {
				server.unknownOption = true
			}
			continue
		}
		server.unknownOption = true
	}
}

func grpcServerOptionVariables(
	file sourceFile,
	function *ast.FuncDecl,
	credentialVariables map[string]bool,
) map[string]registeredGRPCServer {
	result := map[string]registeredGRPCServer{}
	conditionalRanges := functionConditionalRanges(function)
	ast.Inspect(function.Body, func(node ast.Node) bool {
		declaration, declarationOK := node.(*ast.DeclStmt)
		if declarationOK {
			if general, ok := declaration.Decl.(*ast.GenDecl); ok {
				for _, specification := range general.Specs {
					value, valueOK := specification.(*ast.ValueSpec)
					if !valueOK || !isGRPCServerOptionSlice(file, value.Type) || len(value.Values) != 0 {
						continue
					}
					for _, name := range value.Names {
						result[name.Name] = registeredGRPCServer{plain: true}
					}
				}
			}
			return true
		}
		assignment, ok := node.(*ast.AssignStmt)
		if !ok || len(assignment.Lhs) != 1 || len(assignment.Rhs) != 1 {
			return true
		}
		variable, variableOK := assignment.Lhs[0].(*ast.Ident)
		if !variableOK {
			return true
		}
		if literal, literalOK := assignment.Rhs[0].(*ast.CompositeLit); literalOK {
			if !isGRPCServerOptionSlice(file, literal.Type) {
				return true
			}
			state := registeredGRPCServer{plain: len(literal.Elts) == 0}
			for _, option := range literal.Elts {
				classifyGRPCOption(file, option, false, &state, credentialVariables)
			}
			result[variable.Name] = state
			return true
		}
		call, callOK := assignment.Rhs[0].(*ast.CallExpr)
		if !callOK {
			return true
		}
		identifier, appendOK := call.Fun.(*ast.Ident)
		if !appendOK || identifier.Name != "append" || len(call.Args) < 2 ||
			expressionIdentifier(call.Args[0]) != variable.Name {
			return true
		}
		state, exists := result[variable.Name]
		if !exists {
			state.unknownOption = true
		}
		conditional := positionInRanges(call.Pos(), conditionalRanges)
		for _, option := range call.Args[1:] {
			classifyGRPCOption(file, option, conditional, &state, credentialVariables)
		}
		result[variable.Name] = state
		return true
	})
	return result
}

func isGRPCServerOptionSlice(file sourceFile, expression ast.Expr) bool {
	array, ok := expression.(*ast.ArrayType)
	return ok && isImportedType(file, array.Elt, grpcPackage, "ServerOption")
}

func classifyGRPCOption(
	file sourceFile,
	option ast.Expr,
	conditional bool,
	state *registeredGRPCServer,
	credentialVariables map[string]bool,
) {
	if isImportedCall(file, option, grpcPackage, "Creds") {
		call := option.(*ast.CallExpr)
		if len(call.Args) == 1 && grpcTransportCredentialExpression(file, call.Args[0], credentialVariables) {
			state.tls = true
			if conditional {
				state.plain = true
			}
		} else {
			state.unknownOption = true
		}
		return
	}
	if call, ok := option.(*ast.CallExpr); ok {
		if _, name, imported := importedCall(file, call); imported {
			switch name {
			case "MaxRecvMsgSize", "MaxSendMsgSize", "MaxConcurrentStreams", "InitialWindowSize", "InitialConnWindowSize":
				return
			case "ChainStreamInterceptor", "ChainUnaryInterceptor", "StreamInterceptor", "UnaryInterceptor":
				if allObservabilityExpressions(call.Args) {
					return
				}
			}
		}
	}
	state.unknownOption = true
}

func registeredGRPCRuntimeReachable(file sourceFile, function *ast.FuncDecl, serverName string, crossFileReachable map[runtimeFunctionKey]bool) bool {
	if function.Name.Name == "main" || functionReturnsRunnable(function) {
		return true
	}
	localReachable := false
	ast.Inspect(function.Body, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok {
			return true
		}
		selector, ok := call.Fun.(*ast.SelectorExpr)
		if !ok {
			return true
		}
		switch selector.Sel.Name {
		case "Serve", "Start":
			localReachable = expressionContainsIdentifier(selector.X, serverName) ||
				expressionsContainIdentifier(call.Args, serverName)
		case "Add":
			localReachable = expressionsContainIdentifier(call.Args, serverName)
		}
		return !localReachable
	})
	if localReachable {
		return true
	}
	if functionReachableFromMain(file, function.Name.Name) {
		return true
	}
	if crossFileReachable != nil {
		key := runtimeFunction(file, function)
		return crossFileReachable[key]
	}
	return false
}

func functionReturnsRunnable(function *ast.FuncDecl) bool {
	if function.Type.Results == nil {
		return false
	}
	for _, field := range function.Type.Results.List {
		switch typed := field.Type.(type) {
		case *ast.Ident:
			if typed.Name == "Runnable" || typed.Name == "RunnableFunc" {
				return true
			}
		case *ast.SelectorExpr:
			if typed.Sel.Name == "Runnable" || typed.Sel.Name == "RunnableFunc" {
				return true
			}
		}
	}
	return false
}

func functionReachableFromMain(file sourceFile, target string) bool {
	functions := uniqueFunctions(file.file)
	if functions["main"] == nil {
		return false
	}
	seen := map[string]bool{}
	queue := []string{"main"}
	for len(queue) > 0 {
		name := queue[0]
		queue = queue[1:]
		if seen[name] {
			continue
		}
		seen[name] = true
		if name == target {
			return true
		}
		function := functions[name]
		if function == nil || function.Body == nil {
			continue
		}
		ast.Inspect(function.Body, func(node ast.Node) bool {
			call, ok := node.(*ast.CallExpr)
			if !ok {
				return true
			}
			if identifier, ok := call.Fun.(*ast.Ident); ok && functions[identifier.Name] != nil && !seen[identifier.Name] {
				queue = append(queue, identifier.Name)
			}
			return true
		})
	}
	return false
}

func expressionsContainIdentifier(expressions []ast.Expr, name string) bool {
	for _, expression := range expressions {
		if expressionContainsIdentifier(expression, name) {
			return true
		}
	}
	return false
}

func expressionContainsIdentifier(expression ast.Expr, name string) bool {
	found := false
	ast.Inspect(expression, func(node ast.Node) bool {
		identifier, ok := node.(*ast.Ident)
		if ok && identifier.Name == name {
			found = true
			return false
		}
		return !found
	})
	return found
}

func grpcTransportCredentialVariables(file sourceFile, function *ast.FuncDecl) map[string]bool {
	tlsConfigs := map[string]bool{}
	credentials := map[string]bool{}
	ast.Inspect(function.Body, func(node ast.Node) bool {
		assignment, ok := node.(*ast.AssignStmt)
		if !ok {
			return true
		}
		for index, right := range assignment.Rhs {
			if index >= len(assignment.Lhs) {
				continue
			}
			left, ok := assignment.Lhs[index].(*ast.Ident)
			if !ok {
				continue
			}
			if serverTLSConfigExpression(file, right, credentialsWithTLSConfigs(nil, tlsConfigs)) {
				tlsConfigs[left.Name] = true
			}
			if grpcTransportCredentialExpression(file, right, credentialsWithTLSConfigs(credentials, tlsConfigs)) {
				credentials[left.Name] = true
			}
		}
		return true
	})
	return credentialsWithTLSConfigs(credentials, tlsConfigs)
}

func credentialsWithTLSConfigs(credentials, tlsConfigs map[string]bool) map[string]bool {
	result := make(map[string]bool, len(credentials)+len(tlsConfigs))
	for name := range credentials {
		result[name] = true
	}
	for name := range tlsConfigs {
		result["tls-config:"+name] = true
	}
	return result
}

func grpcTransportCredentialExpression(file sourceFile, expression ast.Expr, variables map[string]bool) bool {
	if identifier, ok := expression.(*ast.Ident); ok {
		return variables[identifier.Name]
	}
	call, ok := expression.(*ast.CallExpr)
	if !ok {
		return false
	}
	path, function, imported := importedCall(file, call)
	if !imported || path != "google.golang.org/grpc/credentials" {
		return false
	}
	switch function {
	case "NewServerTLSFromFile":
		return len(call.Args) >= 2
	case "NewTLS":
		return len(call.Args) == 1 && serverTLSConfigExpression(file, call.Args[0], variables)
	default:
		return false
	}
}

func serverTLSConfigExpression(file sourceFile, expression ast.Expr, variables map[string]bool) bool {
	if identifier, ok := expression.(*ast.Ident); ok {
		return variables["tls-config:"+identifier.Name]
	}
	literal := compositeLiteral(expression)
	if literal == nil || !isImportedType(file, literal.Type, "crypto/tls", "Config") {
		return false
	}
	for _, element := range literal.Elts {
		entry, ok := element.(*ast.KeyValueExpr)
		if !ok {
			continue
		}
		field := expressionIdentifier(entry.Key)
		if field == "Certificates" || field == "GetCertificate" || field == "GetConfigForClient" {
			return true
		}
	}
	return false
}

func allObservabilityExpressions(expressions []ast.Expr) bool {
	if len(expressions) == 0 {
		return false
	}
	for _, expression := range expressions {
		name := strings.ToLower(optionExpressionName(expression))
		if !strings.Contains(name, "metric") && !strings.Contains(name, "telemetry") &&
			!strings.Contains(name, "trace") && !strings.Contains(name, "otel") &&
			!strings.Contains(name, "observability") && !strings.Contains(name, "prometheus") {
			return false
		}
	}
	return true
}

func registeredGRPCSecurity(server *registeredGRPCServer) (string, string, string, bool) {
	if server.unknownOption {
		return "Unknown", "Unknown", "gRPC server options include unresolved interceptors or credentials", false
	}
	switch {
	case server.plain && server.tls:
		return "Optional TLS", "None", "Transport TLS is configuration-dependent; no application authentication interceptor is configured", true
	case server.tls:
		return "TLS", "None", "Transport TLS is configured; no application authentication interceptor is configured", true
	case server.plain:
		return "None", "None", "Plaintext gRPC server has no application authentication interceptor", true
	default:
		return "Unknown", "Unknown", "gRPC server construction is unresolved", false
	}
}

func humanizeGRPCService(value string) string {
	var result []rune
	for index, current := range value {
		if index > 0 && unicode.IsUpper(current) {
			previous := rune(value[index-1])
			if unicode.IsLower(previous) || unicode.IsDigit(previous) {
				result = append(result, ' ')
			}
		}
		result = append(result, current)
	}
	return string(result)
}

func dedupeRegisteredGRPCServices(items []model.GRPCService) []model.GRPCService {
	byService := map[string]int{}
	result := make([]model.GRPCService, 0, len(items))
	for _, item := range items {
		key := strings.ToLower(item.Service)
		index, exists := byService[key]
		if exists {
			current := &result[index]
			mergedEncryption := mergeGRPCSecurityValue(current.Encryption, item.Encryption)
			if mergedEncryption != current.Encryption && mergedEncryption == item.Encryption {
				current.Source = item.Source
			}
			current.Encryption = mergedEncryption
			current.Auth = mergeGRPCSecurityValue(current.Auth, item.Auth)
			if current.Limitation == "" {
				current.Limitation = item.Limitation
			}
			if current.Encryption != "Unknown" && current.Auth != "Unknown" {
				current.Limitation = ""
			}
			continue
		}
		byService[key] = len(result)
		result = append(result, item)
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].Service+result[i].Encryption < result[j].Service+result[j].Encryption
	})
	return result
}

func mergeGRPCSecurityValue(left, right string) string {
	if left == right || right == "" {
		return left
	}
	if left == "" {
		return right
	}
	if (left == "None" && (right == "TLS" || right == "Optional TLS")) ||
		(right == "None" && (left == "TLS" || left == "Optional TLS")) ||
		(left == "TLS" && right == "Optional TLS") ||
		(right == "TLS" && left == "Optional TLS") {
		return "Optional TLS"
	}
	return "Unknown"
}

func registeredGRPCAuthentication(services []model.GRPCService) []model.AuthenticationFact {
	var result []model.AuthenticationFact
	for _, service := range services {
		if service.Auth == "Unknown" || service.Encryption == "Unknown" {
			continue
		}
		policy := "Plaintext gRPC service has no application authentication interceptor"
		switch service.Encryption {
		case "TLS":
			policy = "Transport TLS is configured; no application authentication interceptor is configured"
		case "Optional TLS":
			policy = "Transport TLS is configuration-dependent; no application authentication interceptor is configured"
		}
		result = append(result, model.AuthenticationFact{
			Endpoint: humanizeGRPCService(service.Service) + " gRPC",
			Methods:  "gRPC", Mechanism: service.Auth, EnforcementPoint: "N/A",
			Policy: policy, Source: service.Source,
		})
	}
	return result
}
