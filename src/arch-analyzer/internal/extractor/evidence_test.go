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

func TestCrossCuttingEvidencePreservesRequiredTopicsAndProvenance(t *testing.T) {
	input := model.Input{
		Authentication: []model.AuthenticationFact{{Endpoint: "/api", Mechanism: "RBAC", Source: "auth.go:4"}},
		IngressRouting: []model.Ingress{{Kind: "HTTPRoute", Name: "api", Host: "api.example", TLS: true, Source: "route.yaml:3"}},
		Dockerfiles:    []model.Dockerfile{{Path: "Dockerfile", BaseImage: "ubi9", User: "1001"}},
	}
	evidence := crossCuttingEvidence(input)
	for _, topic := range []string{"security", "ingress", "supply_chain", "disconnected_deployment", "high_availability", "deployment_topology"} {
		records := evidence[topic]
		if len(records) == 0 {
			t.Fatalf("topic %q has no evidence", topic)
		}
		for _, record := range records {
			if record.Claim == "" || record.Status == "" || len(record.Sources) == 0 {
				t.Errorf("topic %q record = %#v, want claim/status/provenance", topic, record)
			}
		}
	}
}

func TestFIPSCoverageIsPartialAndSourceLinked(t *testing.T) {
	input := model.Input{
		SecurityEvidence: []model.SecurityEvidence{{
			Kind: "fips-posture", Target: "FIPS validation", Status: "not-extracted",
			Detail: "FIPS validation is not verified", Source: "coverage:fips_compliance",
		}},
	}
	coverage := fipsComplianceCoverage(input)
	if coverage.Status != "partial" || coverage.FactCount != 1 {
		t.Fatalf("coverage = %#v, want one partial FIPS fact", coverage)
	}
	if len(coverage.Evidence) != 1 || coverage.Evidence[0] != "coverage:fips_compliance" {
		t.Fatalf("coverage evidence = %#v, want source provenance", coverage.Evidence)
	}
}

func TestFIPSCoverageWithoutSignalsIsNotVerified(t *testing.T) {
	coverage := fipsComplianceCoverage(model.Input{})
	if coverage.Status != "partial" || coverage.FactCount != 0 {
		t.Fatalf("coverage = %#v, want zero-fact partial coverage", coverage)
	}
	if len(coverage.Evidence) != 1 || coverage.Evidence[0] != "coverage:fips_compliance" {
		t.Fatalf("coverage evidence = %#v, want explicit coverage provenance", coverage.Evidence)
	}
	if !strings.Contains(coverage.Limitations[0], "not verified") {
		t.Fatalf("coverage limitations = %#v, want not-verified limitation", coverage.Limitations)
	}
}

func TestGapEvidenceIndexCoversHighDemandCategories(t *testing.T) {
	input := model.Input{
		HTTPEndpoints:     []model.HTTPEndpoint{{Source: "web/routes.py:12"}},
		GRPCServices:      []model.GRPCService{{Source: "rust/src/server.rs:8"}},
		Authentication:    []model.AuthenticationFact{{Source: "auth.go:4"}},
		IntegrationPoints: []model.IntegrationFact{{Source: "client.py:7"}},
		Dependencies:      model.Dependencies{Internal: []model.InternalDependency{{Source: "controller.go:9"}}},
		RuntimeClients:    []model.RuntimeClient{{Source: "egress.go:5"}},
		Services:          []model.Service{{Source: "service.yaml:2"}},
		Deployments:       []model.Deployment{{Source: "deployment.yaml:3"}},
		ControllerWatches: []model.ControllerWatch{{Controller: "WidgetReconciler", GVK: "example.io/v1/Widget", Source: "controller.go:11"}},
		RBAC:              model.RBAC{ClusterRoles: []model.Role{{Name: "manager", Source: "rbac.yaml:4"}}},
		SourceDefaults:    []model.SourceDefault{{Path: "--port", Sources: []string{"config.go:6"}}},
		Webhooks:          []model.Webhook{{Name: "widget", Path: "/validate", Sources: []model.WebhookSource{{File: "webhook.go", Line: 12}}}},
	}
	index := gapEvidenceIndex(input)
	for _, category := range []string{"http_endpoints", "grpc_services", "authentication", "integration_points", "internal_dependencies", "egress", "services"} {
		candidates := index[category]
		if len(candidates) == 0 {
			t.Errorf("gap category %q has no candidates", category)
		}
		for _, candidate := range candidates {
			if candidate.Status != "candidate" || candidate.Source == "" || candidate.Question == "" || candidate.ExpectedSignal == "" {
				t.Errorf("category %q candidate = %#v, want bounded source-backed metadata", category, candidate)
			}
		}
	}
	for _, category := range []string{"kubernetes_relationships", "authorization", "configuration_lifecycle", "webhooks"} {
		if len(index[category]) == 0 {
			t.Errorf("extended gap category %q has no candidates", category)
		}
	}
}
