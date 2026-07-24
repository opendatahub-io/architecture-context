package gosource

import (
	"go/ast"
	"go/token"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

var sourcePolicyExclusionPattern = regexp.MustCompile(`request\.path\s*!=\s*["']([^"']+)["']\s*\|\|\s*request\.method\s*!=\s*["']([^"']+)["']`)

func extractConstructedAccessPolicies(file sourceFile) []model.AccessPolicy {
	if !importsPackage(file, "k8s.io/apimachinery/pkg/apis/meta/v1/unstructured") ||
		!importsPackage(file, "k8s.io/apimachinery/pkg/runtime/schema") {
		return nil
	}
	if !createsKuadrantAuthPolicy(file) {
		return nil
	}
	var result []model.AccessPolicy
	for _, declaration := range file.file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Body == nil {
			continue
		}
		literals, positions := functionStringLiterals(function)
		if !literals["targetRef"] || !literals["Gateway"] || !literals["authentication"] ||
			!literals["kubernetesTokenReview"] {
			continue
		}
		mechanisms := []string{"Kubernetes TokenReview"}
		if literals["api-keys"] {
			mechanisms = append(mechanisms, "API key")
		}
		if literals["jwt"] {
			mechanisms = append(mechanisms, "OIDC JWT (optional)")
		}
		sort.Strings(mechanisms)
		policy := model.AccessPolicy{
			Name: "controller-created Gateway AuthPolicy", Kind: "Kuadrant AuthPolicy",
			TargetKind: "Gateway", Authentication: mechanisms,
			Source: sourceAt(file, positions["authentication"]),
		}
		if literals["authorization"] {
			policy.Authorization = []string{"policy-defined authorization rules"}
		}
		for literal := range literals {
			matches := sourcePolicyExclusionPattern.FindStringSubmatch(literal)
			if len(matches) == 3 {
				policy.Exclusions = append(policy.Exclusions, model.PolicyExclusion{
					Path: matches[1], Methods: strings.ToUpper(matches[2]),
				})
			}
		}
		result = append(result, policy)
	}
	return result
}

func importsPackage(file sourceFile, packagePath string) bool {
	for _, imported := range file.imports {
		if imported == packagePath {
			return true
		}
	}
	return false
}

func createsKuadrantAuthPolicy(file sourceFile) bool {
	for _, declaration := range file.file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Body == nil {
			continue
		}
		values := functionStringValues(function)
		created := functionCreatedVariables(function)
		found := false
		ast.Inspect(function.Body, func(node ast.Node) bool {
			call, ok := node.(*ast.CallExpr)
			if !ok || len(call.Args) == 0 {
				return true
			}
			selector, ok := call.Fun.(*ast.SelectorExpr)
			if !ok || selector.Sel.Name != "SetGroupVersionKind" {
				return true
			}
			variable, ok := selector.X.(*ast.Ident)
			literal := compositeLiteral(call.Args[0])
			if !ok || literal == nil || !created[variable.Name] {
				return true
			}
			group := compositeStringField(literal, "Group", values)
			kind := compositeStringField(literal, "Kind", values)
			if group == "kuadrant.io" && kind == "AuthPolicy" {
				found = true
			}
			return true
		})
		if found {
			return true
		}
	}
	return false
}

func functionStringLiterals(function *ast.FuncDecl) (map[string]bool, map[string]token.Pos) {
	values := map[string]bool{}
	positions := map[string]token.Pos{}
	ast.Inspect(function.Body, func(node ast.Node) bool {
		literal, ok := node.(*ast.BasicLit)
		if !ok || literal.Kind != token.STRING {
			return true
		}
		value, err := strconv.Unquote(literal.Value)
		if err == nil {
			values[value] = true
			if positions[value] == token.NoPos {
				positions[value] = literal.Pos()
			}
		}
		return true
	})
	return values, positions
}

func dedupeAccessPolicies(policies []model.AccessPolicy) []model.AccessPolicy {
	seen := make(map[string]bool, len(policies))
	result := make([]model.AccessPolicy, 0, len(policies))
	for _, policy := range policies {
		key := strings.ToLower(policy.Kind) + "\x00" + strings.ToLower(policy.TargetKind) + "\x00" + policy.Source
		if !seen[key] {
			seen[key] = true
			result = append(result, policy)
		}
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].Kind+result[i].TargetKind+result[i].Source < result[j].Kind+result[j].TargetKind+result[j].Source
	})
	return result
}
