package gosource

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestExtractGoSourceFacts(t *testing.T) {
	result, err := Extract("testdata/repository")
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	if result.Coverage == "" || result.Coverage == "complete" {
		t.Errorf("coverage = %q, want explicit partial coverage", result.Coverage)
	}
	if result.CRDCoverage != "complete: extracted 2 Kubebuilder CRD identities" {
		t.Errorf("CRD coverage = %q", result.CRDCoverage)
	}
	if len(result.CRDs) != 2 {
		t.Fatalf("CRDs = %#v, want v1 and v2 Widget roots", result.CRDs)
	}
	for _, crd := range result.CRDs {
		if crd.Group != "widgets.example.io" || crd.Kind != "Widget" || crd.Source == "" {
			t.Errorf("CRD = %#v, want source-backed Widget identity", crd)
		}
	}
	if result.CRDs[0].Scope != "Cluster" || result.CRDs[1].Scope != "Namespaced" {
		t.Errorf("CRD scopes = %#v, want explicit and default scope", result.CRDs)
	}
	if result.Dependencies.GoVersion != "1.26.0" || len(result.Dependencies.GoModules) != 3 {
		t.Errorf("dependencies = %#v, want highest Go version and three unique direct modules", result.Dependencies)
	}
	if len(result.ControllerWatches) != 3 {
		t.Fatalf("watches = %#v, want For, Owns, and Watches", result.ControllerWatches)
	}
	wantGVKs := map[string]bool{
		"api/v1/Widget":      true,
		"apps/v1/Deployment": true,
		"/v1/Secret":         true,
	}
	for _, watch := range result.ControllerWatches {
		if !wantGVKs[watch.GVK] {
			t.Errorf("unexpected GVK %q", watch.GVK)
		}
		if watch.Controller != "WidgetReconciler" || watch.Source == "" {
			t.Errorf("watch lacks controller or evidence: %#v", watch)
		}
	}
	if len(result.HTTPEndpoints) != 4 {
		t.Fatalf("routes = %#v, want root and nested-module routes", result.HTTPEndpoints)
	}
	for _, route := range result.HTTPEndpoints {
		if route.Path == "/test-only" {
			t.Error("test-only route was included")
		}
		if route.Path == "/generated" {
			t.Error("generated route was included")
		}
		if route.Source == "" {
			t.Errorf("route lacks evidence: %#v", route)
		}
	}
	if len(result.ComponentRefs) != 2 {
		t.Fatalf("resource operations = %#v, want Deployment and Secret", result.ComponentRefs)
	}
	wantInteractions := map[string]string{
		"apps/v1/Deployment": "Resource CRUD",
		"/v1/Secret":         "Resource read",
	}
	for _, reference := range result.ComponentRefs {
		if wantInteractions[reference.Component] != reference.Interaction {
			t.Errorf("resource operation = %#v", reference)
		}
	}
	resolvedDefault, ok := result.TemplateDefaults["Spec.Endpoint.Port"]
	if !ok || resolvedDefault.Value != "9443" || len(resolvedDefault.Sources) == 0 {
		t.Errorf("template default = %#v, want source-backed nested default", resolvedDefault)
	}
	if len(result.ConstructedSecrets) != 1 {
		t.Fatalf("constructed secrets = %#v, want only the creation-backed Secret", result.ConstructedSecrets)
	}
	constructed := result.ConstructedSecrets[0]
	if constructed.Name != "{name}-credentials" || constructed.Type != "kubernetes.io/tls" || constructed.Source == "" {
		t.Errorf("constructed secret = %#v", constructed)
	}
}

func TestExtractRhodsOperatorKubebuilderCRDs(t *testing.T) {
	result, err := Extract("testdata/rhods-operator")
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	if result.CRDCoverage != "complete: extracted 6 Kubebuilder CRD identities" {
		t.Errorf("CRD coverage = %q", result.CRDCoverage)
	}
	if len(result.CRDs) != 6 {
		t.Fatalf("CRDs = %#v, want six versioned identities", result.CRDs)
	}
	want := map[string]string{
		"components.platform.opendatahub.io/v1alpha1/Dashboard":      "Cluster",
		"services.platform.opendatahub.io/v1alpha1/Auth":             "Cluster",
		"infrastructure.opendatahub.io/v1/HardwareProfile":           "Namespaced",
		"infrastructure.opendatahub.io/v1alpha1/AWSKubernetesEngine": "Cluster",
		"datasciencecluster.opendatahub.io/v1/DataScienceCluster":    "Cluster",
		"datasciencecluster.opendatahub.io/v2/DataScienceCluster":    "Cluster",
	}
	for _, crd := range result.CRDs {
		key := crd.Group + "/" + crd.Version + "/" + crd.Kind
		if want[key] != crd.Scope {
			t.Errorf("CRD = %#v, unexpected identity or scope", crd)
		}
		if crd.Source == "" {
			t.Errorf("CRD = %#v, missing source evidence", crd)
		}
		delete(want, key)
	}
	if len(want) != 0 {
		t.Errorf("missing CRDs = %#v", want)
	}
}

func TestExtractKubebuilderCRDCoverageStates(t *testing.T) {
	tests := []struct {
		name       string
		source     string
		wantPrefix string
	}{
		{
			name:       "no root markers",
			source:     "package api\n\ntype Config struct{}\n",
			wantPrefix: "not_found",
		},
		{
			name: "root missing group metadata",
			source: `package v1

// +kubebuilder:object:root=true
type Widget struct{}
`,
			wantPrefix: "partial:",
		},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			root := t.TempDir()
			if err := os.WriteFile(filepath.Join(root, "go.mod"), []byte("module example.com/api\n\ngo 1.25.0\n"), 0o600); err != nil {
				t.Fatal(err)
			}
			if err := os.WriteFile(filepath.Join(root, "types.go"), []byte(test.source), 0o600); err != nil {
				t.Fatal(err)
			}

			result, err := Extract(root)
			if err != nil {
				t.Fatalf("Extract() error = %v", err)
			}
			if !strings.HasPrefix(result.CRDCoverage, test.wantPrefix) {
				t.Errorf("CRD coverage = %q, want prefix %q", result.CRDCoverage, test.wantPrefix)
			}
		})
	}

	result, err := Extract(t.TempDir())
	if err != nil {
		t.Fatalf("Extract() without Go module error = %v", err)
	}
	if result.CRDCoverage != "not_applicable" {
		t.Errorf("CRD coverage = %q, want not_applicable", result.CRDCoverage)
	}
}

func TestExtractKubebuilderReferenceContract(t *testing.T) {
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, "go.mod"), []byte("module example.com/api\n\ngo 1.25.0\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	source := `package v1

// +kubebuilder:object:root=true
type Pool struct { Spec PoolSpec }
type PoolSpec struct { PickerRef PickerReference }
type PickerReference struct {
  // +kubebuilder:default=Service
  Kind Kind
  // +kubebuilder:default="FailClose"
  FailureMode FailureMode
}
type Kind string
type FailureMode string
const (
  FailureOpen FailureMode = "FailOpen"
  FailureClose FailureMode = "FailClose"
)
`
	if err := os.WriteFile(filepath.Join(root, "types.go"), []byte(source), 0o600); err != nil {
		t.Fatal(err)
	}
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.APIReferenceContracts) != 1 {
		t.Fatalf("reference contracts = %#v, want one typed CRD reference", result.APIReferenceContracts)
	}
	contract := result.APIReferenceContracts[0]
	if contract.OwnerKind != "Pool" || contract.Field != "Spec.PickerRef" || contract.DefaultKind != "Service" ||
		contract.FailureModeDefault != "FailClose" || strings.Join(contract.FailureModes, "/") != "FailOpen/FailClose" ||
		contract.Source == "" {
		t.Fatalf("reference contract = %#v, want source-backed default kind and failure behavior", contract)
	}
}

func TestExtractRuntimeModuleUseRequiresDirectDependencyAndRuntimeImport(t *testing.T) {
	root := t.TempDir()
	goMod := "module example.com/runtime\n\ngo 1.25.0\n\nrequire github.com/llm-d/llm-d-kv-cache v0.9.0\n"
	if err := os.WriteFile(filepath.Join(root, "go.mod"), []byte(goMod), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "main.go"), []byte(`package main
import _ "github.com/llm-d/llm-d-kv-cache/pkg/kvcache"
func main() {}
`), 0o600); err != nil {
		t.Fatal(err)
	}
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.RuntimeModuleUses) != 1 || result.RuntimeModuleUses[0].Module != "github.com/llm-d/llm-d-kv-cache" ||
		result.RuntimeModuleUses[0].Source == "" {
		t.Fatalf("runtime module uses = %#v, want direct runtime import", result.RuntimeModuleUses)
	}
	if err := os.WriteFile(filepath.Join(root, "main.go"), []byte("package main\nfunc main() {}\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	result, err = Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.RuntimeModuleUses) != 0 {
		t.Fatalf("runtime module uses = %#v, go.mod declaration alone must be rejected", result.RuntimeModuleUses)
	}
}

func TestExtractRuntimeModuleUseRejectsNestedModuleOwnedByRepository(t *testing.T) {
	root := t.TempDir()
	goMod := "module github.com/opendatahub-io/mlflow-operator\n\ngo 1.25.0\n\nrequire github.com/opendatahub-io/mlflow-operator/api v0.1.0\n"
	if err := os.WriteFile(filepath.Join(root, "go.mod"), []byte(goMod), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "main.go"), []byte(`package main
import _ "github.com/opendatahub-io/mlflow-operator/api/v1"
func main() {}
`), 0o600); err != nil {
		t.Fatal(err)
	}
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.RuntimeModuleUses) != 0 {
		t.Fatalf("runtime module uses = %#v, want repository-owned nested module rejected", result.RuntimeModuleUses)
	}
}
