package gosource

import (
	"go/ast"
	"go/token"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

const (
	configFlagsPackage = "k8s.io/cli-runtime/pkg/genericclioptions"
	restPackage        = "k8s.io/client-go/rest"
	typedClientPackage = "k8s.io/client-go/kubernetes"
	authorizationAPI   = "k8s.io/api/authorization/v1"
	olmClientPackage   = "github.com/operator-framework/operator-lifecycle-manager/pkg/api/client/clientset/versioned"
)

type cliRuntimeProvider struct {
	key    runtimeFunctionKey
	source string
}

type cliClientProvider struct {
	key              runtimeFunctionKey
	olmSource        string
	kubernetesSource string
}

type cliRuntimeBridge struct {
	key     runtimeFunctionKey
	clients cliClientProvider
}

type cliRuntimeOperation struct {
	key    runtimeFunctionKey
	source string
}

// extractCLIKubernetesRuntimeBoundaries recognizes a closed client-go CLI
// lifecycle. A module or constructor alone is insufficient: a shipped entrypoint
// must reach a returned ConfigFlags REST config, pass it to a wrapper that returns
// concrete Kubernetes and OLM clients, and reach the corresponding API operation.
func extractCLIKubernetesRuntimeBoundaries(files []sourceFile) ([]model.RuntimeClient, []model.AuthenticationFact) {
	graph := buildProductRuntimeCallGraph(files)
	declarations := cliRuntimeDeclarations(files)
	graph = expandCLIRegisteredRuntimeMethods(graph, declarations)
	configProviders := cliRESTConfigProviders(graph, declarations)
	clientProviders := cliClientsetProviders(graph, declarations)
	bridges := cliRuntimeBridges(graph, declarations, configProviders, clientProviders)
	if len(bridges) == 0 {
		return nil, nil
	}

	olmReads := cliOLMReadOperations(graph, declarations)
	reviews := cliSelfSubjectAccessReviewOperations(graph, declarations)
	var clients []model.RuntimeClient
	var authentication []model.AuthenticationFact
	for _, bridge := range bridges {
		for _, operation := range olmReads {
			if !sameRuntimeLifecycle(graph, bridge.key, operation.key) {
				continue
			}
			clients = append(clients, model.RuntimeClient{
				Target:        "Operator Lifecycle Manager (OLM)",
				Client:        "OLM API and typed client",
				Configuration: "kubeconfig-derived REST configuration with runtime Subscription and ClusterServiceVersion reads",
				Source:        bridge.clients.olmSource,
			})
			break
		}
		for _, operation := range reviews {
			if !sameRuntimeLifecycle(graph, bridge.key, operation.key) {
				continue
			}
			clients = append(clients, model.RuntimeClient{
				Target:        "Kubernetes API",
				Client:        "client-go typed clientset",
				Configuration: "kubeconfig credential chain with runtime SelfSubjectAccessReview preflight",
				Source:        bridge.clients.kubernetesSource,
			})
			authentication = append(authentication, model.AuthenticationFact{
				Endpoint:         "Kubernetes API (6443/TCP)",
				Methods:          "kubeconfig credential chain (bearer token, client certificate, OIDC)",
				Mechanism:        "k8s.io/client-go transport credentials",
				EnforcementPoint: "kube-apiserver",
				Policy:           "RBAC pre-flight via SelfSubjectAccessReview before privileged operations",
				Source:           operation.source,
			})
			break
		}
	}
	return clients, authentication
}

func expandCLIRegisteredRuntimeMethods(
	graph runtimeCallGraph,
	declarations map[runtimeFunctionKey]struct {
		file     sourceFile
		function *ast.FuncDecl
	},
) runtimeCallGraph {
	for {
		registered := map[runtimeReceiverRef]map[runtimeFunctionKey]bool{}
		for key, declaration := range declarations {
			if !graph.reachable[key] {
				continue
			}
			ast.Inspect(declaration.function.Body, func(node ast.Node) bool {
				call, ok := node.(*ast.CallExpr)
				if !ok {
					return true
				}
				selector, ok := call.Fun.(*ast.SelectorExpr)
				if !ok || (selector.Sel.Name != "Register" && selector.Sel.Name != "MustRegister") {
					return true
				}
				for _, argument := range call.Args {
					typeName := expressionType(argument, nil, declaration.file)
					if typeName.name != "" {
						receiver := runtimeReceiverRef{packagePath: typeName.packagePath, receiver: typeName.name}
						if registered[receiver] == nil {
							registered[receiver] = map[runtimeFunctionKey]bool{}
						}
						registered[receiver][key] = true
					}
				}
				return true
			})
		}
		var roots []runtimeFunctionKey
		for key := range declarations {
			registrars := registered[runtimeReceiverRef{packagePath: key.packagePath, receiver: key.receiver}]
			if key.receiver == "" || len(registrars) == 0 {
				continue
			}
			for registrar := range registrars {
				if graph.edges[registrar] == nil {
					graph.edges[registrar] = map[runtimeFunctionKey]bool{}
				}
				graph.edges[registrar][key] = true
			}
			if !graph.reachable[key] {
				roots = append(roots, key)
			}
		}
		if len(roots) == 0 {
			return graph
		}
		graph = graph.withAdditionalRoots(roots)
	}
}

func cliRuntimeDeclarations(files []sourceFile) map[runtimeFunctionKey]struct {
	file     sourceFile
	function *ast.FuncDecl
} {
	result := map[runtimeFunctionKey]struct {
		file     sourceFile
		function *ast.FuncDecl
	}{}
	duplicates := map[runtimeFunctionKey]bool{}
	for _, file := range files {
		for _, declaration := range file.file.Decls {
			function, ok := declaration.(*ast.FuncDecl)
			if !ok || function.Body == nil {
				continue
			}
			key := runtimeFunction(file, function)
			if duplicates[key] {
				continue
			}
			if _, duplicate := result[key]; duplicate {
				delete(result, key)
				duplicates[key] = true
				continue
			}
			result[key] = struct {
				file     sourceFile
				function *ast.FuncDecl
			}{file: file, function: function}
		}
	}
	return result
}

func cliRESTConfigProviders(
	graph runtimeCallGraph,
	declarations map[runtimeFunctionKey]struct {
		file     sourceFile
		function *ast.FuncDecl
	},
) map[runtimeFunctionKey]cliRuntimeProvider {
	result := map[runtimeFunctionKey]cliRuntimeProvider{}
	for key, declaration := range declarations {
		if !graph.reachable[key] {
			continue
		}
		variables := functionVariables(declaration.function, declaration.file)
		returned := returnedIdentifiers(declaration.function)
		ast.Inspect(declaration.function.Body, func(node ast.Node) bool {
			assignment, ok := node.(*ast.AssignStmt)
			if !ok || len(assignment.Rhs) == 0 || len(assignment.Lhs) == 0 {
				return true
			}
			call, ok := assignment.Rhs[0].(*ast.CallExpr)
			if !ok || !isConfigFlagsToRESTConfig(declaration.file, variables, call) {
				return true
			}
			name, ok := assignment.Lhs[0].(*ast.Ident)
			if !ok || !returned[name.Name] {
				return true
			}
			result[key] = cliRuntimeProvider{key: key, source: sourceAt(declaration.file, call.Fun.Pos())}
			return true
		})
	}
	return result
}

func isConfigFlagsToRESTConfig(file sourceFile, variables map[string]goType, call *ast.CallExpr) bool {
	selector, ok := call.Fun.(*ast.SelectorExpr)
	if !ok || selector.Sel.Name != "ToRESTConfig" {
		return false
	}
	receiver, ok := selector.X.(*ast.Ident)
	if !ok {
		return false
	}
	return variables[receiver.Name] == (goType{packagePath: configFlagsPackage, name: "ConfigFlags"})
}

func cliClientsetProviders(
	graph runtimeCallGraph,
	declarations map[runtimeFunctionKey]struct {
		file     sourceFile
		function *ast.FuncDecl
	},
) map[runtimeFunctionKey]cliClientProvider {
	result := map[runtimeFunctionKey]cliClientProvider{}
	for key, declaration := range declarations {
		if !graph.reachable[key] {
			continue
		}
		variables := functionVariables(declaration.function, declaration.file)
		returned := returnedIdentifiers(declaration.function)
		type construction struct {
			variable string
			source   string
		}
		olmByConfig := map[string]construction{}
		kubeByConfig := map[string]construction{}
		ast.Inspect(declaration.function.Body, func(node ast.Node) bool {
			assignment, ok := node.(*ast.AssignStmt)
			if !ok || len(assignment.Rhs) == 0 || len(assignment.Lhs) == 0 {
				return true
			}
			call, ok := assignment.Rhs[0].(*ast.CallExpr)
			if !ok || len(call.Args) == 0 {
				return true
			}
			path, name, imported := importedCall(declaration.file, call)
			config, configOK := call.Args[0].(*ast.Ident)
			client, clientOK := assignment.Lhs[0].(*ast.Ident)
			if !imported || name != "NewForConfig" || !configOK || !clientOK ||
				variables[config.Name] != (goType{packagePath: restPackage, name: "Config"}) {
				return true
			}
			created := construction{variable: client.Name, source: sourceAt(declaration.file, call.Fun.Pos())}
			switch path {
			case olmClientPackage:
				olmByConfig[config.Name] = created
			case typedClientPackage:
				kubeByConfig[config.Name] = created
			}
			return true
		})
		for config, olm := range olmByConfig {
			kube, ok := kubeByConfig[config]
			if !ok || !returned[olm.variable] || !returned[kube.variable] {
				continue
			}
			result[key] = cliClientProvider{key: key, olmSource: olm.source, kubernetesSource: kube.source}
			break
		}
	}
	return result
}

func returnedIdentifiers(function *ast.FuncDecl) map[string]bool {
	result := map[string]bool{}
	ast.Inspect(function.Body, func(node ast.Node) bool {
		statement, ok := node.(*ast.ReturnStmt)
		if !ok {
			return true
		}
		for _, expression := range statement.Results {
			ast.Inspect(expression, func(child ast.Node) bool {
				if identifier, ok := child.(*ast.Ident); ok {
					result[identifier.Name] = true
				}
				return true
			})
		}
		return true
	})
	return result
}

func cliRuntimeBridges(
	graph runtimeCallGraph,
	declarations map[runtimeFunctionKey]struct {
		file     sourceFile
		function *ast.FuncDecl
	},
	configs map[runtimeFunctionKey]cliRuntimeProvider,
	clients map[runtimeFunctionKey]cliClientProvider,
) []cliRuntimeBridge {
	var result []cliRuntimeBridge
	for key, declaration := range declarations {
		if !graph.reachable[key] {
			continue
		}
		type configuredValue struct {
			provider runtimeFunctionKey
			position token.Pos
		}
		configured := map[string]configuredValue{}
		ast.Inspect(declaration.function.Body, func(node ast.Node) bool {
			assignment, ok := node.(*ast.AssignStmt)
			if !ok || len(assignment.Rhs) == 0 || len(assignment.Lhs) == 0 {
				return true
			}
			call, ok := assignment.Rhs[0].(*ast.CallExpr)
			if !ok {
				return true
			}
			provider := cliFunctionCallTarget(declaration.file, call)
			if _, ok := configs[provider]; !ok {
				return true
			}
			identifier, ok := assignment.Lhs[0].(*ast.Ident)
			if ok {
				configured[identifier.Name] = configuredValue{provider: provider, position: call.Pos()}
			}
			return true
		})
		ast.Inspect(declaration.function.Body, func(node ast.Node) bool {
			call, ok := node.(*ast.CallExpr)
			if !ok || len(call.Args) == 0 {
				return true
			}
			providerKey := cliFunctionCallTarget(declaration.file, call)
			provider, ok := clients[providerKey]
			if !ok {
				return true
			}
			argument, ok := call.Args[0].(*ast.Ident)
			value, configuredOK := configured[argument.Name]
			if ok && configuredOK && value.position < call.Pos() {
				result = append(result, cliRuntimeBridge{key: key, clients: provider})
			}
			return true
		})
	}
	return result
}

func cliFunctionCallTarget(file sourceFile, call *ast.CallExpr) runtimeFunctionKey {
	if path, name, imported := importedCall(file, call); imported {
		return runtimeFunctionKey{packagePath: path, name: name}
	}
	if identifier, ok := call.Fun.(*ast.Ident); ok {
		return runtimeFunctionKey{packagePath: packagePath(file), name: identifier.Name}
	}
	return runtimeFunctionKey{}
}

func cliOLMReadOperations(
	graph runtimeCallGraph,
	declarations map[runtimeFunctionKey]struct {
		file     sourceFile
		function *ast.FuncDecl
	},
) []cliRuntimeOperation {
	var result []cliRuntimeOperation
	for key, declaration := range declarations {
		if !graph.reachable[key] || !importsWithPrefix(declaration.file, "github.com/operator-framework/api/pkg/operators/") {
			continue
		}
		ast.Inspect(declaration.function.Body, func(node ast.Node) bool {
			call, ok := node.(*ast.CallExpr)
			if !ok {
				return true
			}
			selector, ok := call.Fun.(*ast.SelectorExpr)
			if !ok || (selector.Sel.Name != "Get" && selector.Sel.Name != "List") ||
				(!cliExpressionCallsMethod(selector.X, "Subscriptions") && !cliExpressionCallsMethod(selector.X, "ClusterServiceVersions")) {
				return true
			}
			result = append(result, cliRuntimeOperation{key: key, source: sourceAt(declaration.file, selector.Sel.Pos())})
			return true
		})
	}
	return result
}

func cliSelfSubjectAccessReviewOperations(
	graph runtimeCallGraph,
	declarations map[runtimeFunctionKey]struct {
		file     sourceFile
		function *ast.FuncDecl
	},
) []cliRuntimeOperation {
	var result []cliRuntimeOperation
	wantType := goType{packagePath: authorizationAPI, name: "SelfSubjectAccessReview"}
	for key, declaration := range declarations {
		if !graph.reachable[key] {
			continue
		}
		variables := functionVariables(declaration.function, declaration.file)
		ast.Inspect(declaration.function.Body, func(node ast.Node) bool {
			call, ok := node.(*ast.CallExpr)
			if !ok {
				return true
			}
			selector, ok := call.Fun.(*ast.SelectorExpr)
			if !ok || selector.Sel.Name != "Create" || !cliExpressionCallsMethod(selector.X, "SelfSubjectAccessReviews") {
				return true
			}
			for _, argument := range call.Args {
				if expressionType(argument, variables, declaration.file) == wantType {
					result = append(result, cliRuntimeOperation{key: key, source: sourceAt(declaration.file, selector.Sel.Pos())})
					break
				}
			}
			return true
		})
	}
	return result
}

func importsWithPrefix(file sourceFile, prefix string) bool {
	for _, path := range file.imports {
		if strings.HasPrefix(path, prefix) {
			return true
		}
	}
	return false
}

func cliExpressionCallsMethod(expression ast.Expr, method string) bool {
	found := false
	ast.Inspect(expression, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok {
			return true
		}
		selector, ok := call.Fun.(*ast.SelectorExpr)
		if ok && selector.Sel.Name == method {
			found = true
			return false
		}
		return true
	})
	return found
}

func sameRuntimeLifecycle(graph runtimeCallGraph, left, right runtimeFunctionKey) bool {
	leftAncestors := graph.reachableAncestors(left)
	for ancestor := range graph.reachableAncestors(right) {
		if leftAncestors[ancestor] {
			return true
		}
	}
	return false
}
