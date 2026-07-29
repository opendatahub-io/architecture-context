package platformfacts

import (
	"os"
	"path/filepath"
	"slices"
	"strings"
	"testing"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func TestInternalDependencyDiscoveryAliasesIncludeSemanticResourceGroups(t *testing.T) {
	aliases := InternalDependencyDiscoveryAliases()
	for group, fact := range resourceGroups {
		if fact.InternalName != "" && !slices.Contains(aliases, group) {
			t.Errorf("aliases = %#v, want semantic resource group %q", aliases, group)
		}
	}
	if !slices.IsSorted(aliases) {
		t.Fatalf("aliases = %#v, want deterministic sorted vocabulary", aliases)
	}
}

func TestWatchInternalDependencies(t *testing.T) {
	watches := []model.ControllerWatch{
		{Controller: "JobSet", GVK: "jobset/v1alpha2/JobSet", Source: "jobset.go:198"},
		{Controller: "Volcano", GVK: "scheduling/v1beta1/PodGroup", Source: "volcano.go:341"},
		{Controller: "CoScheduling", GVK: "scheduling/v1alpha1/PodGroup", Source: "coscheduling.go:268"},
		// The controller and resource must both match. Generated model references,
		// self-owned APIs, and lookalike resources are not runtime dependencies.
		{Controller: "GeneratedModel", GVK: "example.generated.io/v1/Gateway", Source: "swagger.json:1"},
		{Controller: "Trainer", GVK: "trainer.kubeflow.org/v1alpha1/TrainJob", Source: "trainer.go:1"},
		{Controller: "Other", GVK: "scheduling/v1beta1/PodGroup", Source: "other.go:1"},
		{Controller: "JobSet", GVK: "example.io/v1/Widget", Source: "other.go:2"},
	}

	facts := watchInternalDependencies(watches)
	if len(facts) != 3 {
		t.Fatalf("facts = %#v, want JobSet, Volcano, and CoScheduling", facts)
	}
	want := map[string]string{
		"JobSet":            "jobset.go:198",
		"Volcano Scheduler": "volcano.go:341",
		"Kubernetes Scheduler Plugins (CoScheduling)": "coscheduling.go:268",
	}
	for _, fact := range facts {
		if want[fact.Component] != fact.Source || fact.Interaction == "" || fact.Purpose == "" {
			t.Errorf("fact = %#v, want source-backed scheduler dependency", fact)
		}
		delete(want, fact.Component)
	}
	if len(want) != 0 {
		t.Errorf("missing dependencies = %#v", want)
	}
}

func TestAutoscalingWatchInternalDependencies(t *testing.T) {
	watches := []model.ControllerWatch{
		{Controller: "ScaledObjectReconciler", GVK: "keda.sh/v1alpha1/ScaledObject", Conditional: true, Source: "scaledobject.go:68"},
		{Controller: "VariantAutoscalingReconciler", GVK: "leaderworkerset.x-k8s.io/v1/LeaderWorkerSet", Conditional: true, Source: "variant.go:428"},
		{Controller: "InferencePoolReconciler", GVK: "inference.networking.k8s.io/v1/InferencePool", Source: "pool.go:113"},
		{Controller: "InferencePoolReconciler", GVK: "inference.networking.x-k8s.io/v1alpha2/InferencePool", Source: "pool.go:109"},
		{Controller: "VariantAutoscalingReconciler", GVK: "monitoring.coreos.com/v1/ServiceMonitor", Source: "variant.go:413"},
		{Controller: "Other", GVK: "keda.sh/v1alpha1/ScaledObject", Source: "other.go:1"},
	}

	facts := watchInternalDependencies(watches)
	if len(facts) != 4 {
		t.Fatalf("facts = %#v, want four autoscaling platform dependencies", facts)
	}
	want := map[string]bool{
		"KEDA": true, "LeaderWorkerSet (lws)": true,
		"gateway-api-inference-extension": true, "prometheus-operator": true,
	}
	for _, fact := range facts {
		if !want[fact.Component] || fact.Interaction == "" || fact.Purpose == "" || fact.Source == "" {
			t.Errorf("fact = %#v, want source-backed watch dependency", fact)
		}
		delete(want, fact.Component)
	}
	if len(want) != 0 {
		t.Errorf("missing dependencies = %#v", want)
	}
}

func TestInputWatchInternalDependenciesRejectSelfOwnedAPIGroup(t *testing.T) {
	watches := []model.ControllerWatch{{
		Controller: "InferencePoolReconciler",
		GVK:        "inference.networking.k8s.io/v1/InferencePool",
		Source:     "pool.go:76",
	}}
	crds := []model.CRD{{Group: "inference.networking.k8s.io", Kind: "InferencePool"}}
	if facts := inputWatchInternalDependencies(watches, crds); len(facts) != 0 {
		t.Fatalf("facts = %#v, want self-owned API watch rejected", facts)
	}
}

func TestGenericWatchInternalDependencyForKnownPlatformAPIGroup(t *testing.T) {
	watches := []model.ControllerWatch{
		{Controller: "InferenceServiceReconciler", GVK: "serving.kserve.io/v1beta1/InferenceService", Conditional: true, Source: "controller.go:251"},
	}
	facts := watchInternalDependencies(watches)
	if len(facts) != 1 || facts[0].Component != "KServe InferenceService" || facts[0].Source != "controller.go:251" {
		t.Fatalf("facts = %#v, want generic KServe watch dependency", facts)
	}
	if facts[0].Interaction != "Controller watch (conditional)" {
		t.Errorf("interaction = %q, want conditional watch", facts[0].Interaction)
	}
}

func TestGenericWatchInternalDependencyRejectsSelfOwnedGroup(t *testing.T) {
	watches := []model.ControllerWatch{
		{Controller: "ModelRegistryReconciler", GVK: "modelregistry.opendatahub.io/v1alpha1/ModelRegistry", Source: "controller.go:50"},
	}
	crds := []model.CRD{{Group: "modelregistry.opendatahub.io", Kind: "ModelRegistry"}}
	if facts := inputWatchInternalDependencies(watches, crds); len(facts) != 0 {
		t.Fatalf("facts = %#v, want self-owned API group rejected even with generic fallback", facts)
	}
}

func TestGenericWatchInternalDependencyDoesNotDuplicateNamedControllerCase(t *testing.T) {
	watches := []model.ControllerWatch{
		{Controller: "JobSet", GVK: "jobset.x-k8s.io/v1alpha2/JobSet", Source: "jobset.go:198"},
	}
	facts := watchInternalDependencies(watches)
	if len(facts) != 1 || facts[0].Component != "JobSet" {
		t.Fatalf("facts = %#v, want named case to take precedence", facts)
	}
}

func TestPrometheusRuntimeClientInternalDependency(t *testing.T) {
	facts := runtimeClientInternalDependencies([]model.RuntimeClient{
		{Target: "Prometheus", Client: "Prometheus HTTP API client", Source: "main.go:442"},
	})
	if len(facts) != 1 || facts[0].Component != "Prometheus" || facts[0].Source != "main.go:442" {
		t.Fatalf("facts = %#v, want Prometheus runtime dependency", facts)
	}
	if facts := runtimeClientInternalDependencies([]model.RuntimeClient{{Target: "Prometheus", Client: "type declaration"}}); len(facts) != 0 {
		t.Fatalf("facts = %#v, want non-constructed client rejected", facts)
	}
}

func TestEndpointMetricsRuntimeClientInternalDependency(t *testing.T) {
	facts := runtimeClientInternalDependencies([]model.RuntimeClient{
		{Target: "Model-serving endpoints", Client: "HTTP metrics data source", Source: "client.go:72"},
	})
	if len(facts) != 1 || facts[0].Component != "Model-serving endpoints" ||
		facts[0].Interaction != "HTTP metrics scrape" || facts[0].Source != "client.go:72" {
		t.Fatalf("facts = %#v, want model-serving endpoint metrics dependency", facts)
	}
	if facts := runtimeClientInternalDependencies([]model.RuntimeClient{{
		Target: "Model-serving endpoints", Client: "HTTP metrics data source",
	}}); len(facts) != 0 {
		t.Fatalf("facts = %#v, source-free client must not imply endpoint dependency", facts)
	}
}

func TestInferenceGatewayRuntimeClientInternalDependency(t *testing.T) {
	facts := runtimeClientInternalDependencies([]model.RuntimeClient{
		{Target: "llm-d inference gateway", Client: "HTTP client", Source: "client.go:134"},
	})
	if len(facts) != 1 || facts[0].Component != "llm-d inference gateway" ||
		facts[0].Interaction != "HTTP client" || facts[0].Source != "client.go:134" {
		t.Fatalf("facts = %#v, want source-backed llm-d inference gateway dependency", facts)
	}
	if facts := runtimeClientInternalDependencies([]model.RuntimeClient{{
		Target: "llm-d inference gateway", Client: "HTTP client",
	}}); len(facts) != 0 {
		t.Fatalf("facts = %#v, source-free client must not imply gateway dependency", facts)
	}
}

func TestOLMRuntimeClientInternalDependency(t *testing.T) {
	facts := runtimeClientInternalDependencies([]model.RuntimeClient{{
		Target: "Operator Lifecycle Manager (OLM)", Client: "OLM API and typed client", Source: "pkg/client/client.go:87",
	}})
	if len(facts) != 1 || facts[0].Component != "Operator Lifecycle Manager (OLM)" ||
		facts[0].Interaction != "Go module import (API + client)" || facts[0].Purpose == "" || facts[0].Source == "" {
		t.Fatalf("facts = %#v, want source-backed OLM dependency", facts)
	}
	if facts := runtimeClientInternalDependencies([]model.RuntimeClient{{
		Target: "Operator Lifecycle Manager (OLM)", Client: "type declaration",
	}}); len(facts) != 0 {
		t.Fatalf("facts = %#v, want OLM declarations without the closed runtime client rejected", facts)
	}
}

func TestRuntimeServerComponentsRequireLifecycleEvidence(t *testing.T) {
	components := runtimeServerComponents([]model.RuntimeServer{
		{Surface: "health", Protocol: "gRPC", Lifecycle: "manager Runnable", Source: "runner.go:728"},
		{Surface: "metrics", Protocol: "HTTP", Lifecycle: "ListenAndServe", Source: "runner.go:1035"},
		{Surface: "metrics", Protocol: "HTTP", Lifecycle: "ListenAndServe"},
	})
	if len(components) != 2 {
		t.Fatalf("components = %#v, want health and metrics runtime components", components)
	}
	want := map[string]string{"Health Server": "gRPC Service", "Metrics Server": "HTTP Service"}
	for _, component := range components {
		if want[component.Name] != component.Type || component.Source == "" {
			t.Errorf("component = %#v, want source-backed runtime component", component)
		}
		delete(want, component.Name)
	}
	if len(want) != 0 {
		t.Errorf("missing components = %#v", want)
	}
}

func TestGRPCServiceInternalDependencyRequiresSourceBackedExternalProcessor(t *testing.T) {
	facts := grpcServiceInternalDependencies([]model.GRPCService{
		{Service: "Health", Source: "health.go:12"},
		{Service: "ExternalProcessor", Source: "server.go:183"},
	})
	if len(facts) != 1 || facts[0].Component != "Envoy proxy" ||
		facts[0].Interaction != "gRPC ExtProc callout" || facts[0].Source != "server.go:183" {
		t.Fatalf("facts = %#v, want reachable ExternalProcessor relationship", facts)
	}
	if facts := grpcServiceInternalDependencies([]model.GRPCService{{Service: "ExternalProcessor"}}); len(facts) != 0 {
		t.Fatalf("facts = %#v, source-free declaration must not imply Envoy relationship", facts)
	}
}

func TestComponentRefInternalDependenciesRequireRuntimeMutation(t *testing.T) {
	references := []model.ComponentRef{
		{Component: "config.openshift.io/v1/APIServer", Interaction: "Resource read", Reference: "get operations", Source: "tls.go:383"},
		{Component: "cert-manager.io/v1/Certificate", Interaction: "Resource CRUD", Reference: "create operations", Source: "mtls.go:610"},
		{Component: "cert-manager.io/v1/Issuer", Interaction: "Resource CRUD", Reference: "create operations", Source: "mtls.go:529"},
		{Component: "gateway.networking.k8s.io/v1/HTTPRoute", Interaction: "Resource CRUD", Reference: "delete operations", Source: "authentication.go:462"},
		{Component: "gateway.networking.k8s.io/v1beta1/ReferenceGrant", Interaction: "Resource read", Reference: "get operations", Source: "authentication.go:652"},
	}
	facts := componentRefInternalDependencies(references)
	if len(facts) != 3 {
		t.Fatalf("facts = %#v, want OpenShift, cert-manager, and Gateway API dependencies", facts)
	}
	want := map[string]string{
		"OpenShift Cluster Configuration": "APIServer resource read",
		"cert-manager":                    "Certificate and Issuer CRD CRUD",
		"Gateway API":                     "HTTPRoute CRUD",
	}
	for _, fact := range facts {
		if want[fact.Component] != fact.Interaction || fact.Purpose == "" || fact.Source == "" {
			t.Errorf("fact = %#v, want mutation-backed platform dependency", fact)
		}
		delete(want, fact.Component)
	}
	if len(want) != 0 {
		t.Errorf("missing dependencies = %#v", want)
	}

	readOnly := []model.ComponentRef{
		{Component: "cert-manager.io/v1/Certificate", Interaction: "Resource read", Reference: "get operations", Source: "read.go:1"},
		{Component: "gateway.networking.k8s.io/v1/HTTPRoute", Interaction: "Resource CRUD", Reference: "get, list operations", Source: "misclassified.go:1"},
	}
	if facts := componentRefInternalDependencies(readOnly); len(facts) != 0 {
		t.Fatalf("facts = %#v, want read-only type evidence rejected", facts)
	}
}

func TestProjectionInternalDependenciesRequireExplicitOrchestratorContract(t *testing.T) {
	projections := []model.FieldProjection{
		{APIGroup: "components.platform.opendatahub.io", Kind: "Workbenches", Field: "spec.gatewayDomain", Projector: "orchestrator", UpstreamSource: "platform GatewayConfig", Source: "workbenches.yaml:56"},
		{APIGroup: "components.platform.opendatahub.io", Kind: "Workbenches", Field: "spec.mlflowEnabled", Projector: "orchestrator", UpstreamSource: "DSC MLflowOperator state", Source: "workbenches.yaml:79"},
		{APIGroup: "components.platform.opendatahub.io", Kind: "Workbenches", Field: "spec.platform", Projector: "orchestrator", Source: "workbenches.yaml:84"},
		{APIGroup: "example.io", Kind: "Widget", Field: "spec.owner", Projector: "controller", UpstreamSource: "GatewayConfig", Source: "widget.yaml:20"},
	}

	facts := projectionInternalDependencies(projections)
	if len(facts) != 3 {
		t.Fatalf("facts = %#v, want orchestrator, GatewayConfig, and MLflowOperator", facts)
	}
	want := map[string]string{
		"Platform orchestrator": "CR field projection",
		"GatewayConfig":         "Indirect (via orchestrator)",
		"DSC MLflowOperator":    "Indirect (via orchestrator)",
	}
	for _, fact := range facts {
		if want[fact.Component] != fact.Interaction || fact.Purpose == "" || fact.Source == "" {
			t.Errorf("fact = %#v, want explicit projection dependency", fact)
		}
		delete(want, fact.Component)
	}
	if len(want) != 0 {
		t.Errorf("missing dependencies = %#v", want)
	}
}

func TestManagedComponentDependenciesRequireSchemaRuntimeAndLifecycleRBAC(t *testing.T) {
	contract := model.ManagedComponentContract{
		APIGroup: "components.platform.opendatahub.io", Kind: "AIGateway",
		Field: "spec.batchGateway.managementState", Component: "batch-gateway operator",
		ManagedState: "Managed", RemovedState: "Removed", Source: "aigateway.yaml:56",
	}
	runtimeUse := model.RuntimeManagedComponent{
		Field: "spec.batchGateway.managementState", Action: "initialize",
		Lifecycle: "Manifest reconciliation", Source: "aigateway.go:87",
	}
	role := model.Role{Name: "manager-role", Source: "role.yaml:1", Rules: []model.RoleRule{{
		APIGroups: []string{"batch.llm-d.ai"}, Resources: []string{"llmbatchgateways"},
		Verbs: []string{"create", "delete", "deletecollection", "get", "list", "patch", "update", "watch"},
	}}}

	facts := managedComponentInternalDependencies(
		[]model.ManagedComponentContract{contract}, []model.RuntimeManagedComponent{runtimeUse},
		model.RBAC{ClusterRoles: []model.Role{role}},
	)
	if len(facts) != 1 || facts[0].Component != "llm-d batch gateway" ||
		facts[0].Interaction != "CRD-managed sub-component" || facts[0].Source != "aigateway.go:87" ||
		!strings.Contains(facts[0].Purpose, "batch.llm-d.ai/llmbatchgateways") {
		t.Fatalf("managed dependency = %#v, want correlated lifecycle fact", facts)
	}

	tests := []struct {
		name      string
		contracts []model.ManagedComponentContract
		runtime   []model.RuntimeManagedComponent
		role      model.Role
	}{
		{name: "schema missing", runtime: []model.RuntimeManagedComponent{runtimeUse}, role: role},
		{name: "runtime missing", contracts: []model.ManagedComponentContract{contract}, role: role},
		{
			name: "unrelated resource", contracts: []model.ManagedComponentContract{contract},
			runtime: []model.RuntimeManagedComponent{runtimeUse},
			role: model.Role{Source: "role.yaml:1", Rules: []model.RoleRule{{
				APIGroups: []string{"batch.llm-d.ai"}, Resources: []string{"widgets"}, Verbs: role.Rules[0].Verbs,
			}}},
		},
		{
			name: "incomplete lifecycle", contracts: []model.ManagedComponentContract{contract},
			runtime: []model.RuntimeManagedComponent{runtimeUse},
			role: model.Role{Source: "role.yaml:1", Rules: []model.RoleRule{{
				APIGroups: []string{"batch.llm-d.ai"}, Resources: []string{"llmbatchgateways"}, Verbs: []string{"get", "list", "watch"},
			}}},
		},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			got := managedComponentInternalDependencies(test.contracts, test.runtime, model.RBAC{ClusterRoles: []model.Role{test.role}})
			if len(got) != 0 {
				t.Fatalf("managed dependencies = %#v, want incomplete proof rejected", got)
			}
		})
	}
}

func TestExtractSemanticPlatformFacts(t *testing.T) {
	root := t.TempDir()
	files := map[string]string{
		"backend/src/plugins/kube.ts":                                   "makeApiClient()\n",
		"backend/src/routes/api/service/trustyai/index.ts":              "fastify.all()\n",
		"backend/src/utils/constants.ts":                                "x-forwarded-access-token\n",
		"backend/src/utils/proxy.ts":                                    "Authorization\n",
		"packages/gen-ai/bff/internal/api/middleware.go":                "RequireAccessToService\n",
		"packages/maas/bff/internal/config/environment.go":              "DefaultAuthTokenHeader\n",
		"packages/agent-ops/bff/internal/api/middleware.go":             "RequireAccessToAgent\n",
		"packages/gen-ai/bff/cmd/main.go":                               "LLAMA_STACK_URL\nMLFLOW_URL\nNEMO_GUARDRAILS_URL\n",
		"packages/maas/bff/cmd/main.go":                                 "MAAS_API_URL\n",
		"backend/src/utils/prometheusUtils.ts":                          "generatePrometheusHostURL\n",
		"manifests/modular-architecture/federation-configmap.yaml":      `"name": "perses"` + "\n",
		"dashboard-operator/charts/dashboard/values.yaml":               "components.platform.opendatahub.io/managed-by: opendatahub-operator\n",
		"dashboard-operator/config/webhook/manifests.yaml":              "kind: Certificate\n",
		"manifests/modular-architecture/modules/gen-ai/deployment.yaml": "BFF_MAAS_SERVICE_NAME\n",
		"packages/gen-ai/bff/internal/constants/mcp.go":                 "TransportTypeStreamableHTTP\n",
	}
	for relative, content := range files {
		path := filepath.Join(root, filepath.FromSlash(relative))
		if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	input := model.Input{
		Dependencies: model.Dependencies{
			GoModules: []model.GoModule{{Module: "github.com/opendatahub-io/odh-platform-utilities", Source: "operator/go.mod"}},
			Packages:  []model.LanguagePackage{{Name: "@kubernetes/client-node"}},
		},
		SourceComponents: []model.SourceComponent{{Name: "kube-rbac-proxy", Source: "deployment.yaml:1"}},
		IngressRouting:   []model.Ingress{{Kind: "HTTPRoute", Source: "httproute.yaml:1"}},
		RBAC: model.RBAC{ClusterRoles: []model.Role{{
			Name: "dashboard", Source: "role.yaml:1",
			Rules: []model.RoleRule{
				{APIGroups: []string{"trustyai.opendatahub.io"}},
				{APIGroups: []string{"dashboard.opendatahub.io"}, Resources: []string{"acceleratorprofiles"}},
				{APIGroups: []string{"nim.opendatahub.io"}, Resources: []string{"accounts"}},
				{APIGroups: []string{"serving.kserve.io"}, Resources: []string{"servingruntimes"}},
			},
		}}},
	}
	result := Extract(root, input)
	if len(result.Internal) != 7 {
		t.Errorf("internal dependencies = %#v, want resources, library, proxy, gateway, Perses, and operator", result.Internal)
	}
	if len(result.Connections) != 8 {
		t.Errorf("connections = %#v, want source-backed egress inventory", result.Connections)
	}
	if len(result.Authentication) != 5 {
		t.Errorf("authentication = %#v, want only source-backed backend, BFF, and K8s controls", result.Authentication)
	}
	if len(result.Integrations) != 11 {
		t.Errorf("integrations = %#v, want resource, proxy, gateway, and dashboard relationship facts", result.Integrations)
	}
	if result.Coverage == "" || result.Coverage == "complete" {
		t.Errorf("coverage = %q, want explicit partial coverage", result.Coverage)
	}
}

func TestKubeRBACProxyAuthenticationConvergesSourceAndManifestControls(t *testing.T) {
	input := completeRuntimeProxyInput()
	facts := kubeRBACProxyAuthenticationFacts(input)
	if len(facts) != 1 {
		t.Fatalf("facts = %#v, want one complete source proxy control", facts)
	}
	if facts[0].Endpoint != "Evalhub API (port 8443)" || facts[0].Methods != "REST" ||
		facts[0].Mechanism != "Bearer Token (Kubernetes TokenReview)" ||
		facts[0].Policy != "Per-endpoint Kubernetes SubjectAccessReview" {
		t.Errorf("fact = %#v, want source-backed proxy enforcement", facts[0])
	}

	manifest := completeManifestProxyInput()
	facts = kubeRBACProxyAuthenticationFacts(manifest)
	if len(facts) != 1 || facts[0].Endpoint != "Trustyai Service (port 8443)" {
		t.Fatalf("facts = %#v, want manifest workload proxy convergence", facts)
	}
}

func TestKubeRBACProxyAuthenticationRejectsDisconnectedEvidence(t *testing.T) {
	tests := []struct {
		name   string
		mutate func(*model.Input)
	}{
		{name: "container image alone", mutate: func(input *model.Input) {
			input.RuntimeProxies = nil
			input.SourceComponents = []model.SourceComponent{{Name: "kube-rbac-proxy"}}
		}},
		{name: "service alone", mutate: func(input *model.Input) {
			input.RuntimeProxies = nil
			input.Services = []model.Service{{Name: "proxy", Ports: []model.ServicePort{{Port: 8443}}}}
		}},
		{name: "review RBAC alone", mutate: func(input *model.Input) { input.RuntimeProxies = nil }},
		{name: "missing upstream", mutate: func(input *model.Input) { input.RuntimeProxies[0].Upstream = "" }},
		{name: "missing Secret mount", mutate: func(input *model.Input) { input.RuntimeProxies[0].TLSSecret = "" }},
		{name: "missing Service", mutate: func(input *model.Input) { input.RuntimeProxies[0].ServicePort = 0 }},
		{name: "TokenReview missing", mutate: func(input *model.Input) { input.RBAC.ClusterRoles[0].Rules = input.RBAC.ClusterRoles[0].Rules[1:] }},
		{name: "binding points elsewhere", mutate: func(input *model.Input) { input.RBAC.ClusterRoleBindings[0].Subjects[0].Name = "other" }},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			input := completeRuntimeProxyInput()
			test.mutate(&input)
			if facts := kubeRBACProxyAuthenticationFacts(input); len(facts) != 0 {
				t.Fatalf("facts = %#v, want disconnected evidence rejected", facts)
			}
		})
	}
}

func TestRuntimeWebhookAuthenticationRequiresServerWorkloadServiceAndCertificate(t *testing.T) {
	input := completeRuntimeWebhookInput()
	facts := runtimeWebhookAuthenticationFacts(input)
	if len(facts) != 1 || facts[0].Endpoint != "Webhook (port 9443)" || facts[0].Methods != "HTTPS" ||
		!strings.Contains(facts[0].Mechanism, "server identity") || !strings.Contains(facts[0].Policy, "conditionally") {
		t.Fatalf("facts = %#v, want correlated conditional webhook TLS", facts)
	}

	tests := []struct {
		name   string
		mutate func(*model.Input)
	}{
		{name: "port without runtime construction", mutate: func(input *model.Input) { input.RuntimeWebhooks = nil }},
		{name: "server without workload", mutate: func(input *model.Input) { input.Deployments = nil }},
		{name: "server without Service", mutate: func(input *model.Input) { input.Services = nil }},
		{name: "service-ca evidence alone", mutate: func(input *model.Input) { input.RuntimeWebhooks = nil; input.Deployments = nil }},
		{name: "certificate not mounted", mutate: func(input *model.Input) { input.Secrets[0].ReferencedBy = []string{"webhook-service"} }},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			candidate := completeRuntimeWebhookInput()
			test.mutate(&candidate)
			if facts := runtimeWebhookAuthenticationFacts(candidate); len(facts) != 0 {
				t.Fatalf("facts = %#v, want incomplete webhook graph rejected", facts)
			}
		})
	}
}

func completeRuntimeProxyInput() model.Input {
	return model.Input{
		RuntimeProxies: []model.RuntimeProxyControl{{
			Surface: "Evalhub API", Methods: "REST", Workload: "buildDeploymentSpec", ServiceAccount: "{name}-service",
			ListenPort: 8443, Upstream: "http://127.0.0.1:8444/", ConfigFile: "/etc/proxy/auth.yaml",
			TLSCertFile: "/etc/tls/tls.crt", TLSPrivateKeyFile: "/etc/tls/tls.key", TLSSecret: "{name}-tls",
			ServicePort: 443, ServiceTargetPort: 8443,
			ReviewRole: "auth-reviewer", ReviewBinding: "{name}-auth-reviewer",
			AuthorizationScope: "Per-endpoint Kubernetes SubjectAccessReview", Source: "deployment.go:80",
		}},
		RBAC: reviewRBAC("{name}-service", "{name}-auth-reviewer"),
	}
}

func completeManifestProxyInput() model.Input {
	return model.Input{
		Deployments: []model.Deployment{{
			Name: "{template-value}", ServiceAccount: "{template-value}-proxy", Source: "deployment.tmpl.yaml:1",
			Containers: []model.Container{
				{Name: "trustyai-service"},
				{Name: "kube-rbac-proxy", Args: []string{
					"--secure-listen-address=0.0.0.0:8443", "--upstream=http://127.0.0.1:8080/",
					"--config-file=/etc/proxy/config.yaml", "--tls-cert-file=/etc/tls/tls.crt", "--tls-private-key-file=/etc/tls/tls.key",
				}, Ports: []model.ContainerPort{{Name: "https", ContainerPort: 8443}}},
			},
		}},
		Services: []model.Service{{Name: "{registry-name}", Ports: []model.ServicePort{{Port: 443, TargetPort: 8443}}}},
		Secrets:  []model.Secret{{Name: "{template-value}-tls", Type: "kubernetes.io/tls", ReferencedBy: []string{"{template-value}"}}},
		RBAC:     reviewRBAC("{name}-proxy", "{name}-proxy-binding"),
	}
}

func completeRuntimeWebhookInput() model.Input {
	return model.Input{
		RuntimeWebhooks: []model.RuntimeWebhookServer{{Port: 9443, Conditional: true, Source: "cmd/main.go:136"}},
		Deployments:     []model.Deployment{{Name: "controller-manager", Source: "manager.yaml:1", Containers: []model.Container{{Name: "manager", Ports: []model.ContainerPort{{Name: "webhook", ContainerPort: 9443}}}}}},
		Services:        []model.Service{{Name: "webhook-service", TargetDeployment: "controller-manager", Source: "webhook-service.yaml:1", Ports: []model.ServicePort{{Port: 443, TargetPort: 9443}}}},
		Secrets:         []model.Secret{{Name: "webhook-server-cert", Type: "kubernetes.io/tls", ProvisionedBy: "OpenShift service-ca operator", ReferencedBy: []string{"controller-manager", "webhook-service"}}},
	}
}

func reviewRBAC(serviceAccount, bindingName string) model.RBAC {
	return model.RBAC{
		ClusterRoles: []model.Role{{Name: "auth-reviewer", Rules: []model.RoleRule{
			{APIGroups: []string{"authentication.k8s.io"}, Resources: []string{"tokenreviews"}, Verbs: []string{"create"}},
			{APIGroups: []string{"authorization.k8s.io"}, Resources: []string{"subjectaccessreviews"}, Verbs: []string{"create"}},
		}}},
		ClusterRoleBindings: []model.Binding{{Name: bindingName, RoleRef: "auth-reviewer", Subjects: []model.Subject{{Kind: "ServiceAccount", Name: serviceAccount}}}},
	}
}

func TestRBACAuthenticationFacts(t *testing.T) {
	roles := []model.Role{
		{
			Name: "argo-aggregate-to-admin", Source: "admin.yaml:2",
			Labels: map[string]string{"rbac.authorization.k8s.io/aggregate-to-admin": "true"},
			Rules:  []model.RoleRule{{APIGroups: []string{"argoproj.io"}, Resources: []string{"workflows"}, Verbs: []string{"*"}}},
		},
		{
			Name: "argo-aggregate-to-edit", Source: "edit.yaml:2",
			Labels: map[string]string{"rbac.authorization.k8s.io/aggregate-to-edit": "true"},
			Rules:  []model.RoleRule{{APIGroups: []string{"argoproj.io"}, Resources: []string{"workflows"}, Verbs: []string{"get", "create"}}},
		},
		{
			Name: "argo-aggregate-to-view", Source: "view.yaml:2",
			Labels: map[string]string{"rbac.authorization.k8s.io/aggregate-to-view": "true"},
			Rules:  []model.RoleRule{{APIGroups: []string{"argoproj.io"}, Resources: []string{"workflows"}, Verbs: []string{"get"}}},
		},
		{
			Name: "argo-cluster-role", Source: "restricted.yaml:2",
			Rules: []model.RoleRule{{
				APIGroups: []string{""}, Resources: []string{"secrets"},
				ResourceNames: []string{"argo-workflows-agent-ca-certificates"}, Verbs: []string{"get"},
			}},
		},
	}

	facts := rbacAuthenticationFacts(model.RBAC{ClusterRoles: roles})
	if len(facts) != 2 {
		t.Fatalf("facts = %#v, want aggregate access and named-secret restriction", facts)
	}
	if facts[0].Endpoint != "Argo Workflow agent secrets" || facts[1].Endpoint != "Argo Workflow CRDs (argoproj.io)" {
		t.Fatalf("facts = %#v, want stable Argo authorization identities", facts)
	}
}

func TestRBACAuthenticationFactsRejectIncompletePatterns(t *testing.T) {
	roles := []model.Role{
		{
			Name: "unrelated", Source: "role.yaml:2",
			Labels: map[string]string{"example.com/aggregate-to-view": "true"},
			Rules:  []model.RoleRule{{APIGroups: []string{"example.io"}, Resources: []string{"widgets"}}},
		},
		{
			Name: "unrestricted", Source: "role.yaml:10",
			Rules: []model.RoleRule{{APIGroups: []string{""}, Resources: []string{"secrets"}, Verbs: []string{"get"}}},
		},
	}
	if facts := rbacAuthenticationFacts(model.RBAC{ClusterRoles: roles}); len(facts) != 0 {
		t.Fatalf("facts = %#v, want no authorization facts", facts)
	}
}

func TestKubernetesAPIAuthenticationRequiresRuntimeDeploymentAndRBAC(t *testing.T) {
	input := model.Input{
		RuntimeClients: []model.RuntimeClient{{
			Target: "Kubernetes API", Client: "controller-runtime manager", Source: "cmd/main.go:71",
		}},
		Deployments: []model.Deployment{{
			Name: "controller-manager", ServiceAccount: "controller-manager", Source: "config/manager/manager.yaml:1",
		}},
		RBAC: model.RBAC{
			ClusterRoles: []model.Role{{
				Name: "manager-role", Source: "config/rbac/role.yaml:2",
				Rules: []model.RoleRule{{APIGroups: []string{"apps"}, Resources: []string{"deployments"}, Verbs: []string{"get"}}},
			}},
			ClusterRoleBindings: []model.Binding{{
				Name: "manager-rolebinding", RoleRef: "manager-role", RoleKind: "ClusterRole",
				Subjects: []model.Subject{{Kind: "ServiceAccount", Name: "controller-manager"}},
			}},
		},
	}

	facts := kubernetesAPIAuthenticationFacts(input)
	if len(facts) != 1 {
		t.Fatalf("facts = %#v, want one converged Kubernetes API authentication fact", facts)
	}
	fact := facts[0]
	if fact.Endpoint != "Kubernetes API" || fact.Methods != "REST" ||
		fact.Mechanism != "ServiceAccount token (in-cluster)" || fact.EnforcementPoint != "kube-apiserver" {
		t.Errorf("fact = %#v, want in-cluster ServiceAccount authentication", fact)
	}
	if fact.Policy != "RBAC enforced via manager-role ClusterRole; SA controller-manager" || fact.Source != "cmd/main.go:71" {
		t.Errorf("fact = %#v, want observed role, ServiceAccount, and runtime source", fact)
	}
}

func TestRuntimeClientIntegrationFacts(t *testing.T) {
	clients := []model.RuntimeClient{
		{Target: "PostgreSQL", Client: "pgx connection pool", Source: "postgres.go:116"},
		{Target: "Redis/Valkey", Client: "go-redis client", Source: "redis.go:144"},
		{Target: "S3-compatible storage", Client: "AWS SDK S3 client", Source: "s3.go:116"},
		{Target: "OpenTelemetry Collector", Client: "OTLP/gRPC trace exporter", Source: "otel.go:94"},
		{Target: "llm-d inference gateway", Client: "HTTP client", Source: "gateway.go:134"},
		{Target: "PostgreSQL", Client: "pgx connection pool", Source: "duplicate.go:1"},
		{Target: "Unknown", Client: "lookalike", Source: "unknown.go:1"},
	}

	facts := runtimeClientIntegrationFacts(clients)
	if len(facts) != 5 {
		t.Fatalf("facts = %#v, want five deduplicated integrations", facts)
	}
	want := map[string]struct {
		interaction string
		protocol    string
		port        any
	}{
		"PostgreSQL":              {"Database client", "TCP", "Configured by runtime"},
		"Redis/Valkey":            {"Exchange client", "TCP", "Configured by runtime"},
		"S3-compatible storage":   {"File storage client", "HTTP/HTTPS", "Configured by runtime"},
		"OpenTelemetry Collector": {"gRPC client", "OTLP/gRPC", "Configured by runtime"},
		"llm-d inference gateway": {"HTTP client", "HTTP/HTTPS", "Configured by runtime"},
	}
	for _, fact := range facts {
		expected, ok := want[fact.Component]
		if !ok || fact.InteractionType != expected.interaction || fact.Protocol != expected.protocol ||
			fact.Port != expected.port || fact.Encryption == "" || fact.Purpose == "" || fact.Source == "" {
			t.Errorf("fact = %#v, want stable source-backed runtime-client integration", fact)
		}
		delete(want, fact.Component)
	}
	if len(want) != 0 {
		t.Errorf("missing integration facts = %#v", want)
	}
}

func TestKubernetesAPIAuthenticationRejectsIncompleteEvidence(t *testing.T) {
	complete := model.Input{
		Dependencies:   model.Dependencies{GoModules: []model.GoModule{{Module: "k8s.io/client-go"}}},
		RuntimeClients: []model.RuntimeClient{{Target: "Kubernetes API", Source: "main.go:10"}},
		Deployments:    []model.Deployment{{Name: "manager", ServiceAccount: "controller-manager"}},
		RBAC: model.RBAC{
			ClusterRoles: []model.Role{{
				Name: "manager-role",
				Rules: []model.RoleRule{
					{APIGroups: []string{"authentication.k8s.io"}, Resources: []string{"tokenreviews"}, Verbs: []string{"create"}},
					{APIGroups: []string{"authorization.k8s.io"}, Resources: []string{"subjectaccessreviews"}, Verbs: []string{"create"}},
				},
			}},
			ClusterRoleBindings: []model.Binding{{
				RoleRef: "manager-role", RoleKind: "ClusterRole",
				Subjects: []model.Subject{{Kind: "ServiceAccount", Name: "controller-manager"}},
			}},
		},
	}

	tests := []struct {
		name   string
		mutate func(*model.Input)
	}{
		{name: "client library without runtime construction", mutate: func(input *model.Input) { input.RuntimeClients = nil }},
		{name: "runtime client without deployment", mutate: func(input *model.Input) { input.Deployments = nil }},
		{name: "deployment without ServiceAccount", mutate: func(input *model.Input) { input.Deployments[0].ServiceAccount = "" }},
		{name: "RBAC review permissions without runtime client", mutate: func(input *model.Input) { input.RuntimeClients = nil }},
		{name: "ServiceAccount without matching binding", mutate: func(input *model.Input) { input.RBAC.ClusterRoleBindings[0].Subjects[0].Name = "other" }},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			input := complete
			input.RuntimeClients = append([]model.RuntimeClient(nil), complete.RuntimeClients...)
			input.Deployments = append([]model.Deployment(nil), complete.Deployments...)
			input.RBAC.ClusterRoleBindings = append([]model.Binding(nil), complete.RBAC.ClusterRoleBindings...)
			input.RBAC.ClusterRoleBindings[0].Subjects = append([]model.Subject(nil), complete.RBAC.ClusterRoleBindings[0].Subjects...)
			test.mutate(&input)
			if facts := kubernetesAPIAuthenticationFacts(input); len(facts) != 0 {
				t.Fatalf("facts = %#v, want incomplete evidence rejected", facts)
			}
		})
	}
}

func TestSecureControllerMetricsAuthenticationConvergesEvidence(t *testing.T) {
	input := completeSecureMetricsInput()
	facts := secureControllerMetricsAuthenticationFacts(input)
	if len(facts) != 1 {
		t.Fatalf("facts = %#v, want one secure metrics authentication fact", facts)
	}
	fact := facts[0]
	if fact.Endpoint != ":8443/metrics" || fact.Methods != "GET" ||
		fact.Mechanism != "TokenReview + SubjectAccessReview (controller-runtime authn/authz filter)" {
		t.Errorf("fact = %#v, want secured controller-runtime metrics identity", fact)
	}
	if fact.EnforcementPoint != "controller-runtime metrics authn/authz filter" ||
		fact.Policy != "RBAC via metrics-auth-role; exposed by Service controller-manager-metrics-service; TLS certificate provisioned by OpenShift service-ca" ||
		fact.Source != "cmd/main.go:130" {
		t.Errorf("fact = %#v, want converged filter, RBAC, and TLS evidence", fact)
	}
}

func TestSecureControllerMetricsAuthenticationRejectsIncompleteEvidence(t *testing.T) {
	tests := []struct {
		name   string
		mutate func(*model.Input)
	}{
		{name: "filter not attached", mutate: func(input *model.Input) { input.RuntimeSecurity = nil }},
		{name: "RBAC review permissions without runtime configuration", mutate: func(input *model.Input) { input.RuntimeSecurity = nil }},
		{name: "deployment without explicit address", mutate: func(input *model.Input) { input.Deployments[0].Containers[0].Args = nil }},
		{name: "secure serving disabled", mutate: func(input *model.Input) { input.Deployments[0].Containers[0].Args[1] = "--metrics-secure=false" }},
		{name: "TokenReview missing", mutate: func(input *model.Input) { input.RBAC.ClusterRoles[0].Rules = input.RBAC.ClusterRoles[0].Rules[1:] }},
		{name: "review role not bound to workload ServiceAccount", mutate: func(input *model.Input) { input.RBAC.ClusterRoleBindings[0].Subjects[0].Name = "other" }},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			input := completeSecureMetricsInput()
			test.mutate(&input)
			if facts := secureControllerMetricsAuthenticationFacts(input); len(facts) != 0 {
				t.Fatalf("facts = %#v, want incomplete evidence rejected", facts)
			}
		})
	}
}

func TestSecureControllerMetricsAuthenticationSupportsNonServiceCATLS(t *testing.T) {
	tests := []struct {
		name       string
		mutate     func(*model.Input)
		wantPolicy string
	}{
		{
			name: "workload-local self-signed endpoint",
			mutate: func(input *model.Input) {
				input.Services = nil
				input.Secrets = nil
				input.RuntimeSecurity[0].CertificateMode = "controller-runtime-default"
			},
			wantPolicy: "no selected Service exposes the endpoint; controller-runtime generated self-signed TLS certificate",
		},
		{
			name: "service exposure with unresolved certificate",
			mutate: func(input *model.Input) {
				input.Secrets = nil
				input.RuntimeSecurity[0].CertificateMode = "unresolved"
			},
			wantPolicy: "exposed by Service controller-manager-metrics-service; TLS certificate source unresolved",
		},
		{
			name: "disconnected service does not become exposure evidence",
			mutate: func(input *model.Input) {
				input.Services[0].TargetDeployment = "other"
				input.Secrets = nil
				input.RuntimeSecurity[0].CertificateMode = "controller-runtime-default"
			},
			wantPolicy: "no selected Service exposes the endpoint; controller-runtime generated self-signed TLS certificate",
		},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			input := completeSecureMetricsInput()
			test.mutate(&input)
			facts := secureControllerMetricsAuthenticationFacts(input)
			if len(facts) != 1 || !strings.Contains(facts[0].Policy, test.wantPolicy) {
				t.Fatalf("facts = %#v, want policy containing %q", facts, test.wantPolicy)
			}
		})
	}
}

func TestControllerRuntimeMetricsKustomizeAuthenticationFacts(t *testing.T) {
	root := t.TempDir()
	writeTestFile(t, root, "cmd/controller/main.go", `package main

func main() {
	metricsServerOptions.FilterProvider = filters.WithAuthenticationAndAuthorization
}`)
	writeTestFile(t, root, "manifests/kustomize/options/controller/default/manager_metrics_patch.yaml", `- op: add
  path: /spec/template/spec/containers/0/args/0
  value: --metrics-bind-address=:8443
`)
	writeTestFile(t, root, "manifests/kustomize/options/controller/rbac/metrics_auth_role.yaml", `kind: ClusterRole
rules:
- apiGroups: [authentication.k8s.io]
  resources: [tokenreviews]
  verbs: [create]
- apiGroups: [authorization.k8s.io]
  resources: [subjectaccessreviews]
  verbs: [create]
`)
	writeTestFile(t, root, "manifests/kustomize/options/controller/rbac/metrics_auth_role_binding.yaml", `kind: ClusterRoleBinding
subjects:
- kind: ServiceAccount
  name: controller-manager
`)
	input := model.Input{RuntimeSecurity: []model.RuntimeSecurityControl{{
		Surface: "controller-runtime metrics", AddressFlag: "metrics-bind-address", AddressDefault: "0",
		SecureFlag: "metrics-secure", SecureDefault: true,
		Mechanism: "Kubernetes TokenReview and SubjectAccessReview",
		Source:    "cmd/controller/main.go:4",
	}}}

	facts := controllerRuntimeMetricsKustomizeAuthenticationFacts(root, input)
	if len(facts) != 1 {
		t.Fatalf("facts = %#v, want one metrics authentication fact", facts)
	}
	fact := facts[0]
	if fact.Endpoint != ":8443/metrics" ||
		fact.Mechanism != "TokenReview + SubjectAccessReview (controller-runtime authn/authz filter)" ||
		fact.EnforcementPoint != "controller-runtime FilterProvider (WithAuthenticationAndAuthorization)" {
		t.Errorf("fact = %#v, want source-backed controller metrics auth", fact)
	}
}

func TestGoBFFAuthenticationFactsExtractAuthMethodAndBearerDefaults(t *testing.T) {
	root := t.TempDir()
	relative := filepath.FromSlash("clients/ui/bff/cmd/main.go")
	path := filepath.Join(root, relative)
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	content := `// @BasePath /api/v1
package main

func main() {
	flag.StringVar(&cfg.AuthMethod, "auth-method", "internal", "Authentication method (internal or user_token)")
	flag.StringVar(&cfg.AuthTokenHeader, "auth-token-header", getEnvAsString("AUTH_TOKEN_HEADER", config.DefaultAuthTokenHeader), "Header used to extract the token")
	flag.StringVar(&cfg.AuthTokenPrefix, "auth-token-prefix", getEnvAsString("AUTH_TOKEN_PREFIX", config.DefaultAuthTokenPrefix), "Prefix used in the token header")
	if cfg.AuthMethod != config.AuthMethodInternal && cfg.AuthMethod != config.AuthMethodUser {
		panic("invalid auth method")
	}
}`
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}

	facts := goBFFAuthenticationFacts(root)
	if len(facts) != 1 {
		t.Fatalf("facts = %#v, want one BFF authentication fact", facts)
	}
	fact := facts[0]
	if fact.Endpoint != "/api/v1/*" ||
		fact.Mechanism != "Bearer Token (Authorization header) or internal ServiceAccount token" ||
		fact.EnforcementPoint != "Go BFF authentication configuration" {
		t.Errorf("fact = %#v, want BFF auth-method and bearer-token fact", fact)
	}
	if fact.Source != "clients/ui/bff/cmd/main.go:5" {
		t.Errorf("source = %q, want auth-method line", fact.Source)
	}
}

func completeSecureMetricsInput() model.Input {
	return model.Input{
		RuntimeSecurity: []model.RuntimeSecurityControl{{
			Surface: "controller-runtime metrics", AddressFlag: "metrics-bind-address", AddressDefault: "0",
			SecureFlag: "metrics-secure", SecureDefault: true,
			Mechanism:        "Kubernetes TokenReview and SubjectAccessReview",
			EnforcementPoint: "controller-runtime metrics authn/authz filter", Source: "cmd/main.go:130",
		}},
		Deployments: []model.Deployment{{
			Name: "controller-manager", ServiceAccount: "controller-manager",
			Containers: []model.Container{{Args: []string{"--metrics-bind-address=:8443", "--metrics-secure=true"}}},
		}},
		Services: []model.Service{{
			Name: "controller-manager-metrics-service", TargetDeployment: "controller-manager",
			Ports: []model.ServicePort{{Name: "https", Port: 8443, TargetPort: 8443}},
		}},
		Secrets: []model.Secret{{
			Name: "controller-manager-metrics-tls", Type: "kubernetes.io/tls",
			ProvisionedBy: "OpenShift service-ca operator", ReferencedBy: []string{"controller-manager-metrics-service"},
		}},
		RBAC: model.RBAC{
			ClusterRoles: []model.Role{{
				Name: "metrics-auth-role",
				Rules: []model.RoleRule{
					{APIGroups: []string{"authentication.k8s.io"}, Resources: []string{"tokenreviews"}, Verbs: []string{"create"}},
					{APIGroups: []string{"authorization.k8s.io"}, Resources: []string{"subjectaccessreviews"}, Verbs: []string{"create"}},
				},
			}},
			ClusterRoleBindings: []model.Binding{{
				RoleRef: "metrics-auth-role", RoleKind: "ClusterRole",
				Subjects: []model.Subject{{Kind: "ServiceAccount", Name: "controller-manager"}},
			}},
		},
	}
}

func TestGatewayAccessPolicyAuthenticationUsesRuntimePolicy(t *testing.T) {
	input := model.Input{
		AccessPolicies: []model.AccessPolicy{{
			Name: "gateway-auth", Kind: "Kuadrant AuthPolicy", TargetKind: "Gateway",
			Authentication: []string{"API key", "Kubernetes TokenReview", "OIDC JWT (optional)"},
			Authorization:  []string{"policy-defined authorization rules"},
			Exclusions:     []model.PolicyExclusion{{Path: "/maas-api/health", Methods: "GET"}},
			Source:         "controller.go:772",
		}},
		IngressRouting: []model.Ingress{{
			Kind: "HTTPRoute", Paths: []string{"/v1/models", "/maas-api"}, Backend: "maas-api",
		}},
		HTTPEndpoints: []model.HTTPEndpoint{
			{Method: "GET", Path: "/models"},
			{Method: "POST", Path: "/api-keys"},
			{Method: "DELETE", Path: "/api-keys/:id"},
			{Method: "OPTIONS", Path: "/*path"},
		},
	}

	facts := accessPolicyAuthenticationFacts(input)
	if len(facts) != 1 {
		t.Fatalf("facts = %#v, want one Gateway policy fact", facts)
	}
	fact := facts[0]
	if fact.Endpoint != "/v1/models, /maas-api/*" || fact.Methods != "GET, POST, DELETE, OPTIONS" ||
		fact.EnforcementPoint != "Kuadrant/Authorino Gateway AuthPolicy" {
		t.Errorf("fact = %#v, want route-correlated Gateway authentication", fact)
	}
	if !strings.Contains(fact.Mechanism, "Kubernetes TokenReview") || !strings.Contains(fact.Policy, "excludes GET /maas-api/health") {
		t.Errorf("fact = %#v, want mechanisms and explicit exclusion", fact)
	}
}

func TestGatewayAccessPolicyAuthenticationRejectsDisconnectedEvidence(t *testing.T) {
	policy := model.AccessPolicy{
		Kind: "Kuadrant AuthPolicy", TargetKind: "Gateway",
		Authentication: []string{"Kubernetes TokenReview"}, Source: "policy.go:1",
	}
	route := model.Ingress{Kind: "HTTPRoute", Paths: []string{"/v1"}}
	endpoint := model.HTTPEndpoint{Method: "GET", Path: "/v1"}
	tests := []model.Input{
		{AccessPolicies: []model.AccessPolicy{policy}, HTTPEndpoints: []model.HTTPEndpoint{endpoint}},
		{IngressRouting: []model.Ingress{route}, HTTPEndpoints: []model.HTTPEndpoint{endpoint}},
		{
			IngressRouting: []model.Ingress{route}, HTTPEndpoints: []model.HTTPEndpoint{endpoint},
			RBAC: model.RBAC{ClusterRoles: []model.Role{
				{Rules: []model.RoleRule{
					{
						APIGroups: []string{"authentication.k8s.io"},
						Resources: []string{"tokenreviews"}, Verbs: []string{"create"},
					},
				}},
			}},
		},
	}
	for index, input := range tests {
		if facts := accessPolicyAuthenticationFacts(input); len(facts) != 0 {
			t.Errorf("case %d facts = %#v, want disconnected policy, route, or RBAC evidence rejected", index, facts)
		}
	}
}

func TestIstioAuthorizationPolicyAuthenticationUsesVirtualServiceRoute(t *testing.T) {
	input := model.Input{
		AccessPolicies: []model.AccessPolicy{{
			Name:           "model-registry-service",
			Kind:           "Istio AuthorizationPolicy",
			TargetKind:     "Workload selector",
			TargetName:     "component=model-registry-server",
			Authentication: []string{"Istio source principal", "Kubernetes JWT (Authorization header)"},
			Authorization: []string{
				"action=ALLOW",
				"allows principals: cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account",
				"allows namespaces: kubeflow",
				"blocks request.headers[kubeflow-userid]",
			},
			Source: "manifests/kustomize/options/istio/istio-authorization-policy.yaml:1",
		}},
		IngressRouting: []model.Ingress{{
			Kind: "VirtualService", Paths: []string{"/api/model_registry/"}, Backend: "model-registry-service.kubeflow.svc.cluster.local",
		}, {
			Kind: "VirtualService", Name: "other-api", Paths: []string{"/api/other/"}, Backend: "other-api.kubeflow.svc.cluster.local",
		}},
		HTTPEndpoints: []model.HTTPEndpoint{
			{Method: "GET", Path: "/api/model_registry/v1alpha3/registered_models"},
			{Method: "POST", Path: "/api/model_registry/v1alpha3/registered_models"},
			{Method: "PATCH", Path: "/api/model_registry/v1alpha3/registered_models/{id}"},
		},
	}

	facts := accessPolicyAuthenticationFacts(input)
	if len(facts) != 1 {
		t.Fatalf("facts = %#v, want one Istio AuthorizationPolicy fact", facts)
	}
	fact := facts[0]
	if fact.Endpoint != "/api/model_registry/*" || fact.Methods != "GET, POST, PATCH" ||
		fact.EnforcementPoint != "Istio sidecar proxy AuthorizationPolicy" {
		t.Fatalf("fact = %#v, want model-registry route-scoped Istio auth", fact)
	}
	for _, want := range []string{"Kubernetes JWT", "istio-ingressgateway-service-account", "blocks request.headers[kubeflow-userid]"} {
		if !strings.Contains(fact.Mechanism+" "+fact.Policy, want) {
			t.Fatalf("fact = %#v, want %q", fact, want)
		}
	}
}

func TestWorkloadProbeAuthenticationRequiresHandlerAndNoHeaders(t *testing.T) {
	complete := func() model.Input {
		return model.Input{
			HTTPEndpoints: []model.HTTPEndpoint{{Method: "GET", Path: "/health", Source: "main.go:10"}},
			Deployments: []model.Deployment{{
				Name: "api", Source: "deployment.yaml:1",
				Containers: []model.Container{{
					Ports:          []model.ContainerPort{{Name: "http", ContainerPort: 8080}},
					LivenessProbe:  &model.Probe{Type: "httpGet", Path: "/health", Port: "http"},
					ReadinessProbe: &model.Probe{Type: "httpGet", Path: "/health", Port: "http"},
				}},
			}},
		}
	}
	facts := workloadProbeAuthenticationFacts(complete())
	if len(facts) != 1 || facts[0].Endpoint != ":8080/health" || facts[0].Mechanism != "None" {
		t.Fatalf("facts = %#v, want deduplicated unauthenticated health probe", facts)
	}

	withSourceFact := complete()
	withSourceFact.Authentication = []model.AuthenticationFact{{Endpoint: ":8080/health", Methods: "GET"}}
	if facts := workloadProbeAuthenticationFacts(withSourceFact); len(facts) != 0 {
		t.Errorf("facts = %#v, want source-backed probe fact to suppress manifest duplicate", facts)
	}

	withHeaders := complete()
	withHeaders.Deployments[0].Containers[0].LivenessProbe.Headers = []model.HTTPHeader{{Name: "Authorization", Value: "Bearer token"}}
	withHeaders.Deployments[0].Containers[0].ReadinessProbe.Headers = []model.HTTPHeader{{Name: "Authorization", Value: "Bearer token"}}
	if facts := workloadProbeAuthenticationFacts(withHeaders); len(facts) != 0 {
		t.Errorf("facts = %#v, want header-bearing probes unresolved", facts)
	}
	withoutHandler := complete()
	withoutHandler.HTTPEndpoints = nil
	if facts := workloadProbeAuthenticationFacts(withoutHandler); len(facts) != 0 {
		t.Errorf("facts = %#v, want manifest-only probe unresolved", facts)
	}
}

func TestEndpointPickerRuntimeComponentRequiresConfigAPIAndRegisteredService(t *testing.T) {
	complete := model.Input{
		CRDs: []model.CRD{{Kind: "EndpointPickerConfig", Source: "config_types.go:32"}},
		APIReferenceContracts: []model.APIReferenceContract{{
			OwnerKind: "InferencePool", Field: "Spec.EndpointPickerRef", DefaultKind: "Service",
			FailureModeDefault: "FailClose", FailureModes: []string{"FailOpen", "FailClose"}, Source: "inferencepool_types.go:132",
		}},
		GRPCServices: []model.GRPCService{{
			Service: "ExternalProcessor", Source: "server.go:183",
		}},
	}
	components := endpointPickerRuntimeComponents(complete)
	if len(components) != 1 || components[0].Name != "Endpoint Picker (EPP)" ||
		!strings.Contains(components[0].Purpose, "Service") || !strings.Contains(components[0].Purpose, "FailOpen/FailClose") ||
		components[0].Source != "inferencepool_types.go:132" {
		t.Fatalf("components = %#v, want source-backed EPP runtime", components)
	}

	withoutAPI := complete
	withoutAPI.CRDs = nil
	if components := endpointPickerRuntimeComponents(withoutAPI); len(components) != 0 {
		t.Errorf("components = %#v, service registration alone must not imply Endpoint Picker role", components)
	}
	withoutService := complete
	withoutService.GRPCServices = nil
	if components := endpointPickerRuntimeComponents(withoutService); len(components) != 0 {
		t.Errorf("components = %#v, config API alone must not imply deployed runtime", components)
	}
}

func TestUnknownMetricsAuthenticationRequiresSourceWorkloadAndService(t *testing.T) {
	complete := func() model.Input {
		return model.Input{
			HTTPEndpoints: []model.HTTPEndpoint{{Method: "Unknown", Path: "/metrics", Source: "metrics.go:19"}},
			Deployments: []model.Deployment{{
				Name: "api", Source: "deployment.yaml:1",
				Containers: []model.Container{{Ports: []model.ContainerPort{{Name: "metrics", ContainerPort: 9090}}}},
			}},
			Services: []model.Service{{
				Name: "api", Ports: []model.ServicePort{{Name: "metrics", Port: 9090, TargetPort: "metrics"}},
			}},
		}
	}
	facts := unknownMetricsAuthenticationFacts(complete())
	if len(facts) != 1 || facts[0].Endpoint != "/metrics" || facts[0].Methods != "Unknown" || facts[0].Mechanism != "Unknown" {
		t.Fatalf("facts = %#v, want explicit unknown metrics authentication", facts)
	}

	withoutSource := complete()
	withoutSource.HTTPEndpoints = nil
	if facts := unknownMetricsAuthenticationFacts(withoutSource); len(facts) != 0 {
		t.Errorf("facts = %#v, want manifest-only metrics unresolved", facts)
	}
	withoutService := complete()
	withoutService.Services = nil
	if facts := unknownMetricsAuthenticationFacts(withoutService); len(facts) != 0 {
		t.Errorf("facts = %#v, want source without deployed Service unresolved", facts)
	}
}

func TestRuntimeModuleInternalDependencyRequiresSourceBackedUse(t *testing.T) {
	facts := runtimeModuleInternalDependencies([]model.RuntimeModuleUse{
		{Module: "github.com/llm-d/llm-d-kv-cache", Source: "plugins/cache.go:27"},
		{Module: "github.com/opendatahub-io/opendatahub-operator/v2", Source: "main.go:30"},
		{Module: "github.com/opendatahub-io/mlflow-operator/api", Source: "controller.go:28"},
	})
	want := map[string]bool{
		"llm-d-kv-cache": true, "opendatahub-operator": true, "mlflow-operator": true,
	}
	for _, fact := range facts {
		if !want[fact.Component] || fact.Interaction != "Go library" || fact.Source == "" {
			t.Errorf("fact = %#v, want source-backed repository identity", fact)
		}
		delete(want, fact.Component)
	}
	if len(want) != 0 {
		t.Fatalf("missing module dependencies = %#v; facts = %#v", want, facts)
	}
	if facts := runtimeModuleInternalDependencies([]model.RuntimeModuleUse{{Module: "github.com/llm-d/declared-only"}}); len(facts) != 0 {
		t.Fatalf("facts = %#v, source-free module must not become an internal dependency", facts)
	}
}

func TestResourceGroupRBACProducesInfrastructureDependencies(t *testing.T) {
	root := t.TempDir()
	input := model.Input{
		RBAC: model.RBAC{ClusterRoles: []model.Role{{
			Name: "manager-role", Source: "role.yaml:1",
			Rules: []model.RoleRule{
				{APIGroups: []string{"monitoring.coreos.com"}, Resources: []string{"servicemonitors"}, Verbs: []string{"create", "delete"}},
				{APIGroups: []string{"cert-manager.io"}, Resources: []string{"certificates"}, Verbs: []string{"create", "delete"}},
				{APIGroups: []string{"gateway.networking.k8s.io"}, Resources: []string{"httproutes"}, Verbs: []string{"create", "delete", "patch"}},
			},
		}}},
	}
	result := Extract(root, input)
	if len(result.Internal) != 3 {
		t.Fatalf("internal = %#v, want prometheus-operator, cert-manager, and Gateway API", result.Internal)
	}
	want := map[string]string{
		"prometheus-operator": "CRD CRUD",
		"cert-manager":        "CRD CRUD",
		"Gateway API":         "CRD CRUD",
	}
	for _, dep := range result.Internal {
		if want[dep.Component] != dep.Interaction || dep.Purpose == "" || dep.Source == "" {
			t.Errorf("dependency = %#v, want RBAC-derived infrastructure dependency", dep)
		}
		delete(want, dep.Component)
	}
	if len(want) != 0 {
		t.Errorf("missing infrastructure dependencies = %#v", want)
	}
	if len(result.Integrations) != 3 {
		t.Errorf("integrations = %#v, want three corresponding integration facts", result.Integrations)
	}
}

func TestResourceGroupRBACRejectsUnmappedGroups(t *testing.T) {
	root := t.TempDir()
	input := model.Input{
		RBAC: model.RBAC{ClusterRoles: []model.Role{{
			Name: "manager-role", Source: "role.yaml:1",
			Rules: []model.RoleRule{
				{APIGroups: []string{"example.io"}, Resources: []string{"widgets"}, Verbs: []string{"create"}},
			},
		}}},
	}
	result := Extract(root, input)
	if len(result.Internal) != 0 {
		t.Fatalf("internal = %#v, want unmapped API group rejected", result.Internal)
	}
}

func TestResourceGroupRBACCoexistsWithComponentRefDependencies(t *testing.T) {
	root := t.TempDir()
	input := model.Input{
		RBAC: model.RBAC{ClusterRoles: []model.Role{{
			Name: "manager-role", Source: "role.yaml:1",
			Rules: []model.RoleRule{
				{APIGroups: []string{"cert-manager.io"}, Resources: []string{"certificates"}, Verbs: []string{"create"}},
			},
		}}},
		ComponentRefs: []model.ComponentRef{
			{Component: "cert-manager.io/v1/Certificate", Interaction: "Resource CRUD", Reference: "create operations", Source: "mtls.go:610"},
			{Component: "cert-manager.io/v1/Issuer", Interaction: "Resource CRUD", Reference: "create operations", Source: "mtls.go:529"},
		},
	}
	result := Extract(root, input)
	wantRBAC := false
	wantComponentRef := false
	for _, dep := range result.Internal {
		if dep.Component == "cert-manager" && dep.Interaction == "CRD CRUD" {
			wantRBAC = true
		}
		if dep.Component == "cert-manager" && dep.Interaction == "Certificate and Issuer CRD CRUD" {
			wantComponentRef = true
		}
	}
	if !wantRBAC {
		t.Errorf("missing RBAC-derived cert-manager dependency; internal = %#v", result.Internal)
	}
	if !wantComponentRef {
		t.Errorf("missing componentRef-derived cert-manager dependency; internal = %#v", result.Internal)
	}
}

func TestCoreResourceFactsEmitsNodeDependency(t *testing.T) {
	rbac := model.RBAC{
		ClusterRoles: []model.Role{{
			Name:   "planner-gpu-reader",
			Source: "gpu-reader-rbac.yaml:9",
			Rules: []model.RoleRule{{
				APIGroups: []string{""},
				Resources: []string{"nodes"},
				Verbs:     []string{"list"},
			}},
		}},
	}
	deps, integrations := coreResourceFacts(rbac)
	if len(deps) != 1 {
		t.Fatalf("deps = %d, want 1 node dependency", len(deps))
	}
	if deps[0].Component != "Kubernetes API (nodes)" {
		t.Errorf("component = %q, want Kubernetes API (nodes)", deps[0].Component)
	}
	if deps[0].Interaction != "list" {
		t.Errorf("interaction = %q, want list", deps[0].Interaction)
	}
	if len(integrations) != 1 {
		t.Fatalf("integrations = %d, want 1 API client fact", len(integrations))
	}
	if integrations[0].Component != "Kubernetes API" || integrations[0].InteractionType != "API client" {
		t.Errorf("integration = %q / %q, want Kubernetes API / API client",
			integrations[0].Component, integrations[0].InteractionType)
	}
}

func TestCoreResourceFactsIgnoresNormalControllerResources(t *testing.T) {
	rbac := model.RBAC{
		ClusterRoles: []model.Role{{
			Name:   "controller-manager",
			Source: "rbac.yaml:1",
			Rules: []model.RoleRule{{
				APIGroups: []string{""},
				Resources: []string{"pods", "services", "events", "configmaps"},
				Verbs:     []string{"get", "list", "watch"},
			}},
		}},
	}
	deps, integrations := coreResourceFacts(rbac)
	if len(deps) != 0 {
		t.Errorf("deps = %d, want 0 for normal controller resources", len(deps))
	}
	if len(integrations) != 0 {
		t.Errorf("integrations = %d, want 0 for normal controller resources", len(integrations))
	}
}

func TestCoreResourceFactsDeduplicatesAcrossRoles(t *testing.T) {
	rbac := model.RBAC{
		ClusterRoles: []model.Role{
			{
				Name:   "reader-1",
				Source: "rbac1.yaml:1",
				Rules: []model.RoleRule{{
					APIGroups: []string{""},
					Resources: []string{"nodes"},
					Verbs:     []string{"list"},
				}},
			},
			{
				Name:   "reader-2",
				Source: "rbac2.yaml:1",
				Rules: []model.RoleRule{{
					APIGroups: []string{""},
					Resources: []string{"nodes"},
					Verbs:     []string{"get", "list"},
				}},
			},
		},
	}
	deps, integrations := coreResourceFacts(rbac)
	if len(deps) != 1 {
		t.Errorf("deps = %d, want 1 deduplicated node dependency", len(deps))
	}
	if len(integrations) != 1 {
		t.Errorf("integrations = %d, want 1 deduplicated API client fact", len(integrations))
	}
}

func TestCoreResourceFactsCRUDVerbDetection(t *testing.T) {
	rbac := model.RBAC{
		ClusterRoles: []model.Role{{
			Name:   "admin",
			Source: "rbac.yaml:1",
			Rules: []model.RoleRule{{
				APIGroups: []string{""},
				Resources: []string{"persistentvolumes"},
				Verbs:     []string{"get", "list", "create", "delete"},
			}},
		}},
	}
	deps, _ := coreResourceFacts(rbac)
	if len(deps) != 1 {
		t.Fatalf("deps = %d, want 1", len(deps))
	}
	if deps[0].Interaction != "CRUD" {
		t.Errorf("interaction = %q, want CRUD for write verbs", deps[0].Interaction)
	}
}

func TestCoreResourceFactsSkipsRolesNotClusterRoles(t *testing.T) {
	rbac := model.RBAC{
		Roles: []model.Role{{
			Name:   "ns-reader",
			Source: "role.yaml:1",
			Rules: []model.RoleRule{{
				APIGroups: []string{""},
				Resources: []string{"nodes"},
				Verbs:     []string{"list"},
			}},
		}},
	}
	deps, integrations := coreResourceFacts(rbac)
	if len(deps) != 0 {
		t.Errorf("deps = %d, want 0 for namespace-scoped Roles", len(deps))
	}
	if len(integrations) != 0 {
		t.Errorf("integrations = %d, want 0 for namespace-scoped Roles", len(integrations))
	}
}

func TestExternalConnectionIntegrationFacts(t *testing.T) {
	connections := []model.ExternalConnection{
		{Service: "Azure OpenAI", Target: "Azure OpenAI", Type: "SDK client", Protocol: "HTTPS", Encryption: "TLS", Port: "443", Function: "LLM inference", Source: "llm.py:5"},
		{Service: "OpenAI", Target: "OpenAI", Type: "SDK client", Protocol: "HTTPS", Encryption: "TLS", Port: "443", Function: "LLM inference", Source: "api.py:10"},
	}
	facts := externalConnectionIntegrationFacts(connections)
	if len(facts) != 2 {
		t.Fatalf("facts = %d, want 2", len(facts))
	}
	components := map[string]bool{}
	for _, f := range facts {
		components[f.Component] = true
		if f.Protocol != "HTTPS" {
			t.Errorf("fact %q protocol = %q", f.Component, f.Protocol)
		}
	}
	if !components["Azure OpenAI"] || !components["OpenAI"] {
		t.Errorf("missing expected components: %v", components)
	}
}

func TestExternalConnectionIntegrationFactsDedup(t *testing.T) {
	connections := []model.ExternalConnection{
		{Service: "OpenAI", Type: "SDK client", Source: "a.py:1"},
		{Service: "OpenAI", Type: "SDK client", Source: "b.py:2"},
	}
	facts := externalConnectionIntegrationFacts(connections)
	if len(facts) != 1 {
		t.Errorf("facts = %d, want 1 (dedup)", len(facts))
	}
}

func TestExternalConnectionIntegrationFactsTestSourceExcluded(t *testing.T) {
	connections := []model.ExternalConnection{
		{Service: "OpenAI", Type: "SDK client", Source: "tests/test_llm.py:5"},
		{Service: "AWS", Type: "SDK client", Source: "test/conftest.py:10"},
	}
	facts := externalConnectionIntegrationFacts(connections)
	if len(facts) != 0 {
		t.Errorf("facts = %v, want empty (test sources excluded)", facts)
	}
}

func TestExternalConnectionIntegrationFactsEmptyService(t *testing.T) {
	connections := []model.ExternalConnection{
		{Service: "", Type: "SDK client", Source: "app.py:1"},
	}
	facts := externalConnectionIntegrationFacts(connections)
	if len(facts) != 0 {
		t.Errorf("facts = %v, want empty (empty service)", facts)
	}
}

func writeTestFile(t *testing.T, root, relative, content string) {
	t.Helper()
	path := filepath.Join(root, filepath.FromSlash(relative))
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
}
