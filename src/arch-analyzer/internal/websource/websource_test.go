package websource

import "testing"

func TestExtractWebWorkspaceFacts(t *testing.T) {
	result, err := Extract("testdata/repository")
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	if result.Coverage == "" || result.Coverage == "complete" {
		t.Errorf("coverage = %q, want explicit partial coverage", result.Coverage)
	}
	if len(result.Components) != 8 {
		t.Errorf("components = %#v, want host, operator, BFFs, and three libraries", result.Components)
	}
	if len(result.Dependencies) != 7 {
		t.Errorf("dependencies = %#v, want seven normalized npm/runtime dependencies", result.Dependencies)
	}
	wantVersions := map[string]string{
		"Node.js": ">= 22.0.0", "Fastify": "4.29.1", "React": "18.3.x",
		"PatternFly": "6.4.x", "Webpack Module Federation": "5.x",
		"@kubernetes/client-node": "0.12.3", "Turborepo": "2.9.16",
	}
	for _, dependency := range result.Dependencies {
		if dependency.Version != wantVersions[dependency.Name] || dependency.Source == "" {
			t.Errorf("dependency = %#v, want normalized version and evidence", dependency)
		}
	}
	if len(result.Endpoints) != 7 {
		t.Fatalf("endpoints = %#v, want four host, health, and two BFF surfaces", result.Endpoints)
	}
	wanted := map[string]bool{
		"GET /": true, "ALL /api/*": true, "ALL /_mf/:name/*": true,
		"WS /wss/k8s/*": true, "GET /healthcheck": true,
		"ALL /gen-ai/api/*": true, "ALL /gen-ai/api/v1/*": true,
	}
	for _, endpoint := range result.Endpoints {
		if !wanted[endpoint.Method+" "+endpoint.Path] || endpoint.Source == "" {
			t.Errorf("unexpected endpoint or missing evidence: %#v", endpoint)
		}
	}
	if len(result.Services) != 1 || result.Services[0].Ports[0].AppProtocol != "https" {
		t.Errorf("services = %#v, want TLS federation service evidence", result.Services)
	}
}
