package schema

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestExtractCRDVersionSchemas(t *testing.T) {
	repository := t.TempDir()
	content := `apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: widgets.example.io
spec:
  names:
    kind: Widget
  versions:
    - name: v1
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
    - name: v1beta1
      schema:
        openAPIV3Schema:
          type: object
`
	if err := os.WriteFile(filepath.Join(repository, "widget.yaml"), []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
	output := filepath.Join(t.TempDir(), "schemas")
	count, err := Extract(repository, output)
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	if count != 2 {
		t.Fatalf("count = %d, want two version schemas", count)
	}
	result, err := os.ReadFile(filepath.Join(output, "widget.v1.json"))
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(result), `"properties"`) || !strings.HasSuffix(string(result), "\n") {
		t.Errorf("schema output = %s, want formatted JSON schema", result)
	}
}
