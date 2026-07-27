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
		"**Downstream interactions:**",
		"platform-api",
		"postgresql",
		"[source: cmd/main.go:12, 24, api/http.go:41, client.go:8]",
		"**postgresql:** SQL client.",
		"**Evidence boundary:** Analyzer coverage is partial for source",
		"**Category coverage (authentication)**: complete under authentication/v1; 1 facts; checks: runtime-inventory",
	} {
		if !strings.Contains(text, expected) {
			t.Errorf("Markdown() missing %q\n%s", expected, text)
		}
	}
	if strings.Contains(text, "Pending constrained synthesis") {
		t.Fatalf("Markdown() retained pending synthesis placeholder:\n%s", text)
	}
}
