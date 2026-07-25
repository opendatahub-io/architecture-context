package model

import (
	"fmt"
	"time"
)

// ContractVersion is the current version of the context contract schema.
const ContractVersion = "1"

// ValidationState represents the validation status of a contract field.
// It distinguishes between confirmed facts, values needing validation,
// values that are explicitly unknown, and values that were not extracted.
type ValidationState string

const (
	ValidationConfirmed       ValidationState = "confirmed"
	ValidationNeedsValidation ValidationState = "needs-validation"
	ValidationUnknown         ValidationState = "unknown"
	ValidationNotExtracted    ValidationState = "not-extracted"
)

func (v ValidationState) Valid() bool {
	switch v {
	case ValidationConfirmed, ValidationNeedsValidation, ValidationUnknown, ValidationNotExtracted:
		return true
	default:
		return false
	}
}

// Maturity represents the lifecycle stage of a component or feature.
type Maturity string

const (
	MaturityGA         Maturity = "GA"
	MaturityTP         Maturity = "TP"
	MaturityDP         Maturity = "DP"
	MaturityPlanned    Maturity = "planned"
	MaturityDeprecated Maturity = "deprecated"
)

func (m Maturity) Valid() bool {
	switch m {
	case MaturityGA, MaturityTP, MaturityDP, MaturityPlanned, MaturityDeprecated:
		return true
	default:
		return false
	}
}

// DependencyStatus represents the status of a dependency relationship.
type DependencyStatus string

const (
	DependencyExists  DependencyStatus = "exists"
	DependencyNeeded  DependencyStatus = "needed"
	DependencyOpen    DependencyStatus = "open"
	DependencyBlocked DependencyStatus = "blocked"
)

func (d DependencyStatus) Valid() bool {
	switch d {
	case DependencyExists, DependencyNeeded, DependencyOpen, DependencyBlocked:
		return true
	default:
		return false
	}
}

// ContextContract is the versioned envelope that carries provenance,
// applicability, confidence, maturity, scope, dependency status, and
// behavioral evidence metadata alongside the component-architecture.json
// data. All sub-fields are optional: absent means "not provided" which is
// distinct from an explicit unknown or not-extracted state.
type ContextContract struct {
	ContractVersion         string                           `json:"contract_version"`
	Provenance              *ContractProvenance              `json:"provenance,omitempty"`
	Applicability           *ContractApplicability           `json:"applicability,omitempty"`
	Confidence              *ContractConfidence              `json:"confidence,omitempty"`
	Maturity                *ContractMaturity                `json:"maturity,omitempty"`
	Scope                   *ContractScope                   `json:"scope,omitempty"`
	Dependencies            []ContractDependency             `json:"dependencies,omitempty"`
	BehavioralEvidence      *ContractBehavioralEvidence      `json:"behavioral_evidence,omitempty"`
	ComponentClassification *ContractComponentClassification `json:"component_classification,omitempty"`
}

// ContractProvenance records where and when the data was extracted.
type ContractProvenance struct {
	Source          string          `json:"source"`
	ExtractedAt     string          `json:"extracted_at"`
	AnalyzerVersion string          `json:"analyzer_version"`
	CommitSHA       string          `json:"commit_sha,omitempty"`
	Repository      string          `json:"repository,omitempty"`
	Validation      ValidationState `json:"validation"`
}

// ContractApplicability records the version/release range and freshness
// window for which the extracted data is considered applicable.
type ContractApplicability struct {
	Version         string          `json:"version,omitempty"`
	Release         string          `json:"release,omitempty"`
	ApplicableFrom  string          `json:"applicable_from,omitempty"`
	ApplicableUntil string          `json:"applicable_until,omitempty"`
	FreshnessWindow string          `json:"freshness_window,omitempty"`
	Validation      ValidationState `json:"validation"`
}

func (a *ContractApplicability) Validate() error {
	if a == nil {
		return nil
	}
	if a.ApplicableFrom == "" || a.ApplicableUntil == "" {
		return nil
	}
	from, errFrom := parseDate(a.ApplicableFrom)
	until, errUntil := parseDate(a.ApplicableUntil)
	if errFrom != nil || errUntil != nil {
		return nil
	}
	if from.After(until) {
		return fmt.Errorf("applicable_from %s is after applicable_until %s", a.ApplicableFrom, a.ApplicableUntil)
	}
	return nil
}

func (a *ContractApplicability) Stale(referenceDate time.Time) bool {
	if a == nil || a.ApplicableUntil == "" {
		return false
	}
	until, err := parseDate(a.ApplicableUntil)
	if err != nil {
		return false
	}
	return referenceDate.After(until)
}

func parseDate(s string) (time.Time, error) {
	for _, layout := range []string{"2006-01-02", time.RFC3339} {
		if t, err := time.Parse(layout, s); err == nil {
			return t, nil
		}
	}
	return time.Time{}, fmt.Errorf("unrecognized date format: %s", s)
}

func (c *ContextContract) Validate() error {
	if c == nil {
		return nil
	}
	return c.Applicability.Validate()
}

// ContractConfidence records the overall and per-category validation state
// of the extracted facts.
type ContractConfidence struct {
	OverallValidation ValidationState            `json:"overall_validation"`
	FactValidation    map[string]ValidationState `json:"fact_validation,omitempty"`
}

// ContractMaturity records the lifecycle stage and its validation status.
type ContractMaturity struct {
	Lifecycle  Maturity        `json:"lifecycle"`
	Validation ValidationState `json:"validation"`
}

// ContractScope records scope limitations and deployment topology.
type ContractScope struct {
	Limitations        []string        `json:"limitations,omitempty"`
	DeploymentTopology string          `json:"deployment_topology,omitempty"`
	Validation         ValidationState `json:"validation"`
}

// ContractDependency records the status of a named dependency, its
// upstream provenance, and validation state.
type ContractDependency struct {
	Name       string           `json:"name"`
	Status     DependencyStatus `json:"status"`
	Upstream   string           `json:"upstream,omitempty"`
	Provenance string           `json:"provenance,omitempty"`
	Validation ValidationState  `json:"validation"`
}

// ContractBehavioralEvidence records integration constraints, failure
// modes, test topology, and performance baselines when evidence exists.
// Empty slices mean no evidence was found; this is distinct from
// not-extracted.
type ContractBehavioralEvidence struct {
	IntegrationConstraints []string        `json:"integration_constraints,omitempty"`
	FailureModes           []string        `json:"failure_modes,omitempty"`
	TestTopology           []string        `json:"test_topology,omitempty"`
	PerformanceBaselines   []string        `json:"performance_baselines,omitempty"`
	ConfigurationRBAC      []string        `json:"configuration_rbac,omitempty"`
	ArchProviderMatrices   []string        `json:"arch_provider_matrices,omitempty"`
	ObservableOutcomes     []string        `json:"observable_outcomes,omitempty"`
	ImageBuildStatus       []string        `json:"image_build_status,omitempty"`
	Validation             ValidationState `json:"validation"`
}

// ContractComponentClassification records whether the component is
// primary or peripheral and its delivery-independence status.
type ContractComponentClassification struct {
	Role                 string          `json:"role,omitempty"`
	DeliveryIndependence string          `json:"delivery_independence,omitempty"`
	Validation           ValidationState `json:"validation"`
}
