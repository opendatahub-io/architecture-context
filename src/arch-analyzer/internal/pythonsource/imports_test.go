package pythonsource

import (
	"testing"
)

func TestParseImportAnalysisUsedDeps(t *testing.T) {
	data := []byte(`{
		"used": [
			{"package": "grpcio", "imports": ["grpc"], "source": "server.py:5"},
			{"package": "fastapi", "imports": ["fastapi"], "source": "app.py:1"}
		],
		"test_only": ["pytest"],
		"declared_unused": ["black"],
		"optional_groups": {
			"dev": {"used": [], "unused": ["pytest", "black"]},
			"runtime-grpc": {"used": ["grpcio-health-checking"], "unused": ["grpcio-reflection"]}
		},
		"grpc_server": true,
		"grpc_registrations": [
			{"servicer": "InferenceServiceServicer", "source": "server.py:77"},
			{"servicer": "HealthServicer", "source": "server.py:90"}
		]
	}`)
	analysis, err := parseImportAnalysis(data)
	if err != nil {
		t.Fatalf("parseImportAnalysis() error = %v", err)
	}
	if analysis == nil {
		t.Fatal("analysis is nil")
	}
	if len(analysis.Used) != 2 {
		t.Fatalf("used = %d, want 2", len(analysis.Used))
	}
	if analysis.Used[0].Package != "grpcio" || analysis.Used[0].Source != "server.py:5" {
		t.Errorf("used[0] = %v", analysis.Used[0])
	}
	if len(analysis.TestOnly) != 1 || analysis.TestOnly[0] != "pytest" {
		t.Errorf("test_only = %v", analysis.TestOnly)
	}
	if len(analysis.DeclaredUnused) != 1 || analysis.DeclaredUnused[0] != "black" {
		t.Errorf("declared_unused = %v", analysis.DeclaredUnused)
	}
	if !analysis.GRPCServer {
		t.Error("grpc_server = false, want true")
	}
	if len(analysis.GRPCRegistrations) != 2 {
		t.Fatalf("grpc_registrations = %d, want 2", len(analysis.GRPCRegistrations))
	}
}

func TestParseImportAnalysisNoDeps(t *testing.T) {
	data := []byte(`{"status": "no_dependencies_found"}`)
	analysis, err := parseImportAnalysis(data)
	if err != nil {
		t.Fatalf("parseImportAnalysis() error = %v", err)
	}
	if analysis != nil {
		t.Errorf("analysis should be nil for no_dependencies_found, got %v", analysis)
	}
}

func TestParseImportAnalysisOptionalGroups(t *testing.T) {
	data := []byte(`{
		"used": [],
		"test_only": [],
		"declared_unused": [],
		"optional_groups": {
			"runtime-grpc": {"used": ["grpcio-health-checking", "py-grpc-prometheus"], "unused": ["grpcio-reflection"]},
			"dev-test": {"used": [], "unused": ["pytest"]}
		},
		"grpc_server": false,
		"grpc_registrations": []
	}`)
	analysis, err := parseImportAnalysis(data)
	if err != nil {
		t.Fatalf("parseImportAnalysis() error = %v", err)
	}
	grpc := analysis.OptionalGroups["runtime-grpc"]
	if len(grpc.Used) != 2 {
		t.Errorf("runtime-grpc used = %v, want 2 items", grpc.Used)
	}
	if len(grpc.Unused) != 1 || grpc.Unused[0] != "grpcio-reflection" {
		t.Errorf("runtime-grpc unused = %v", grpc.Unused)
	}
	dev := analysis.OptionalGroups["dev-test"]
	if len(dev.Used) != 0 {
		t.Errorf("dev-test used = %v, want empty", dev.Used)
	}
}

func TestImportAnalysisGRPCServicesNil(t *testing.T) {
	services := importAnalysisGRPCServices(nil)
	if len(services) != 0 {
		t.Errorf("services = %v, want empty", services)
	}
}

func TestImportAnalysisGRPCServicesNoServer(t *testing.T) {
	analysis := &ImportAnalysis{
		GRPCServer:        false,
		GRPCRegistrations: []GRPCRegistration{{Servicer: "FooServicer", Source: "foo.py:1"}},
	}
	services := importAnalysisGRPCServices(analysis)
	if len(services) != 0 {
		t.Errorf("services = %v, want empty (no server)", services)
	}
}

func TestImportAnalysisGRPCServicesRegistration(t *testing.T) {
	analysis := &ImportAnalysis{
		GRPCServer: true,
		GRPCRegistrations: []GRPCRegistration{
			{Servicer: "GRPCInferenceServiceServicer", Source: "grpc/server.py:77"},
			{Servicer: "ModelRepositoryServiceServicer", Source: "grpc/server.py:80"},
			{Servicer: "HealthServicer", Source: "grpc/server.py:90"},
		},
	}
	services := importAnalysisGRPCServices(analysis)
	if len(services) != 3 {
		t.Fatalf("services = %d, want 3", len(services))
	}
	names := map[string]bool{}
	for _, s := range services {
		names[s.Service] = true
		if s.Protocol != "gRPC" {
			t.Errorf("protocol = %q", s.Protocol)
		}
		if s.Purpose != "Python gRPC service registration" {
			t.Errorf("purpose = %q", s.Purpose)
		}
	}
	for _, want := range []string{"GRPCInferenceService", "ModelRepositoryService", "Health"} {
		if !names[want] {
			t.Errorf("missing service %q in %v", want, names)
		}
	}
}

func TestImportAnalysisGRPCServicesDedup(t *testing.T) {
	analysis := &ImportAnalysis{
		GRPCServer: true,
		GRPCRegistrations: []GRPCRegistration{
			{Servicer: "InferenceServicer", Source: "a.py:1"},
			{Servicer: "InferenceServicer", Source: "b.py:2"},
		},
	}
	services := importAnalysisGRPCServices(analysis)
	if len(services) != 1 {
		t.Errorf("services = %d, want 1 (dedup)", len(services))
	}
}

func TestImportAnalysisInternalDependenciesNil(t *testing.T) {
	deps := importAnalysisInternalDependencies(nil)
	if len(deps) != 0 {
		t.Errorf("deps = %v, want empty", deps)
	}
}

func TestImportAnalysisInternalDependenciesPlatformPackages(t *testing.T) {
	analysis := &ImportAnalysis{
		Used: []ImportedPackage{
			{Package: "kubernetes", Imports: []string{"kubernetes.client"}, Source: "app.py:3"},
			{Package: "ray", Imports: []string{"ray"}, Source: "worker.py:1"},
			{Package: "kserve", Imports: []string{"kserve"}, Source: "serve.py:2"},
		},
	}
	deps := importAnalysisInternalDependencies(analysis)
	if len(deps) != 3 {
		t.Fatalf("deps = %d, want 3", len(deps))
	}
	components := map[string]bool{}
	for _, d := range deps {
		components[d.Component] = true
		if d.Interaction == "" || d.Purpose == "" {
			t.Errorf("dep %q missing interaction or purpose", d.Component)
		}
	}
	for _, want := range []string{"Kubernetes API", "Ray", "KServe"} {
		if !components[want] {
			t.Errorf("missing component %q", want)
		}
	}
}

func TestImportAnalysisInternalDependenciesUtilityLibsExcluded(t *testing.T) {
	analysis := &ImportAnalysis{
		Used: []ImportedPackage{
			{Package: "numpy", Imports: []string{"numpy"}, Source: "math.py:1"},
			{Package: "pandas", Imports: []string{"pandas"}, Source: "data.py:1"},
			{Package: "pydantic", Imports: []string{"pydantic"}, Source: "model.py:1"},
			{Package: "requests", Imports: []string{"requests"}, Source: "http.py:1"},
			{Package: "flask", Imports: []string{"flask"}, Source: "web.py:1"},
		},
	}
	deps := importAnalysisInternalDependencies(analysis)
	if len(deps) != 0 {
		t.Errorf("deps = %v, want empty (utility libs must not generate facts)", deps)
	}
}

func TestImportAnalysisInternalDependenciesGRPCRequiresServer(t *testing.T) {
	analysis := &ImportAnalysis{
		Used:       []ImportedPackage{{Package: "grpcio", Imports: []string{"grpc"}, Source: "client.py:1"}},
		GRPCServer: false,
	}
	deps := importAnalysisInternalDependencies(analysis)
	if len(deps) != 0 {
		t.Errorf("grpcio without GRPCServer should not generate facts, got %v", deps)
	}

	analysis.GRPCServer = true
	deps = importAnalysisInternalDependencies(analysis)
	if len(deps) != 1 || deps[0].Component != "gRPC framework" {
		t.Errorf("grpcio with GRPCServer should generate gRPC fact, got %v", deps)
	}
}

func TestImportAnalysisInternalDependenciesDedup(t *testing.T) {
	analysis := &ImportAnalysis{
		Used: []ImportedPackage{
			{Package: "caikit", Imports: []string{"caikit"}, Source: "a.py:1"},
			{Package: "caikit-nlp", Imports: []string{"caikit_nlp"}, Source: "b.py:1"},
		},
	}
	deps := importAnalysisInternalDependencies(analysis)
	if len(deps) != 1 {
		t.Errorf("deps = %d, want 1 (caikit and caikit-nlp map to same component)", len(deps))
	}
	if deps[0].Component != "Caikit Runtime" {
		t.Errorf("component = %q, want Caikit Runtime", deps[0].Component)
	}
}

func TestImportAnalysisInternalDependenciesSource(t *testing.T) {
	analysis := &ImportAnalysis{
		Used: []ImportedPackage{
			{Package: "kubernetes", Imports: []string{"kubernetes.client"}, Source: "app.py:3"},
		},
	}
	deps := importAnalysisInternalDependencies(analysis)
	if len(deps) != 1 || deps[0].Source != "app.py:3" {
		t.Errorf("source = %q, want app.py:3", deps[0].Source)
	}

	analysis.Used[0].Source = ""
	deps = importAnalysisInternalDependencies(analysis)
	if len(deps) != 1 || deps[0].Source != "import:kubernetes.client" {
		t.Errorf("source fallback = %q, want import:kubernetes.client", deps[0].Source)
	}
}

func TestImportAnalysisIntegrationFactsNil(t *testing.T) {
	facts := importAnalysisIntegrationFacts(nil)
	if len(facts) != 0 {
		t.Errorf("facts = %v, want empty", facts)
	}
}

func TestImportAnalysisIntegrationFactsSDKPackages(t *testing.T) {
	analysis := &ImportAnalysis{
		Used: []ImportedPackage{
			{Package: "openai", Imports: []string{"openai"}, Source: "llm.py:1"},
			{Package: "boto3", Imports: []string{"boto3"}, Source: "storage.py:2"},
			{Package: "google-cloud-storage", Imports: []string{"google.cloud.storage"}, Source: "gcs.py:1"},
		},
	}
	facts := importAnalysisIntegrationFacts(analysis)
	if len(facts) != 3 {
		t.Fatalf("facts = %d, want 3", len(facts))
	}
	components := map[string]bool{}
	for _, f := range facts {
		components[f.Component] = true
		if f.Protocol != "HTTPS" || f.Encryption != "TLS" {
			t.Errorf("fact %q: protocol=%q, encryption=%q", f.Component, f.Protocol, f.Encryption)
		}
	}
	for _, want := range []string{"OpenAI API", "AWS (S3-compatible storage)", "Google Cloud Storage"} {
		if !components[want] {
			t.Errorf("missing component %q", want)
		}
	}
}

func TestImportAnalysisIntegrationFactsUtilityLibsExcluded(t *testing.T) {
	analysis := &ImportAnalysis{
		Used: []ImportedPackage{
			{Package: "numpy", Imports: []string{"numpy"}, Source: "math.py:1"},
			{Package: "fastapi", Imports: []string{"fastapi"}, Source: "web.py:1"},
			{Package: "kubernetes", Imports: []string{"kubernetes"}, Source: "k8s.py:1"},
		},
	}
	facts := importAnalysisIntegrationFacts(analysis)
	if len(facts) != 0 {
		t.Errorf("facts = %v, want empty (non-SDK packages must not generate integration facts)", facts)
	}
}

func TestImportAnalysisIntegrationFactsDedup(t *testing.T) {
	analysis := &ImportAnalysis{
		Used: []ImportedPackage{
			{Package: "boto3", Imports: []string{"boto3"}, Source: "a.py:1"},
			{Package: "botocore", Imports: []string{"botocore"}, Source: "b.py:1"},
		},
	}
	facts := importAnalysisIntegrationFacts(analysis)
	if len(facts) != 1 {
		t.Errorf("facts = %d, want 1 (boto3 and botocore map to same component)", len(facts))
	}
}

func TestImportAnalysisCoverageNil(t *testing.T) {
	if c := importAnalysisCoverage(nil); c != "" {
		t.Errorf("coverage = %q, want empty", c)
	}
}

func TestImportAnalysisCoverage(t *testing.T) {
	analysis := &ImportAnalysis{
		Used:              []ImportedPackage{{Package: "grpcio"}, {Package: "fastapi"}},
		TestOnly:          []string{"pytest"},
		DeclaredUnused:    []string{"black", "flake8"},
		GRPCServer:        true,
		GRPCRegistrations: []GRPCRegistration{{Servicer: "FooServicer"}},
	}
	coverage := importAnalysisCoverage(analysis)
	if coverage == "" {
		t.Fatal("coverage is empty")
	}
	for _, want := range []string{"2 imported", "1 test-only", "2 declared but unused", "1 gRPC"} {
		if !contains(coverage, want) {
			t.Errorf("coverage = %q, want substring %q", coverage, want)
		}
	}
}

func TestImportAnalysisCoverageNoGRPC(t *testing.T) {
	analysis := &ImportAnalysis{
		Used:       []ImportedPackage{{Package: "fastapi"}},
		GRPCServer: false,
	}
	coverage := importAnalysisCoverage(analysis)
	if contains(coverage, "gRPC") {
		t.Errorf("coverage = %q, should not mention gRPC", coverage)
	}
}

func TestExtractImportAnalysisTestdata(t *testing.T) {
	analysis := extractImportAnalysis("testdata/repository")
	if analysis == nil {
		t.Skip("python3 not available or script failed")
	}
	usedNames := map[string]bool{}
	for _, u := range analysis.Used {
		usedNames[u.Package] = true
	}
	if !usedNames["fastapi"] {
		t.Errorf("fastapi should be in used: %v", analysis.Used)
	}
	if usedNames["grpcio"] {
		t.Errorf("grpcio should not be in used (not imported): %v", analysis.Used)
	}
	if analysis.GRPCServer {
		t.Errorf("testdata/repository should not have gRPC server")
	}
}

func contains(s, sub string) bool {
	return len(s) >= len(sub) && (s == sub || len(s) > 0 && containsSubstring(s, sub))
}

func containsSubstring(s, sub string) bool {
	for i := 0; i <= len(s)-len(sub); i++ {
		if s[i:i+len(sub)] == sub {
			return true
		}
	}
	return false
}
