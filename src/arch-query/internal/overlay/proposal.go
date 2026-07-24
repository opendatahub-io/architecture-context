package overlay

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"sort"
	"strings"
	"time"

	"github.com/jctanner/arch-query/internal/types"
)

var validProposalStatuses = map[string]bool{
	"pending":    true,
	"reviewed":   true,
	"rejected":   true,
	"superseded": true,
}

var validProposalCategories = map[string]bool{
	"version-correction":    true,
	"scope-correction":      true,
	"ownership-correction":  true,
	"maturity-correction":   true,
	"dependency-correction": true,
	"architecture-update":   true,
	"inventory-gap":         true,
	"factual-error":         true,
	"unknown":               true,
	"not-extracted":         true,
}

func ValidProposalStatuses() []string {
	out := make([]string, 0, len(validProposalStatuses))
	for k := range validProposalStatuses {
		out = append(out, k)
	}
	return out
}

func ValidProposalCategories() []string {
	out := make([]string, 0, len(validProposalCategories))
	for k := range validProposalCategories {
		out = append(out, k)
	}
	return out
}

func ValidateProposal(p *types.CorrectionProposal) error {
	var errs []string

	if p.ContractVersion != types.ProposalContractVersion {
		errs = append(errs, fmt.Sprintf("unsupported contract_version %q (expected %q)", p.ContractVersion, types.ProposalContractVersion))
	}
	if p.ID == "" {
		errs = append(errs, "id is required")
	}
	if p.Component == "" {
		errs = append(errs, "component is required")
	}
	if !validProposalCategories[p.Category] {
		errs = append(errs, fmt.Sprintf("unsupported category %q", p.Category))
	}
	if !validProposalStatuses[p.Status] {
		errs = append(errs, fmt.Sprintf("unsupported status %q", p.Status))
	}
	if p.Claim == "" {
		errs = append(errs, "claim is required")
	}
	if len(p.Provenance) == 0 {
		errs = append(errs, "at least one provenance entry is required")
	}
	if p.Author == "" {
		errs = append(errs, "author is required")
	}
	if p.CreatedDate == "" {
		errs = append(errs, "created_date is required")
	} else if _, err := time.Parse("2006-01-02", p.CreatedDate); err != nil {
		errs = append(errs, fmt.Sprintf("created_date %q is not a valid YYYY-MM-DD date", p.CreatedDate))
	}

	if p.LastVerified != "" {
		lv, lvErr := time.Parse("2006-01-02", p.LastVerified)
		if lvErr != nil {
			errs = append(errs, fmt.Sprintf("last_verified %q is not a valid YYYY-MM-DD date", p.LastVerified))
		} else if p.CreatedDate != "" {
			cd, cdErr := time.Parse("2006-01-02", p.CreatedDate)
			if cdErr == nil && lv.Before(cd) {
				errs = append(errs, fmt.Sprintf("last_verified %q is before created_date %q", p.LastVerified, p.CreatedDate))
			}
		}
	}

	if p.Status == "superseded" && p.SupersededBy == "" {
		errs = append(errs, "superseded_by is required when status is superseded")
	}

	if len(errs) > 0 {
		return fmt.Errorf("proposal %q: %s", p.ID, strings.Join(errs, "; "))
	}
	return nil
}

func LoadProposals(fsys fs.FS) (*types.ProposalSet, error) {
	data, err := fs.ReadFile(fsys, "proposals.json")
	if err != nil {
		return nil, err
	}
	var ps types.ProposalSet
	if err := json.Unmarshal(data, &ps); err != nil {
		return nil, fmt.Errorf("parsing proposals.json: %w", err)
	}
	return &ps, nil
}

func ValidateProposalSet(ps *types.ProposalSet) []error {
	var errs []error
	if ps.ContractVersion != types.ProposalContractVersion {
		errs = append(errs, fmt.Errorf("proposal set contract_version %q unsupported (expected %q)", ps.ContractVersion, types.ProposalContractVersion))
	}
	seen := make(map[string]bool)
	for i := range ps.Proposals {
		p := &ps.Proposals[i]
		if seen[p.ID] {
			errs = append(errs, fmt.Errorf("duplicate proposal id %q", p.ID))
		}
		seen[p.ID] = true
		if err := ValidateProposal(p); err != nil {
			errs = append(errs, err)
		}
	}
	return errs
}

func GenerateProposalFromOverlay(o *types.OverlayDoc) *types.CorrectionProposal {
	p := &types.CorrectionProposal{
		ContractVersion: types.ProposalContractVersion,
		ID:              "proposal-" + o.ID,
		Category:        "unknown",
		Status:          "pending",
		Claim:           o.Fact,
		Provenance:      o.Provenance,
		Author:          o.Author,
		CreatedDate:     o.Created,
	}

	if len(o.Affects) > 0 {
		p.Component = o.Affects[0]
	}
	if len(o.Release) > 0 {
		p.Releases = o.Release
	}
	if p.Claim == "" {
		p.Claim = o.Title
	}
	if p.Author == "" {
		p.Author = "unknown"
	}
	if len(p.Provenance) == 0 {
		p.Provenance = []string{"overlay:" + o.ID}
	}

	return p
}

func GenerateProposalSet(overlays []*types.OverlayDoc, generatedAt string) *types.ProposalSet {
	ps := &types.ProposalSet{
		ContractVersion: types.ProposalContractVersion,
		GeneratedAt:     generatedAt,
	}
	for _, o := range overlays {
		if o.SupersededBy != nil && *o.SupersededBy != "" {
			continue
		}
		p := GenerateProposalFromOverlay(o)
		ps.Proposals = append(ps.Proposals, *p)
	}
	if ps.Proposals == nil {
		ps.Proposals = []types.CorrectionProposal{}
	}
	sort.Slice(ps.Proposals, func(i, j int) bool {
		return ps.Proposals[i].ID < ps.Proposals[j].ID
	})
	return ps
}
