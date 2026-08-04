package gosource

import "testing"

func TestExtractControllerCreatedGatewayAuthPolicy(t *testing.T) {
	root := writeSecurityRepository(t, `package main

import (
	"context"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime/schema"
)

type creator interface { Create(context.Context, any) error }

func buildPolicy() map[string]any {
	authentication := map[string]any{
		"api-keys": map[string]any{"plain": map[string]any{}},
		"cluster": map[string]any{"kubernetesTokenReview": map[string]any{}},
	}
	if optionalOIDC() {
		authentication["oidc"] = map[string]any{"jwt": map[string]any{}}
	}
	return map[string]any{
		"targetRef": map[string]any{"kind": "Gateway"},
		"defaults": map[string]any{
			"when": []any{map[string]any{"predicate": "request.path != \"/health\" || request.method != \"GET\""}},
			"rules": map[string]any{"authentication": authentication, "authorization": map[string]any{}},
		},
	}
}

func reconcile(ctx context.Context, client creator) error {
	policy := &unstructured.Unstructured{}
	policy.SetGroupVersionKind(schema.GroupVersionKind{Group: "kuadrant.io", Version: "v1", Kind: "AuthPolicy"})
	return client.Create(ctx, policy)
}
`)

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.AccessPolicies) != 1 {
		t.Fatalf("access policies = %#v, want one created Gateway AuthPolicy", result.AccessPolicies)
	}
	policy := result.AccessPolicies[0]
	if policy.TargetKind != "Gateway" || len(policy.Authentication) != 3 || len(policy.Exclusions) != 1 || policy.Source == "" {
		t.Errorf("policy = %#v, want source-backed mechanisms and health exclusion", policy)
	}
}

func TestConstructedAccessPolicyRequiresCreationAndPolicyContract(t *testing.T) {
	tests := []struct {
		name   string
		source string
	}{
		{
			name: "builder without created resource",
			source: `package main
func build() map[string]any {
	return map[string]any{"targetRef": map[string]any{"kind": "Gateway"}, "authentication": map[string]any{"cluster": map[string]any{"kubernetesTokenReview": map[string]any{}}}}
}`,
		},
		{
			name: "created resource without policy contract",
			source: `package main
import (
	"context"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime/schema"
)
type creator interface { Create(context.Context, any) error }
func reconcile(ctx context.Context, client creator) error {
	policy := &unstructured.Unstructured{}
	policy.SetGroupVersionKind(schema.GroupVersionKind{Group: "kuadrant.io", Version: "v1", Kind: "AuthPolicy"})
	return client.Create(ctx, policy)
}`,
		},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			root := writeSecurityRepository(t, test.source)
			result, err := Extract(root)
			if err != nil {
				t.Fatal(err)
			}
			if len(result.AccessPolicies) != 0 {
				t.Fatalf("access policies = %#v, want incomplete contract rejected", result.AccessPolicies)
			}
		})
	}
}
