package renderer

import (
	"bytes"
	"strings"
	"testing"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func TestMarkdownRejectsIncompleteCRDIdentity(t *testing.T) {
	document := model.Document{CRDs: []model.CRDRow{{
		Purpose: "Invalid patch-derived row",
	}}}

	err := Markdown(&bytes.Buffer{}, document)
	if err == nil || !strings.Contains(err.Error(), "incomplete identity") {
		t.Fatalf("Markdown() error = %v, want incomplete CRD identity", err)
	}
}

func TestMarkdownRendersCRDCountScopeAndAPIRole(t *testing.T) {
	document := model.Document{
		Component: "kueue",
		CRDs: []model.CRDRow{
			{
				Group: "kueue.x-k8s.io", Version: "v1beta1", Kind: "Workload",
				Scope: "Namespaced", APIRole: "Core API", Purpose: "core queueing resource",
			},
			{
				Group: "visibility.kueue.x-k8s.io", Version: "v1beta1", Kind: "PendingWorkloadsSummary",
				Scope: "Namespaced", APIRole: "Visibility API", Purpose: "pending workload query resource",
			},
		},
	}

	var output bytes.Buffer
	if err := Markdown(&output, document); err != nil {
		t.Fatalf("Markdown() error = %v", err)
	}
	text := output.String()

	for _, expected := range []string{
		"CRD count scope: 1 core API CRDs; 2 total CRD/API rows including configuration and visibility APIs.",
		"| Group | Version | Kind | Scope | API Role | Purpose |",
		"| kueue.x-k8s.io | v1beta1 | Workload | Namespaced | Core API | core queueing resource |",
		"| visibility.kueue.x-k8s.io | v1beta1 | PendingWorkloadsSummary | Namespaced | Visibility API | pending workload query resource |",
	} {
		if !strings.Contains(text, expected) {
			t.Errorf("Markdown() missing %q\n%s", expected, text)
		}
	}
}

func TestSynthesisEvidenceMarkdownIsBoundedAndSourceLinked(t *testing.T) {
	input := model.Input{
		Component: "example",
		CoverageFindings: []model.CoverageFinding{{
			Category: "grpc_services", Status: "confirmed-empty",
			Finding: "0 grpc services facts extracted", Sources: []string{"scan.go:4"},
		}},
		CrossReferences: []model.CrossReference{{
			Kind: "network", From: "GET /readyz", To: "api", Relationship: "served-by",
			Sources: []string{"server.go:10", "service.yaml:2"},
		}},
		SynthesisEvidence: map[string][]model.EvidenceRecord{
			"services": {{Claim: "api port=8080", Sources: []string{"service.yaml:2"}}},
		},
		GapEvidenceIndex: map[string][]model.GapEvidenceCandidate{
			"http_endpoints": {{
				Source: "server.go", LineRange: "10", Symbols: []string{"GET", "/readyz"},
				Question: "Where is the dynamic handler?", ExpectedSignal: "handler registration",
				Status: "candidate", Limitations: []string{"candidate location only"},
			}},
		},
	}
	var output bytes.Buffer
	if err := SynthesisEvidenceMarkdown(&output, input); err != nil {
		t.Fatalf("SynthesisEvidenceMarkdown() error = %v", err)
	}
	text := output.String()
	for _, expected := range []string{
		"# Analyzer Synthesis Context: example",
		"confirmed-empty",
		"GET /readyz —served-by→ api",
		"api port=8080 [source: service.yaml:2]",
		"## Gap Evidence Index",
		"Where is the dynamic handler?",
		"server.go:10",
		"candidate location only",
	} {
		if !strings.Contains(text, expected) {
			t.Errorf("projection missing %q:\n%s", expected, text)
		}
	}
}

func TestMarkdownRendersDeterministicSourceBackedSynthesis(t *testing.T) {
	document := model.Document{
		Component: "example-api",
		Metadata: model.Metadata{
			DeploymentType: "Kubernetes Deployment",
		},
		Purpose: "Static analysis found one service.",
		ArchitectureComponents: []model.ArchitectureComponent{{
			Component: "api",
			Type:      "Deployment",
			Purpose:   "serves requests",
		}},
		ServingRuntimes: []model.ServingRuntimeRow{{
			Name: "triton", Kind: "ClusterServingRuntime", APIGroup: "serving.kserve.io",
			Version: "v1alpha1", Scope: "Cluster", SupportedModelFormats: "triton:2 (autoSelect)",
			ContainerImages: "triton=example/tritonserver:latest", BuiltInAdapter: "triton",
			Source: "config/runtimes/triton.yaml:1",
		}},
		HTTPEndpoints: []model.HTTPEndpointRow{{Path: "/v1/items", Method: "GET"}},
		Services:      []model.ServiceRow{{Name: "api", Port: "8080"}},
		InternalDependencies: []model.InternalDependencyRow{{
			Component:       "platform-api",
			InteractionType: "HTTP client",
		}},
		IntegrationPoints: []model.IntegrationPointRow{{
			Component:       "postgresql",
			InteractionType: "SQL client",
		}},
		Authentication: []model.AuthenticationRow{{
			Endpoint:  "/v1/*",
			Mechanism: "Bearer token",
		}},
		DataCoverage: map[string]string{
			"source": "partial: dynamic call graphs unresolved",
		},
		CategoryCoverage: map[string]model.CategoryCoverage{
			"authentication": {
				Status: "complete", FactCount: 1,
				DiscoveryContract: "authentication/v1",
				CompletedChecks:   []string{"runtime-inventory"},
			},
		},
		Sources: []model.SourceRow{
			{File: "cmd/main.go", Lines: "12, 24", Sections: "Architecture Components"},
			{File: "api/http.go", Lines: "41", Sections: "APIs Exposed"},
			{File: "client.go", Lines: "8", Sections: "Integration Points, Dependencies"},
		},
	}

	var output bytes.Buffer
	if err := Markdown(&output, document); err != nil {
		t.Fatalf("Markdown() error = %v", err)
	}
	text := output.String()

	for _, expected := range []string{
		"**Detailed**: example-api is represented by 1 architecture component",
		"**Entry and service surface:**",
		"**Runtime inventory:**",
		"## APIs Exposed",
		"### Serving Runtime Definitions",
		"| triton | ClusterServingRuntime | serving.kserve.io | v1alpha1 | Cluster | triton:2 (autoSelect) | triton=example/tritonserver:latest | triton | config/runtimes/triton.yaml:1 |",
		"**Downstream interactions:**",
		"platform-api",
		"postgresql",
		"[source: cmd/main.go:12, 24, api/http.go:41, client.go:8]",
		"**postgresql:** SQL client.",
		"Pending analyzer-assisted synthesis.",
	} {
		if !strings.Contains(text, expected) {
			t.Errorf("Markdown() missing %q\n%s", expected, text)
		}
	}
	for _, forbidden := range []string{
		"**Analyzer coverage",
		"**Category coverage",
		"Deterministic Cross-References",
		"Bounded Synthesis Evidence",
	} {
		if strings.Contains(text, forbidden) {
			t.Errorf("Markdown() leaked analyzer diagnostic marker %q\n%s", forbidden, text)
		}
	}
	if strings.Contains(text, "Pending constrained synthesis") {
		t.Fatalf("Markdown() retained pending synthesis placeholder:\n%s", text)
	}
}

func TestMarkdownRendersSecurityEvidenceSignalType(t *testing.T) {
	document := model.Document{
		Component: "agents-operator",
		SecurityEvidence: []model.SecurityEvidence{
			{
				Kind:    "tls-config",
				Target:  "crypto/tls",
				Detail:  "TLS configuration import",
				Status:  "dependency-signal",
				Sources: []string{"forwardproxy.go", "reverseproxy.go"},
			},
		},
	}

	var output bytes.Buffer
	if err := Markdown(&output, document); err != nil {
		t.Fatalf("Markdown() error = %v", err)
	}
	text := output.String()
	if !strings.Contains(text, "| Kind | Target | Detail | Signal Type |") {
		t.Fatalf("security evidence header missing Signal Type:\n%s", text)
	}
	row := "| tls-config | crypto/tls | TLS configuration import | dependency-signal |"
	if strings.Count(text, row) != 1 {
		t.Fatalf("security evidence row count = %d, want 1:\n%s", strings.Count(text, row), text)
	}
	if strings.Contains(text, "| tls-config | crypto/tls | TLS configuration import | literal |") {
		t.Fatalf("security evidence rendered generic TLS import as literal:\n%s", text)
	}
}
