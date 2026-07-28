package loader

import (
	"testing"
	"testing/fstest"
)

func TestLoadVersionMergesComponentAnalyzerArtifacts(t *testing.T) {
	fsys := fstest.MapFS{
		"rhoai.next/example.md": {
			Data: []byte(`# Component: example

## Overview

Example component.
`),
		},
		"rhoai.next/example/.analyzer/component-architecture.json": {
			Data: []byte(`{
				"component": "example",
				"webhooks": [
					{
						"name": "vexample.kb.io",
						"type": "validating",
						"path": "/validate-example",
						"rules": [
							{"apiGroups": ["example.io"], "apiVersions": ["v1"], "resources": ["examples"], "operations": ["CREATE"]}
						]
					}
				],
				"platform_webhooks": [{"component": "example", "webhook": "vexample.kb.io"}],
				"controller_watches": [{"type": "Owns", "gvk": "apps/v1.Deployment", "controller": "example", "source": "controllers/example.go"}]
			}`),
		},
	}

	data, err := LoadVersion(fsys, nil, "rhoai.next")
	if err != nil {
		t.Fatalf("LoadVersion: %v", err)
	}
	doc := data.Components["example"]
	if doc == nil {
		t.Fatal("example component was not loaded")
	}
	if len(doc.Webhooks) != 1 {
		t.Fatalf("expected analyzer webhook to be merged, got %d", len(doc.Webhooks))
	}
	if len(doc.PlatformWebhooks) != 1 {
		t.Fatalf("expected platform webhook ref to be merged, got %d", len(doc.PlatformWebhooks))
	}
	if len(doc.ControllerWatches) != 1 {
		t.Fatalf("expected controller watch to be merged, got %d", len(doc.ControllerWatches))
	}
}
