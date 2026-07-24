package model

import (
	"encoding/json"
	"strings"
	"testing"
	"time"
)

func TestContextContractRoundTrips(t *testing.T) {
	input := Input{
		Component: "test-component",
		ContextContract: &ContextContract{
			ContractVersion: ContractVersion,
			Provenance: &ContractProvenance{
				Source:          "arch-analyzer",
				ExtractedAt:     "2026-07-24T12:00:00Z",
				AnalyzerVersion: "0.1.0-dev",
				CommitSHA:       "abc123",
				Repository:      "example/repo",
				Validation:      ValidationConfirmed,
			},
			Applicability: &ContractApplicability{
				Version:         "v2.15",
				Release:         "rhoai-2.15",
				ApplicableFrom:  "2026-07-01",
				ApplicableUntil: "2026-12-31",
				FreshnessWindow: "30d",
				Validation:      ValidationConfirmed,
			},
			Confidence: &ContractConfidence{
				OverallValidation: ValidationNeedsValidation,
				FactValidation: map[string]ValidationState{
					"crds":           ValidationConfirmed,
					"authentication": ValidationNotExtracted,
				},
			},
			Maturity: &ContractMaturity{
				Lifecycle:  MaturityGA,
				Validation: ValidationConfirmed,
			},
			Scope: &ContractScope{
				Limitations:        []string{"single-cluster only", "requires OpenShift 4.14+"},
				DeploymentTopology: "single-namespace operator",
				Validation:         ValidationConfirmed,
			},
			Dependencies: []ContractDependency{
				{
					Name:       "controller-runtime",
					Status:     DependencyExists,
					Upstream:   "sigs.k8s.io/controller-runtime",
					Provenance: "go.mod",
					Validation: ValidationConfirmed,
				},
				{
					Name:       "gpu-operator",
					Status:     DependencyNeeded,
					Validation: ValidationNeedsValidation,
				},
			},
			BehavioralEvidence: &ContractBehavioralEvidence{
				IntegrationConstraints: []string{"requires CRD installation before controller start"},
				FailureModes:           []string{"webhook timeout causes admission rejection"},
				TestTopology:           []string{"envtest with real API server"},
				PerformanceBaselines:   []string{"reconcile P99 < 500ms measured in CI"},
				Validation:             ValidationConfirmed,
			},
		},
	}

	var encoded strings.Builder
	if err := EncodeInput(&encoded, input); err != nil {
		t.Fatal(err)
	}

	decoded, err := DecodeInput(strings.NewReader(encoded.String()))
	if err != nil {
		t.Fatal(err)
	}

	contract := decoded.ContextContract
	if contract == nil {
		t.Fatal("context_contract missing after round-trip")
	}
	if contract.ContractVersion != ContractVersion {
		t.Fatalf("contract_version = %q, want %q", contract.ContractVersion, ContractVersion)
	}

	if contract.Provenance.Source != "arch-analyzer" {
		t.Errorf("provenance.source = %q", contract.Provenance.Source)
	}
	if contract.Provenance.Validation != ValidationConfirmed {
		t.Errorf("provenance.validation = %q", contract.Provenance.Validation)
	}

	if contract.Applicability.Version != "v2.15" {
		t.Errorf("applicability.version = %q", contract.Applicability.Version)
	}
	if contract.Applicability.FreshnessWindow != "30d" {
		t.Errorf("applicability.freshness_window = %q", contract.Applicability.FreshnessWindow)
	}

	if contract.Confidence.OverallValidation != ValidationNeedsValidation {
		t.Errorf("confidence.overall_validation = %q", contract.Confidence.OverallValidation)
	}
	if contract.Confidence.FactValidation["crds"] != ValidationConfirmed {
		t.Errorf("fact_validation[crds] = %q", contract.Confidence.FactValidation["crds"])
	}
	if contract.Confidence.FactValidation["authentication"] != ValidationNotExtracted {
		t.Errorf("fact_validation[authentication] = %q", contract.Confidence.FactValidation["authentication"])
	}

	if contract.Maturity.Lifecycle != MaturityGA {
		t.Errorf("maturity.lifecycle = %q", contract.Maturity.Lifecycle)
	}

	if len(contract.Scope.Limitations) != 2 {
		t.Fatalf("scope.limitations count = %d", len(contract.Scope.Limitations))
	}
	if contract.Scope.DeploymentTopology != "single-namespace operator" {
		t.Errorf("scope.deployment_topology = %q", contract.Scope.DeploymentTopology)
	}

	if len(contract.Dependencies) != 2 {
		t.Fatalf("dependencies count = %d", len(contract.Dependencies))
	}
	if contract.Dependencies[0].Status != DependencyExists {
		t.Errorf("dependencies[0].status = %q", contract.Dependencies[0].Status)
	}
	if contract.Dependencies[1].Status != DependencyNeeded {
		t.Errorf("dependencies[1].status = %q", contract.Dependencies[1].Status)
	}

	if len(contract.BehavioralEvidence.FailureModes) != 1 {
		t.Errorf("behavioral_evidence.failure_modes count = %d", len(contract.BehavioralEvidence.FailureModes))
	}
}

func TestContextContractAbsentPreservesBackwardCompatibility(t *testing.T) {
	input, err := DecodeInput(strings.NewReader(`{
  "component": "legacy-component",
  "repo": "example/legacy",
  "services": [{"name": "api", "ports": [{"port": 8080}]}]
}`))
	if err != nil {
		t.Fatalf("DecodeInput() error = %v", err)
	}
	if input.ContextContract != nil {
		t.Fatal("context_contract should be nil for legacy input without the field")
	}
	if input.Component != "legacy-component" {
		t.Fatalf("Component = %q", input.Component)
	}
}

func TestContextContractExplicitUnknownsRoundTrip(t *testing.T) {
	input := Input{
		Component: "unknown-component",
		ContextContract: &ContextContract{
			ContractVersion: ContractVersion,
			Provenance: &ContractProvenance{
				Source:          "arch-analyzer",
				ExtractedAt:     "2026-07-24T12:00:00Z",
				AnalyzerVersion: "0.1.0-dev",
				Validation:      ValidationUnknown,
			},
			Applicability: &ContractApplicability{
				Validation: ValidationNotExtracted,
			},
			Confidence: &ContractConfidence{
				OverallValidation: ValidationUnknown,
			},
			Maturity: &ContractMaturity{
				Lifecycle:  MaturityPlanned,
				Validation: ValidationNeedsValidation,
			},
			Scope: &ContractScope{
				Validation: ValidationNotExtracted,
			},
			BehavioralEvidence: &ContractBehavioralEvidence{
				Validation: ValidationNotExtracted,
			},
		},
	}

	var encoded strings.Builder
	if err := EncodeInput(&encoded, input); err != nil {
		t.Fatal(err)
	}

	decoded, err := DecodeInput(strings.NewReader(encoded.String()))
	if err != nil {
		t.Fatal(err)
	}

	contract := decoded.ContextContract
	if contract.Provenance.Validation != ValidationUnknown {
		t.Errorf("provenance.validation = %q, want unknown", contract.Provenance.Validation)
	}
	if contract.Applicability.Validation != ValidationNotExtracted {
		t.Errorf("applicability.validation = %q, want not-extracted", contract.Applicability.Validation)
	}
	if contract.Confidence.OverallValidation != ValidationUnknown {
		t.Errorf("confidence.overall_validation = %q, want unknown", contract.Confidence.OverallValidation)
	}
	if contract.Maturity.Validation != ValidationNeedsValidation {
		t.Errorf("maturity.validation = %q, want needs-validation", contract.Maturity.Validation)
	}
	if contract.Scope.Validation != ValidationNotExtracted {
		t.Errorf("scope.validation = %q, want not-extracted", contract.Scope.Validation)
	}
	if contract.BehavioralEvidence.Validation != ValidationNotExtracted {
		t.Errorf("behavioral_evidence.validation = %q, want not-extracted", contract.BehavioralEvidence.Validation)
	}
}

func TestContextContractOmitsEmptySubFields(t *testing.T) {
	input := Input{
		Component:       "minimal",
		ContextContract: &ContextContract{ContractVersion: ContractVersion},
	}

	var encoded strings.Builder
	if err := EncodeInput(&encoded, input); err != nil {
		t.Fatal(err)
	}

	var raw map[string]any
	if err := json.Unmarshal([]byte(encoded.String()), &raw); err != nil {
		t.Fatal(err)
	}
	contract := raw["context_contract"].(map[string]any)
	if _, exists := contract["provenance"]; exists {
		t.Error("nil provenance should be omitted from JSON")
	}
	if _, exists := contract["applicability"]; exists {
		t.Error("nil applicability should be omitted from JSON")
	}
	if _, exists := contract["dependencies"]; exists {
		t.Error("nil dependencies should be omitted from JSON")
	}
}

func TestValidationStateValid(t *testing.T) {
	valid := []ValidationState{
		ValidationConfirmed, ValidationNeedsValidation,
		ValidationUnknown, ValidationNotExtracted,
	}
	for _, state := range valid {
		if !state.Valid() {
			t.Errorf("ValidationState(%q).Valid() = false, want true", state)
		}
	}
	invalid := []ValidationState{"", "invalid", "CONFIRMED", "Unknown"}
	for _, state := range invalid {
		if state.Valid() {
			t.Errorf("ValidationState(%q).Valid() = true, want false", state)
		}
	}
}

func TestMaturityValid(t *testing.T) {
	valid := []Maturity{MaturityGA, MaturityTP, MaturityDP, MaturityPlanned, MaturityDeprecated}
	for _, m := range valid {
		if !m.Valid() {
			t.Errorf("Maturity(%q).Valid() = false, want true", m)
		}
	}
	invalid := []Maturity{"", "ga", "alpha", "BETA"}
	for _, m := range invalid {
		if m.Valid() {
			t.Errorf("Maturity(%q).Valid() = true, want false", m)
		}
	}
}

func TestDependencyStatusValid(t *testing.T) {
	valid := []DependencyStatus{DependencyExists, DependencyNeeded, DependencyOpen, DependencyBlocked}
	for _, d := range valid {
		if !d.Valid() {
			t.Errorf("DependencyStatus(%q).Valid() = false, want true", d)
		}
	}
	invalid := []DependencyStatus{"", "EXISTS", "required", "missing"}
	for _, d := range invalid {
		if d.Valid() {
			t.Errorf("DependencyStatus(%q).Valid() = true, want false", d)
		}
	}
}

func TestExistingFixturesDecodeWithoutContract(t *testing.T) {
	fixtures := []string{
		`{"component":"example","repo":"example/example","services":[{"name":"api","ports":[{"port":8443,"targetPort":"https","protocol":"TCP"},{"port":"metrics","targetPort":8080,"protocol":"TCP"}]}],"field_from_a_newer_schema":{"ignored":true}}`,
		`{"component":"legacy-adapter","category_coverage":{"authentication":{"status":"unknown","fact_count":0,"discovery_contract":"authentication/v1","completed_checks":[],"limitations":["coverage was not collected"],"evidence":[]}}}`,
	}

	for _, fixture := range fixtures {
		input, err := DecodeInput(strings.NewReader(fixture))
		if err != nil {
			t.Fatalf("DecodeInput() error = %v for fixture: %s", err, fixture[:50])
		}
		if input.ContextContract != nil {
			t.Errorf("context_contract should be nil for fixture without it")
		}
	}
}

func TestApplicabilityValidateDateOrdering(t *testing.T) {
	tests := []struct {
		name    string
		app     *ContractApplicability
		wantErr bool
	}{
		{
			name: "valid ordering from before until",
			app: &ContractApplicability{
				ApplicableFrom:  "2026-01-01",
				ApplicableUntil: "2026-12-31",
				Validation:      ValidationConfirmed,
			},
			wantErr: false,
		},
		{
			name: "same date is valid",
			app: &ContractApplicability{
				ApplicableFrom:  "2026-06-15",
				ApplicableUntil: "2026-06-15",
				Validation:      ValidationConfirmed,
			},
			wantErr: false,
		},
		{
			name: "inverted ordering from after until",
			app: &ContractApplicability{
				ApplicableFrom:  "2026-12-31",
				ApplicableUntil: "2026-01-01",
				Validation:      ValidationConfirmed,
			},
			wantErr: true,
		},
		{
			name: "missing from is valid",
			app: &ContractApplicability{
				ApplicableUntil: "2026-12-31",
				Validation:      ValidationConfirmed,
			},
			wantErr: false,
		},
		{
			name: "missing until is valid",
			app: &ContractApplicability{
				ApplicableFrom: "2026-01-01",
				Validation:     ValidationConfirmed,
			},
			wantErr: false,
		},
		{
			name: "both missing is valid",
			app: &ContractApplicability{
				Validation: ValidationNotExtracted,
			},
			wantErr: false,
		},
		{
			name:    "nil applicability is valid",
			app:     nil,
			wantErr: false,
		},
		{
			name: "RFC3339 format valid ordering",
			app: &ContractApplicability{
				ApplicableFrom:  "2026-01-01T00:00:00Z",
				ApplicableUntil: "2026-12-31T23:59:59Z",
				Validation:      ValidationConfirmed,
			},
			wantErr: false,
		},
		{
			name: "RFC3339 format inverted ordering",
			app: &ContractApplicability{
				ApplicableFrom:  "2026-12-31T23:59:59Z",
				ApplicableUntil: "2026-01-01T00:00:00Z",
				Validation:      ValidationConfirmed,
			},
			wantErr: true,
		},
		{
			name: "unparseable dates pass through without error",
			app: &ContractApplicability{
				ApplicableFrom:  "Q3-2026",
				ApplicableUntil: "Q4-2026",
				Validation:      ValidationNeedsValidation,
			},
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.app.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestApplicabilityStale(t *testing.T) {
	ref := time.Date(2026, 7, 24, 0, 0, 0, 0, time.UTC)

	tests := []struct {
		name string
		app  *ContractApplicability
		want bool
	}{
		{
			name: "not stale when until is in the future",
			app: &ContractApplicability{
				ApplicableUntil: "2026-12-31",
				Validation:      ValidationConfirmed,
			},
			want: false,
		},
		{
			name: "stale when until is in the past",
			app: &ContractApplicability{
				ApplicableUntil: "2026-06-01",
				Validation:      ValidationConfirmed,
			},
			want: true,
		},
		{
			name: "not stale on exact boundary date",
			app: &ContractApplicability{
				ApplicableUntil: "2026-07-24",
				Validation:      ValidationConfirmed,
			},
			want: false,
		},
		{
			name: "stale day after boundary",
			app: &ContractApplicability{
				ApplicableUntil: "2026-07-23",
				Validation:      ValidationConfirmed,
			},
			want: true,
		},
		{
			name: "not stale when until is absent",
			app: &ContractApplicability{
				Validation: ValidationNotExtracted,
			},
			want: false,
		},
		{
			name: "not stale when nil",
			app:  nil,
			want: false,
		},
		{
			name: "not stale with unparseable date",
			app: &ContractApplicability{
				ApplicableUntil: "Q3-2026",
				Validation:      ValidationNeedsValidation,
			},
			want: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := tt.app.Stale(ref)
			if got != tt.want {
				t.Errorf("Stale() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestContextContractValidateDelegatesToApplicability(t *testing.T) {
	valid := &ContextContract{
		ContractVersion: ContractVersion,
		Applicability: &ContractApplicability{
			ApplicableFrom:  "2026-01-01",
			ApplicableUntil: "2026-12-31",
			Validation:      ValidationConfirmed,
		},
	}
	if err := valid.Validate(); err != nil {
		t.Errorf("Validate() on valid contract = %v", err)
	}

	invalid := &ContextContract{
		ContractVersion: ContractVersion,
		Applicability: &ContractApplicability{
			ApplicableFrom:  "2026-12-31",
			ApplicableUntil: "2026-01-01",
			Validation:      ValidationConfirmed,
		},
	}
	if err := invalid.Validate(); err == nil {
		t.Error("Validate() on inverted date contract should return error")
	}

	var nilContract *ContextContract
	if err := nilContract.Validate(); err != nil {
		t.Errorf("Validate() on nil contract = %v", err)
	}
}
