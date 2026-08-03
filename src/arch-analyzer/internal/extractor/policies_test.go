package extractor

import (
	"testing"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func TestCollectResolvedKuadrantAuthPolicy(t *testing.T) {
	item := object{source: "policy.yaml", data: map[string]any{
		"apiVersion": "kuadrant.io/v1", "kind": "AuthPolicy",
		"metadata": map[string]any{"name": "gateway-auth"},
		"spec": map[string]any{
			"targetRef": map[string]any{"kind": "Gateway", "name": "main"},
			"defaults": map[string]any{
				"when": []any{map[string]any{"predicate": `request.path != "/health" || request.method != "GET"`}},
				"rules": map[string]any{
					"authentication": map[string]any{
						"api-keys": map[string]any{"plain": map[string]any{}},
						"cluster":  map[string]any{"kubernetesTokenReview": map[string]any{}},
						"oidc":     map[string]any{"jwt": map[string]any{}},
					},
					"authorization": map[string]any{"allowed": map[string]any{}},
				},
			},
		},
	}}
	input := model.Input{}
	collect([]object{item}, &input)
	if len(input.AccessPolicies) != 1 {
		t.Fatalf("access policies = %#v, want one resolved AuthPolicy", input.AccessPolicies)
	}
	policy := input.AccessPolicies[0]
	if policy.TargetKind != "Gateway" || policy.TargetName != "main" || len(policy.Authentication) != 3 ||
		len(policy.Authorization) != 1 || len(policy.Exclusions) != 1 {
		t.Errorf("policy = %#v, want normalized target, mechanisms, authorization, and exclusion", policy)
	}
}
