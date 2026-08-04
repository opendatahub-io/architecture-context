package proposal

import (
	"encoding/json"
	"strings"
	"testing"
)

const testAuthor = "test-harvester"
const testDate = "2026-07-24"

func TestHarvestFiltersSMEInput(t *testing.T) {
	input := `
- jira_key: TEST-1
  summary: sme record
  correction_types:
  - scope_correction
  sme_content: "Fix the scope"
  human_review: true
  human_review_type: sme_input
  components:
  - name: Dashboard
    id: "1"
- jira_key: TEST-2
  summary: reprocess record
  correction_types:
  - scope_correction
  sme_content: "Reprocess this"
  human_review: true
  human_review_type: reprocess_with_input
  components:
  - name: Dashboard
    id: "2"
`
	result, err := Harvest(strings.NewReader(input), "test.yaml", testAuthor, testDate)
	if err != nil {
		t.Fatal(err)
	}
	if result.TotalRecords != 2 {
		t.Errorf("TotalRecords = %d, want 2", result.TotalRecords)
	}
	if result.FilteredRecords != 1 {
		t.Errorf("FilteredRecords = %d, want 1", result.FilteredRecords)
	}
	if len(result.Proposals) != 1 {
		t.Fatalf("len(Proposals) = %d, want 1", len(result.Proposals))
	}
	hasJira := false
	for _, s := range result.Proposals[0].Provenance {
		if s == "jira:TEST-1" {
			hasJira = true
		}
	}
	if !hasJira {
		t.Errorf("Provenance missing jira:TEST-1, got %v", result.Proposals[0].Provenance)
	}
}

func TestHarvestEmptySMEContentSkipped(t *testing.T) {
	input := `
- jira_key: TEST-3
  summary: empty content
  correction_types:
  - scope_correction
  sme_content: "   "
  human_review: true
  human_review_type: sme_input
  components:
  - name: Dashboard
    id: "1"
`
	result, err := Harvest(strings.NewReader(input), "test.yaml", testAuthor, testDate)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Proposals) != 0 {
		t.Errorf("expected no proposals for whitespace-only content, got %d", len(result.Proposals))
	}
	if result.SkippedReasons["empty_sme_content"] != 1 {
		t.Errorf("SkippedReasons[empty_sme_content] = %d, want 1", result.SkippedReasons["empty_sme_content"])
	}
}

func TestHarvestMissingComponentsSkipped(t *testing.T) {
	input := `
- jira_key: TEST-4
  summary: no components
  correction_types:
  - scope_correction
  sme_content: "Valid content"
  human_review: true
  human_review_type: sme_input
  components: []
`
	result, err := Harvest(strings.NewReader(input), "test.yaml", testAuthor, testDate)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Proposals) != 0 {
		t.Errorf("expected no proposals for missing components, got %d", len(result.Proposals))
	}
	if result.SkippedReasons["no_components"] != 1 {
		t.Errorf("SkippedReasons[no_components] = %d, want 1", result.SkippedReasons["no_components"])
	}
}

func TestHarvestMultipleComponentsAndTypes(t *testing.T) {
	input := `
- jira_key: TEST-5
  summary: multi
  correction_types:
  - scope_correction
  - team_ownership
  - maturity_correction
  sme_content: "Multi correction"
  human_review: true
  human_review_type: sme_input
  components:
  - name: AI Core Dashboard
    id: "79990"
  - name: Notebooks Images
    id: "80059"
`
	result, err := Harvest(strings.NewReader(input), "test.yaml", testAuthor, testDate)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Proposals) != 6 {
		t.Fatalf("len(Proposals) = %d, want 6", len(result.Proposals))
	}

	components := map[string]int{}
	categories := map[string]int{}
	for _, p := range result.Proposals {
		components[p.Component]++
		categories[p.Category]++
	}
	if components["AI Core Dashboard"] != 3 {
		t.Errorf("AI Core Dashboard proposals = %d, want 3", components["AI Core Dashboard"])
	}
	if components["Notebooks Images"] != 3 {
		t.Errorf("Notebooks Images proposals = %d, want 3", components["Notebooks Images"])
	}
	if categories[CategoryScopeCorrection] != 2 {
		t.Errorf("scope-correction proposals = %d, want 2", categories[CategoryScopeCorrection])
	}
	if categories[CategoryOwnershipCorrection] != 2 {
		t.Errorf("ownership-correction proposals = %d, want 2", categories[CategoryOwnershipCorrection])
	}
	if categories[CategoryMaturityCorrection] != 2 {
		t.Errorf("maturity-correction proposals = %d, want 2", categories[CategoryMaturityCorrection])
	}
}

func TestHarvestUnsupportedCorrectionType(t *testing.T) {
	input := `
- jira_key: TEST-6
  summary: unsupported type
  correction_types:
  - made_up_type
  sme_content: "Content"
  human_review: true
  human_review_type: sme_input
  components:
  - name: Dashboard
    id: "1"
`
	result, err := Harvest(strings.NewReader(input), "test.yaml", testAuthor, testDate)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Proposals) != 1 {
		t.Fatalf("len(Proposals) = %d, want 1", len(result.Proposals))
	}
	if result.Proposals[0].Category != CategoryUnknown {
		t.Errorf("Category = %q, want %q", result.Proposals[0].Category, CategoryUnknown)
	}
}

func TestHarvestComponentNameVerbatim(t *testing.T) {
	input := `
- jira_key: TEST-7
  summary: verbatim name
  correction_types:
  - scope_correction
  sme_content: "Content"
  human_review: true
  human_review_type: sme_input
  components:
  - name: "AI Core Dashboard"
    id: "79990"
  - name: "Notebooks Images"
    id: "80059"
`
	result, err := Harvest(strings.NewReader(input), "test.yaml", testAuthor, testDate)
	if err != nil {
		t.Fatal(err)
	}
	names := map[string]bool{}
	for _, p := range result.Proposals {
		names[p.Component] = true
	}
	if !names["AI Core Dashboard"] {
		t.Error("expected verbatim component name 'AI Core Dashboard'")
	}
	if !names["Notebooks Images"] {
		t.Error("expected verbatim component name 'Notebooks Images'")
	}
}

func TestHarvestMultilineContent(t *testing.T) {
	input := `
- jira_key: TEST-8
  summary: multiline
  correction_types:
  - scope_correction
  sme_content: |
    Line one.
    Line two.
    Line three.
  human_review: true
  human_review_type: sme_input
  components:
  - name: Dashboard
    id: "1"
`
	result, err := Harvest(strings.NewReader(input), "test.yaml", testAuthor, testDate)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Proposals) != 1 {
		t.Fatalf("len(Proposals) = %d, want 1", len(result.Proposals))
	}
	if !strings.Contains(result.Proposals[0].Claim, "Line one.") {
		t.Error("multiline content not preserved")
	}
	if !strings.Contains(result.Proposals[0].Claim, "Line three.") {
		t.Error("multiline content truncated")
	}
}

func TestHarvestProvenance(t *testing.T) {
	input := `
- jira_key: RHAISTRAT-100
  summary: provenance test
  correction_types:
  - architecture_constraint
  sme_content: "Architecture correction"
  human_review: true
  human_review_type: sme_input
  components:
  - name: Dashboard
    id: "1"
`
	sourcePath := "tmp/feedback-data/corpus/extraction/staff-corrections.yaml"
	result, err := Harvest(strings.NewReader(input), sourcePath, testAuthor, testDate)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Proposals) != 1 {
		t.Fatalf("len(Proposals) = %d, want 1", len(result.Proposals))
	}
	p := result.Proposals[0]
	wantProv := []string{
		"source:" + sourcePath,
		"record:0",
	}
	for _, want := range wantProv {
		found := false
		for _, got := range p.Provenance {
			if got == want {
				found = true
				break
			}
		}
		if !found {
			t.Errorf("Provenance missing %q, got %v", want, p.Provenance)
		}
	}
	hasJira := false
	for _, s := range p.Provenance {
		if s == "jira:RHAISTRAT-100" {
			hasJira = true
		}
	}
	if !hasJira {
		t.Errorf("Provenance missing jira:RHAISTRAT-100, got %v", p.Provenance)
	}
	hasLine := false
	for _, s := range p.Provenance {
		if strings.HasPrefix(s, "yaml-line:") {
			hasLine = true
		}
	}
	if !hasLine {
		t.Errorf("Provenance missing yaml-line entry, got %v", p.Provenance)
	}
}

func TestHarvestAuthorAndDate(t *testing.T) {
	input := `
- jira_key: TEST-AD
  summary: author date test
  correction_types:
  - scope_correction
  sme_content: "Content"
  human_review: true
  human_review_type: sme_input
  components:
  - name: Dashboard
    id: "1"
`
	result, err := Harvest(strings.NewReader(input), "test.yaml", "Jane Doe", "2026-05-01")
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Proposals) != 1 {
		t.Fatalf("len(Proposals) = %d, want 1", len(result.Proposals))
	}
	p := result.Proposals[0]
	if p.Author != "Jane Doe" {
		t.Errorf("Author = %q, want %q", p.Author, "Jane Doe")
	}
	if p.CreatedDate != "2026-05-01" {
		t.Errorf("CreatedDate = %q, want %q", p.CreatedDate, "2026-05-01")
	}
}

func TestHarvestDeterministicOrdering(t *testing.T) {
	input := `
- jira_key: B-2
  summary: second
  correction_types:
  - scope_correction
  sme_content: "B"
  human_review: true
  human_review_type: sme_input
  components:
  - name: Zebra
    id: "2"
- jira_key: A-1
  summary: first
  correction_types:
  - scope_correction
  sme_content: "A"
  human_review: true
  human_review_type: sme_input
  components:
  - name: Alpha
    id: "1"
`
	r1, err := Harvest(strings.NewReader(input), "test.yaml", testAuthor, testDate)
	if err != nil {
		t.Fatal(err)
	}
	r2, err := Harvest(strings.NewReader(input), "test.yaml", testAuthor, testDate)
	if err != nil {
		t.Fatal(err)
	}
	if len(r1.Proposals) != len(r2.Proposals) {
		t.Fatal("different proposal counts")
	}
	for i := range r1.Proposals {
		if r1.Proposals[i].ID != r2.Proposals[i].ID {
			t.Errorf("proposal[%d] ID mismatch: %q vs %q", i, r1.Proposals[i].ID, r2.Proposals[i].ID)
		}
	}
	for i := 1; i < len(r1.Proposals); i++ {
		if r1.Proposals[i].ID < r1.Proposals[i-1].ID {
			t.Errorf("proposals not sorted: [%d].ID=%q < [%d].ID=%q",
				i, r1.Proposals[i].ID, i-1, r1.Proposals[i-1].ID)
		}
	}
}

func TestHarvestDuplicateIDsDeduped(t *testing.T) {
	input := `
- jira_key: DUP-1
  summary: first
  correction_types:
  - scope_correction
  sme_content: "Content A"
  human_review: true
  human_review_type: sme_input
  components:
  - name: Dashboard
    id: "1"
- jira_key: DUP-1
  summary: duplicate
  correction_types:
  - scope_correction
  sme_content: "Content B"
  human_review: true
  human_review_type: sme_input
  components:
  - name: Dashboard
    id: "1"
`
	result, err := Harvest(strings.NewReader(input), "test.yaml", testAuthor, testDate)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Proposals) != 1 {
		t.Errorf("len(Proposals) = %d, want 1 (duplicate should be deduped)", len(result.Proposals))
	}
	if result.SkippedReasons["duplicate_id"] != 1 {
		t.Errorf("SkippedReasons[duplicate_id] = %d, want 1", result.SkippedReasons["duplicate_id"])
	}
}

func TestHarvestProposalStatus(t *testing.T) {
	input := `
- jira_key: TEST-S
  summary: status test
  correction_types:
  - scope_correction
  sme_content: "Content"
  human_review: true
  human_review_type: sme_input
  components:
  - name: Dashboard
    id: "1"
`
	result, err := Harvest(strings.NewReader(input), "test.yaml", testAuthor, testDate)
	if err != nil {
		t.Fatal(err)
	}
	for _, p := range result.Proposals {
		if p.Status != "pending" {
			t.Errorf("Status = %q, want %q", p.Status, "pending")
		}
		if p.ContractVersion != ProposalContractVersion {
			t.Errorf("ContractVersion = %q, want %q", p.ContractVersion, ProposalContractVersion)
		}
	}
}

func TestHarvestNoCorrectionTypes(t *testing.T) {
	input := `
- jira_key: TEST-NC
  summary: no correction types
  correction_types: []
  sme_content: "Content"
  human_review: true
  human_review_type: sme_input
  components:
  - name: Dashboard
    id: "1"
`
	result, err := Harvest(strings.NewReader(input), "test.yaml", testAuthor, testDate)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Proposals) != 0 {
		t.Errorf("expected no proposals for empty correction_types, got %d", len(result.Proposals))
	}
}

func TestCorrectionTypeMappingComplete(t *testing.T) {
	known := []struct {
		source   string
		expected ProposalCategory
	}{
		{"scope_correction", CategoryScopeCorrection},
		{"component_scope", CategoryScopeCorrection},
		{"architecture_constraint", CategoryArchitectureUpdate},
		{"team_ownership", CategoryOwnershipCorrection},
		{"maturity_correction", CategoryMaturityCorrection},
		{"upstream_correction", CategoryDependencyCorrection},
		{"priority_correction", CategoryUnknown},
		{"general_refinement", CategoryUnknown},
	}
	for _, tc := range known {
		got := MapCorrectionType(tc.source)
		if got != tc.expected {
			t.Errorf("MapCorrectionType(%q) = %q, want %q", tc.source, got, tc.expected)
		}
	}

	got := MapCorrectionType("invented_type")
	if got != CategoryUnknown {
		t.Errorf("MapCorrectionType(invented_type) = %q, want %q", got, CategoryUnknown)
	}
}

func TestToProposalSet(t *testing.T) {
	result := &HarvestResult{
		Proposals: []Proposal{
			{ID: "prop-abc", Component: "X", Status: "pending"},
		},
		TotalRecords:    5,
		FilteredRecords: 1,
	}
	ps := result.ToProposalSet("2026-07-24T00:00:00Z")
	if ps.ContractVersion != ProposalContractVersion {
		t.Errorf("ContractVersion = %q", ps.ContractVersion)
	}
	if ps.GeneratedAt != "2026-07-24T00:00:00Z" {
		t.Errorf("GeneratedAt = %q", ps.GeneratedAt)
	}
	if len(ps.Proposals) != 1 {
		t.Errorf("len(Proposals) = %d", len(ps.Proposals))
	}
}

func TestToProposalSetNilProposals(t *testing.T) {
	result := &HarvestResult{TotalRecords: 0}
	ps := result.ToProposalSet("")
	if ps.Proposals == nil {
		t.Error("Proposals should be empty slice, not nil")
	}
}

func TestEncodeProposalSet(t *testing.T) {
	ps := ProposalSet{
		ContractVersion: ProposalContractVersion,
		GeneratedAt:     "2026-07-24T00:00:00Z",
		Proposals: []Proposal{
			{
				ContractVersion: ProposalContractVersion,
				ID:              "prop-123",
				Component:       "Dashboard",
				Category:        CategoryScopeCorrection,
				Status:          "pending",
				Claim:           "Fix scope",
				Provenance:      []string{"source:test.yaml", "record:0", "yaml-line:1", "jira:TEST-1"},
				Author:          testAuthor,
				CreatedDate:     testDate,
			},
		},
	}
	data, err := EncodeProposalSet(ps)
	if err != nil {
		t.Fatal(err)
	}
	out := string(data)
	if !strings.Contains(out, `"contract_version": "v1"`) {
		t.Error("missing contract_version in output")
	}
	if !strings.Contains(out, `"status": "pending"`) {
		t.Error("missing pending status in output")
	}
	if !strings.Contains(out, `"jira:TEST-1"`) {
		t.Error("missing jira provenance in output")
	}
	if !strings.Contains(out, `"author": "test-harvester"`) {
		t.Error("missing author in output")
	}
	if !strings.Contains(out, `"created_date": "2026-07-24"`) {
		t.Error("missing created_date in output")
	}
}

func TestHarvestCategoryValues(t *testing.T) {
	validCategories := map[string]bool{
		"scope-correction":      true,
		"ownership-correction":  true,
		"maturity-correction":   true,
		"dependency-correction": true,
		"architecture-update":   true,
		"unknown":               true,
	}
	for _, cat := range CorrectionTypeMapping {
		if !validCategories[cat] {
			t.Errorf("CorrectionTypeMapping emits invalid category %q", cat)
		}
	}
}

func TestHarvestOutputMatchesArchQueryContract(t *testing.T) {
	input := `
- jira_key: CONTRACT-1
  summary: contract test
  correction_types:
  - scope_correction
  - upstream_correction
  sme_content: "This is the claim text"
  human_review: true
  human_review_type: sme_input
  components:
  - name: notebooks
    id: "1"
`
	result, err := Harvest(strings.NewReader(input), "staff-corrections.yaml", "Ana Biazetti", "2026-07-24")
	if err != nil {
		t.Fatal(err)
	}
	ps := result.ToProposalSet("2026-07-24T00:00:00Z")
	data, err := EncodeProposalSet(ps)
	if err != nil {
		t.Fatal(err)
	}

	// Parse back as generic JSON to verify field names match arch-query contract
	var raw map[string]interface{}
	if err := json.Unmarshal(data, &raw); err != nil {
		t.Fatal(err)
	}
	if raw["contract_version"] != "v1" {
		t.Errorf("top-level contract_version = %v, want v1", raw["contract_version"])
	}
	if raw["generated_at"] != "2026-07-24T00:00:00Z" {
		t.Errorf("generated_at = %v", raw["generated_at"])
	}

	proposals, ok := raw["proposals"].([]interface{})
	if !ok {
		t.Fatal("proposals is not an array")
	}
	if len(proposals) != 2 {
		t.Fatalf("expected 2 proposals, got %d", len(proposals))
	}

	requiredFields := []string{
		"contract_version", "id", "component", "category",
		"status", "claim", "provenance", "author", "created_date",
	}
	for i, prop := range proposals {
		pm, ok := prop.(map[string]interface{})
		if !ok {
			t.Fatalf("proposal[%d] is not an object", i)
		}
		for _, field := range requiredFields {
			if _, exists := pm[field]; !exists {
				t.Errorf("proposal[%d] missing required field %q", i, field)
			}
		}
		if pm["status"] != "pending" {
			t.Errorf("proposal[%d] status = %v, want pending", i, pm["status"])
		}
		if pm["author"] != "Ana Biazetti" {
			t.Errorf("proposal[%d] author = %v", i, pm["author"])
		}
		prov, ok := pm["provenance"].([]interface{})
		if !ok || len(prov) == 0 {
			t.Errorf("proposal[%d] provenance should be a non-empty array", i)
		}

		// Verify no divergent structured provenance fields exist
		for _, banned := range []string{"source_path", "jira_key", "record_index", "yaml_line", "correction_type"} {
			if _, exists := pm[banned]; exists {
				t.Errorf("proposal[%d] has banned field %q", i, banned)
			}
		}
	}

	// Verify categories are in the expected set
	validCategories := map[string]bool{
		"scope-correction": true, "ownership-correction": true,
		"maturity-correction": true, "dependency-correction": true,
		"architecture-update": true, "unknown": true,
	}
	for i, prop := range proposals {
		pm := prop.(map[string]interface{})
		cat := pm["category"].(string)
		if !validCategories[cat] {
			t.Errorf("proposal[%d] category %q not in valid set", i, cat)
		}
	}
}

func TestHarvestProvenanceNoJiraKey(t *testing.T) {
	input := `
- jira_key: ""
  summary: no jira
  correction_types:
  - scope_correction
  sme_content: "Content"
  human_review: true
  human_review_type: sme_input
  components:
  - name: Dashboard
    id: "1"
`
	result, err := Harvest(strings.NewReader(input), "test.yaml", testAuthor, testDate)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Proposals) != 1 {
		t.Fatalf("len(Proposals) = %d, want 1", len(result.Proposals))
	}
	for _, s := range result.Proposals[0].Provenance {
		if strings.HasPrefix(s, "jira:") {
			t.Errorf("should not include empty jira provenance, got %q", s)
		}
	}
}
