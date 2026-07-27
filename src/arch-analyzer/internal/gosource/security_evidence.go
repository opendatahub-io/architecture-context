package gosource

import (
	"go/ast"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

var tlsPackages = map[string]bool{
	"crypto/tls":                             true,
	"google.golang.org/grpc/credentials":     true,
	"google.golang.org/grpc/credentials/tls": true,
}

var rbacPackages = map[string]bool{
	"k8s.io/apiserver/pkg/authorization/authorizer":      true,
	"k8s.io/client-go/kubernetes/typed/authorization/v1": true,
	"k8s.io/client-go/kubernetes/typed/rbac/v1":          true,
}

var authMiddlewarePackages = map[string]bool{
	"k8s.io/apiserver/pkg/authentication":         true,
	"k8s.io/apiserver/pkg/authentication/request": true,
	"k8s.io/apiserver/pkg/endpoints/filters":      true,
}

func extractGoSecurityEvidence(files []sourceFile) []model.SecurityEvidence {
	var result []model.SecurityEvidence
	seen := map[string]bool{}

	for _, file := range files {
		for importAlias, importPath := range file.imports {
			_ = importAlias
			if tlsPackages[importPath] {
				key := "tls-config:" + file.path
				if !seen[key] {
					seen[key] = true
					result = append(result, model.SecurityEvidence{
						Kind:   "tls-config",
						Target: importPath,
						Detail: "TLS configuration import",
						Status: "literal",
						Source: file.path,
					})
				}
			}
			if rbacPackages[importPath] {
				key := "rbac-ref:" + file.path
				if !seen[key] {
					seen[key] = true
					result = append(result, model.SecurityEvidence{
						Kind:   "rbac-ref",
						Target: importPath,
						Detail: "RBAC/authorization API import",
						Status: "literal",
						Source: file.path,
					})
				}
			}
			if authMiddlewarePackages[importPath] {
				key := "auth-middleware:" + file.path
				if !seen[key] {
					seen[key] = true
					result = append(result, model.SecurityEvidence{
						Kind:   "auth-middleware",
						Target: importPath,
						Detail: "Authentication middleware import",
						Status: "literal",
						Source: file.path,
					})
				}
			}
		}

		ast.Inspect(file.file, func(node ast.Node) bool {
			call, ok := node.(*ast.CallExpr)
			if !ok {
				return true
			}
			selector, ok := call.Fun.(*ast.SelectorExpr)
			if !ok {
				return true
			}
			name := strings.ToLower(selector.Sel.Name)
			if strings.Contains(name, "tokenreview") || strings.Contains(name, "subjectaccessreview") {
				key := "rbac-ref:" + file.path + ":" + selector.Sel.Name
				if !seen[key] {
					seen[key] = true
					result = append(result, model.SecurityEvidence{
						Kind:   "rbac-ref",
						Target: selector.Sel.Name,
						Detail: "Token or subject access review call",
						Status: "literal",
						Source: sourceAt(file, selector.Sel.Pos()),
					})
				}
			}
			return true
		})
	}
	return result
}
