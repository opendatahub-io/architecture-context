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
