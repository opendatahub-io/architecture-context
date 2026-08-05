package normalize

import (
	"testing"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func TestInputMergesCRDVersionsIntoCanonicalRow(t *testing.T) {
	document := Input(model.Input{
		Component: "operator",
		CRDs: []model.CRD{
			{Group: "example.io", Version: "v2", Kind: "Widget", Scope: "Cluster"},
			{Group: "example.io", Version: "v1", Kind: "Widget", Scope: "Cluster"},
		},
	}, Options{})

	if len(document.CRDs) != 1 {
		t.Fatalf("CRDs = %#v, want one canonical row", document.CRDs)
	}
	if document.CRDs[0].Version != "v1, v2" {
		t.Errorf("version = %q, want sorted combined versions", document.CRDs[0].Version)
	}
}

func TestInputClassifiesCRDAPIRoles(t *testing.T) {
	document := Input(model.Input{
		Component: "kueue",
		CRDs: []model.CRD{
			{Group: "kueue.x-k8s.io", Version: "v1beta1", Kind: "Workload", Scope: "Namespaced"},
			{Group: "config.kueue.x-k8s.io", Version: "v1beta1", Kind: "Configuration", Scope: "Namespaced"},
			{Group: "visibility.kueue.x-k8s.io", Version: "v1beta1", Kind: "PendingWorkloadsSummary", Scope: "Namespaced"},
		},
	}, Options{})

	roles := map[string]string{}
	for _, crd := range document.CRDs {
		roles[crd.Kind] = crd.APIRole
	}
	if roles["Workload"] != "Core API" {
		t.Errorf("Workload role = %q, want Core API", roles["Workload"])
	}
	if roles["Configuration"] != "Configuration API" {
		t.Errorf("Configuration role = %q, want Configuration API", roles["Configuration"])
	}
	if roles["PendingWorkloadsSummary"] != "Visibility API" {
		t.Errorf("PendingWorkloadsSummary role = %q, want Visibility API", roles["PendingWorkloadsSummary"])
	}
}

func TestInputPrefersExplicitIntegrationOverInternalProjection(t *testing.T) {
	document := Input(model.Input{
		Dependencies: model.Dependencies{Internal: []model.InternalDependency{{
			Component: "inference gateway", Interaction: "HTTP client", Purpose: "Internal dependency",
		}}},
		IntegrationPoints: []model.IntegrationFact{
			{
				Component: "inference gateway", InteractionType: "HTTP client",
				Port: "Configured by runtime", Protocol: "HTTP/HTTPS", Encryption: "Configured by runtime",
				Purpose: "Runtime inference requests",
			},
		},
	}, Options{})

	if len(document.IntegrationPoints) != 1 {
		t.Fatalf("integration points = %#v, want one canonical row", document.IntegrationPoints)
	}
	row := document.IntegrationPoints[0]
	if row.Port != "Configured by runtime" || row.Protocol != "HTTP/HTTPS" ||
		row.Encryption != "Configured by runtime" || row.Purpose != "Runtime inference requests" {
		t.Fatalf("integration point = %#v, want richer explicit runtime fact", row)
	}
}

func TestInputPassesThroughContextContract(t *testing.T) {
	contract := &model.ContextContract{
		ContractVersion: model.ContractVersion,
		Provenance: &model.ContractProvenance{
			Source:          "arch-analyzer",
			ExtractedAt:     "2026-07-24T12:00:00Z",
			AnalyzerVersion: "0.1.0-dev",
			Validation:      model.ValidationConfirmed,
		},
		Maturity: &model.ContractMaturity{
			Lifecycle:  model.MaturityGA,
			Validation: model.ValidationConfirmed,
		},
	}
	document := Input(model.Input{
		Component:       "with-contract",
		ContextContract: contract,
	}, Options{})

	if document.Contract == nil {
		t.Fatal("contract should be passed through to document")
	}
	if document.Contract.ContractVersion != model.ContractVersion {
		t.Fatalf("contract_version = %q, want %q", document.Contract.ContractVersion, model.ContractVersion)
	}
	if document.Contract.Provenance.Source != "arch-analyzer" {
		t.Errorf("provenance.source = %q", document.Contract.Provenance.Source)
	}
	if document.Contract.Maturity.Lifecycle != model.MaturityGA {
		t.Errorf("maturity.lifecycle = %q", document.Contract.Maturity.Lifecycle)
	}
}

func TestInputNilContractPassesThrough(t *testing.T) {
	document := Input(model.Input{
		Component: "no-contract",
	}, Options{})

	if document.Contract != nil {
		t.Fatal("nil contract on input should remain nil on document")
	}
}

func TestInputPassesThroughNewContractFields(t *testing.T) {
	contract := &model.ContextContract{
		ContractVersion: model.ContractVersion,
		BehavioralEvidence: &model.ContractBehavioralEvidence{
			ConfigurationRBAC:    []string{"ClusterRole grants CRD access"},
			ArchProviderMatrices: []string{"x86_64: GA"},
			ObservableOutcomes:   []string{"emits metrics"},
			ImageBuildStatus:     []string{"Konflux pipeline"},
			Validation:           model.ValidationConfirmed,
		},
		ComponentClassification: &model.ContractComponentClassification{
			Role:                 "primary",
			DeliveryIndependence: "independent",
			Validation:           model.ValidationConfirmed,
		},
	}
	document := Input(model.Input{
		Component:       "new-fields",
		ContextContract: contract,
	}, Options{})

	if document.Contract == nil {
		t.Fatal("contract should be passed through")
	}
	if len(document.Contract.BehavioralEvidence.ConfigurationRBAC) != 1 {
		t.Error("configuration_rbac should pass through")
	}
	if len(document.Contract.BehavioralEvidence.ArchProviderMatrices) != 1 {
		t.Error("arch_provider_matrices should pass through")
	}
	if len(document.Contract.BehavioralEvidence.ObservableOutcomes) != 1 {
		t.Error("observable_outcomes should pass through")
	}
	if len(document.Contract.BehavioralEvidence.ImageBuildStatus) != 1 {
		t.Error("image_build_status should pass through")
	}
	if document.Contract.ComponentClassification == nil {
		t.Fatal("component_classification should pass through")
	}
	if document.Contract.ComponentClassification.Role != "primary" {
		t.Errorf("role = %q, want primary", document.Contract.ComponentClassification.Role)
	}
}

func TestInputPassesThroughHTTPEndpointOwner(t *testing.T) {
	document := Input(model.Input{
		HTTPEndpoints: []model.HTTPEndpoint{
			{Path: "/api/v1/widgets", Method: "GET", Owner: "pkg/api", Transport: "HTTP/1.1", Source: "api.go:10"},
		},
	}, Options{})
	if len(document.HTTPEndpoints) != 1 {
		t.Fatalf("HTTP endpoints = %d, want 1", len(document.HTTPEndpoints))
	}
	if document.HTTPEndpoints[0].Owner != "pkg/api" {
		t.Errorf("owner = %q, want pkg/api", document.HTTPEndpoints[0].Owner)
	}
}

func TestInputPassesThroughGRPCServiceOwner(t *testing.T) {
	document := Input(model.Input{
		GRPCServices: []model.GRPCService{
			{Service: "example.v1.Widget", Owner: "internal/grpc", Transport: "HTTP/2", Source: "grpc.go:5"},
		},
	}, Options{})
	if len(document.GRPCServices) != 1 {
		t.Fatalf("gRPC services = %d, want 1", len(document.GRPCServices))
	}
	if document.GRPCServices[0].Owner != "internal/grpc" {
		t.Errorf("owner = %q, want internal/grpc", document.GRPCServices[0].Owner)
	}
}

func TestInputInternalDependencyRoleDefaultsToUnknown(t *testing.T) {
	document := Input(model.Input{
		Dependencies: model.Dependencies{Internal: []model.InternalDependency{
			{Component: "etcd", Interaction: "gRPC client", Purpose: "State storage"},
			{Component: "redis", Interaction: "TCP client", Role: "cache", Purpose: "Cache layer"},
		}},
	}, Options{})
	if len(document.InternalDependencies) != 2 {
		t.Fatalf("internal deps = %d, want 2", len(document.InternalDependencies))
	}
	for _, dep := range document.InternalDependencies {
		if dep.Component == "etcd" && dep.Role != "Unknown" {
			t.Errorf("etcd role = %q, want Unknown (default)", dep.Role)
		}
		if dep.Component == "redis" && dep.Role != "cache" {
			t.Errorf("redis role = %q, want cache", dep.Role)
		}
	}
}

func TestInputEntrypointsMappedToArchitectureComponents(t *testing.T) {
	document := Input(model.Input{
		Entrypoints: []model.Entrypoint{
			{Name: "operator", Type: "Go controller-runtime operator", Runtime: "Go", Command: "cmd/operator", Source: "cmd/operator/main.go:10"},
		},
	}, Options{})
	found := false
	for _, comp := range document.ArchitectureComponents {
		if comp.Component == "operator" {
			found = true
			if comp.Type != "Go controller-runtime operator" {
				t.Errorf("type = %q, want Go controller-runtime operator", comp.Type)
			}
		}
	}
	if !found {
		t.Error("entrypoint should appear as architecture component")
	}
}

func TestInputComposesEvidenceBackedDeploymentRoles(t *testing.T) {
	document := Input(model.Input{
		CRDs: []model.CRD{{Group: "example.io", Version: "v1", Kind: "Widget", Scope: "Namespaced"}},
		SourceComponents: []model.SourceComponent{
			{Name: "sdk", Type: "Python SDK"},
			{Name: "pod mutation", Type: "Sidecar / Init Container Utility"},
		},
	}, Options{})
	if got, want := document.Metadata.DeploymentType, "Kubernetes Operator / Controller + Python SDK + Sidecar utilities"; got != want {
		t.Fatalf("deployment type = %q, want %q", got, want)
	}
}

func TestInputIgnoresPythonTestFixturesWhenInferringLanguages(t *testing.T) {
	sources := newSourceIndex()
	sources.add("packages/cypress/resources/pipelines_samples/dummy_pipeline.py:1", "Architecture Components")
	sources.add("frontend/src/app.tsx:1", "Architecture Components")

	document := model.Input{
		Dependencies: model.Dependencies{GoVersion: "1.26"},
		SourceComponents: []model.SourceComponent{
			{Name: "fixture", Type: "Python application", Source: "packages/cypress/resources/pipelines_samples/dummy_pipeline.py:1"},
		},
	}
	got := languages(document, sources)
	if got != "Go, TypeScript" {
		t.Fatalf("languages = %q, want Go, TypeScript", got)
	}
}

func TestInputRetainsExplicitPythonRuntimeEvidence(t *testing.T) {
	sources := newSourceIndex()
	document := model.Input{
		Dependencies: model.Dependencies{Packages: []model.LanguagePackage{{Name: "Python", Ecosystem: "Python"}}},
	}
	if got := languages(document, sources); got != "Python" {
		t.Fatalf("languages = %q, want Python", got)
	}
}

func TestInputSecurityEvidenceRemainsSeparateFromAuthentication(t *testing.T) {
	document := Input(model.Input{
		SecurityEvidence: []model.SecurityEvidence{
			{Kind: "tls-config", Target: "crypto/tls", Detail: "TLS configuration import", Status: "literal", Source: "server.go:5"},
		},
	}, Options{})
	if len(document.Authentication) != 0 {
		t.Fatal("security evidence must not be promoted to endpoint authentication")
	}
	if len(document.SecurityEvidence) != 1 || document.SecurityEvidence[0].Target != "crypto/tls" {
		t.Error("security evidence should remain in the security-evidence inventory")
	}
}

func TestInputBuildsRepoLineageFromComponentMap(t *testing.T) {
	document := Input(model.Input{
		Component: "rhods-operator",
		Repo:      "https://github.com/red-hat-data-services/rhods-operator.git",
	}, Options{
		ComponentMap: &model.ComponentMap{
			Components: map[string]model.ComponentEntry{
				"rhods-operator": {
					RepoOrg:  "red-hat-data-services",
					RepoName: "rhods-operator",
				},
			},
			Provenance: &model.ComponentMapProvenance{
				Repos: map[string]model.ComponentMapRepo{
					"red-hat-data-services/rhods-operator": {
						Org:               "red-hat-data-services",
						Repo:              "rhods-operator",
						IsFork:            true,
						Upstream:          "opendatahub-io/opendatahub-operator",
						UpstreamDetection: "sync_config",
						SyncMechanism:     "auto_merge",
						SyncWorkflows:     []string{"sync-main-to-stable.yaml", "sync-stable-to-rhoai.yaml"},
						SyncBranch:        "rhoai",
					},
				},
			},
		},
	})

	if len(document.RepoLineage) != 2 {
		t.Fatalf("RepoLineage = %d rows, want 2", len(document.RepoLineage))
	}
	upstream := document.RepoLineage[0]
	if upstream.Role != "Upstream" {
		t.Errorf("row 0 role = %q, want Upstream", upstream.Role)
	}
	if upstream.Repository != "https://github.com/opendatahub-io/opendatahub-operator" {
		t.Errorf("upstream repo = %q", upstream.Repository)
	}
	downstream := document.RepoLineage[1]
	if downstream.Role != "Downstream" {
		t.Errorf("row 1 role = %q, want Downstream", downstream.Role)
	}
	if downstream.SyncMechanism != "auto_merge" {
		t.Errorf("sync mechanism = %q, want auto_merge", downstream.SyncMechanism)
	}
	if downstream.SyncBranch != "rhoai" {
		t.Errorf("sync branch = %q, want rhoai", downstream.SyncBranch)
	}
}

func TestInputRepoLineageNilWithoutComponentMap(t *testing.T) {
	document := Input(model.Input{
		Component: "example",
	}, Options{})

	if document.RepoLineage != nil {
		t.Fatalf("RepoLineage = %#v, want nil without component map", document.RepoLineage)
	}
}

func TestInputDeterministicallySortsIntegrationTies(t *testing.T) {
	document := Input(model.Input{
		IntegrationPoints: []model.IntegrationFact{
			{Component: "/v1/Service", InteractionType: "Controller watch", Purpose: "ZuluReconciler"},
			{Component: "/v1/Service", InteractionType: "Controller watch", Purpose: "AlphaReconciler"},
		},
	}, Options{})

	if len(document.IntegrationPoints) != 2 {
		t.Fatalf("integration points = %#v, want two rows", document.IntegrationPoints)
	}
	if document.IntegrationPoints[0].Purpose != "AlphaReconciler" || document.IntegrationPoints[1].Purpose != "ZuluReconciler" {
		t.Fatalf("integration points = %#v, want full-row deterministic ordering", document.IntegrationPoints)
	}
}
