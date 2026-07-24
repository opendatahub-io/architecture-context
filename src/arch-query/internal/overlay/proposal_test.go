package overlay

import (
	"encoding/json"
	"os"
	"testing"
	"testing/fstest"

	"github.com/jctanner/arch-query/internal/types"
)

func validProposal() types.CorrectionProposal {
	return types.CorrectionProposal{
		ContractVersion: "v1",
		ID:              "test-001",
		Component:       "notebooks",
		Category:        "version-correction",
		Status:          "reviewed",
		Claim:           "KFP SDK version should be 2.16, not 2.15",
		Replacement:     "2.16",
		Provenance:      []string{"https://github.com/example/pr/1007"},
		Author:          "Test Author",
		Releases:        []string{"3.4"},
		CreatedDate:     "2026-04-20",
		LastVerified:    "2026-05-01",
	}
}

func TestValidateProposal_Valid(t *testing.T) {
	p := validProposal()
	if err := ValidateProposal(&p); err != nil {
		t.Fatalf("expected valid proposal, got error: %v", err)
	}
}

func TestValidateProposal_ValidPending(t *testing.T) {
	p := validProposal()
	p.Status = "pending"
	p.LastVerified = ""
	if err := ValidateProposal(&p); err != nil {
		t.Fatalf("expected valid pending proposal, got error: %v", err)
	}
}

func TestValidateProposal_ValidUnknownCategory(t *testing.T) {
	p := validProposal()
	p.Category = "unknown"
	if err := ValidateProposal(&p); err != nil {
		t.Fatalf("expected unknown category to be valid, got error: %v", err)
	}
}

func TestValidateProposal_ValidNotExtractedCategory(t *testing.T) {
	p := validProposal()
	p.Category = "not-extracted"
	if err := ValidateProposal(&p); err != nil {
		t.Fatalf("expected not-extracted category to be valid, got error: %v", err)
	}
}

func TestValidateProposal_MissingID(t *testing.T) {
	p := validProposal()
	p.ID = ""
	err := ValidateProposal(&p)
	if err == nil {
		t.Fatal("expected error for missing ID")
	}
}

func TestValidateProposal_MissingComponent(t *testing.T) {
	p := validProposal()
	p.Component = ""
	err := ValidateProposal(&p)
	if err == nil {
		t.Fatal("expected error for missing component")
	}
}

func TestValidateProposal_InvalidCategory(t *testing.T) {
	p := validProposal()
	p.Category = "invented-category"
	err := ValidateProposal(&p)
	if err == nil {
		t.Fatal("expected error for invalid category")
	}
}

func TestValidateProposal_InvalidStatus(t *testing.T) {
	p := validProposal()
	p.Status = "approved"
	err := ValidateProposal(&p)
	if err == nil {
		t.Fatal("expected error for invalid status")
	}
}

func TestValidateProposal_MissingClaim(t *testing.T) {
	p := validProposal()
	p.Claim = ""
	err := ValidateProposal(&p)
	if err == nil {
		t.Fatal("expected error for missing claim")
	}
}

func TestValidateProposal_MissingProvenance(t *testing.T) {
	p := validProposal()
	p.Provenance = nil
	err := ValidateProposal(&p)
	if err == nil {
		t.Fatal("expected error for missing provenance")
	}
}

func TestValidateProposal_MissingAuthor(t *testing.T) {
	p := validProposal()
	p.Author = ""
	err := ValidateProposal(&p)
	if err == nil {
		t.Fatal("expected error for missing author")
	}
}

func TestValidateProposal_MissingCreatedDate(t *testing.T) {
	p := validProposal()
	p.CreatedDate = ""
	err := ValidateProposal(&p)
	if err == nil {
		t.Fatal("expected error for missing created_date")
	}
}

func TestValidateProposal_InvalidCreatedDate(t *testing.T) {
	p := validProposal()
	p.CreatedDate = "April 20 2026"
	err := ValidateProposal(&p)
	if err == nil {
		t.Fatal("expected error for invalid created_date format")
	}
}

func TestValidateProposal_InvalidLastVerified(t *testing.T) {
	p := validProposal()
	p.LastVerified = "not-a-date"
	err := ValidateProposal(&p)
	if err == nil {
		t.Fatal("expected error for invalid last_verified format")
	}
}

func TestValidateProposal_LastVerifiedBeforeCreated(t *testing.T) {
	p := validProposal()
	p.CreatedDate = "2026-05-01"
	p.LastVerified = "2026-04-01"
	err := ValidateProposal(&p)
	if err == nil {
		t.Fatal("expected error for last_verified before created_date")
	}
}

func TestValidateProposal_WrongContractVersion(t *testing.T) {
	p := validProposal()
	p.ContractVersion = "v99"
	err := ValidateProposal(&p)
	if err == nil {
		t.Fatal("expected error for wrong contract version")
	}
}

func TestValidateProposal_SupersededRequiresReference(t *testing.T) {
	p := validProposal()
	p.Status = "superseded"
	p.SupersededBy = ""
	err := ValidateProposal(&p)
	if err == nil {
		t.Fatal("expected error for superseded without superseded_by")
	}
}

func TestValidateProposal_SupersededWithReference(t *testing.T) {
	p := validProposal()
	p.Status = "superseded"
	p.SupersededBy = "test-002"
	if err := ValidateProposal(&p); err != nil {
		t.Fatalf("expected valid superseded proposal, got: %v", err)
	}
}

func TestValidateProposal_MultipleErrors(t *testing.T) {
	p := types.CorrectionProposal{
		ContractVersion: "v99",
	}
	err := ValidateProposal(&p)
	if err == nil {
		t.Fatal("expected multiple errors")
	}
	s := err.Error()
	for _, want := range []string{"contract_version", "id is required", "component is required", "claim is required", "author is required", "created_date is required"} {
		if !contains(s, want) {
			t.Errorf("expected error to contain %q, got: %s", want, s)
		}
	}
}

func TestValidateProposalSet_Valid(t *testing.T) {
	p := validProposal()
	ps := types.ProposalSet{
		ContractVersion: "v1",
		GeneratedAt:     "2026-05-01T00:00:00Z",
		Proposals:       []types.CorrectionProposal{p},
	}
	errs := ValidateProposalSet(&ps)
	if len(errs) > 0 {
		t.Fatalf("expected no errors, got %v", errs)
	}
}

func TestValidateProposalSet_DuplicateIDs(t *testing.T) {
	p1 := validProposal()
	p2 := validProposal()
	ps := types.ProposalSet{
		ContractVersion: "v1",
		Proposals:       []types.CorrectionProposal{p1, p2},
	}
	errs := ValidateProposalSet(&ps)
	found := false
	for _, e := range errs {
		if contains(e.Error(), "duplicate") {
			found = true
		}
	}
	if !found {
		t.Fatal("expected duplicate ID error")
	}
}

func TestValidateProposalSet_WrongVersion(t *testing.T) {
	ps := types.ProposalSet{
		ContractVersion: "v2",
		Proposals:       nil,
	}
	errs := ValidateProposalSet(&ps)
	if len(errs) == 0 {
		t.Fatal("expected version error")
	}
}

func TestValidateProposalSet_Empty(t *testing.T) {
	ps := types.ProposalSet{
		ContractVersion: "v1",
		Proposals:       []types.CorrectionProposal{},
	}
	errs := ValidateProposalSet(&ps)
	if len(errs) > 0 {
		t.Fatalf("expected empty proposal set to be valid, got %v", errs)
	}
}

func TestRoundTrip_ReviewedProposal(t *testing.T) {
	p := validProposal()
	data, err := json.Marshal(p)
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}
	var p2 types.CorrectionProposal
	if err := json.Unmarshal(data, &p2); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if p2.ID != p.ID || p2.Component != p.Component || p2.Category != p.Category ||
		p2.Status != p.Status || p2.Claim != p.Claim || p2.Replacement != p.Replacement ||
		p2.Author != p.Author || p2.CreatedDate != p.CreatedDate || p2.LastVerified != p.LastVerified ||
		p2.SupersededBy != p.SupersededBy || p2.Notes != p.Notes {
		t.Fatalf("round trip lost fields: got %+v", p2)
	}
	if len(p2.Provenance) != len(p.Provenance) {
		t.Fatalf("round trip lost provenance entries")
	}
	if len(p2.Releases) != len(p.Releases) {
		t.Fatalf("round trip lost releases entries")
	}
}

func TestRoundTrip_PendingProposal(t *testing.T) {
	p := validProposal()
	p.Status = "pending"
	p.LastVerified = ""
	p.Replacement = ""
	p.Notes = "needs SME review"
	data, err := json.Marshal(p)
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}
	var p2 types.CorrectionProposal
	if err := json.Unmarshal(data, &p2); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if p2.Status != "pending" || p2.Notes != "needs SME review" {
		t.Fatalf("round trip lost pending fields: got %+v", p2)
	}
	if p2.LastVerified != "" || p2.Replacement != "" {
		t.Fatal("round trip introduced empty fields")
	}
}

func TestRoundTrip_ProposalSet(t *testing.T) {
	ps := types.ProposalSet{
		ContractVersion: "v1",
		GeneratedAt:     "2026-05-01T00:00:00Z",
		Proposals:       []types.CorrectionProposal{validProposal()},
	}
	data, err := json.Marshal(ps)
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}
	var ps2 types.ProposalSet
	if err := json.Unmarshal(data, &ps2); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if ps2.ContractVersion != "v1" || ps2.GeneratedAt != ps.GeneratedAt || len(ps2.Proposals) != 1 {
		t.Fatalf("round trip lost set fields: got %+v", ps2)
	}
}

func TestGenerateProposalFromOverlay(t *testing.T) {
	o := &types.OverlayDoc{
		ID:         "0001",
		Title:      "Test overlay",
		Status:     "active",
		Created:    "2026-04-20",
		Affects:    []string{"notebooks", "platform"},
		Release:    []string{"3.4"},
		Provenance: []string{"https://example.com/pr/1"},
		Author:     "Jane Doe",
		Fact:       "SDK version is 2.16",
	}
	p := GenerateProposalFromOverlay(o)
	if p.ID != "proposal-0001" {
		t.Errorf("expected id proposal-0001, got %s", p.ID)
	}
	if p.Component != "notebooks" {
		t.Errorf("expected component notebooks, got %s", p.Component)
	}
	if p.Status != "pending" {
		t.Errorf("expected status pending, got %s", p.Status)
	}
	if p.Claim != "SDK version is 2.16" {
		t.Errorf("expected claim from Fact, got %s", p.Claim)
	}
	if p.ContractVersion != "v1" {
		t.Errorf("expected contract v1, got %s", p.ContractVersion)
	}
	if len(p.Releases) != 1 || p.Releases[0] != "3.4" {
		t.Errorf("expected releases [3.4], got %v", p.Releases)
	}
}

func TestGenerateProposalFromOverlay_NoFact(t *testing.T) {
	o := &types.OverlayDoc{
		ID:         "0099",
		Title:      "Missing fact overlay",
		Status:     "active",
		Affects:    []string{"kserve"},
		Provenance: []string{"manual"},
		Author:     "Author",
		Created:    "2026-06-01",
	}
	p := GenerateProposalFromOverlay(o)
	if p.Claim != "Missing fact overlay" {
		t.Errorf("expected claim to fall back to title, got %s", p.Claim)
	}
}

func TestGenerateProposalFromOverlay_MinimalOverlay(t *testing.T) {
	o := &types.OverlayDoc{
		ID:    "0100",
		Title: "Bare overlay",
	}
	p := GenerateProposalFromOverlay(o)
	if p.Author != "unknown" {
		t.Errorf("expected author fallback to unknown, got %s", p.Author)
	}
	if p.CreatedDate != "" {
		t.Errorf("expected empty created_date for missing source date, got %s", p.CreatedDate)
	}
	if len(p.Provenance) != 1 || p.Provenance[0] != "overlay:0100" {
		t.Errorf("expected provenance fallback, got %v", p.Provenance)
	}
}

func TestGenerateProposalSet_SkipsSuperseded(t *testing.T) {
	supersededBy := "0002"
	overlays := []*types.OverlayDoc{
		{
			ID:           "0001",
			Title:        "Superseded overlay",
			SupersededBy: &supersededBy,
			Affects:      []string{"comp-a"},
			Provenance:   []string{"test"},
			Author:       "Author",
			Created:      "2026-01-01",
		},
		{
			ID:         "0002",
			Title:      "Active overlay",
			Affects:    []string{"comp-b"},
			Provenance: []string{"test"},
			Author:     "Author",
			Created:    "2026-02-01",
			Fact:       "Some fact",
		},
	}
	ps := GenerateProposalSet(overlays, "2026-07-01T00:00:00Z")
	if len(ps.Proposals) != 1 {
		t.Fatalf("expected 1 proposal (superseded skipped), got %d", len(ps.Proposals))
	}
	if ps.Proposals[0].ID != "proposal-0002" {
		t.Errorf("expected proposal-0002, got %s", ps.Proposals[0].ID)
	}
}

func TestGenerateProposalSet_Empty(t *testing.T) {
	ps := GenerateProposalSet(nil, "2026-07-01T00:00:00Z")
	if ps.ContractVersion != "v1" {
		t.Errorf("expected v1, got %s", ps.ContractVersion)
	}
	if ps.Proposals == nil {
		t.Fatal("expected non-nil empty proposals slice")
	}
	if len(ps.Proposals) != 0 {
		t.Errorf("expected 0 proposals, got %d", len(ps.Proposals))
	}
}

func TestLoadProposals(t *testing.T) {
	ps := types.ProposalSet{
		ContractVersion: "v1",
		GeneratedAt:     "2026-07-01T00:00:00Z",
		Proposals:       []types.CorrectionProposal{validProposal()},
	}
	data, _ := json.Marshal(ps)
	fsys := fstest.MapFS{
		"proposals.json": &fstest.MapFile{Data: data},
	}
	loaded, err := LoadProposals(fsys)
	if err != nil {
		t.Fatalf("load: %v", err)
	}
	if loaded.ContractVersion != "v1" || len(loaded.Proposals) != 1 {
		t.Fatalf("loaded wrong data: %+v", loaded)
	}
}

func TestLoadProposals_Missing(t *testing.T) {
	fsys := fstest.MapFS{}
	_, err := LoadProposals(fsys)
	if err == nil {
		t.Fatal("expected error for missing file")
	}
}

func TestLoadProposals_InvalidJSON(t *testing.T) {
	fsys := fstest.MapFS{
		"proposals.json": &fstest.MapFile{Data: []byte("{bad json")},
	}
	_, err := LoadProposals(fsys)
	if err == nil {
		t.Fatal("expected error for invalid JSON")
	}
}

// Verify existing overlay loading still works alongside proposal code.
func TestOverlayParserCompatibility(t *testing.T) {
	overlay := `---
id: "0099"
title: Test overlay
status: active
created: 2026-06-01
affects:
  - notebooks
release:
  - "3.4"
provenance:
  - https://example.com
author: Tester
---

## Fact

Some fact here.

## Impact on Strategies

Some impact.

## Context

Some context.
`
	fsys := fstest.MapFS{
		"0099-test.md": &fstest.MapFile{Data: []byte(overlay)},
	}
	overlays, err := LoadOverlays(fsys)
	if err != nil {
		t.Fatalf("load: %v", err)
	}
	if len(overlays) != 1 {
		t.Fatalf("expected 1 overlay, got %d", len(overlays))
	}
	o := overlays[0]
	if o.ID != "0099" || o.Title != "Test overlay" || o.Fact != "Some fact here." {
		t.Errorf("overlay parsed wrong: %+v", o)
	}
}

func TestAllCategories(t *testing.T) {
	cats := ValidProposalCategories()
	if len(cats) == 0 {
		t.Fatal("expected categories")
	}
	for _, c := range cats {
		if !validProposalCategories[c] {
			t.Errorf("returned invalid category %q", c)
		}
	}
}

func TestAllStatuses(t *testing.T) {
	statuses := ValidProposalStatuses()
	if len(statuses) == 0 {
		t.Fatal("expected statuses")
	}
	for _, s := range statuses {
		if !validProposalStatuses[s] {
			t.Errorf("returned invalid status %q", s)
		}
	}
}

func TestTestdataValidFiles(t *testing.T) {
	validFiles := []string{
		"testdata/valid-reviewed.json",
		"testdata/valid-pending.json",
		"testdata/valid-unknown-category.json",
	}
	for _, path := range validFiles {
		t.Run(path, func(t *testing.T) {
			raw, readErr := os.ReadFile(path)
			if readErr != nil {
				t.Fatalf("reading %s: %v", path, readErr)
			}
			fsys := fstest.MapFS{
				"proposals.json": &fstest.MapFile{Data: raw},
			}
			loaded, loadErr := LoadProposals(fsys)
			if loadErr != nil {
				t.Fatalf("loading %s: %v", path, loadErr)
			}
			errs := ValidateProposalSet(loaded)
			if len(errs) > 0 {
				t.Fatalf("expected valid, got errors: %v", errs)
			}
		})
	}
}

func TestTestdataInvalidFiles(t *testing.T) {
	invalidFiles := []string{
		"testdata/invalid-missing-fields.json",
		"testdata/invalid-stale-dates.json",
	}
	for _, path := range invalidFiles {
		t.Run(path, func(t *testing.T) {
			raw, readErr := os.ReadFile(path)
			if readErr != nil {
				t.Fatalf("reading %s: %v", path, readErr)
			}
			fsys := fstest.MapFS{
				"proposals.json": &fstest.MapFile{Data: raw},
			}
			loaded, loadErr := LoadProposals(fsys)
			if loadErr != nil {
				t.Fatalf("loading %s: %v", path, loadErr)
			}
			errs := ValidateProposalSet(loaded)
			if len(errs) == 0 {
				t.Fatal("expected validation errors for invalid file")
			}
		})
	}
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(s) > 0 && containsHelper(s, substr))
}

func containsHelper(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}

func TestGenerateProposalSet_DeterministicOrdering(t *testing.T) {
	mkOverlay := func(id, title string) *types.OverlayDoc {
		return &types.OverlayDoc{
			ID:         id,
			Title:      title,
			Affects:    []string{"comp"},
			Provenance: []string{"test"},
			Author:     "A",
			Created:    "2026-01-01",
			Fact:       title,
		}
	}

	forward := []*types.OverlayDoc{
		mkOverlay("0003", "Third"),
		mkOverlay("0001", "First"),
		mkOverlay("0002", "Second"),
	}
	reverse := []*types.OverlayDoc{
		mkOverlay("0002", "Second"),
		mkOverlay("0001", "First"),
		mkOverlay("0003", "Third"),
	}

	psForward := GenerateProposalSet(forward, "2026-07-01T00:00:00Z")
	psReverse := GenerateProposalSet(reverse, "2026-07-01T00:00:00Z")

	if len(psForward.Proposals) != 3 || len(psReverse.Proposals) != 3 {
		t.Fatalf("expected 3 proposals each, got %d and %d", len(psForward.Proposals), len(psReverse.Proposals))
	}
	for i := range psForward.Proposals {
		if psForward.Proposals[i].ID != psReverse.Proposals[i].ID {
			t.Errorf("position %d: forward=%s reverse=%s", i, psForward.Proposals[i].ID, psReverse.Proposals[i].ID)
		}
	}
	if psForward.Proposals[0].ID != "proposal-0001" ||
		psForward.Proposals[1].ID != "proposal-0002" ||
		psForward.Proposals[2].ID != "proposal-0003" {
		t.Errorf("proposals not sorted by ID: %v", []string{
			psForward.Proposals[0].ID, psForward.Proposals[1].ID, psForward.Proposals[2].ID,
		})
	}
}

func TestGenerateProposalSet_RepeatedDeterministicGeneration(t *testing.T) {
	overlays := []*types.OverlayDoc{
		{
			ID: "0010", Title: "Alpha", Affects: []string{"x"},
			Provenance: []string{"p"}, Author: "A", Created: "2026-03-01", Fact: "alpha fact",
		},
		{
			ID: "0005", Title: "Beta", Affects: []string{"y"},
			Provenance: []string{"q"}, Author: "B", Created: "2026-02-01", Fact: "beta fact",
		},
	}

	ts := "2026-07-24T12:00:00Z"
	first, _ := json.Marshal(GenerateProposalSet(overlays, ts))
	second, _ := json.Marshal(GenerateProposalSet(overlays, ts))

	if string(first) != string(second) {
		t.Fatalf("repeated generation produced different output:\n  first:  %s\n  second: %s", first, second)
	}
}

func TestGenerateProposalSet_DefaultDeterminism(t *testing.T) {
	overlays := []*types.OverlayDoc{
		{
			ID: "0010", Title: "Alpha", Affects: []string{"x"},
			Provenance: []string{"p"}, Author: "A", Created: "2026-03-01", Fact: "alpha fact",
		},
	}

	first, _ := json.Marshal(GenerateProposalSet(overlays, ""))
	second, _ := json.Marshal(GenerateProposalSet(overlays, ""))

	if string(first) != string(second) {
		t.Fatalf("default (empty) generated_at produced different output:\n  first:  %s\n  second: %s", first, second)
	}

	var ps types.ProposalSet
	if err := json.Unmarshal(first, &ps); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if ps.GeneratedAt != "" {
		t.Errorf("expected empty generated_at by default, got %q", ps.GeneratedAt)
	}
}

func TestGenerateProposalFromOverlay_MissingDate_Representable(t *testing.T) {
	o := &types.OverlayDoc{
		ID:         "0200",
		Title:      "No date overlay",
		Affects:    []string{"comp"},
		Provenance: []string{"test"},
		Author:     "Author",
		Fact:       "Some fact",
	}
	p := GenerateProposalFromOverlay(o)

	if p.CreatedDate != "" {
		t.Errorf("expected empty created_date, got %q", p.CreatedDate)
	}

	data, err := json.Marshal(p)
	if err != nil {
		t.Fatalf("marshal failed: %v", err)
	}
	if contains(string(data), "created_date") {
		t.Errorf("expected created_date to be omitted from JSON, got: %s", data)
	}

	var p2 types.CorrectionProposal
	if err := json.Unmarshal(data, &p2); err != nil {
		t.Fatalf("unmarshal failed: %v", err)
	}
	if p2.CreatedDate != "" {
		t.Errorf("expected empty created_date after round-trip, got %q", p2.CreatedDate)
	}
}

func TestGenerateProposalFromOverlay_MissingDate_NotFalselyValid(t *testing.T) {
	o := &types.OverlayDoc{
		ID:         "0201",
		Title:      "No date overlay",
		Affects:    []string{"comp"},
		Provenance: []string{"test"},
		Author:     "Author",
		Fact:       "Some claim",
	}
	p := GenerateProposalFromOverlay(o)
	err := ValidateProposal(p)
	if err == nil {
		t.Fatal("expected validation error for missing created_date")
	}
	if !contains(err.Error(), "created_date") {
		t.Errorf("expected error about created_date, got: %v", err)
	}
}
