package extractor

import (
	"strings"
	"testing"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func TestCrossReferencesJoinExplicitNetworkAndSecurityFacts(t *testing.T) {
	input := model.Input{
		HTTPEndpoints:  []model.HTTPEndpoint{{Method: "GET", Path: "/readyz", Port: 8080, Source: "server.go:10"}},
		Services:       []model.Service{{Name: "api", Ports: []model.ServicePort{{Port: 8080}}, Source: "service.yaml:4"}},
		Authentication: []model.AuthenticationFact{{Endpoint: "/readyz", Mechanism: "RBAC", EnforcementPoint: "middleware", Source: "auth.go:3"}},
	}
	refs := crossReferences(input)
	if len(refs) != 2 {
		t.Fatalf("cross references = %#v, want endpoint/service and endpoint/auth joins", refs)
	}
	joined := false
	protected := false
	for _, ref := range refs {
		joined = joined || ref.Relationship == "served-by" && ref.To == "api"
		protected = protected || ref.Relationship == "protected-by" && ref.To == "RBAC"
		if len(ref.Sources) != 2 {
			t.Errorf("reference sources = %#v, want both contributing facts", ref.Sources)
		}
	}
	if !joined || !protected {
		t.Errorf("references = %#v, want explicit service and auth joins", refs)
	}
}

func TestCoverageFindingsDoNotClaimAbsenceForPartialCoverage(t *testing.T) {
	input := model.Input{
		DataCoverage: map[string]string{"go_crds": "partial: parse warning", "manifests": "complete"},
		CategoryCoverage: map[string]model.CategoryCoverage{
			"grpc_services": {Status: "partial"}, "http_endpoints": {Status: "complete"},
			"services": {Status: "complete"},
		},
	}
	findings := coverageFindings(input)
	for _, finding := range findings {
		if finding.Status == "confirmed-empty" && finding.Category == "crds" {
			t.Fatal("partial CRD coverage must not produce a confirmed-empty finding")
		}
	}
	statuses := map[string]string{}
	for _, finding := range findings {
		statuses[finding.Category] = finding.Status
	}
	if statuses["crds"] != "not-verified" || statuses["http_endpoints"] != "confirmed-empty" {
		t.Errorf("findings = %#v, want explicit not-verified and confirmed-empty statuses", findings)
	}
	if !strings.Contains(findings[0].Finding, "absence is not proven") {
		t.Errorf("CRD finding = %#v, want explicit limitation", findings[0])
	}
}

func TestSynthesisEvidenceIsBoundedAndSourceLinked(t *testing.T) {
	input := model.Input{
		HTTPEndpoints:  []model.HTTPEndpoint{{Path: "/a", Source: "a.go:1"}},
		Authentication: []model.AuthenticationFact{{Endpoint: "/a", Mechanism: "OAuth", Source: "auth.go:2"}},
	}
	evidence := synthesisEvidence(input)
	if len(evidence["http_endpoints"]) != 1 || len(evidence["authentication"]) != 1 {
		t.Fatalf("evidence = %#v, want endpoint and auth bundles", evidence)
	}
	for category, records := range evidence {
		for _, record := range records {
			if record.Claim == "" || len(record.Sources) == 0 {
				t.Errorf("%s record = %#v, want claim and provenance", category, record)
			}
		}
	}
}
