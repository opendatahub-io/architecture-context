package index

import (
	"encoding/json"
	"testing"

	"github.com/jctanner/arch-query/internal/types"
)

func TestGenerate_NilData(t *testing.T) {
	idx := Generate("v1", nil)
	if idx.FormatVersion != FormatVersion {
		t.Errorf("format_version = %q, want %q", idx.FormatVersion, FormatVersion)
	}
	if idx.Version != "v1" {
		t.Errorf("version = %q, want %q", idx.Version, "v1")
	}
	if len(idx.Components) != 0 {
		t.Errorf("components = %d, want 0", len(idx.Components))
	}
	if idx.CategoryMappings == nil {
		t.Fatal("category_mappings should be present even for nil data")
	}
}

func TestGenerate_EmptyComponents(t *testing.T) {
	data := &types.VersionData{
		Components: map[string]*types.ComponentDoc{},
	}
	idx := Generate("v1", data)
	if len(idx.Components) != 0 {
		t.Errorf("components = %d, want 0", len(idx.Components))
	}
}

func TestGenerate_DeterministicOrder(t *testing.T) {
	data := &types.VersionData{
		Components: map[string]*types.ComponentDoc{
			"zebra": {Purpose: "z-component"},
			"alpha": {Purpose: "a-component"},
			"mid":   {Purpose: "m-component"},
		},
	}

	for i := 0; i < 10; i++ {
		idx := Generate("v1", data)
		if len(idx.Components) != 3 {
			t.Fatalf("run %d: components = %d, want 3", i, len(idx.Components))
		}
		if idx.Components[0].Name != "alpha" {
			t.Errorf("run %d: first = %q, want alpha", i, idx.Components[0].Name)
		}
		if idx.Components[1].Name != "mid" {
			t.Errorf("run %d: second = %q, want mid", i, idx.Components[1].Name)
		}
		if idx.Components[2].Name != "zebra" {
			t.Errorf("run %d: third = %q, want zebra", i, idx.Components[2].Name)
		}
	}
}

func TestGenerate_SectionCounts(t *testing.T) {
	data := &types.VersionData{
		Version: types.VersionInfo{Path: "rhoai-3.5"},
		Components: map[string]*types.ComponentDoc{
			"comp": {
				FileName:   "comp.md",
				Purpose:    "test",
				DeployType: "operator",
				CRDs: []types.CRD{
					{Group: "g1", Version: "v1", Kind: "K1"},
					{Group: "g2", Version: "v1", Kind: "K2"},
				},
				Services: []types.Service{
					{Name: "svc1", Port: "8080"},
				},
				ExternalDeps: []types.Dependency{
					{Component: "dep1"},
				},
				CommitSHA:       "abc123",
				AnalyzerVersion: "1.0",
			},
		},
	}

	idx := Generate("v1", data)
	if len(idx.Components) != 1 {
		t.Fatalf("components = %d, want 1", len(idx.Components))
	}

	entry := idx.Components[0]
	if entry.Name != "comp" {
		t.Errorf("name = %q, want comp", entry.Name)
	}
	if entry.SourcePath != "rhoai-3.5/comp.md" {
		t.Errorf("source_path = %q, want rhoai-3.5/comp.md", entry.SourcePath)
	}
	if entry.Purpose != "test" {
		t.Errorf("purpose = %q, want test", entry.Purpose)
	}
	if entry.DeployType != "operator" {
		t.Errorf("deploy_type = %q, want operator", entry.DeployType)
	}

	if entry.Sections["crds"] != 2 {
		t.Errorf("crds = %d, want 2", entry.Sections["crds"])
	}
	if entry.Sections["services"] != 1 {
		t.Errorf("services = %d, want 1", entry.Sections["services"])
	}
	if entry.Sections["external_deps"] != 1 {
		t.Errorf("external_deps = %d, want 1", entry.Sections["external_deps"])
	}
	if _, ok := entry.Sections["endpoints"]; ok {
		t.Error("endpoints should not be present when empty")
	}

	if entry.Metadata["commit_sha"] != "abc123" {
		t.Errorf("commit_sha = %q, want abc123", entry.Metadata["commit_sha"])
	}
	if entry.Metadata["analyzer_version"] != "1.0" {
		t.Errorf("analyzer_version = %q, want 1.0", entry.Metadata["analyzer_version"])
	}
}

func TestGenerate_EmptySectionsOmitted(t *testing.T) {
	data := &types.VersionData{
		Components: map[string]*types.ComponentDoc{
			"bare": {Purpose: "minimal"},
		},
	}

	idx := Generate("v1", data)
	entry := idx.Components[0]
	if len(entry.Sections) != 0 {
		t.Errorf("sections = %d, want 0 for bare component", len(entry.Sections))
	}
	if entry.Metadata != nil {
		t.Error("metadata should be nil when commit_sha and analyzer_version are empty")
	}
}

func TestGenerate_JSONRoundTrip(t *testing.T) {
	data := &types.VersionData{
		Version: types.VersionInfo{Path: "odh-3.3"},
		Components: map[string]*types.ComponentDoc{
			"comp": {
				FileName: "comp.md",
				Purpose:  "test",
				CRDs:     []types.CRD{{Group: "g", Version: "v1", Kind: "K"}},
			},
		},
	}

	idx := Generate("v1", data)
	buf, err := json.Marshal(idx)
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}

	var parsed ContextIndex
	if err := json.Unmarshal(buf, &parsed); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if parsed.FormatVersion != FormatVersion {
		t.Errorf("roundtrip format_version = %q", parsed.FormatVersion)
	}
	if parsed.CategoryMappings == nil {
		t.Fatal("roundtrip category_mappings should not be nil")
	}
	if len(parsed.Components) != 1 {
		t.Fatalf("roundtrip components = %d", len(parsed.Components))
	}
	if parsed.Components[0].Sections["crds"] != 1 {
		t.Errorf("roundtrip crds = %d", parsed.Components[0].Sections["crds"])
	}
	if parsed.Components[0].SourcePath != "odh-3.3/comp.md" {
		t.Errorf("roundtrip source_path = %q, want odh-3.3/comp.md", parsed.Components[0].SourcePath)
	}
}

func TestGenerate_CategoryMappings(t *testing.T) {
	idx := Generate("v1", nil)

	required := []string{"api-surface", "deployment-model", "dependencies", "security", "purpose"}
	for _, cat := range required {
		sections, ok := idx.CategoryMappings[cat]
		if !ok {
			t.Errorf("missing required category %q", cat)
			continue
		}
		for i := 1; i < len(sections); i++ {
			if sections[i] < sections[i-1] {
				t.Errorf("category %q sections not sorted: %v", cat, sections)
				break
			}
		}
	}

	if len(idx.CategoryMappings["purpose"]) != 0 {
		t.Errorf("purpose mapping should be empty (answered by purpose field), got %v", idx.CategoryMappings["purpose"])
	}

	apiSections := idx.CategoryMappings["api-surface"]
	want := map[string]bool{"endpoints": true, "grpc_services": true, "crds": true}
	got := make(map[string]bool)
	for _, s := range apiSections {
		got[s] = true
	}
	for w := range want {
		if !got[w] {
			t.Errorf("api-surface missing section %q", w)
		}
	}
}

func TestGenerate_CategoryMappingsDeterministic(t *testing.T) {
	for i := 0; i < 10; i++ {
		idx := Generate("v1", nil)
		buf, err := json.Marshal(idx.CategoryMappings)
		if err != nil {
			t.Fatalf("run %d: marshal: %v", i, err)
		}
		if i == 0 {
			continue
		}
		idx2 := Generate("v1", nil)
		buf2, err := json.Marshal(idx2.CategoryMappings)
		if err != nil {
			t.Fatalf("run %d: marshal: %v", i, err)
		}
		if string(buf) != string(buf2) {
			t.Errorf("run %d: category_mappings not deterministic", i)
		}
	}
}

func TestGenerate_SourcePath(t *testing.T) {
	data := &types.VersionData{
		Version: types.VersionInfo{Path: "rhoai-3.5"},
		Components: map[string]*types.ComponentDoc{
			"kserve": {FileName: "kserve.md", Purpose: "serving"},
		},
	}
	idx := Generate("rhoai-3.5", data)
	if idx.Components[0].SourcePath != "rhoai-3.5/kserve.md" {
		t.Errorf("source_path = %q, want rhoai-3.5/kserve.md", idx.Components[0].SourcePath)
	}
}

func TestGenerate_SourcePathEmptyFileName(t *testing.T) {
	data := &types.VersionData{
		Version: types.VersionInfo{Path: "rhoai-3.5"},
		Components: map[string]*types.ComponentDoc{
			"bare": {Purpose: "minimal"},
		},
	}
	idx := Generate("rhoai-3.5", data)
	if idx.Components[0].SourcePath != "" {
		t.Errorf("source_path = %q, want empty for missing filename", idx.Components[0].SourcePath)
	}
}

func TestGenerate_SourcePathEmptyVersionPath(t *testing.T) {
	data := &types.VersionData{
		Components: map[string]*types.ComponentDoc{
			"comp": {FileName: "comp.md", Purpose: "test"},
		},
	}
	idx := Generate("v1", data)
	if idx.Components[0].SourcePath != "" {
		t.Errorf("source_path = %q, want empty for missing version path", idx.Components[0].SourcePath)
	}
}

func TestFormatVersion(t *testing.T) {
	if FormatVersion != "2" {
		t.Errorf("FormatVersion = %q, want 2", FormatVersion)
	}
}
