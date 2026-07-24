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
