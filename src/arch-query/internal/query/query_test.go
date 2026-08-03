package query

import (
	"encoding/json"
	"testing"

	"github.com/jctanner/arch-query/internal/types"
)

func vd(components map[string]*types.ComponentDoc) *types.VersionData {
	return &types.VersionData{Components: components}
}

// --- CRD query tests ---

func TestQueryCRDs_OK(t *testing.T) {
	data := vd(map[string]*types.ComponentDoc{
		"kserve": {
			FileName: "kserve.md",
			CRDs: []types.CRD{
				{Group: "serving.kserve.io", Version: "v1beta1", Kind: "InferenceService", Scope: "Namespaced"},
			},
			ControllerWatches: []types.ControllerWatch{
				{Type: "For", GVK: "serving.kserve.io/v1beta1/InferenceService", Controller: "InferenceServiceReconciler"},
			},
			AnalyzerVersion: "0.5.0",
		},
	})
	resp := QueryCRDs("kserve", "rhoai-3.4", data)
	if resp.Status != StatusOK {
		t.Fatalf("status = %q, want ok", resp.Status)
	}
	if resp.ContractVersion != ContractVersion {
		t.Errorf("contract_version = %q, want %q", resp.ContractVersion, ContractVersion)
	}
	if resp.Query != "crds" {
		t.Errorf("query = %q, want crds", resp.Query)
	}
	result, ok := resp.Result.(CRDResult)
	if !ok {
		t.Fatalf("result type = %T, want CRDResult", resp.Result)
	}
	if len(result.CRDs) != 1 {
		t.Errorf("crds count = %d, want 1", len(result.CRDs))
	}
	if len(result.Watches) != 1 {
		t.Errorf("watches count = %d, want 1", len(result.Watches))
	}
	if len(resp.Evidence) < 1 {
		t.Error("expected evidence entries")
	}
}

func TestQueryCRDs_NoCRDs(t *testing.T) {
	data := vd(map[string]*types.ComponentDoc{
		"vllm": {FileName: "vllm.md"},
	})
	resp := QueryCRDs("vllm", "rhoai-3.4", data)
	if resp.Status != StatusOK {
		t.Fatalf("status = %q, want ok", resp.Status)
	}
	result := resp.Result.(CRDResult)
	if len(result.CRDs) != 0 {
		t.Errorf("crds = %d, want 0", len(result.CRDs))
	}
	if len(result.Watches) != 0 {
		t.Errorf("watches = %d, want 0", len(result.Watches))
	}
}

func TestQueryCRDs_Unknown(t *testing.T) {
	data := vd(map[string]*types.ComponentDoc{})
	resp := QueryCRDs("nonexistent", "rhoai-3.4", data)
	if resp.Status != StatusUnknown {
		t.Errorf("status = %q, want unknown", resp.Status)
	}
	if resp.Reason == "" {
		t.Error("expected reason for unknown status")
	}
}

func TestQueryCRDs_CaseInsensitive(t *testing.T) {
	data := vd(map[string]*types.ComponentDoc{
		"KServe": {
			FileName: "kserve.md",
			CRDs: []types.CRD{
				{Group: "serving.kserve.io", Version: "v1beta1", Kind: "InferenceService", Scope: "Namespaced"},
			},
		},
	})
	resp := QueryCRDs("kserve", "rhoai-3.4", data)
	if resp.Status != StatusOK {
		t.Errorf("status = %q, want ok (case-insensitive match)", resp.Status)
	}
}

// --- Diff query tests ---

func TestQueryDiff_OK(t *testing.T) {
	from := vd(map[string]*types.ComponentDoc{
		"comp": {CRDs: []types.CRD{{Group: "g1", Version: "v1", Kind: "K1"}}},
	})
	to := vd(map[string]*types.ComponentDoc{
		"comp": {CRDs: []types.CRD{
			{Group: "g1", Version: "v1", Kind: "K1"},
			{Group: "g2", Version: "v1", Kind: "K2"},
		}},
	})
	resp := QueryDiff("comp", "v1", "v2", from, to)
	if resp.Status != StatusOK {
		t.Fatalf("status = %q, want ok", resp.Status)
	}
	if resp.Version != "v1..v2" {
		t.Errorf("version = %q, want v1..v2", resp.Version)
	}
	if len(resp.Evidence) < 2 {
		t.Error("expected evidence for both versions")
	}
}

func TestQueryDiff_UnknownComponent(t *testing.T) {
	from := vd(map[string]*types.ComponentDoc{})
	to := vd(map[string]*types.ComponentDoc{})
	resp := QueryDiff("missing", "v1", "v2", from, to)
	if resp.Status != StatusUnknown {
		t.Errorf("status = %q, want unknown", resp.Status)
	}
}

func TestQueryDiff_BothNil(t *testing.T) {
	resp := QueryDiff("comp", "v1", "v2", nil, nil)
	if resp.Status != StatusNotExtracted {
		t.Errorf("status = %q, want not-extracted", resp.Status)
	}
}

func TestQueryDiff_FromNil(t *testing.T) {
	to := vd(map[string]*types.ComponentDoc{"comp": {}})
	resp := QueryDiff("comp", "v1", "v2", nil, to)
	if resp.Status != StatusNotExtracted {
		t.Errorf("status = %q, want not-extracted", resp.Status)
	}
}

func TestQueryDiff_PlatformWide(t *testing.T) {
	from := vd(map[string]*types.ComponentDoc{"a": {}})
	to := vd(map[string]*types.ComponentDoc{"a": {}, "b": {}})
	resp := QueryDiff("", "v1", "v2", from, to)
	if resp.Status != StatusOK {
		t.Fatalf("status = %q, want ok", resp.Status)
	}
}

// --- Dependency-status query tests ---

func TestQueryDeps_OK(t *testing.T) {
	data := vd(map[string]*types.ComponentDoc{
		"kserve": {
			FileName: "kserve.md",
			ExternalDeps: []types.Dependency{
				{Component: "cert-manager", Purpose: "TLS certificates", Required: "Yes"},
			},
			InternalDeps: []types.Dependency{
				{Component: "odh-model-controller", Purpose: "extends KServe"},
			},
		},
		"odh-model-controller": {
			FileName: "odh-model-controller.md",
			InternalDeps: []types.Dependency{
				{Component: "kserve", Purpose: "model serving"},
			},
		},
	})
	resp := QueryDependencyStatus("kserve", "", "rhoai-3.4", data)
	if resp.Status != StatusOK {
		t.Fatalf("status = %q, want ok", resp.Status)
	}
	result := resp.Result.(DependencyStatusResult)
	if len(result.Dependencies) != 2 {
		t.Errorf("deps = %d, want 2", len(result.Dependencies))
	}
	for _, d := range result.Dependencies {
		if d.LifecycleStatus != "unknown" {
			t.Errorf("lifecycle_status = %q, want unknown", d.LifecycleStatus)
		}
		if d.Kind != "external" && d.Kind != "internal" {
			t.Errorf("kind = %q, want external or internal", d.Kind)
		}
	}
	if len(result.ReverseDeps) != 1 {
		t.Errorf("reverse_deps = %d, want 1", len(result.ReverseDeps))
	}
}

func TestQueryDeps_Unknown(t *testing.T) {
	data := vd(map[string]*types.ComponentDoc{})
	resp := QueryDependencyStatus("missing", "", "rhoai-3.4", data)
	if resp.Status != StatusUnknown {
		t.Errorf("status = %q, want unknown", resp.Status)
	}
}

func TestQueryDeps_WithRelease(t *testing.T) {
	data := vd(map[string]*types.ComponentDoc{
		"comp": {FileName: "comp.md"},
	})
	resp := QueryDependencyStatus("comp", "3.4", "rhoai-3.4", data)
	if resp.Status != StatusOK {
		t.Fatalf("status = %q, want ok", resp.Status)
	}
	if resp.Args["release"] != "3.4" {
		t.Errorf("args.release = %v, want 3.4", resp.Args["release"])
	}
}

func TestQueryDeps_NoDeps(t *testing.T) {
	data := vd(map[string]*types.ComponentDoc{
		"leaf": {FileName: "leaf.md"},
	})
	resp := QueryDependencyStatus("leaf", "", "rhoai-3.4", data)
	if resp.Status != StatusOK {
		t.Fatalf("status = %q, want ok", resp.Status)
	}
	result := resp.Result.(DependencyStatusResult)
	if len(result.Dependencies) != 0 {
		t.Errorf("deps = %d, want 0", len(result.Dependencies))
	}
	if len(result.ReverseDeps) != 0 {
		t.Errorf("reverse_deps = %d, want 0", len(result.ReverseDeps))
	}
}

// --- Not-extracted query tests ---

func TestQueryCallersOf_NotExtracted(t *testing.T) {
	resp := QueryCallersOf("Reconcile", "controller", "rhoai-3.4", nil)
	if resp.Status != StatusNotExtracted {
		t.Errorf("status = %q, want not-extracted", resp.Status)
	}
	if resp.Query != "callers-of" {
		t.Errorf("query = %q, want callers-of", resp.Query)
	}
	if resp.Reason == "" {
		t.Error("expected reason for not-extracted")
	}
	if resp.Args["function"] != "Reconcile" {
		t.Errorf("args.function = %v, want Reconcile", resp.Args["function"])
	}
	if resp.Args["package"] != "controller" {
		t.Errorf("args.package = %v, want controller", resp.Args["package"])
	}
}

func TestQueryConsumersOf_NotExtracted(t *testing.T) {
	resp := QueryConsumersOf("InferenceService", "rhoai-3.4", nil)
	if resp.Status != StatusNotExtracted {
		t.Errorf("status = %q, want not-extracted", resp.Status)
	}
	if resp.Query != "consumers-of" {
		t.Errorf("query = %q, want consumers-of", resp.Query)
	}
	if resp.Reason == "" {
		t.Error("expected reason for not-extracted")
	}
}

func TestQueryConfigSources_NotExtracted(t *testing.T) {
	data := vd(map[string]*types.ComponentDoc{
		"kserve": {FileName: "kserve.md"},
	})
	resp := QueryConfigSources("kserve", "rhoai-3.4", data)
	if resp.Status != StatusNotExtracted {
		t.Errorf("status = %q, want not-extracted", resp.Status)
	}
	if resp.Query != "config-sources" {
		t.Errorf("query = %q, want config-sources", resp.Query)
	}
}

func TestQueryConfigSources_UnknownComponent(t *testing.T) {
	data := vd(map[string]*types.ComponentDoc{})
	resp := QueryConfigSources("missing", "rhoai-3.4", data)
	if resp.Status != StatusUnknown {
		t.Errorf("status = %q, want unknown", resp.Status)
	}
}

// --- Contract tests ---

func TestResponseJSONRoundTrip(t *testing.T) {
	data := vd(map[string]*types.ComponentDoc{
		"kserve": {
			FileName: "kserve.md",
			CRDs: []types.CRD{
				{Group: "serving.kserve.io", Version: "v1beta1", Kind: "InferenceService", Scope: "Namespaced"},
			},
		},
	})
	resp := QueryCRDs("kserve", "rhoai-3.4", data)

	buf, err := json.Marshal(resp)
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}

	var parsed Response
	if err := json.Unmarshal(buf, &parsed); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if parsed.ContractVersion != ContractVersion {
		t.Errorf("roundtrip contract_version = %q", parsed.ContractVersion)
	}
	if parsed.Status != StatusOK {
		t.Errorf("roundtrip status = %q", parsed.Status)
	}
	if parsed.Query != "crds" {
		t.Errorf("roundtrip query = %q", parsed.Query)
	}
}

func TestContractVersion(t *testing.T) {
	if ContractVersion != "v1" {
		t.Errorf("contract version = %q, want v1", ContractVersion)
	}
}

func TestAllQueriesIncludeContractVersion(t *testing.T) {
	data := vd(map[string]*types.ComponentDoc{
		"comp": {FileName: "comp.md"},
	})

	responses := []*Response{
		QueryCRDs("comp", "v1", data),
		QueryDependencyStatus("comp", "", "v1", data),
		QueryCallersOf("fn", "pkg", "v1", nil),
		QueryConsumersOf("Type", "v1", nil),
		QueryConfigSources("comp", "v1", data),
	}

	from := vd(map[string]*types.ComponentDoc{"comp": {}})
	to := vd(map[string]*types.ComponentDoc{"comp": {}})
	responses = append(responses, QueryDiff("comp", "v1", "v2", from, to))

	for i, resp := range responses {
		if resp.ContractVersion != ContractVersion {
			t.Errorf("response %d: contract_version = %q, want %q",
				i, resp.ContractVersion, ContractVersion)
		}
		if resp.Query == "" {
			t.Errorf("response %d: query is empty", i)
		}
	}
}

func TestNotExtractedResponseHelper(t *testing.T) {
	resp := NotExtractedResponse("test-query",
		map[string]any{"key": "val"}, "v1", "test reason")
	if resp.Status != StatusNotExtracted {
		t.Errorf("status = %q, want not-extracted", resp.Status)
	}
	if resp.Reason != "test reason" {
		t.Errorf("reason = %q, want test reason", resp.Reason)
	}
	if resp.Result != nil {
		t.Errorf("result = %v, want nil", resp.Result)
	}
}

func TestUnknownResponseHelper(t *testing.T) {
	resp := UnknownResponse("test-query",
		map[string]any{"key": "val"}, "v1", "test reason")
	if resp.Status != StatusUnknown {
		t.Errorf("status = %q, want unknown", resp.Status)
	}
	if resp.Reason != "test reason" {
		t.Errorf("reason = %q, want test reason", resp.Reason)
	}
}

// --- JSON output structure tests ---

func TestQueryCRDs_JSONStructure(t *testing.T) {
	data := vd(map[string]*types.ComponentDoc{
		"kserve": {
			FileName: "kserve.md",
			CRDs: []types.CRD{
				{Group: "serving.kserve.io", Version: "v1beta1", Kind: "InferenceService", Scope: "Namespaced", Purpose: "ML model serving"},
			},
			ControllerWatches: []types.ControllerWatch{
				{Type: "For", GVK: "serving.kserve.io/v1beta1/InferenceService", Controller: "Reconciler", Source: "controllers/inferenceservice_controller.go"},
			},
		},
	})
	resp := QueryCRDs("kserve", "rhoai-3.4", data)

	buf, err := json.MarshalIndent(resp, "", "  ")
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}

	var raw map[string]any
	if err := json.Unmarshal(buf, &raw); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}

	requiredKeys := []string{"contract_version", "query", "args", "status", "result"}
	for _, key := range requiredKeys {
		if _, ok := raw[key]; !ok {
			t.Errorf("missing required key %q in JSON output", key)
		}
	}

	result := raw["result"].(map[string]any)
	if _, ok := result["crds"]; !ok {
		t.Error("result missing 'crds' key")
	}
	if _, ok := result["watches"]; !ok {
		t.Error("result missing 'watches' key")
	}
}

func TestQueryDiff_JSONStructure(t *testing.T) {
	from := vd(map[string]*types.ComponentDoc{"comp": {}})
	to := vd(map[string]*types.ComponentDoc{"comp": {}})
	resp := QueryDiff("comp", "v1", "v2", from, to)

	buf, err := json.MarshalIndent(resp, "", "  ")
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}

	var raw map[string]any
	if err := json.Unmarshal(buf, &raw); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}

	result := raw["result"].(map[string]any)
	for _, key := range []string{"format_version", "from_version", "to_version", "status"} {
		if _, ok := result[key]; !ok {
			t.Errorf("diff result missing key %q", key)
		}
	}
}
