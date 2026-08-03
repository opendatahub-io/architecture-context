package gosource

import (
	"go/ast"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func extractK8sClientAuthentication(file sourceFile) []model.AuthenticationFact {
	var result []model.AuthenticationFact
	result = append(result, extractInClusterServiceAccountAuth(file)...)
	result = append(result, extractKubeconfigAuth(file)...)
	result = append(result, extractTokenReviewAuth(file)...)
	return result
}

func extractInClusterServiceAccountAuth(file sourceFile) []model.AuthenticationFact {
	if !importsPackage(file, "k8s.io/client-go/rest") {
		return nil
	}
	hasClientConstructor := importsPackage(file, "k8s.io/client-go/kubernetes") ||
		importsPackage(file, "k8s.io/client-go/dynamic")
	if !hasClientConstructor {
		return nil
	}
	var result []model.AuthenticationFact
	for _, declaration := range file.file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Body == nil {
			continue
		}
		hasInCluster := false
		ast.Inspect(function.Body, func(node ast.Node) bool {
			call, ok := node.(*ast.CallExpr)
			if !ok {
				return true
			}
			path, name, imported := importedCall(file, call)
			if imported && path == "k8s.io/client-go/rest" && name == "InClusterConfig" {
				hasInCluster = true
				return false
			}
			return true
		})
		if !hasInCluster {
			continue
		}
		hasNewForConfig := false
		ast.Inspect(function.Body, func(node ast.Node) bool {
			call, ok := node.(*ast.CallExpr)
			if !ok {
				return true
			}
			path, name, imported := importedCall(file, call)
			if !imported {
				return true
			}
			if (path == "k8s.io/client-go/kubernetes" || path == "k8s.io/client-go/dynamic") &&
				(name == "NewForConfig" || name == "NewForConfigOrDie" || name == "NewForConfigAndClient") {
				hasNewForConfig = true
				return false
			}
			return true
		})
		if hasNewForConfig {
			result = append(result, model.AuthenticationFact{
				Endpoint: "Kubernetes API", Methods: "REST",
				Mechanism:        "ServiceAccount token (in-cluster)",
				EnforcementPoint: "kube-apiserver",
				Policy:           "In-cluster configuration provides automatic ServiceAccount token authentication",
				Source:           sourceAt(file, function.Pos()),
			})
		}
	}
	return result
}

func extractKubeconfigAuth(file sourceFile) []model.AuthenticationFact {
	hasClientcmd := importsPackage(file, "k8s.io/client-go/tools/clientcmd")
	if !hasClientcmd {
		return nil
	}
	hasClientConstructor := importsPackage(file, "k8s.io/client-go/kubernetes") ||
		importsPackage(file, "k8s.io/client-go/dynamic")
	if !hasClientConstructor {
		return nil
	}
	var result []model.AuthenticationFact
	for _, declaration := range file.file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Body == nil {
			continue
		}
		hasKubeconfig := false
		ast.Inspect(function.Body, func(node ast.Node) bool {
			call, ok := node.(*ast.CallExpr)
			if !ok {
				return true
			}
			path, name, imported := importedCall(file, call)
			if imported && path == "k8s.io/client-go/tools/clientcmd" &&
				(name == "BuildConfigFromFlags" || name == "NewNonInteractiveDeferredLoadingClientConfig") {
				hasKubeconfig = true
				return false
			}
			return true
		})
		if hasKubeconfig {
			result = append(result, model.AuthenticationFact{
				Endpoint: "Kubernetes API", Methods: "REST",
				Mechanism:        "kubeconfig credential chain",
				EnforcementPoint: "kube-apiserver",
				Policy:           "Kubeconfig-based authentication using user-provided credentials",
				Source:           sourceAt(file, function.Pos()),
			})
		}
	}
	return result
}

func extractTokenReviewAuth(file sourceFile) []model.AuthenticationFact {
	if !importsPackage(file, "k8s.io/api/authentication/v1") {
		return nil
	}
	var result []model.AuthenticationFact
	for _, declaration := range file.file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Body == nil {
			continue
		}
		hasTokenReviewConstruction := false
		hasTokenReviewCall := false
		ast.Inspect(function.Body, func(node ast.Node) bool {
			literal, ok := node.(*ast.CompositeLit)
			if ok && isImportedType(file, literal.Type, "k8s.io/api/authentication/v1", "TokenReview") {
				hasTokenReviewConstruction = true
			}
			call, ok := node.(*ast.CallExpr)
			if !ok {
				return true
			}
			selector, ok := call.Fun.(*ast.SelectorExpr)
			if !ok {
				return true
			}
			if selector.Sel.Name == "Create" {
				inner, ok := selector.X.(*ast.CallExpr)
				if ok {
					innerSelector, ok := inner.Fun.(*ast.SelectorExpr)
					if ok && innerSelector.Sel.Name == "TokenReviews" {
						hasTokenReviewCall = true
					}
				}
			}
			return true
		})
		if hasTokenReviewConstruction && hasTokenReviewCall {
			result = append(result, model.AuthenticationFact{
				Endpoint: "Token validation", Methods: "Kubernetes TokenReview API",
				Mechanism:        "Kubernetes TokenReview API",
				EnforcementPoint: "Application-level token validation via kube-apiserver",
				Policy:           "Validates bearer tokens against Kubernetes TokenReview API",
				Source:           sourceAt(file, function.Pos()),
			})
		}
	}
	return result
}
