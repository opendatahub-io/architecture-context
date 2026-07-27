package rustsource

import (
	"os"
	"path/filepath"
	"testing"
)

func TestExtractRustSourceFacts(t *testing.T) {
	result, err := Extract("testdata/repository")
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	if result.Coverage == "" || result.Coverage == "complete" {
		t.Errorf("coverage = %q, want explicit partial coverage", result.Coverage)
	}
	if len(result.Components) != 1 || result.Components[0].Name != "guardrail-example" ||
		result.Components[0].Type != "Rust Service (axum + tonic)" {
		t.Errorf("components = %#v", result.Components)
	}
	if len(result.Dependencies) != 4 {
		t.Fatalf("dependencies = %#v, want four direct Cargo dependencies", result.Dependencies)
	}
	if len(result.HTTPEndpoints) != 4 {
		t.Fatalf("endpoints = %#v, want health, info, and two application routes", result.HTTPEndpoints)
	}
	for _, endpoint := range result.HTTPEndpoints {
		if endpoint.Path == "/test-only" {
			t.Error("test-only route was extracted")
		}
		if endpoint.Source == "" || endpoint.Port == nil {
			t.Errorf("endpoint lacks evidence or port: %#v", endpoint)
		}
	}
	if len(result.Services) != 2 {
		t.Errorf("services = %#v, want application and health listeners", result.Services)
	}
	if len(result.Connections) != 4 || len(result.Internal) != 4 {
		t.Errorf("connections = %#v, internal = %#v", result.Connections, result.Internal)
	}
	if len(result.Secrets) != 4 {
		t.Errorf("secrets = %#v, want server TLS, client CA, downstream TLS, and API tokens", result.Secrets)
	}
	if len(result.Authentication) != 4 {
		t.Errorf("authentication = %#v, want passthrough, health, TLS, and token rewrite controls", result.Authentication)
	}
}

func TestExtractRustWorkspaceManifest(t *testing.T) {
	root := t.TempDir()
	member := filepath.Join(root, "router")
	if err := os.MkdirAll(member, 0o755); err != nil {
		t.Fatal(err)
	}
	write := func(path, content string) {
		t.Helper()
		if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
			t.Fatal(err)
		}
	}
	write(filepath.Join(root, "Cargo.toml"), "[workspace]\nmembers = [\"router\"]\nresolver = \"2\"\n")
	write(filepath.Join(member, "Cargo.toml"), "[package]\nname = \"workspace-router\"\nversion = \"0.1.0\"\ndescription = \"workspace router\"\n\n[dependencies]\naxum = \"0.7\"\n")

	result, err := Extract(root)
	if err != nil {
		t.Fatalf("Extract() workspace error = %v", err)
	}
	if len(result.Components) != 1 || result.Components[0].Name != "workspace-router" {
		t.Fatalf("components = %#v, want workspace member package", result.Components)
	}
	if len(result.Dependencies) != 1 || result.Dependencies[0].Name != "axum" || result.Dependencies[0].Source != "router/Cargo.toml:7" {
		t.Fatalf("dependencies = %#v, want source-backed workspace dependency", result.Dependencies)
	}
}
