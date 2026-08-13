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
	if len(input.ServingRuntimes) != 1 {
		t.Fatalf("serving runtimes = %#v, want one ClusterServingRuntime", input.ServingRuntimes)
	}
	runtime := input.ServingRuntimes[0]
	if runtime.Name != "rhoai-triton" || runtime.Kind != "ClusterServingRuntime" || runtime.APIGroup != "serving.kserve.io" ||
		runtime.Version != "v1alpha1" || runtime.Scope != "Cluster" || runtime.BuiltInAdapter != "triton" {
		t.Errorf("serving runtime = %#v, want extracted ClusterServingRuntime identity and adapter", runtime)
	}
	if strings.Join(runtime.SupportedModelFormats, ", ") != "onnx, triton:2 (autoSelect)" {
		t.Errorf("runtime formats = %#v, want sorted supported model formats", runtime.SupportedModelFormats)
	}
	if strings.Join(runtime.ContainerImages, ", ") != "adapter=example/modelmesh-runtime-adapter:latest, triton=example/tritonserver:latest" {
		t.Errorf("runtime images = %#v, want named container images", runtime.ContainerImages)
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
	if len(input.GapEvidenceIndex["http_endpoints"]) == 0 || len(input.GapEvidenceIndex["services"]) == 0 {
		t.Errorf("gap evidence index = %#v, want HTTP and service candidates", input.GapEvidenceIndex)
	}
	for _, candidate := range input.GapEvidenceIndex["http_endpoints"] {
		if candidate.Status != "candidate" || candidate.Source == "" || candidate.Question == "" || len(candidate.Limitations) == 0 {
			t.Errorf("invalid HTTP gap candidate = %#v", candidate)
		}
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

func TestExtractSupplementsServingRuntimeDefinitionsFromRuntimeKustomization(t *testing.T) {
	root := t.TempDir()
	mustWriteFile(t, root, "config/default/kustomization.yaml", `apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
`)
	mustWriteFile(t, root, "config/default/deployment.yaml", `apiVersion: apps/v1
kind: Deployment
metadata:
  name: manager
spec:
  template:
    spec:
      containers:
        - name: manager
          image: example/manager:latest
`)
	mustWriteFile(t, root, "config/runtimes/kustomization.yaml", `apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - triton.yaml
`)
	mustWriteFile(t, root, "config/runtimes/triton.yaml", `apiVersion: serving.kserve.io/v1alpha1
kind: ClusterServingRuntime
metadata:
  name: triton-2.x
spec:
  supportedModelFormats:
    - name: onnx
      version: "1"
      autoSelect: true
  builtInAdapter:
    serverType: triton
  containers:
    - name: triton
      image: tritonserver-2:replace
`)
	mustWriteFile(t, root, "scripts/manifests/runtimes/kustomization.yaml", `apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - duplicate.yaml
`)
	mustWriteFile(t, root, "scripts/manifests/runtimes/duplicate.yaml", `apiVersion: serving.kserve.io/v1alpha1
kind: ServingRuntime
metadata:
  name: duplicate-script-runtime
spec:
  containers:
    - name: runtime
      image: ignored:latest
`)

	input, err := Extract(root, Options{})
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	if len(input.ServingRuntimes) != 1 {
		t.Fatalf("serving runtimes = %#v, want supplemental runtime definition", input.ServingRuntimes)
	}
	runtime := input.ServingRuntimes[0]
	if runtime.Name != "triton-2.x" || runtime.BuiltInAdapter != "triton" ||
		strings.Join(runtime.SupportedModelFormats, ", ") != "onnx:1 (autoSelect)" {
		t.Fatalf("serving runtime = %#v, want source-backed Triton runtime definition", runtime)
	}
	if !strings.HasPrefix(runtime.Source, "config/runtimes/triton.yaml:") {
		t.Fatalf("serving runtime source = %q, want config/runtimes evidence", runtime.Source)
	}
	if !strings.HasPrefix(input.DataCoverage["serving_runtime_definitions"], "complete: 1 serving runtime") {
		t.Fatalf("serving runtime coverage = %q, want complete supplemental coverage", input.DataCoverage["serving_runtime_definitions"])
	}
}

func TestExtractSupplementsIstioAccessPoliciesFromOptionKustomization(t *testing.T) {
	root := t.TempDir()
	mustWriteFile(t, root, "config/default/kustomization.yaml", `apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
`)
	mustWriteFile(t, root, "config/default/deployment.yaml", `apiVersion: apps/v1
kind: Deployment
metadata:
  name: model-registry
spec:
  template:
    spec:
      containers:
        - name: app
          image: example/model-registry:latest
`)
	mustWriteFile(t, root, "manifests/kustomize/options/istio/kustomization.yaml", `apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - authz.yaml
  - virtual-service.yaml
`)
	mustWriteFile(t, root, "manifests/kustomize/options/istio/authz.yaml", `apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: model-registry-service
spec:
  action: ALLOW
  selector:
    matchLabels:
      component: model-registry-server
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account
  - from:
    - source:
        namespaces:
        - kubeflow
    when:
    - key: request.headers[authorization]
      values:
      - "*"
    - key: request.headers[kubeflow-userid]
      notValues:
      - "*"
`)
	mustWriteFile(t, root, "manifests/kustomize/options/istio/virtual-service.yaml", `apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: model-registry
spec:
  hosts:
  - "*"
  http:
  - match:
    - uri:
        prefix: /api/model_registry/
    route:
    - destination:
        host: model-registry-service.kubeflow.svc.cluster.local
`)
	mustWriteFile(t, root, "samples/options/istio/kustomization.yaml", `apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ignored.yaml
`)
	mustWriteFile(t, root, "samples/options/istio/ignored.yaml", `apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ignored
spec:
  selector:
    matchLabels:
      app: ignored
  rules:
  - from:
    - source:
        namespaces:
        - sample
`)

	input, err := Extract(root, Options{})
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	if len(input.AccessPolicies) != 1 {
		t.Fatalf("access policies = %#v, want one supplemental Istio AuthorizationPolicy", input.AccessPolicies)
	}
	policy := input.AccessPolicies[0]
	if policy.Kind != "Istio AuthorizationPolicy" || policy.TargetName != "component=model-registry-server" {
		t.Fatalf("policy = %#v, want Istio AuthorizationPolicy with selector evidence", policy)
	}
	policyText := strings.Join(append(policy.Authentication, policy.Authorization...), " ")
	for _, want := range []string{"Istio source principal", "Kubernetes JWT", "allows namespaces: kubeflow", "blocks request.headers[kubeflow-userid]"} {
		if !strings.Contains(policyText, want) {
			t.Fatalf("policy = %#v, want %q", policy, want)
		}
	}
	if len(input.IngressRouting) != 1 || input.IngressRouting[0].Kind != "VirtualService" ||
		strings.Join(input.IngressRouting[0].Paths, ", ") != "/api/model_registry/" {
		t.Fatalf("ingress routing = %#v, want supplemental VirtualService route", input.IngressRouting)
	}
	if !strings.HasPrefix(input.DataCoverage["istio_access_policies"], "complete: 1 Istio access") {
		t.Fatalf("istio access coverage = %q, want complete supplemental coverage", input.DataCoverage["istio_access_policies"])
	}
}

func mustWriteFile(t *testing.T, root, relative, content string) {
	t.Helper()
	path := filepath.Join(root, relative)
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatalf("create parent dir for %s: %v", relative, err)
	}
	if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
		t.Fatalf("write %s: %v", relative, err)
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

func TestCollectInfrastructureResourceCapturesEnvoyFilter(t *testing.T) {
	input := model.Input{}
	objects := []object{{source: "envoyfilter.yaml", line: 1, data: map[string]any{
		"apiVersion": "networking.istio.io/v1alpha3",
		"kind":       "EnvoyFilter",
		"metadata": map[string]any{
			"name":      "ext-authz",
			"namespace": "istio-system",
		},
	}}}
	collect(objects, &input)

	if len(input.InfrastructureResources) != 1 {
		t.Fatalf("infrastructure resources = %#v, want 1 EnvoyFilter", input.InfrastructureResources)
	}
	r := input.InfrastructureResources[0]
	if r.Kind != "EnvoyFilter" || r.APIGroup != "networking.istio.io" || r.Name != "ext-authz" || r.Namespace != "istio-system" {
		t.Errorf("EnvoyFilter = %#v", r)
	}
}

func TestCollectInfrastructureResourceSortsOutput(t *testing.T) {
	input := model.Input{}
	objects := []object{
		{source: "np.yaml", line: 1, data: map[string]any{
			"apiVersion": "networking.k8s.io/v1",
			"kind":       "NetworkPolicy",
			"metadata":   map[string]any{"name": "deny-all"},
		}},
		{source: "hpa.yaml", line: 1, data: map[string]any{
			"apiVersion": "autoscaling/v2",
			"kind":       "HorizontalPodAutoscaler",
			"metadata":   map[string]any{"name": "proxy"},
		}},
	}
	collect(objects, &input)

	if len(input.InfrastructureResources) != 2 {
		t.Fatalf("infrastructure resources = %#v, want 2", input.InfrastructureResources)
	}
	if input.InfrastructureResources[0].Kind != "HorizontalPodAutoscaler" {
		t.Errorf("expected HorizontalPodAutoscaler first (sorted by kind), got %q", input.InfrastructureResources[0].Kind)
	}
}
