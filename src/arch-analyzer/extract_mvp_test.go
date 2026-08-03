package main

import (
	"bytes"
	"path/filepath"
	"strings"
	"testing"

	"github.com/jctanner/arch-analyzer/internal/extractor"
	"github.com/jctanner/arch-analyzer/internal/normalize"
	"github.com/jctanner/arch-analyzer/internal/renderer"
)

func TestExtractRenderMVP(t *testing.T) {
	repository := filepath.Join("internal", "extractor", "testdata", "repository")
	input, err := extractor.Extract(repository, extractor.Options{Distribution: "rhoai.next"})
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	document := normalize.Input(input, normalize.Options{Distribution: "RHOAI", GeneratedBy: "arch-analyzer test"})
	var output bytes.Buffer
	if err := renderer.Markdown(&output, document); err != nil {
		t.Fatalf("Markdown() error = %v", err)
	}
	for _, expected := range []string{
		"# Component: repository",
		"| example.io | v1 | Widget | Namespaced |",
		"| /readyz | GET | metrics | HTTP |",
		"| /v1/widgets | GET |  | HTTP |",
		"| rhoai-controller | ClusterIP | 8443/TCP | metrics | TCP |",
		"| rhoai-manager | example.io | widgets | get, list, watch |",
		"| rhoai-manager | system | rhoai-manager (ClusterRole) | rhoai-controller |",
		"| database-credentials | referenced |",
		"| controller.example.test |",
		"| api/v1/Widget | Controller watch (For) |",
		"overlays/rhoai.next/service-patch.yaml",
	} {
		if !strings.Contains(output.String(), expected) {
			t.Errorf("Markdown missing %q", expected)
		}
	}
}
