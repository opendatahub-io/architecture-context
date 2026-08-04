package gosource

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestRuntimeManagedComponentRequiresRegisteredGatedManifestAction(t *testing.T) {
	source := `package controller

const managedState = "Managed"

func (m *Module) initialize(obj *Gateway, rr *Request) {
  if obj.Spec.BatchGateway.ManagementState == managedState {
    rr.Manifests = append(rr.Manifests, m.batchGatewayManifestInfo)
  }
}

func NewReconciler(m *Module, builder *Builder) {
  builder.WithAction(m.initialize)
}
`
	result := extractManagedComponentFixture(t, source)
	if len(result.RuntimeManagedUses) != 1 {
		t.Fatalf("runtime managed uses = %#v, want one", result.RuntimeManagedUses)
	}
	use := result.RuntimeManagedUses[0]
	if use.Field != "spec.batchGateway.managementState" || use.Action != "initialize" ||
		use.Lifecycle != "Manifest reconciliation" || use.Source == "" {
		t.Fatalf("runtime managed use = %#v, want registered lifecycle evidence", use)
	}

	for _, mutation := range []struct {
		name string
		old  string
		new  string
	}{
		{name: "missing Managed gate", old: "== managedState", new: "== \"Removed\""},
		{name: "missing manifest append", old: "rr.Manifests = append(rr.Manifests, m.batchGatewayManifestInfo)", new: "m.noop()"},
		{name: "missing action registration", old: "builder.WithAction(m.initialize)", new: "builder.Build()"},
	} {
		t.Run(mutation.name, func(t *testing.T) {
			mutated := extractManagedComponentFixture(t, strings.Replace(source, mutation.old, mutation.new, 1))
			if len(mutated.RuntimeManagedUses) != 0 {
				t.Fatalf("runtime managed uses = %#v, want incomplete proof rejected", mutated.RuntimeManagedUses)
			}
		})
	}
}

func TestRuntimeManagedComponentConstantsArePackageScoped(t *testing.T) {
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, "go.mod"), []byte("module example.com/operator\n\ngo 1.25.0\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	files := map[string]string{
		"controller.go": `package controller
const managedState = "Managed"
func (m *Module) initialize(obj *Gateway, rr *Request) {
  if obj.Spec.BatchGateway.ManagementState == managedState {
    rr.Manifests = append(rr.Manifests, m.manifest)
  }
}
func NewReconciler(m *Module, builder *Builder) { builder.WithAction(m.initialize) }
`,
		"other/constants.go": "package other\nconst managedState = \"Removed\"\n",
	}
	for relative, content := range files {
		path := filepath.Join(root, relative)
		if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
			t.Fatal(err)
		}
	}
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.RuntimeManagedUses) != 1 {
		t.Fatalf("runtime managed uses = %#v, want package-local Managed constant", result.RuntimeManagedUses)
	}
}

func extractManagedComponentFixture(t *testing.T, source string) Result {
	t.Helper()
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, "go.mod"), []byte("module example.com/operator\n\ngo 1.25.0\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "controller.go"), []byte(source), 0o600); err != nil {
		t.Fatal(err)
	}
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	return result
}
