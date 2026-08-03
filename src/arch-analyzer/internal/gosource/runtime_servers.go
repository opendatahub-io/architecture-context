package gosource

import (
	"go/ast"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

const (
	grpcHealthPackage = "google.golang.org/grpc/health/grpc_health_v1"
	promHTTPPackage   = "github.com/prometheus/client_golang/prometheus/promhttp"
)

func extractStandaloneRuntimeServers(file sourceFile, reachable map[runtimeFunctionKey]bool) []model.RuntimeServer {
	var result []model.RuntimeServer
	for _, declaration := range file.file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Body == nil || !reachable[runtimeFunction(file, function)] {
			continue
		}
		result = append(result, functionHealthServers(file, function)...)
		result = append(result, functionMetricsServers(file, function)...)
	}
	result = append(result, constructorMetricsServers(file, reachable)...)
	return result
}

// constructorMetricsServers detects metrics servers whose construction
// (NewServeMux, promhttp.Handler, http.Server) happens in a constructor and
// whose lifecycle (ListenAndServe) happens in a separate method on the
// returned type. This covers the pattern where a NewXxxServer function builds
// the server struct and a Start/Serve method invokes the listener.
func constructorMetricsServers(file sourceFile, reachable map[runtimeFunctionKey]bool) []model.RuntimeServer {
	var result []model.RuntimeServer
	for _, declaration := range file.file.Decls {
		constructor, ok := declaration.(*ast.FuncDecl)
		if !ok || constructor.Body == nil || constructor.Recv != nil {
			continue
		}
		if !reachable[runtimeFunction(file, constructor)] {
			continue
		}
		muxes := map[string]bool{}
		metricsHandlers := map[string]bool{}
		serverFields := map[string]string{}
		returnedType := ""
		ast.Inspect(constructor.Body, func(node ast.Node) bool {
			switch typed := node.(type) {
			case *ast.AssignStmt:
				for i, expression := range typed.Rhs {
					if i >= len(typed.Lhs) {
						continue
					}
					identifier, idOK := typed.Lhs[i].(*ast.Ident)
					if !idOK {
						continue
					}
					if isImportedCall(file, expression, "net/http", "NewServeMux") {
						muxes[identifier.Name] = true
					}
				}
			case *ast.CallExpr:
				selector, selectorOK := typed.Fun.(*ast.SelectorExpr)
				if selectorOK && (selector.Sel.Name == "Handle" || selector.Sel.Name == "HandleFunc") && len(typed.Args) >= 2 {
					mux, muxOK := selector.X.(*ast.Ident)
					if muxOK && stringLiteral(typed.Args[0]) == "/metrics" && expressionContainsPrometheusHandler(file, typed.Args[1]) {
						metricsHandlers[mux.Name] = true
					}
				}
			case *ast.ReturnStmt:
				for _, returned := range typed.Results {
					literal := dereferencedComposite(returned)
					if literal == nil {
						continue
					}
					typeName := astTypeName(literal.Type)
					if typeName == "" {
						continue
					}
					for _, element := range literal.Elts {
						kv, kvOK := element.(*ast.KeyValueExpr)
						if !kvOK {
							continue
						}
						fieldName, fieldOK := kv.Key.(*ast.Ident)
						if !fieldOK {
							continue
						}
						serverLiteral := dereferencedComposite(kv.Value)
						if serverLiteral != nil && isImportedType(file, serverLiteral.Type, "net/http", "Server") {
							handler := compositeFieldExpression(serverLiteral, "Handler")
							if mux, muxOK := handler.(*ast.Ident); muxOK {
								serverFields[mux.Name] = fieldName.Name
								returnedType = typeName
							}
						}
					}
				}
			}
			return true
		})
		for mux := range metricsHandlers {
			if !muxes[mux] {
				continue
			}
			field, hasField := serverFields[mux]
			if !hasField || returnedType == "" {
				continue
			}
			if !methodInvokesFieldLifecycle(file, returnedType, field) {
				continue
			}
			result = append(result, model.RuntimeServer{
				Surface: "metrics", Protocol: "HTTP", Lifecycle: "ListenAndServe",
				Source: sourceAt(file, constructor.Pos()),
			})
		}
	}
	return result
}

func methodInvokesFieldLifecycle(file sourceFile, receiver, field string) bool {
	for _, declaration := range file.file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Body == nil || function.Recv == nil {
			continue
		}
		if runtimeReceiverType(function) != receiver {
			continue
		}
		receiverName := receiverName(function)
		invoked := false
		ast.Inspect(function.Body, func(node ast.Node) bool {
			call, callOK := node.(*ast.CallExpr)
			if !callOK {
				return true
			}
			selector, selectorOK := call.Fun.(*ast.SelectorExpr)
			if !selectorOK {
				return true
			}
			if selector.Sel.Name != "ListenAndServe" && selector.Sel.Name != "ListenAndServeTLS" &&
				selector.Sel.Name != "Serve" && selector.Sel.Name != "ServeTLS" {
				return true
			}
			fieldAccess, fieldOK := selector.X.(*ast.SelectorExpr)
			if !fieldOK {
				return true
			}
			owner, ownerOK := fieldAccess.X.(*ast.Ident)
			if ownerOK && owner.Name == receiverName && fieldAccess.Sel.Name == field {
				invoked = true
				return false
			}
			return true
		})
		if invoked {
			return true
		}
	}
	return false
}

func functionHealthServers(file sourceFile, function *ast.FuncDecl) []model.RuntimeServer {
	constructed := map[string]bool{}
	registered := map[string]string{}
	lifecycles := map[string]string{}
	ast.Inspect(function.Body, func(node ast.Node) bool {
		switch typed := node.(type) {
		case *ast.AssignStmt:
			for index, expression := range typed.Rhs {
				if index >= len(typed.Lhs) || !isImportedCall(file, expression, grpcPackage, "NewServer") {
					continue
				}
				if identifier, ok := typed.Lhs[index].(*ast.Ident); ok {
					constructed[identifier.Name] = true
				}
			}
		case *ast.CallExpr:
			path, name, imported := importedCall(file, typed)
			if imported && path == grpcHealthPackage && name == "RegisterHealthServer" && len(typed.Args) > 0 {
				if identifier, ok := typed.Args[0].(*ast.Ident); ok {
					registered[identifier.Name] = sourceAt(file, typed.Pos())
				}
			}
			for server := range constructed {
				if lifecycle := grpcServerLifecycle(typed, server); lifecycle != "" {
					lifecycles[server] = lifecycle
				}
			}
		}
		return true
	})
	var result []model.RuntimeServer
	for server, source := range registered {
		if constructed[server] && lifecycles[server] != "" {
			result = append(result, model.RuntimeServer{
				Surface: "health", Protocol: "gRPC", Lifecycle: lifecycles[server], Source: source,
			})
		}
	}
	return result
}

func grpcServerLifecycle(call *ast.CallExpr, server string) string {
	selector, ok := call.Fun.(*ast.SelectorExpr)
	if !ok {
		return ""
	}
	switch selector.Sel.Name {
	case "Serve":
		if expressionContainsIdentifier(selector.X, server) || expressionsContainIdentifier(call.Args, server) {
			return "Serve"
		}
	case "Start":
		if expressionContainsIdentifier(selector.X, server) || expressionsContainIdentifier(call.Args, server) {
			return "Start"
		}
	case "Add":
		for _, argument := range call.Args {
			if expressionContainsIdentifier(argument, server) && expressionCallsFunction(argument, "GRPCServer") {
				return "manager Runnable"
			}
		}
	}
	return ""
}

func functionMetricsServers(file sourceFile, function *ast.FuncDecl) []model.RuntimeServer {
	muxes := map[string]bool{}
	metricsHandlers := map[string]bool{}
	servers := map[string]string{}
	lifecycles := map[string]string{}
	ast.Inspect(function.Body, func(node ast.Node) bool {
		switch typed := node.(type) {
		case *ast.AssignStmt:
			for index, expression := range typed.Rhs {
				if index >= len(typed.Lhs) {
					continue
				}
				identifier, ok := typed.Lhs[index].(*ast.Ident)
				if !ok {
					continue
				}
				if isImportedCall(file, expression, "net/http", "NewServeMux") {
					muxes[identifier.Name] = true
					continue
				}
				literal := compositeLiteral(expression)
				if literal == nil || !isImportedType(file, literal.Type, "net/http", "Server") {
					continue
				}
				handler := compositeFieldExpression(literal, "Handler")
				if mux, ok := handler.(*ast.Ident); ok {
					servers[identifier.Name] = mux.Name
				}
			}
		case *ast.CallExpr:
			selector, selectorOK := typed.Fun.(*ast.SelectorExpr)
			if selectorOK && (selector.Sel.Name == "Handle" || selector.Sel.Name == "HandleFunc") && len(typed.Args) >= 2 {
				mux, muxOK := selector.X.(*ast.Ident)
				if muxOK && stringLiteral(typed.Args[0]) == "/metrics" && expressionContainsPrometheusHandler(file, typed.Args[1]) {
					metricsHandlers[mux.Name] = true
				}
			}
			if selectorOK && (selector.Sel.Name == "ListenAndServe" || selector.Sel.Name == "Serve" || selector.Sel.Name == "Start") {
				if server, ok := selector.X.(*ast.Ident); ok {
					lifecycles[server.Name] = selector.Sel.Name
				}
			}
		}
		return true
	})
	var result []model.RuntimeServer
	for server, mux := range servers {
		if muxes[mux] && metricsHandlers[mux] && lifecycles[server] != "" {
			result = append(result, model.RuntimeServer{
				Surface: "metrics", Protocol: "HTTP", Lifecycle: lifecycles[server],
				Source: runtimeCallSource(file, function, server, lifecycles[server]),
			})
		}
	}
	return result
}

func expressionContainsPrometheusHandler(file sourceFile, expression ast.Expr) bool {
	found := false
	ast.Inspect(expression, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok {
			return true
		}
		path, name, imported := importedCall(file, call)
		if imported && path == promHTTPPackage && (name == "Handler" || name == "HandlerFor") {
			found = true
			return false
		}
		return true
	})
	return found
}

func expressionCallsFunction(expression ast.Expr, name string) bool {
	found := false
	ast.Inspect(expression, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if ok && calledFunctionName(call.Fun) == name {
			found = true
			return false
		}
		return true
	})
	return found
}

func runtimeCallSource(file sourceFile, function *ast.FuncDecl, receiver, method string) string {
	source := ""
	ast.Inspect(function.Body, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok {
			return true
		}
		selector, ok := call.Fun.(*ast.SelectorExpr)
		if !ok {
			return true
		}
		identifier, identifierOK := selector.X.(*ast.Ident)
		if identifierOK && identifier.Name == receiver && selector.Sel.Name == method {
			source = sourceAt(file, call.Pos())
			return false
		}
		return true
	})
	return source
}

func dedupeRuntimeServers(servers []model.RuntimeServer) []model.RuntimeServer {
	sort.Slice(servers, func(i, j int) bool {
		if servers[i].Surface != servers[j].Surface {
			return servers[i].Surface < servers[j].Surface
		}
		return servers[i].Source < servers[j].Source
	})
	seen := map[string]bool{}
	result := make([]model.RuntimeServer, 0, len(servers))
	for _, server := range servers {
		key := strings.ToLower(server.Surface) + "\x00" + strings.ToLower(server.Protocol)
		if server.Source != "" && !seen[key] {
			seen[key] = true
			result = append(result, server)
		}
	}
	return result
}

// preferStandaloneGRPCServices keeps the registration attached to a proven
// dedicated listener when the same protobuf service is also conditionally hosted
// on another gRPC server. The source correlation avoids merging different
// transport policies into one misleading row.
func preferStandaloneGRPCServices(services []model.GRPCService, servers []model.RuntimeServer) []model.GRPCService {
	standaloneHealthSources := map[string]bool{}
	for _, server := range servers {
		if strings.EqualFold(server.Surface, "health") && strings.EqualFold(server.Protocol, "gRPC") && server.Source != "" {
			standaloneHealthSources[server.Source] = true
		}
	}
	if len(standaloneHealthSources) == 0 {
		return services
	}
	hasMatchingRegistration := false
	for _, service := range services {
		if service.Service == "Health" && standaloneHealthSources[service.Source] {
			hasMatchingRegistration = true
			break
		}
	}
	if !hasMatchingRegistration {
		return services
	}
	result := make([]model.GRPCService, 0, len(services))
	for _, service := range services {
		if service.Service != "Health" || standaloneHealthSources[service.Source] {
			result = append(result, service)
		}
	}
	return result
}
