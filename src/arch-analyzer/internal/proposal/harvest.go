package proposal

import (
	"crypto/sha256"
	"fmt"
	"io"
	"sort"
	"strings"

	"gopkg.in/yaml.v3"
)

// StaffCorrection is the YAML schema for a single record in
// staff-corrections.yaml.
type StaffCorrection struct {
	JiraKey         string                `yaml:"jira_key"`
	Summary         string                `yaml:"summary"`
	CorrectionTypes []string              `yaml:"correction_types"`
	SMEContent      string                `yaml:"sme_content"`
	HumanReview     bool                  `yaml:"human_review"`
	HumanReviewType string                `yaml:"human_review_type"`
	Labels          []string              `yaml:"labels"`
	Components      []CorrectionComponent `yaml:"components"`
}

// CorrectionComponent is a component entry in the staff corrections YAML.
type CorrectionComponent struct {
	Name string `yaml:"name"`
	ID   string `yaml:"id"`
}

// HarvestResult contains the proposals and diagnostic counters from a
// harvest operation.
type HarvestResult struct {
	Proposals       []Proposal
	TotalRecords    int
	FilteredRecords int
	SkippedReasons  map[string]int
}

// Harvest reads staff-corrections.yaml from r and produces pending
// proposals for qualifying records. A record qualifies when:
//   - human_review_type is "sme_input"
//   - sme_content is non-empty after trimming whitespace
//   - at least one component is listed
//
// One proposal is emitted per (record, component, correction_type) tuple.
// Component names are copied verbatim. Correction types are mapped via
// CorrectionTypeMapping; unsupported values become "unknown".
//
// sourcePath is recorded in provenance and used in proposal IDs.
// author and createdDate are set on every emitted proposal.
func Harvest(r io.Reader, sourcePath, author, createdDate string) (*HarvestResult, error) {
	decoder := yaml.NewDecoder(r)

	var rootNode yaml.Node
	if err := decoder.Decode(&rootNode); err != nil {
		return nil, fmt.Errorf("decode YAML: %w", err)
	}

	seqNode := &rootNode
	if rootNode.Kind == yaml.DocumentNode && len(rootNode.Content) > 0 {
		seqNode = rootNode.Content[0]
	}
	if seqNode.Kind != yaml.SequenceNode {
		return nil, fmt.Errorf("expected YAML sequence, got kind %d", seqNode.Kind)
	}

	result := &HarvestResult{
		SkippedReasons: make(map[string]int),
	}

	recordLines := make([]int, len(seqNode.Content))
	records := make([]StaffCorrection, len(seqNode.Content))

	for i, itemNode := range seqNode.Content {
		recordLines[i] = itemNode.Line
		var rec StaffCorrection
		if err := itemNode.Decode(&rec); err != nil {
			return nil, fmt.Errorf("decode record %d (line %d): %w", i, itemNode.Line, err)
		}
		records[i] = rec
	}

	result.TotalRecords = len(records)
	seen := make(map[string]bool)

	for i, rec := range records {
		if rec.HumanReviewType != "sme_input" {
			result.SkippedReasons["not_sme_input"]++
			continue
		}
		if strings.TrimSpace(rec.SMEContent) == "" {
			result.SkippedReasons["empty_sme_content"]++
			continue
		}
		if len(rec.Components) == 0 {
			result.SkippedReasons["no_components"]++
			continue
		}
		if len(rec.CorrectionTypes) == 0 {
			result.SkippedReasons["no_correction_types"]++
			continue
		}

		result.FilteredRecords++

		for _, comp := range rec.Components {
			for _, ct := range rec.CorrectionTypes {
				id := proposalID(sourcePath, rec.JiraKey, comp.Name, ct)
				if seen[id] {
					result.SkippedReasons["duplicate_id"]++
					continue
				}
				seen[id] = true

				provenance := buildProvenance(sourcePath, rec.JiraKey, i, recordLines[i])

				p := Proposal{
					ContractVersion: ProposalContractVersion,
					ID:              id,
					Component:       comp.Name,
					Category:        MapCorrectionType(ct),
					Status:          "pending",
					Claim:           rec.SMEContent,
					Provenance:      provenance,
					Author:          author,
					CreatedDate:     createdDate,
				}
				result.Proposals = append(result.Proposals, p)
			}
		}
	}

	sort.Slice(result.Proposals, func(i, j int) bool {
		return result.Proposals[i].ID < result.Proposals[j].ID
	})

	return result, nil
}

// buildProvenance encodes source location metadata as deterministic strings.
func buildProvenance(sourcePath, jiraKey string, recordIndex, yamlLine int) []string {
	prov := []string{
		fmt.Sprintf("source:%s", sourcePath),
		fmt.Sprintf("record:%d", recordIndex),
		fmt.Sprintf("yaml-line:%d", yamlLine),
	}
	if jiraKey != "" {
		prov = append(prov, fmt.Sprintf("jira:%s", jiraKey))
	}
	return prov
}

// proposalID produces a deterministic, stable ID from the source path,
// Jira key, component name, and correction type. The ID is a truncated
// SHA-256 hex digest prefixed with "prop-".
func proposalID(sourcePath, jiraKey, component, correctionType string) string {
	h := sha256.New()
	fmt.Fprintf(h, "%s\x00%s\x00%s\x00%s", sourcePath, jiraKey, component, correctionType)
	return fmt.Sprintf("prop-%x", h.Sum(nil)[:12])
}

// ToProposalSet converts a HarvestResult into a ProposalSet envelope.
func (r *HarvestResult) ToProposalSet(generatedAt string) ProposalSet {
	proposals := r.Proposals
	if proposals == nil {
		proposals = []Proposal{}
	}
	return ProposalSet{
		ContractVersion: ProposalContractVersion,
		GeneratedAt:     generatedAt,
		Proposals:       proposals,
	}
}
