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
	seen := map[string]int{}
	add := func(evidence model.SecurityEvidence) {
		key := evidence.Kind + "\x00" + evidence.Target + "\x00" + evidence.Detail
		if index, ok := seen[key]; ok {
			result[index].Sources = appendUniqueSource(result[index].Sources, evidence.Source)
			return
		}
		evidence.Sources = appendUniqueSource(nil, evidence.Source)
		seen[key] = len(result)
		result = append(result, evidence)
	}

	for _, file := range files {
		for importAlias, importPath := range file.imports {
			_ = importAlias
			if tlsPackages[importPath] {
				add(model.SecurityEvidence{Kind: "tls-config", Target: importPath, Detail: "TLS configuration import", Status: "dependency-signal", Source: file.path})
			}
			if rbacPackages[importPath] {
				add(model.SecurityEvidence{Kind: "rbac-ref", Target: importPath, Detail: "RBAC/authorization API import", Status: "dependency-signal", Source: file.path})
			}
			if authMiddlewarePackages[importPath] {
				add(model.SecurityEvidence{Kind: "auth-middleware", Target: importPath, Detail: "Authentication middleware import", Status: "dependency-signal", Source: file.path})
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
				add(model.SecurityEvidence{Kind: "rbac-ref", Target: selector.Sel.Name, Detail: "Token or subject access review call", Status: "literal", Source: sourceAt(file, selector.Sel.Pos())})
			}
			return true
		})
	}
	return result
}

func appendUniqueSource(sources []string, source string) []string {
	if source == "" {
		return sources
	}
	for _, existing := range sources {
		if existing == source {
			return sources
		}
	}
	return append(sources, source)
}
