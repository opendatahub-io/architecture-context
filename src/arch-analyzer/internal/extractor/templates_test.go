package extractor

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/jctanner/arch-analyzer/internal/normalize"
	"github.com/jctanner/arch-analyzer/internal/renderer"
)

func TestExtractControllerTemplates(t *testing.T) {
	input, err := Extract("testdata/template-repository", Options{})
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	if !strings.HasPrefix(input.DataCoverage["controller_templates"], "partial:") {
		t.Errorf("template coverage = %q, want partial", input.DataCoverage["controller_templates"])
	}
	defaultValues := map[string]string{}
	for _, resolvedDefault := range input.SourceDefaults {
		defaultValues[resolvedDefault.Path] = resolvedDefault.Value
		if len(resolvedDefault.Sources) == 0 {
			t.Errorf("default lacks source evidence: %#v", resolvedDefault)
		}
	}
	if defaultValues["Spec.Rest.Port"] != "8080" || defaultValues["Spec.Proxy.Port"] != "8443" {
		t.Errorf("resolved defaults = %#v, want nested REST and proxy ports", defaultValues)
	}
	if len(input.Deployments) != 1 {
		t.Fatalf("deployments = %#v, want one deduplicated embedded template", input.Deployments)
	}
	deployment := input.Deployments[0]
	if deployment.Name != "{registry-name}" || deployment.Kind != "Controller-created Deployment" {
		t.Errorf("deployment = %#v, want generated registry deployment", deployment)
	}
	if len(deployment.Containers) != 2 {
		t.Errorf("containers = %#v, want possible API and proxy containers", deployment.Containers)
	}
	if len(input.Services) != 2 {
		t.Fatalf("services = %#v, want registry and catalog services", input.Services)
	}
	services := map[string]bool{}
	for _, service := range input.Services {
		services[service.Name] = true
		if service.Name == "must-not-appear" {
			t.Error("unreferenced template was extracted")
		}
	}
	for _, service := range input.Services {
		if service.Name == "{registry-name}" && (len(service.Ports) != 2 || service.Ports[0].AppProtocol != "https") {
			t.Errorf("conditional service ports = %#v, want application protocols", service.Ports)
		}
		for _, port := range service.Ports {
			if strings.Contains(portString(port.Port), "{") || strings.Contains(portString(port.TargetPort), "{") {
				t.Errorf("service port retained unresolved placeholder: %#v", port)
			}
		}
	}
	if !services["{registry-name}"] || !services["model-catalog"] {
		t.Errorf("service identities = %#v", services)
	}
	if len(input.IngressRouting) != 1 || input.IngressRouting[0].Backend != "{registry-name}" {
		t.Errorf("routing = %#v, want generated HTTPRoute", input.IngressRouting)
	}
	if len(input.Secrets) != 1 || input.Secrets[0].Name != "{registry-name}-credentials" ||
		input.Secrets[0].Type != "kubernetes.io/tls" || input.Secrets[0].ProvisionedBy != "controller Go source" {
		t.Errorf("secrets = %#v, want merged template reference and Go creation facts", input.Secrets)
	}
	if !strings.Contains(input.Deployments[0].Source, "managed.yaml.tmpl:") {
		t.Errorf("source = %q, want template evidence", input.Deployments[0].Source)
	}

	document := normalize.Input(input, normalize.Options{Distribution: "RHOAI", GeneratedBy: "test"})
	var markdown bytes.Buffer
	if err := renderer.Markdown(&markdown, document); err != nil {
		t.Fatalf("Markdown() error = %v", err)
	}
	for _, expected := range []string{
		"| {registry-name} | Controller-created Deployment |",
		"| {registry-name} | ClusterIP | 8443/TCP | 8443 | HTTPS |",
		"| model-catalog | ClusterIP | 8080/TCP | 8080 | TCP |",
		"| model-registry-{registry-name} | HTTPRoute |",
		"managed.yaml.tmpl",
	} {
		if !strings.Contains(markdown.String(), expected) {
			t.Errorf("Markdown missing %q", expected)
		}
	}
}

func TestExtractControllerTemplatesSkipsUnparseableTemplate(t *testing.T) {
	root := t.TempDir()
	validPath := filepath.Join(root, "valid.yaml.tmpl")
	invalidPath := filepath.Join(root, "invalid.yaml.tmpl")
	valid := "apiVersion: v1\nkind: Service\nmetadata:\n  name: example\n"
	if err := os.WriteFile(validPath, []byte(valid), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(invalidPath, []byte("kind: [\n"), 0o600); err != nil {
		t.Fatal(err)
	}

	facts, _, coverage, err := extractControllerTemplates(
		root, []string{validPath, invalidPath}, nil,
	)
	if err != nil {
		t.Fatalf("extractControllerTemplates() error = %v", err)
	}
	if len(facts.Services) != 1 || facts.Services[0].Name != "example" {
		t.Fatalf("services = %#v, want valid template retained", facts.Services)
	}
	if !strings.Contains(coverage, "1 controller templates could not be parsed") {
		t.Errorf("coverage = %q, want parse failure", coverage)
	}
}

func portString(value any) string {
	if value == nil {
		return ""
	}
	return strings.TrimSpace(strings.ReplaceAll(strings.TrimSpace(fmt.Sprint(value)), "\n", ""))
}
