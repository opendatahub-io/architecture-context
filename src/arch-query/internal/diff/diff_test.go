package diff

import (
	"encoding/json"
	"testing"

	"github.com/jctanner/arch-query/internal/types"
)

func makeVersionData(components map[string]*types.ComponentDoc) *types.VersionData {
	return &types.VersionData{Components: components}
}

func TestCompute_BothNil(t *testing.T) {
	result := Compute("v1", "v2", nil, nil)
	if result.Status != "incompatible" {
		t.Errorf("status = %q, want incompatible", result.Status)
	}
	if result.FormatVersion != FormatVersion {
		t.Errorf("format_version = %q, want %q", result.FormatVersion, FormatVersion)
	}
}

func TestCompute_FromNil(t *testing.T) {
	to := makeVersionData(map[string]*types.ComponentDoc{
		"comp": {Purpose: "test"},
	})
	result := Compute("v1", "v2", nil, to)
	if result.Status != "not-extracted:from" {
		t.Errorf("status = %q, want not-extracted:from", result.Status)
	}
}

func TestCompute_ToNil(t *testing.T) {
	from := makeVersionData(map[string]*types.ComponentDoc{
		"comp": {Purpose: "test"},
	})
	result := Compute("v1", "v2", from, nil)
	if result.Status != "not-extracted:to" {
		t.Errorf("status = %q, want not-extracted:to", result.Status)
	}
}

func TestCompute_EmptyVersions(t *testing.T) {
	from := makeVersionData(map[string]*types.ComponentDoc{})
	to := makeVersionData(map[string]*types.ComponentDoc{})
	result := Compute("v1", "v2", from, to)
	if result.Status != "ok" {
		t.Errorf("status = %q, want ok", result.Status)
	}
	if len(result.Added) != 0 {
		t.Errorf("added = %d, want 0", len(result.Added))
	}
	if len(result.Removed) != 0 {
		t.Errorf("removed = %d, want 0", len(result.Removed))
	}
	if len(result.Changed) != 0 {
		t.Errorf("changed = %d, want 0", len(result.Changed))
	}
}

func TestCompute_AddedComponents(t *testing.T) {
	from := makeVersionData(map[string]*types.ComponentDoc{})
	to := makeVersionData(map[string]*types.ComponentDoc{
		"new-comp": {Purpose: "new"},
	})
	result := Compute("v1", "v2", from, to)
	if len(result.Added) != 1 || result.Added[0] != "new-comp" {
		t.Errorf("added = %v, want [new-comp]", result.Added)
	}
}

func TestCompute_RemovedComponents(t *testing.T) {
	from := makeVersionData(map[string]*types.ComponentDoc{
		"old-comp": {Purpose: "old"},
	})
	to := makeVersionData(map[string]*types.ComponentDoc{})
	result := Compute("v1", "v2", from, to)
	if len(result.Removed) != 1 || result.Removed[0] != "old-comp" {
		t.Errorf("removed = %v, want [old-comp]", result.Removed)
	}
}

func TestCompute_ChangedComponents(t *testing.T) {
	from := makeVersionData(map[string]*types.ComponentDoc{
		"comp": {
			CRDs: []types.CRD{
				{Group: "g1", Version: "v1", Kind: "K1"},
			},
		},
	})
	to := makeVersionData(map[string]*types.ComponentDoc{
		"comp": {
			CRDs: []types.CRD{
				{Group: "g1", Version: "v1", Kind: "K1"},
				{Group: "g2", Version: "v1", Kind: "K2"},
			},
		},
	})
	result := Compute("v1", "v2", from, to)
	if len(result.Changed) != 1 {
		t.Fatalf("changed = %d, want 1", len(result.Changed))
	}
	cd := result.Changed[0]
	if cd.Name != "comp" {
		t.Errorf("changed name = %q, want comp", cd.Name)
	}
	if len(cd.Categories) != 1 {
		t.Fatalf("categories = %d, want 1", len(cd.Categories))
	}
	if cd.Categories[0].Category != "crds" {
		t.Errorf("category = %q, want crds", cd.Categories[0].Category)
	}
	if cd.Categories[0].Outcome != OutcomeChanged {
		t.Errorf("outcome = %q, want changed", cd.Categories[0].Outcome)
	}
	if len(cd.Categories[0].Added) != 1 {
		t.Errorf("added crds = %d, want 1", len(cd.Categories[0].Added))
	}
}

func TestCompute_UnchangedComponents(t *testing.T) {
	doc := &types.ComponentDoc{
		CRDs: []types.CRD{
			{Group: "g1", Version: "v1", Kind: "K1"},
		},
	}
	from := makeVersionData(map[string]*types.ComponentDoc{"comp": doc})
	to := makeVersionData(map[string]*types.ComponentDoc{"comp": doc})
	result := Compute("v1", "v2", from, to)
	if result.UnchangedCount != 1 {
		t.Errorf("unchanged = %d, want 1", result.UnchangedCount)
	}
	if len(result.Changed) != 0 {
		t.Errorf("changed = %d, want 0", len(result.Changed))
	}
}

func TestCompute_DeterministicOrder(t *testing.T) {
	from := makeVersionData(map[string]*types.ComponentDoc{
		"alpha": {},
		"zebra": {},
	})
	to := makeVersionData(map[string]*types.ComponentDoc{
		"beta":  {},
		"gamma": {},
	})
	for i := 0; i < 10; i++ {
		result := Compute("v1", "v2", from, to)
		if len(result.Added) != 2 {
			t.Fatalf("run %d: added = %d", i, len(result.Added))
		}
		if result.Added[0] != "beta" || result.Added[1] != "gamma" {
			t.Errorf("run %d: added = %v, want [beta gamma]", i, result.Added)
		}
		if len(result.Removed) != 2 {
			t.Fatalf("run %d: removed = %d", i, len(result.Removed))
		}
		if result.Removed[0] != "alpha" || result.Removed[1] != "zebra" {
			t.Errorf("run %d: removed = %v, want [alpha zebra]", i, result.Removed)
		}
	}
}

func TestComputeSingle_NotFound(t *testing.T) {
	from := makeVersionData(map[string]*types.ComponentDoc{})
	to := makeVersionData(map[string]*types.ComponentDoc{})
	result := ComputeSingle("missing", "v1", "v2", from, to)
	if result.Status != "unknown" {
		t.Errorf("status = %q, want unknown", result.Status)
	}
}

func TestComputeSingle_Added(t *testing.T) {
	from := makeVersionData(map[string]*types.ComponentDoc{})
	to := makeVersionData(map[string]*types.ComponentDoc{
		"comp": {Purpose: "new"},
	})
	result := ComputeSingle("comp", "v1", "v2", from, to)
	if result.Status != "ok" {
		t.Errorf("status = %q, want ok", result.Status)
	}
	if len(result.Added) != 1 || result.Added[0] != "comp" {
		t.Errorf("added = %v, want [comp]", result.Added)
	}
}

func TestComputeSingle_Removed(t *testing.T) {
	from := makeVersionData(map[string]*types.ComponentDoc{
		"comp": {Purpose: "old"},
	})
	to := makeVersionData(map[string]*types.ComponentDoc{})
	result := ComputeSingle("comp", "v1", "v2", from, to)
	if result.Status != "ok" {
		t.Errorf("status = %q, want ok", result.Status)
	}
	if len(result.Removed) != 1 || result.Removed[0] != "comp" {
		t.Errorf("removed = %v, want [comp]", result.Removed)
	}
}

func TestComputeSingle_CaseInsensitive(t *testing.T) {
	from := makeVersionData(map[string]*types.ComponentDoc{})
	to := makeVersionData(map[string]*types.ComponentDoc{
		"MyComp": {Purpose: "test"},
	})
	result := ComputeSingle("mycomp", "v1", "v2", from, to)
	if result.Status != "ok" {
		t.Errorf("status = %q, want ok", result.Status)
	}
	if len(result.Added) != 1 {
		t.Errorf("added = %d, want 1 (case-insensitive match)", len(result.Added))
	}
}

func TestComputeSingle_BothNil(t *testing.T) {
	result := ComputeSingle("comp", "v1", "v2", nil, nil)
	if result.Status != "incompatible" {
		t.Errorf("status = %q, want incompatible", result.Status)
	}
}

func TestCompute_MultipleCategories(t *testing.T) {
	from := makeVersionData(map[string]*types.ComponentDoc{
		"comp": {
			CRDs: []types.CRD{
				{Group: "g1", Version: "v1", Kind: "K1"},
			},
			Services: []types.Service{
				{Name: "svc1", Port: "8080"},
			},
		},
	})
	to := makeVersionData(map[string]*types.ComponentDoc{
		"comp": {
			CRDs: []types.CRD{
				{Group: "g2", Version: "v1", Kind: "K2"},
			},
			Services: []types.Service{
				{Name: "svc2", Port: "9090"},
			},
		},
	})
	result := Compute("v1", "v2", from, to)
	if len(result.Changed) != 1 {
		t.Fatalf("changed = %d, want 1", len(result.Changed))
	}
	if len(result.Changed[0].Categories) != 2 {
		t.Errorf("categories = %d, want 2", len(result.Changed[0].Categories))
	}
}

func TestCompute_JSONRoundTrip(t *testing.T) {
	from := makeVersionData(map[string]*types.ComponentDoc{
		"comp": {
			CRDs: []types.CRD{
				{Group: "g1", Version: "v1", Kind: "K1"},
			},
		},
	})
	to := makeVersionData(map[string]*types.ComponentDoc{
		"comp": {
			CRDs: []types.CRD{
				{Group: "g2", Version: "v1", Kind: "K2"},
			},
		},
	})

	result := Compute("v1", "v2", from, to)
	buf, err := json.Marshal(result)
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}

	var parsed DiffResult
	if err := json.Unmarshal(buf, &parsed); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if parsed.FormatVersion != FormatVersion {
		t.Errorf("roundtrip format_version = %q", parsed.FormatVersion)
	}
	if parsed.Status != "ok" {
		t.Errorf("roundtrip status = %q", parsed.Status)
	}
	if len(parsed.Changed) != 1 {
		t.Errorf("roundtrip changed = %d", len(parsed.Changed))
	}
}
