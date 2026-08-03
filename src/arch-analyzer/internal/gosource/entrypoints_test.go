package gosource

import (
	"os"
	"path/filepath"
	"testing"
)

func TestGoEntrypointsDetectsControllerRuntime(t *testing.T) {
	root := writeSecurityRepository(t, `package main

import (
	"sigs.k8s.io/controller-runtime"
)

func main() { _ = ctrl.SetupSignalHandler() }
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Entrypoints) != 1 {
		t.Fatalf("entrypoints = %d, want 1", len(result.Entrypoints))
	}
	ep := result.Entrypoints[0]
	if ep.Runtime != "Go" {
		t.Errorf("runtime = %q, want Go", ep.Runtime)
	}
	if ep.Type != "Go controller-runtime operator" {
		t.Errorf("type = %q, want Go controller-runtime operator", ep.Type)
	}
	if ep.Source == "" {
		t.Error("source must not be empty")
	}
}

func TestGoEntrypointsDetectsCobraCLI(t *testing.T) {
	root := writeSecurityRepository(t, `package main

import (
	"github.com/spf13/cobra"
)

func main() { _ = &cobra.Command{Use: "tool"} }
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Entrypoints) != 1 {
		t.Fatalf("entrypoints = %d, want 1", len(result.Entrypoints))
	}
	if result.Entrypoints[0].Type != "Go CLI application" {
		t.Errorf("type = %q, want Go CLI application", result.Entrypoints[0].Type)
	}
}

func TestGoEntrypointsDetectsPlainExecutable(t *testing.T) {
	root := writeSecurityRepository(t, `package main

func main() { println("hello") }
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Entrypoints) != 1 {
		t.Fatalf("entrypoints = %d, want 1", len(result.Entrypoints))
	}
	if result.Entrypoints[0].Type != "Go executable" {
		t.Errorf("type = %q, want Go executable", result.Entrypoints[0].Type)
	}
}

func TestGoEntrypointsMultiRuntime(t *testing.T) {
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, "go.mod"), []byte("module example.com/multi\n\ngo 1.25.0\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	cmdDir := filepath.Join(root, "cmd", "operator")
	if err := os.MkdirAll(cmdDir, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(cmdDir, "main.go"), []byte(`package main

import "sigs.k8s.io/controller-runtime"

func main() { _ = ctrl.SetupSignalHandler() }
`), 0o600); err != nil {
		t.Fatal(err)
	}
	cliDir := filepath.Join(root, "cmd", "cli")
	if err := os.MkdirAll(cliDir, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(cliDir, "main.go"), []byte(`package main

import "github.com/spf13/cobra"

func main() { _ = &cobra.Command{Use: "tool"} }
`), 0o600); err != nil {
		t.Fatal(err)
	}
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Entrypoints) < 2 {
		t.Fatalf("entrypoints = %d, want at least 2 for multi-runtime", len(result.Entrypoints))
	}
	types := map[string]bool{}
	for _, ep := range result.Entrypoints {
		types[ep.Type] = true
		if ep.Source == "" {
			t.Errorf("entrypoint %q missing source", ep.Name)
		}
	}
	if !types["Go controller-runtime operator"] {
		t.Error("missing controller-runtime operator entrypoint")
	}
	if !types["Go CLI application"] {
		t.Error("missing CLI application entrypoint")
	}
}
