package extractor

import (
	"os"
	"path/filepath"
	"testing"
)

func TestExtractDockerfileEntrypoints(t *testing.T) {
	root := t.TempDir()
	path := filepath.Join(root, "Dockerfile.api")
	if err := os.WriteFile(path, []byte("FROM python:3.13\nENTRYPOINT [\\\"python\\\", \\\"-m\\\", \\\"api\\\"]\nCMD [\\\"--serve\\\"]\n"), 0o644); err != nil {
		t.Fatal(err)
	}

	entrypoints := extractDockerfileEntrypoints(root)
	if len(entrypoints) != 2 {
		t.Fatalf("entrypoints = %#v, want ENTRYPOINT and CMD", entrypoints)
	}
	if entrypoints[0].Runtime != "Container" || entrypoints[0].Source != "Dockerfile.api:2" {
		t.Errorf("entrypoint = %#v, want container source", entrypoints[0])
	}
}
