package proposal

import "encoding/json"

const ProposalContractVersion = "v1"

// ProposalCategory values accepted by arch-query's proposal validator.
type ProposalCategory = string

const (
	CategoryScopeCorrection      ProposalCategory = "scope-correction"
	CategoryOwnershipCorrection  ProposalCategory = "ownership-correction"
	CategoryMaturityCorrection   ProposalCategory = "maturity-correction"
	CategoryDependencyCorrection ProposalCategory = "dependency-correction"
	CategoryArchitectureUpdate   ProposalCategory = "architecture-update"
	CategoryUnknown              ProposalCategory = "unknown"
)

// CorrectionTypeMapping maps source YAML correction_types values to
// proposal categories accepted by arch-query.
//
//	scope_correction       → scope-correction
//	component_scope        → scope-correction
//	architecture_constraint → architecture-update
//	team_ownership         → ownership-correction
//	maturity_correction    → maturity-correction
//	upstream_correction    → dependency-correction
//	priority_correction    → unknown
//	general_refinement     → unknown
var CorrectionTypeMapping = map[string]ProposalCategory{
	"scope_correction":        CategoryScopeCorrection,
	"component_scope":         CategoryScopeCorrection,
	"architecture_constraint": CategoryArchitectureUpdate,
	"team_ownership":          CategoryOwnershipCorrection,
	"maturity_correction":     CategoryMaturityCorrection,
	"upstream_correction":     CategoryDependencyCorrection,
	"priority_correction":     CategoryUnknown,
	"general_refinement":      CategoryUnknown,
}

// MapCorrectionType returns the proposal category for a source correction
// type string. Unsupported types return CategoryUnknown.
func MapCorrectionType(sourceType string) ProposalCategory {
	if cat, ok := CorrectionTypeMapping[sourceType]; ok {
		return cat
	}
	return CategoryUnknown
}

// Proposal matches the arch-query CorrectionProposal JSON contract (v1).
type Proposal struct {
	ContractVersion string   `json:"contract_version"`
	ID              string   `json:"id"`
	Component       string   `json:"component"`
	Category        string   `json:"category"`
	Status          string   `json:"status"`
	Claim           string   `json:"claim"`
	Replacement     string   `json:"replacement,omitempty"`
	Provenance      []string `json:"provenance"`
	Author          string   `json:"author"`
	Releases        []string `json:"releases,omitempty"`
	CreatedDate     string   `json:"created_date,omitempty"`
	LastVerified    string   `json:"last_verified,omitempty"`
	SupersededBy    string   `json:"superseded_by,omitempty"`
	Notes           string   `json:"notes,omitempty"`
}

// ProposalSet is the top-level output envelope for harvest-proposals,
// matching the arch-query ProposalSet contract.
type ProposalSet struct {
	ContractVersion string     `json:"contract_version"`
	GeneratedAt     string     `json:"generated_at"`
	Proposals       []Proposal `json:"proposals"`
}

// EncodeProposalSet writes the proposal set as indented JSON.
func EncodeProposalSet(ps ProposalSet) ([]byte, error) {
	return json.MarshalIndent(ps, "", "  ")
}
