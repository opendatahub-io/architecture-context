package extractor

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func TestExtractResolvesKustomizeOverlay(t *testing.T) {
	input, err := Extract("testdata/repository", Options{Distribution: "rhoai.next"})
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	if input.Component != "repository" {
		t.Errorf("component = %q, want repository", input.Component)
	}
	if input.DataCoverage["kustomize"] != "complete" {
		t.Errorf("kustomize coverage = %q, want complete", input.DataCoverage["kustomize"])
	}
	if !strings.HasPrefix(input.DataCoverage["source"], "partial:") {
		t.Errorf("source coverage = %q, want explicit partial coverage", input.DataCoverage["source"])
	}
	if !strings.HasPrefix(input.DataCoverage["agent_baseline"], "sufficient:") {
		t.Errorf("agent baseline = %q, want sufficient", input.DataCoverage["agent_baseline"])
	}
	if input.Dependencies.GoVersion != "1.25.0" || len(input.Dependencies.GoModules) != 1 {
		t.Errorf("dependencies = %#v, want fixture go.mod", input.Dependencies)
	}
	if len(input.ControllerWatches) != 1 || input.ControllerWatches[0].GVK != "api/v1/Widget" {
		t.Errorf("watches = %#v, want Widget watch", input.ControllerWatches)
	}
	if len(input.HTTPEndpoints) != 1 || input.HTTPEndpoints[0].Path != "/v1/widgets" {
		t.Errorf("HTTP endpoints = %#v, want registered route", input.HTTPEndpoints)
	}
	if len(input.Deployments) != 1 || input.Deployments[0].Name != "rhoai-controller" {
		t.Fatalf("deployments = %#v, want one transformed deployment", input.Deployments)
	}
	if len(input.AccessPolicies) != 0 {
		t.Errorf("access policies = %#v, want unreferenced AuthPolicy YAML excluded", input.AccessPolicies)
	}
	if input.Deployments[0].Containers[0].ReadinessProbe == nil {
		t.Fatal("readiness probe was not extracted")
	}
	if len(input.Deployments[0].Containers[0].Args) != 2 ||
		input.Deployments[0].Containers[0].Args[0] != "--metrics-bind-address=:8443" {
		t.Errorf("container args = %#v, want resolved workload arguments", input.Deployments[0].Containers[0].Args)
	}
	if len(input.Services) != 1 {
		t.Fatalf("services = %d, want one merged service", len(input.Services))
	}
	service := input.Services[0]
	if service.Name != "rhoai-controller" || service.Ports[0].Port != 8443 {
		t.Errorf("service = %#v, want transformed service with patched port", service)
	}
	if service.TargetDeployment != "rhoai-controller" {
		t.Errorf("target deployment = %q, want rhoai-controller", service.TargetDeployment)
	}
	if !strings.HasPrefix(service.Source, "overlays/rhoai.next/service-patch.yaml:") {
		t.Errorf("service source = %q, want patch evidence", service.Source)
	}
	if len(input.CRDs) != 1 || input.CRDs[0].Version != "v1" || input.CRDs[0].Kind != "Widget" {
		t.Errorf("CRDs = %#v, want storage version Widget", input.CRDs)
	}
	if len(input.RBAC.ClusterRoles) != 1 || len(input.RBAC.ClusterRoleBindings) != 1 {
		t.Errorf("RBAC = %#v, want role and binding", input.RBAC)
	}
	if len(input.RBAC.ClusterRoles[0].Rules) != 2 {
		t.Errorf("role rules = %#v, want JSON6902 addition", input.RBAC.ClusterRoles[0].Rules)
	}
	if len(input.IngressRouting) != 1 || input.IngressRouting[0].Backend != "rhoai-controller" {
		t.Errorf("ingress = %#v, want HTTPRoute", input.IngressRouting)
	}
	if len(input.Webhooks) != 1 || input.Webhooks[0].Path != "/validate-example-io-v1-widget" {
		t.Errorf("webhooks = %#v, want validating webhook", input.Webhooks)
	}
	if input.Webhooks[0].ServiceRef != "rhoai-controller" {
		t.Errorf("webhook service = %q, want transformed reference", input.Webhooks[0].ServiceRef)
	}
	if input.RBAC.ClusterRoleBindings[0].RoleRef != "rhoai-manager" {
		t.Errorf("role reference = %q, want transformed reference", input.RBAC.ClusterRoleBindings[0].RoleRef)
	}
	if len(input.Secrets) != 2 {
		t.Fatalf("secrets = %#v, want env and volume references", input.Secrets)
	}
	for _, secret := range input.Secrets {
		if secret.Source == "" || len(secret.ReferencedBy) == 0 {
			t.Errorf("secret lacks evidence or reference: %#v", secret)
		}
	}
}

func TestAgentBaselineCoverageTiers(t *testing.T) {
	tests := []struct {
		name  string
		input model.Input
		want  string
	}{
		{name: "empty", input: model.Input{}, want: "insufficient:"},
		{name: "one fact", input: model.Input{SourceComponents: []model.SourceComponent{{Name: "cli"}}}, want: "partial:"},
		{name: "dependency-only package", input: model.Input{
			SourceComponents: []model.SourceComponent{{Name: "library"}},
			Dependencies: model.Dependencies{Packages: []model.LanguagePackage{
				{Name: "a"}, {Name: "b"}, {Name: "c"}, {Name: "d"}, {Name: "e"},
			}},
		}, want: "partial:"},
		{name: "package with runtime evidence", input: model.Input{
			SourceComponents: []model.SourceComponent{{Name: "service"}},
			HTTPEndpoints:    []model.HTTPEndpoint{{Path: "/readyz"}},
			Dependencies: model.Dependencies{Packages: []model.LanguagePackage{
				{Name: "a"}, {Name: "b"}, {Name: "c"}, {Name: "d"}, {Name: "e"},
			}},
		}, want: "sufficient:"},
		{name: "single runtime surface", input: model.Input{HTTPEndpoints: []model.HTTPEndpoint{
			{Path: "/one"}, {Path: "/two"}, {Path: "/three"},
		}}, want: "partial:"},
		{name: "invalid CRDs are not runtime facts", input: model.Input{
			CRDs: []model.CRD{
				{Source: "patch.yaml:1"},
				{Group: "example.io", Version: "v1", Kind: "Widget"},
			},
		}, want: "insufficient:"},
		{name: "multiple runtime surfaces", input: model.Input{
			HTTPEndpoints: []model.HTTPEndpoint{{Path: "/one"}, {Path: "/two"}},
			Services:      []model.Service{{Name: "api"}},
		}, want: "sufficient:"},
		{name: "protobuf declarations alone", input: model.Input{
			GRPCServices: []model.GRPCService{
				{Service: "example.API/One"},
				{Service: "example.API/Two"},
				{Service: "example.API/Three"},
			},
			SourceComponents: []model.SourceComponent{{Name: "client-library"}},
			Dependencies: model.Dependencies{Packages: []model.LanguagePackage{
				{Name: "grpc"}, {Name: "protobuf"}, {Name: "requests"}, {Name: "runtime"},
			}},
		}, want: "partial:"},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if got := agentBaselineCoverage(test.input); !strings.HasPrefix(got, test.want) {
				t.Errorf("agentBaselineCoverage() = %q, want prefix %q", got, test.want)
			}
		})
	}
}

func TestCollectCRDRejectsIncompletePatch(t *testing.T) {
	input := model.Input{}
	collectCRD(object{source: "patch.yaml", line: 2, data: map[string]any{
		"kind":     "CustomResourceDefinition",
		"metadata": map[string]any{"name": "widgets.example.io"},
	}}, &input)

	if len(input.CRDs) != 0 {
		t.Fatalf("CRDs = %#v, want incomplete patch ignored", input.CRDs)
	}
}

func TestCollectRoleRetainsAuthorizationMetadata(t *testing.T) {
	role := collectRole(object{source: "role.yaml", line: 2, data: map[string]any{
		"metadata": map[string]any{
			"name": "restricted",
			"labels": map[string]any{
				"rbac.authorization.k8s.io/aggregate-to-view": "true",
			},
		},
		"rules": []any{map[string]any{
			"apiGroups": []any{""}, "resources": []any{"secrets"},
			"resourceNames": []any{"named-secret"}, "verbs": []any{"get"},
		}},
	}})

	if role.Labels["rbac.authorization.k8s.io/aggregate-to-view"] != "true" {
		t.Fatalf("labels = %#v, want aggregation label", role.Labels)
	}
	if len(role.Rules) != 1 || len(role.Rules[0].ResourceNames) != 1 || role.Rules[0].ResourceNames[0] != "named-secret" {
		t.Fatalf("rules = %#v, want resourceNames restriction", role.Rules)
	}
}

func TestCollectCRDKeepsCompleteDefinition(t *testing.T) {
	input := model.Input{}
	collectCRD(object{source: "crd.yaml", line: 2, data: map[string]any{
		"kind": "CustomResourceDefinition",
		"spec": map[string]any{
			"group":    "example.io",
			"scope":    "Cluster",
			"names":    map[string]any{"kind": "Widget"},
			"versions": []any{map[string]any{"name": "v1", "storage": true}},
		},
	}}, &input)

	if len(input.CRDs) != 1 || input.CRDs[0].Kind != "Widget" {
		t.Fatalf("CRDs = %#v, want complete definition", input.CRDs)
	}
}

func TestCollectCRDMixedDefinitionsKeepOnlyCompleteFacts(t *testing.T) {
	input := model.Input{}
	items := []object{
		{source: "patch.yaml", line: 1, data: map[string]any{
			"kind":     "CustomResourceDefinition",
			"metadata": map[string]any{"name": "widgets.example.io"},
		}},
		{source: "crd.yaml", line: 1, data: map[string]any{
			"kind": "CustomResourceDefinition",
			"spec": map[string]any{
				"group": "example.io", "version": "v1", "scope": "Namespaced",
				"names": map[string]any{"kind": "Widget"},
			},
		}},
	}
	for _, item := range items {
		collectCRD(item, &input)
	}

	if len(input.CRDs) != 1 || input.CRDs[0].Source != "crd.yaml:1" {
		t.Fatalf("CRDs = %#v, want only complete definition", input.CRDs)
	}
}

func TestMergeCRDFactsPrefersManifestAndAddsSourceVersions(t *testing.T) {
	manifest := []model.CRD{{
		Group: "example.io", Version: "v2", Kind: "Widget", Scope: "Cluster", Source: "crd.yaml:1",
	}}
	source := []model.CRD{
		{Group: "example.io", Version: "v1", Kind: "Widget", Scope: "Cluster", Source: "api/v1/widget.go:10"},
		{Group: "example.io", Version: "v2", Kind: "Widget", Scope: "Cluster", Source: "api/v2/widget.go:10"},
		{Source: "patch.yaml:1"},
	}

	got := mergeCRDFacts(manifest, source)
	if len(got) != 2 {
		t.Fatalf("mergeCRDFacts() = %#v, want two valid versions", got)
	}
	if got[1].Version != "v2" || got[1].Source != "crd.yaml:1" {
		t.Errorf("v2 fact = %#v, want manifest evidence preferred", got[1])
	}
}

func TestCollectServiceRecordsOpenShiftServingCertificate(t *testing.T) {
	item := object{source: "service.yaml", line: 1, data: map[string]any{
		"kind": "Service",
		"metadata": map[string]any{
			"name": "dashboard",
			"annotations": map[string]any{
				"service.beta.openshift.io/serving-cert-secret-name": "dashboard-proxy-tls",
			},
		},
		"spec": map[string]any{},
	}}
	input := model.Input{}
	secrets := map[string]*model.Secret{}

	collectService(item, []object{item}, &input, secrets)

	secret := secrets["dashboard-proxy-tls"]
	if secret == nil || secret.Type != "kubernetes.io/tls" || secret.ProvisionedBy != "OpenShift service-ca operator" {
		t.Fatalf("serving certificate = %#v", secret)
	}
	if len(secret.ReferencedBy) != 1 || secret.ReferencedBy[0] != "dashboard" {
		t.Errorf("serving certificate references = %#v", secret.ReferencedBy)
	}
}

func TestExtractRustRepositoryEndToEnd(t *testing.T) {
	input, err := Extract("../rustsource/testdata/repository", Options{})
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	if input.Component != "repository" {
		t.Errorf("component = %q, want repository fixture basename", input.Component)
	}
	if len(input.SourceComponents) != 1 || len(input.HTTPEndpoints) != 4 || len(input.Services) != 2 {
		t.Errorf("Rust facts missing: components=%d endpoints=%d services=%d",
			len(input.SourceComponents), len(input.HTTPEndpoints), len(input.Services))
	}
	if len(input.Dependencies.Packages) != 4 || len(input.Authentication) != 4 {
		t.Errorf("Rust dependencies/security missing: packages=%d auth=%d",
			len(input.Dependencies.Packages), len(input.Authentication))
	}
	if input.DataCoverage["rust"] == "" || input.DataCoverage["rust"] == "complete" {
		t.Errorf("Rust coverage = %q", input.DataCoverage["rust"])
	}
}

func TestExtractExplicitOverlay(t *testing.T) {
	input, err := Extract("testdata/repository", Options{Overlay: "overlays/rhoai.next"})
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	if len(input.Services) != 1 || input.Services[0].Name != "rhoai-controller" {
		t.Fatalf("explicit overlay services = %#v", input.Services)
	}
}

func TestExtractRejectsUnknownDistribution(t *testing.T) {
	_, err := Extract("testdata/repository", Options{Distribution: "missing"})
	if err == nil || !strings.Contains(err.Error(), "no kustomization matches") {
		t.Fatalf("Extract() error = %v, want missing distribution error", err)
	}
}

func TestExtractSkipsTemplatedYAMLDuringRepositoryDiscovery(t *testing.T) {
	root := t.TempDir()
	valid := `apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  ports:
    - port: 8080
`
	if err := os.WriteFile(filepath.Join(root, "service.yaml"), []byte(valid), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "helm.yaml"), []byte("name: {{ .Values.name }}\n"), 0o600); err != nil {
		t.Fatal(err)
	}

	input, err := Extract(root, Options{})
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	if len(input.Services) != 1 || input.Services[0].Name != "api" {
		t.Fatalf("services = %#v, want valid resource retained", input.Services)
	}
	if !strings.HasPrefix(input.DataCoverage["manifests"], "partial:") {
		t.Errorf("manifest coverage = %q, want partial", input.DataCoverage["manifests"])
	}
}
