package gosource

import (
	"go/ast"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

const controllerRuntimePackage = "sigs.k8s.io/controller-runtime"

var kubernetesClientPackages = map[string]string{
	"k8s.io/client-go/discovery":  "client-go discovery client",
	"k8s.io/client-go/dynamic":    "client-go dynamic client",
	"k8s.io/client-go/kubernetes": "client-go typed clientset",
}

func extractRuntimeClients(file sourceFile) []model.RuntimeClient {
	var result []model.RuntimeClient
	for _, declaration := range file.file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if ok && function.Body != nil {
			result = append(result, functionPrometheusClients(function, file)...)
		}
	}
	ast.Inspect(file.file, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok {
			return true
		}
		path, function, ok := importedCall(file, call)
		if !ok {
			return true
		}

		client := ""
		switch {
		case path == controllerRuntimePackage && function == "NewManager" && managerUsesRuntimeConfig(file, call):
			client = "controller-runtime manager"
		case kubernetesClientPackages[path] != "" && kubernetesClientConstructor(path, function):
			client = kubernetesClientPackages[path]
		}
		if client != "" {
			result = append(result, model.RuntimeClient{
				Target: "Kubernetes API", Client: client,
				Configuration: "runtime Kubernetes configuration",
				Source:        sourceAt(file, call.Fun.Pos()),
			})
		}
		return true
	})
	return result
}

func functionPrometheusClients(function *ast.FuncDecl, file sourceFile) []model.RuntimeClient {
	type construction struct {
		name   string
		source string
	}
	clients := map[string]construction{}
	apis := map[string]construction{}
	ast.Inspect(function.Body, func(node ast.Node) bool {
		assignment, ok := node.(*ast.AssignStmt)
		if !ok {
			return true
		}
		for index, right := range assignment.Rhs {
			call, ok := right.(*ast.CallExpr)
			if !ok || index >= len(assignment.Lhs) {
				continue
			}
			left, ok := assignment.Lhs[index].(*ast.Ident)
			if !ok {
				continue
			}
			path, functionName, imported := importedCall(file, call)
			switch {
			case imported && path == "github.com/prometheus/client_golang/api" && functionName == "NewClient" && len(call.Args) == 1:
				clients[left.Name] = construction{name: left.Name, source: sourceAt(file, call.Fun.Pos())}
			case imported && path == "github.com/prometheus/client_golang/api/prometheus/v1" && functionName == "NewAPI" && len(call.Args) == 1:
				client, ok := call.Args[0].(*ast.Ident)
				if ok {
					if created, exists := clients[client.Name]; exists {
						apis[left.Name] = created
					}
				}
			}
		}
		return true
	})
	if len(apis) == 0 {
		return nil
	}
	used := map[string]bool{}
	ast.Inspect(function.Body, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok {
			return true
		}
		if path, functionName, imported := importedCall(file, call); imported &&
			path == "github.com/prometheus/client_golang/api/prometheus/v1" && functionName == "NewAPI" {
			return true
		}
		for _, argument := range call.Args {
			identifier, ok := argument.(*ast.Ident)
			if ok && apis[identifier.Name].name != "" {
				used[identifier.Name] = true
			}
		}
		return true
	})
	var result []model.RuntimeClient
	for apiName, construction := range apis {
		if !used[apiName] {
			continue
		}
		result = append(result, model.RuntimeClient{
			Target: "Prometheus", Client: "Prometheus HTTP API client",
			Configuration: "constructed client configuration and runtime API use",
			Source:        construction.source,
		})
	}
	return result
}

func kubernetesClientConstructor(path, function string) bool {
	if path == "k8s.io/client-go/discovery" {
		return function == "NewDiscoveryClientForConfigOrDie" || function == "NewDiscoveryClientForConfig"
	}
	return function == "NewForConfigOrDie" || function == "NewForConfig"
}

func managerUsesRuntimeConfig(file sourceFile, call *ast.CallExpr) bool {
	if len(call.Args) == 0 {
		return false
	}
	configCall, ok := call.Args[0].(*ast.CallExpr)
	if !ok {
		return false
	}
	path, function, ok := importedCall(file, configCall)
	return ok && path == controllerRuntimePackage && function == "GetConfigOrDie"
}

func importedCall(file sourceFile, call *ast.CallExpr) (string, string, bool) {
	selector, ok := call.Fun.(*ast.SelectorExpr)
	if !ok {
		return "", "", false
	}
	identifier, ok := selector.X.(*ast.Ident)
	if !ok {
		return "", "", false
	}
	path := file.imports[identifier.Name]
	return path, selector.Sel.Name, path != ""
}

func dedupeRuntimeClients(clients []model.RuntimeClient) []model.RuntimeClient {
	seen := make(map[string]bool, len(clients))
	result := make([]model.RuntimeClient, 0, len(clients))
	for _, client := range clients {
		key := strings.ToLower(client.Target) + "\x00" + strings.ToLower(client.Client) + "\x00" + client.Source
		if !seen[key] {
			seen[key] = true
			result = append(result, client)
		}
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].Target+result[i].Client+result[i].Source < result[j].Target+result[j].Client+result[j].Source
	})
	return result
}
