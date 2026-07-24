package overlay

import (
	"bytes"
	"encoding/json"
	"os"
	"testing"

	"github.com/jctanner/arch-query/internal/types"
)

func mkProposal(id, component, category, status string, releases []string) types.CorrectionProposal {
	p := validProposal()
	p.ID = id
	p.Component = component
	p.Category = category
	p.Status = status
	p.Releases = releases
	if status == "superseded" {
		p.SupersededBy = "newer-" + id
	}
	return p
}

func TestGenerateReport_NilProposalSet(t *testing.T) {
	_, err := GenerateCorrectionFrequencyReport(nil, "2026-07-24T00:00:00Z")
	if err == nil {
		t.Fatal("expected error for nil proposal set")
	}
	if !contains(err.Error(), "nil") {
		t.Errorf("expected error to mention nil, got: %v", err)
	}
}

func TestGenerateReport_EmptyProposalSet(t *testing.T) {
	ps := &types.ProposalSet{
		ContractVersion: "v1",
		GeneratedAt:     "2026-07-01T00:00:00Z",
		Proposals:       []types.CorrectionProposal{},
	}
	r, err := GenerateCorrectionFrequencyReport(ps, "2026-07-24T00:00:00Z")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if r.ContractVersion != "v1" {
		t.Errorf("expected contract v1, got %s", r.ContractVersion)
	}
	if r.Summary.ActiveProposals != 0 {
		t.Errorf("expected 0 active, got %d", r.Summary.ActiveProposals)
	}
	if r.Summary.Components != 0 {
		t.Errorf("expected 0 components, got %d", r.Summary.Components)
	}
	if r.SupersededCount != 0 {
		t.Errorf("expected 0 superseded, got %d", r.SupersededCount)
	}
	if r.ByComponent == nil {
		t.Error("expected non-nil ByComponent slice")
	}
	if r.ByCategory == nil {
		t.Error("expected non-nil ByCategory slice")
	}
	if r.ByStatus == nil {
		t.Error("expected non-nil ByStatus slice")
	}
}

func TestGenerateReport_InvalidProposalSetFails(t *testing.T) {
	ps := &types.ProposalSet{
		ContractVersion: "v1",
		Proposals: []types.CorrectionProposal{
			mkProposal("dup-1", "comp-a", "version-correction", "pending", nil),
			mkProposal("dup-1", "comp-b", "scope-correction", "reviewed", nil),
		},
	}
	_, err := GenerateCorrectionFrequencyReport(ps, "")
	if err == nil {
		t.Fatal("expected error for duplicate IDs")
	}
}

func TestGenerateReport_InvalidContractVersionFails(t *testing.T) {
	ps := &types.ProposalSet{
		ContractVersion: "v99",
		Proposals:       []types.CorrectionProposal{},
	}
	_, err := GenerateCorrectionFrequencyReport(ps, "")
	if err == nil {
		t.Fatal("expected error for invalid contract version")
	}
}

func TestGenerateReport_MixedStatuses(t *testing.T) {
	ps := &types.ProposalSet{
		ContractVersion: "v1",
		GeneratedAt:     "2026-07-01T00:00:00Z",
		Proposals: []types.CorrectionProposal{
			mkProposal("p-1", "notebooks", "version-correction", "pending", []string{"3.4"}),
			mkProposal("p-2", "notebooks", "scope-correction", "reviewed", []string{"3.4"}),
			mkProposal("p-3", "kserve", "factual-error", "rejected", []string{"3.5"}),
			mkProposal("p-4", "kserve", "version-correction", "pending", nil),
		},
	}

	r, err := GenerateCorrectionFrequencyReport(ps, "")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if r.Summary.ActiveProposals != 4 {
		t.Errorf("expected 4 active, got %d", r.Summary.ActiveProposals)
	}
	if r.Summary.Components != 2 {
		t.Errorf("expected 2 components, got %d", r.Summary.Components)
	}

	// Both components have 2 proposals each, so sorted alphabetically
	if len(r.ByComponent) != 2 {
		t.Fatalf("expected 2 components, got %d", len(r.ByComponent))
	}
	if r.ByComponent[0].Component != "kserve" {
		t.Errorf("expected kserve first (alphabetical tiebreak), got %s", r.ByComponent[0].Component)
	}
	if r.ByComponent[0].Total != 2 {
		t.Errorf("expected kserve total=2, got %d", r.ByComponent[0].Total)
	}

	if len(r.ByStatus) != 3 {
		t.Fatalf("expected 3 statuses, got %d", len(r.ByStatus))
	}

	if len(r.ByCategory) != 3 {
		t.Fatalf("expected 3 categories, got %d", len(r.ByCategory))
	}
	// version-correction has 2 occurrences, others have 1
	if r.ByCategory[0].Category != "version-correction" || r.ByCategory[0].Total != 2 {
		t.Errorf("expected version-correction with total 2 first, got %s/%d",
			r.ByCategory[0].Category, r.ByCategory[0].Total)
	}
}

func TestGenerateReport_SupersededExcluded(t *testing.T) {
	ps := &types.ProposalSet{
		ContractVersion: "v1",
		GeneratedAt:     "2026-07-01T00:00:00Z",
		Proposals: []types.CorrectionProposal{
			mkProposal("p-1", "notebooks", "version-correction", "pending", []string{"3.4"}),
			mkProposal("p-2", "notebooks", "version-correction", "superseded", []string{"3.4"}),
			mkProposal("p-3", "kserve", "scope-correction", "reviewed", nil),
		},
	}

	r, err := GenerateCorrectionFrequencyReport(ps, "")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if r.Summary.ActiveProposals != 2 {
		t.Errorf("expected 2 active proposals (superseded excluded), got %d", r.Summary.ActiveProposals)
	}
	if r.SupersededCount != 1 {
		t.Errorf("expected 1 superseded, got %d", r.SupersededCount)
	}
	if r.InputIdentity.TotalProposals != 3 {
		t.Errorf("expected total=3 (including superseded), got %d", r.InputIdentity.TotalProposals)
	}

	for _, c := range r.ByComponent {
		if c.Component == "notebooks" && c.Total != 1 {
			t.Errorf("expected notebooks active count=1, got %d", c.Total)
		}
	}

	for _, s := range r.ByStatus {
		if s.Status == "superseded" {
			t.Error("superseded should not appear in by_status counts")
		}
	}
}

func TestGenerateReport_DeterministicOutput(t *testing.T) {
	ps := &types.ProposalSet{
		ContractVersion: "v1",
		GeneratedAt:     "2026-07-01T00:00:00Z",
		Proposals: []types.CorrectionProposal{
			mkProposal("p-3", "zeta", "factual-error", "pending", []string{"3.5"}),
			mkProposal("p-1", "alpha", "version-correction", "reviewed", []string{"3.4"}),
			mkProposal("p-2", "alpha", "scope-correction", "pending", []string{"3.4", "3.5"}),
		},
	}

	r1, err := GenerateCorrectionFrequencyReport(ps, "2026-07-24T00:00:00Z")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	r2, err := GenerateCorrectionFrequencyReport(ps, "2026-07-24T00:00:00Z")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	j1, _ := json.Marshal(r1)
	j2, _ := json.Marshal(r2)
	if string(j1) != string(j2) {
		t.Fatalf("non-deterministic output:\n  first:  %s\n  second: %s", j1, j2)
	}
}

func TestGenerateReport_InputIdentityPreserved(t *testing.T) {
	ps := &types.ProposalSet{
		ContractVersion: "v1",
		GeneratedAt:     "2026-07-20T10:00:00Z",
		Proposals: []types.CorrectionProposal{
			mkProposal("p-1", "comp", "version-correction", "pending", nil),
		},
	}

	r, err := GenerateCorrectionFrequencyReport(ps, "2026-07-24T12:00:00Z")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if r.InputIdentity.ProposalContractVersion != "v1" {
		t.Errorf("expected proposal contract v1, got %s", r.InputIdentity.ProposalContractVersion)
	}
	if r.InputIdentity.ProposalGeneratedAt != "2026-07-20T10:00:00Z" {
		t.Errorf("expected proposal generated_at preserved, got %s", r.InputIdentity.ProposalGeneratedAt)
	}
	if r.GeneratedAt != "2026-07-24T12:00:00Z" {
		t.Errorf("expected report generated_at, got %s", r.GeneratedAt)
	}
}

func TestGenerateReport_ReleaseAggregation(t *testing.T) {
	ps := &types.ProposalSet{
		ContractVersion: "v1",
		Proposals: []types.CorrectionProposal{
			mkProposal("p-1", "comp-a", "version-correction", "pending", []string{"3.4", "3.5"}),
			mkProposal("p-2", "comp-b", "scope-correction", "reviewed", []string{"3.4"}),
			mkProposal("p-3", "comp-c", "factual-error", "pending", nil),
		},
	}

	r, err := GenerateCorrectionFrequencyReport(ps, "")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if r.Summary.Releases != 2 {
		t.Errorf("expected 2 releases, got %d", r.Summary.Releases)
	}

	releaseMap := make(map[string]int)
	for _, rl := range r.ByRelease {
		releaseMap[rl.Release] = rl.Total
	}
	if releaseMap["3.4"] != 2 {
		t.Errorf("expected release 3.4 count=2, got %d", releaseMap["3.4"])
	}
	if releaseMap["3.5"] != 1 {
		t.Errorf("expected release 3.5 count=1, got %d", releaseMap["3.5"])
	}
}

func TestGenerateReport_ComponentStatusBreakdown(t *testing.T) {
	ps := &types.ProposalSet{
		ContractVersion: "v1",
		Proposals: []types.CorrectionProposal{
			mkProposal("p-1", "notebooks", "version-correction", "pending", nil),
			mkProposal("p-2", "notebooks", "scope-correction", "reviewed", nil),
			mkProposal("p-3", "notebooks", "factual-error", "rejected", nil),
		},
	}

	r, err := GenerateCorrectionFrequencyReport(ps, "")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(r.ByComponent) != 1 {
		t.Fatalf("expected 1 component, got %d", len(r.ByComponent))
	}
	c := r.ByComponent[0]
	if c.ByStatus["pending"] != 1 || c.ByStatus["reviewed"] != 1 || c.ByStatus["rejected"] != 1 {
		t.Errorf("expected 1/1/1 status breakdown, got %v", c.ByStatus)
	}
}

func TestFormatReportText_NonEmpty(t *testing.T) {
	ps := &types.ProposalSet{
		ContractVersion: "v1",
		GeneratedAt:     "2026-07-01T00:00:00Z",
		Proposals: []types.CorrectionProposal{
			mkProposal("p-1", "notebooks", "version-correction", "pending", []string{"3.4"}),
			mkProposal("p-2", "kserve", "scope-correction", "reviewed", nil),
		},
	}

	r, err := GenerateCorrectionFrequencyReport(ps, "")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	var buf bytes.Buffer
	FormatReportText(&buf, r)
	text := buf.String()

	for _, want := range []string{
		"Correction Frequency Report",
		"2 proposals",
		"2 active",
		"By Component:",
		"notebooks",
		"kserve",
		"By Category:",
		"By Status:",
	} {
		if !contains(text, want) {
			t.Errorf("text output missing %q:\n%s", want, text)
		}
	}
}

func TestFormatReportText_Empty(t *testing.T) {
	ps := &types.ProposalSet{
		ContractVersion: "v1",
		Proposals:       []types.CorrectionProposal{},
	}

	r, err := GenerateCorrectionFrequencyReport(ps, "")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	var buf bytes.Buffer
	FormatReportText(&buf, r)
	text := buf.String()

	if !contains(text, "0 proposals") {
		t.Errorf("expected '0 proposals' in output, got:\n%s", text)
	}
}

func TestGenerateReport_JSONRoundTrip(t *testing.T) {
	ps := &types.ProposalSet{
		ContractVersion: "v1",
		GeneratedAt:     "2026-07-01T00:00:00Z",
		Proposals: []types.CorrectionProposal{
			mkProposal("p-1", "notebooks", "version-correction", "pending", []string{"3.4"}),
		},
	}

	r, err := GenerateCorrectionFrequencyReport(ps, "2026-07-24T00:00:00Z")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	data, err := json.Marshal(r)
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}

	var r2 types.CorrectionFrequencyReport
	if err := json.Unmarshal(data, &r2); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}

	if r2.ContractVersion != r.ContractVersion {
		t.Errorf("contract_version mismatch")
	}
	if r2.Summary.ActiveProposals != r.Summary.ActiveProposals {
		t.Errorf("active proposals mismatch")
	}
	if r2.InputIdentity.TotalProposals != r.InputIdentity.TotalProposals {
		t.Errorf("total proposals mismatch")
	}
}

func TestGenerateReport_ComponentSortedByCountThenAlpha(t *testing.T) {
	ps := &types.ProposalSet{
		ContractVersion: "v1",
		Proposals: []types.CorrectionProposal{
			mkProposal("p-1", "zeta", "version-correction", "pending", nil),
			mkProposal("p-2", "zeta", "scope-correction", "pending", nil),
			mkProposal("p-3", "zeta", "factual-error", "pending", nil),
			mkProposal("p-4", "alpha", "version-correction", "pending", nil),
			mkProposal("p-5", "alpha", "scope-correction", "pending", nil),
			mkProposal("p-6", "middle", "version-correction", "pending", nil),
		},
	}

	r, err := GenerateCorrectionFrequencyReport(ps, "")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(r.ByComponent) != 3 {
		t.Fatalf("expected 3 components, got %d", len(r.ByComponent))
	}
	// zeta=3, alpha=2, middle=1
	if r.ByComponent[0].Component != "zeta" || r.ByComponent[0].Total != 3 {
		t.Errorf("expected zeta/3 first, got %s/%d", r.ByComponent[0].Component, r.ByComponent[0].Total)
	}
	if r.ByComponent[1].Component != "alpha" || r.ByComponent[1].Total != 2 {
		t.Errorf("expected alpha/2 second, got %s/%d", r.ByComponent[1].Component, r.ByComponent[1].Total)
	}
	if r.ByComponent[2].Component != "middle" || r.ByComponent[2].Total != 1 {
		t.Errorf("expected middle/1 third, got %s/%d", r.ByComponent[2].Component, r.ByComponent[2].Total)
	}
}

func TestTestdataReportGolden(t *testing.T) {
	goldenFiles := []struct {
		input  string
		golden string
	}{
		{"testdata/report-input-mixed.json", "testdata/report-output-mixed.json"},
		{"testdata/report-input-empty.json", "testdata/report-output-empty.json"},
	}

	for _, tc := range goldenFiles {
		t.Run(tc.input, func(t *testing.T) {
			inputData, err := os.ReadFile(tc.input)
			if err != nil {
				t.Fatalf("reading input %s: %v", tc.input, err)
			}

			var ps types.ProposalSet
			if err := json.Unmarshal(inputData, &ps); err != nil {
				t.Fatalf("parsing input: %v", err)
			}

			report, err := GenerateCorrectionFrequencyReport(&ps, "2026-07-24T00:00:00Z")
			if err != nil {
				t.Fatalf("generating report: %v", err)
			}

			actualJSON, err := json.MarshalIndent(report, "", "  ")
			if err != nil {
				t.Fatalf("marshalling report: %v", err)
			}

			goldenData, err := os.ReadFile(tc.golden)
			if err != nil {
				t.Fatalf("reading golden %s: %v", tc.golden, err)
			}

			if string(actualJSON)+"\n" != string(goldenData) {
				t.Errorf("output does not match golden file %s.\nGot:\n%s\nWant:\n%s",
					tc.golden, actualJSON, goldenData)
			}
		})
	}
}
