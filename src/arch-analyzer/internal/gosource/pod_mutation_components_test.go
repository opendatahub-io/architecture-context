package gosource

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestExtractPodMutationComponentFromSourceEvidence(t *testing.T) {
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, "go.mod"), []byte("module example.com/podmutator\n\ngo 1.25.0\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	path := filepath.Join(root, "pkg", "webhook", "admission", "pod", "mutator.go")
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(`package pod

// Mutator injects an auxiliary container into selected pods.
type Mutator struct{}

func (m *Mutator) InjectContainer() {}
`), 0o600); err != nil {
		t.Fatal(err)
	}

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Components) != 1 {
		t.Fatalf("components = %#v, want one pod mutation component", result.Components)
	}
	if result.Components[0].Type != "Sidecar / Init Container Utility" {
		t.Fatalf("component type = %q", result.Components[0].Type)
	}
	if !strings.Contains(result.Components[0].Source, "mutator.go") {
		t.Fatalf("component source = %q", result.Components[0].Source)
	}
}
