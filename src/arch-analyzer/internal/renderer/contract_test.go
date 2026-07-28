package renderer

import (
	"bytes"
	"strings"
	"testing"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func TestMarkdownOmitsContractSectionWhenAbsent(t *testing.T) {
	document := model.Document{
		Component: "no-contract",
		Metadata:  model.Metadata{GeneratedBy: "test"},
		Contract:  nil,
	}

	var output bytes.Buffer
	if err := Markdown(&output, document); err != nil {
		t.Fatalf("Markdown() error = %v", err)
	}
	if strings.Contains(output.String(), "Context Contract") {
		t.Fatal("Markdown() should not emit Context Contract section when contract is nil")
	}
}

func TestMarkdownRendersContractProvenance(t *testing.T) {
	document := model.Document{
		Component: "with-provenance",
		Metadata:  model.Metadata{GeneratedBy: "test"},
		Contract: &model.ContextContract{
			ContractVersion: "1",
			Provenance: &model.ContractProvenance{
				Source:          "arch-analyzer",
				ExtractedAt:     "2026-07-24T12:00:00Z",
				AnalyzerVersion: "0.1.0-dev",
				CommitSHA:       "abc123",
				Repository:      "example/repo",
				Validation:      model.ValidationConfirmed,
			},
		},
	}

	var output bytes.Buffer
	if err := Markdown(&output, document); err != nil {
		t.Fatalf("Markdown() error = %v", err)
	}
	text := output.String()

	for _, expected := range []string{
		"## Context Contract",
		"**Contract Version**: 1",
		"### Provenance",
		"**Source**: arch-analyzer",
		"**Extracted At**: 2026-07-24T12:00:00Z",
		"**Analyzer Version**: 0.1.0-dev",
		"**Commit SHA**: abc123",
		"**Repository**: example/repo",
		"**Validation**: confirmed",
	} {
		if !strings.Contains(text, expected) {
			t.Errorf("Markdown() missing %q", expected)
		}
	}
}

func TestMarkdownRendersExplicitUnknownLabels(t *testing.T) {
	document := model.Document{
		Component: "unknown-states",
		Metadata:  model.Metadata{GeneratedBy: "test"},
		Contract: &model.ContextContract{
			ContractVersion: "1",
			Provenance: &model.ContractProvenance{
				Source:          "arch-analyzer",
				ExtractedAt:     "2026-07-24T12:00:00Z",
				AnalyzerVersion: "0.1.0-dev",
				Validation:      model.ValidationUnknown,
			},
			Applicability: &model.ContractApplicability{
				Validation: model.ValidationNotExtracted,
			},
			Confidence: &model.ContractConfidence{
				OverallValidation: model.ValidationNeedsValidation,
			},
		},
	}

	var output bytes.Buffer
	if err := Markdown(&output, document); err != nil {
		t.Fatalf("Markdown() error = %v", err)
	}
	text := output.String()

	if !strings.Contains(text, "unknown (value not determined)") {
		t.Error("Markdown() should label unknown validation with descriptive text")
	}
	if !strings.Contains(text, "not-extracted (extraction not attempted)") {
		t.Error("Markdown() should label not-extracted validation with descriptive text")
	}
	if !strings.Contains(text, "needs-validation") {
		t.Error("Markdown() should render needs-validation state")
	}
}

func TestMarkdownRendersContractScope(t *testing.T) {
	document := model.Document{
		Component: "scoped",
		Metadata:  model.Metadata{GeneratedBy: "test"},
		Contract: &model.ContextContract{
			ContractVersion: "1",
			Scope: &model.ContractScope{
				Limitations:        []string{"single-cluster only", "requires OCP 4.14+"},
				DeploymentTopology: "single-namespace operator",
				Validation:         model.ValidationConfirmed,
			},
		},
	}

	var output bytes.Buffer
	if err := Markdown(&output, document); err != nil {
		t.Fatalf("Markdown() error = %v", err)
	}
	text := output.String()

	for _, expected := range []string{
		"### Scope",
		"single-cluster only",
		"requires OCP 4.14+",
		"**Deployment Topology**: single-namespace operator",
	} {
		if !strings.Contains(text, expected) {
			t.Errorf("Markdown() missing %q", expected)
		}
	}
}

func TestMarkdownRendersContractDependencies(t *testing.T) {
	document := model.Document{
		Component: "deps",
		Metadata:  model.Metadata{GeneratedBy: "test"},
		Contract: &model.ContextContract{
			ContractVersion: "1",
			Dependencies: []model.ContractDependency{
				{
					Name:       "controller-runtime",
					Status:     model.DependencyExists,
					Upstream:   "sigs.k8s.io/controller-runtime",
					Provenance: "go.mod",
					Validation: model.ValidationConfirmed,
				},
				{
					Name:       "gpu-operator",
					Status:     model.DependencyBlocked,
					Validation: model.ValidationNeedsValidation,
				},
			},
		},
	}

	var output bytes.Buffer
	if err := Markdown(&output, document); err != nil {
		t.Fatalf("Markdown() error = %v", err)
	}
	text := output.String()

	for _, expected := range []string{
		"### Dependency Status",
		"controller-runtime",
		"exists",
		"sigs.k8s.io/controller-runtime",
		"go.mod",
		"confirmed",
		"gpu-operator",
		"blocked",
		"needs-validation",
	} {
		if !strings.Contains(text, expected) {
			t.Errorf("Markdown() missing %q", expected)
		}
	}
}

func TestMarkdownRendersContractMaturity(t *testing.T) {
	document := model.Document{
		Component: "mature",
		Metadata:  model.Metadata{GeneratedBy: "test"},
		Contract: &model.ContextContract{
			ContractVersion: "1",
			Maturity: &model.ContractMaturity{
				Lifecycle:  model.MaturityGA,
				Validation: model.ValidationConfirmed,
			},
		},
	}

	var output bytes.Buffer
	if err := Markdown(&output, document); err != nil {
		t.Fatalf("Markdown() error = %v", err)
	}
	text := output.String()

	if !strings.Contains(text, "### Maturity") {
		t.Error("Markdown() missing Maturity heading")
	}
	if !strings.Contains(text, "**Lifecycle**: GA") {
		t.Error("Markdown() missing lifecycle value")
	}
}

func TestMarkdownRendersBehavioralEvidence(t *testing.T) {
	document := model.Document{
		Component: "behavioral",
		Metadata:  model.Metadata{GeneratedBy: "test"},
		Contract: &model.ContextContract{
			ContractVersion: "1",
			BehavioralEvidence: &model.ContractBehavioralEvidence{
				IntegrationConstraints: []string{"must install CRDs first"},
				FailureModes:           []string{"webhook timeout rejects admission"},
				TestTopology:           []string{"envtest with real API server"},
				PerformanceBaselines:   []string{"reconcile P99 < 500ms"},
				Validation:             model.ValidationConfirmed,
			},
		},
	}

	var output bytes.Buffer
	if err := Markdown(&output, document); err != nil {
		t.Fatalf("Markdown() error = %v", err)
	}
	text := output.String()

	for _, expected := range []string{
		"### Behavioral Evidence",
		"must install CRDs first",
		"webhook timeout rejects admission",
		"envtest with real API server",
		"reconcile P99 < 500ms",
	} {
		if !strings.Contains(text, expected) {
			t.Errorf("Markdown() missing %q", expected)
		}
	}
}

func TestMarkdownRendersConfidenceFactValidation(t *testing.T) {
	document := model.Document{
		Component: "confidence",
		Metadata:  model.Metadata{GeneratedBy: "test"},
		Contract: &model.ContextContract{
			ContractVersion: "1",
			Confidence: &model.ContractConfidence{
				OverallValidation: model.ValidationNeedsValidation,
				FactValidation: map[string]model.ValidationState{
					"crds":           model.ValidationConfirmed,
					"authentication": model.ValidationNotExtracted,
				},
			},
		},
	}

	var output bytes.Buffer
	if err := Markdown(&output, document); err != nil {
		t.Fatalf("Markdown() error = %v", err)
	}
	text := output.String()

	if !strings.Contains(text, "### Confidence") {
		t.Error("Markdown() missing Confidence heading")
	}
	if !strings.Contains(text, "**authentication**: not-extracted") {
		t.Error("Markdown() missing per-fact authentication validation")
	}
	if !strings.Contains(text, "**crds**: confirmed") {
		t.Error("Markdown() missing per-fact crds validation")
	}
}

func TestMarkdownRendersBehavioralEvidenceNewFields(t *testing.T) {
	document := model.Document{
		Component: "new-evidence",
		Metadata:  model.Metadata{GeneratedBy: "test"},
		Contract: &model.ContextContract{
			ContractVersion: "1",
			BehavioralEvidence: &model.ContractBehavioralEvidence{
				ConfigurationRBAC:    []string{"ClusterRole grants CRD read/write"},
				ArchProviderMatrices: []string{"x86_64: GA", "aarch64: TP"},
				ObservableOutcomes:   []string{"reconcile emits histogram on :8080/metrics"},
				ImageBuildStatus:     []string{"Konflux multi-arch pipeline"},
				Validation:           model.ValidationConfirmed,
			},
		},
	}

	var output bytes.Buffer
	if err := Markdown(&output, document); err != nil {
		t.Fatalf("Markdown() error = %v", err)
	}
	text := output.String()

	for _, expected := range []string{
		"**Configuration/RBAC**:",
		"ClusterRole grants CRD read/write",
		"**Architecture/Provider Matrices**:",
		"x86_64: GA",
		"aarch64: TP",
		"**Observable Outcomes**:",
		"reconcile emits histogram on :8080/metrics",
		"**Image/Build Status**:",
		"Konflux multi-arch pipeline",
	} {
		if !strings.Contains(text, expected) {
			t.Errorf("Markdown() missing %q", expected)
		}
	}
}

func TestMarkdownRendersComponentClassification(t *testing.T) {
	document := model.Document{
		Component: "classified",
		Metadata:  model.Metadata{GeneratedBy: "test"},
		Contract: &model.ContextContract{
			ContractVersion: "1",
			ComponentClassification: &model.ContractComponentClassification{
				Role:                 "primary",
				DeliveryIndependence: "independently versioned and released",
				Validation:           model.ValidationConfirmed,
			},
		},
	}

	var output bytes.Buffer
	if err := Markdown(&output, document); err != nil {
		t.Fatalf("Markdown() error = %v", err)
	}
	text := output.String()

	for _, expected := range []string{
		"### Component Classification",
		"**Role**: primary",
		"**Delivery Independence**: independently versioned and released",
		"**Validation**: confirmed",
	} {
		if !strings.Contains(text, expected) {
			t.Errorf("Markdown() missing %q", expected)
		}
	}
}

func TestMarkdownRendersComponentClassificationNotExtracted(t *testing.T) {
	document := model.Document{
		Component: "unclassified",
		Metadata:  model.Metadata{GeneratedBy: "test"},
		Contract: &model.ContextContract{
			ContractVersion: "1",
			ComponentClassification: &model.ContractComponentClassification{
				Validation: model.ValidationNotExtracted,
			},
		},
	}

	var output bytes.Buffer
	if err := Markdown(&output, document); err != nil {
		t.Fatalf("Markdown() error = %v", err)
	}
	text := output.String()

	if !strings.Contains(text, "### Component Classification") {
		t.Error("Markdown() should render Component Classification section even when not-extracted")
	}
	if !strings.Contains(text, "not-extracted (extraction not attempted)") {
		t.Error("Markdown() should show not-extracted label for component classification")
	}
	if strings.Contains(text, "**Role**:") {
		t.Error("Markdown() should not render empty Role")
	}
	if strings.Contains(text, "**Delivery Independence**:") {
		t.Error("Markdown() should not render empty DeliveryIndependence")
	}
}

func TestMarkdownOmitsComponentClassificationWhenNil(t *testing.T) {
	document := model.Document{
		Component: "no-classification",
		Metadata:  model.Metadata{GeneratedBy: "test"},
		Contract: &model.ContextContract{
			ContractVersion: "1",
		},
	}

	var output bytes.Buffer
	if err := Markdown(&output, document); err != nil {
		t.Fatalf("Markdown() error = %v", err)
	}
	text := output.String()

	if strings.Contains(text, "Component Classification") {
		t.Error("Markdown() should not render Component Classification when nil")
	}
}

func TestMarkdownOmitsNewBehavioralFieldsWhenEmpty(t *testing.T) {
	document := model.Document{
		Component: "existing-only",
		Metadata:  model.Metadata{GeneratedBy: "test"},
		Contract: &model.ContextContract{
			ContractVersion: "1",
			BehavioralEvidence: &model.ContractBehavioralEvidence{
				IntegrationConstraints: []string{"existing constraint"},
				Validation:             model.ValidationConfirmed,
			},
		},
	}

	var output bytes.Buffer
	if err := Markdown(&output, document); err != nil {
		t.Fatalf("Markdown() error = %v", err)
	}
	text := output.String()

	if !strings.Contains(text, "existing constraint") {
		t.Error("Markdown() should render existing integration constraints")
	}
	for _, absent := range []string{
		"Configuration/RBAC",
		"Architecture/Provider Matrices",
		"Observable Outcomes",
		"Image/Build Status",
	} {
		if strings.Contains(text, absent) {
			t.Errorf("Markdown() should not render %q when field is empty", absent)
		}
	}
}

func TestMarkdownExistingOutputUnchangedWithoutContract(t *testing.T) {
	document := model.Document{
		Component: "example-api",
		Metadata: model.Metadata{
			DeploymentType: "Kubernetes Deployment",
			GeneratedBy:    "test",
		},
		Purpose: "Static analysis found one service.",
		ArchitectureComponents: []model.ArchitectureComponent{{
			Component: "api", Type: "Deployment", Purpose: "serves requests",
		}},
		HTTPEndpoints: []model.HTTPEndpointRow{{Path: "/v1/items", Method: "GET"}},
		Services:      []model.ServiceRow{{Name: "api", Port: "8080"}},
		DataCoverage: map[string]string{
			"source": "partial: dynamic call graphs unresolved",
		},
		CategoryCoverage: map[string]model.CategoryCoverage{
			"authentication": {
				Status: "complete", FactCount: 1,
				DiscoveryContract: "authentication/v1",
				CompletedChecks:   []string{"runtime-inventory"},
			},
		},
	}

	var output bytes.Buffer
	if err := Markdown(&output, document); err != nil {
		t.Fatalf("Markdown() error = %v", err)
	}
	text := output.String()

	if strings.Contains(text, "Context Contract") {
		t.Fatal("Output should not contain Context Contract when contract is nil")
	}
	for _, expected := range []string{
		"# Component: example-api",
		"## Purpose",
		"## Architecture Components",
		"Pending analyzer-assisted synthesis.",
	} {
		if !strings.Contains(text, expected) {
			t.Errorf("Markdown() missing expected section %q — backward compatibility broken", expected)
		}
	}
	if strings.Contains(text, "**Category coverage") {
		t.Fatal("Output should keep category coverage diagnostics out of final Markdown")
	}
}
