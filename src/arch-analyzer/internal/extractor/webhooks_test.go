package extractor

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestExtractEnumeratesGoAndConversionWebhooks(t *testing.T) {
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, "go.mod"), []byte("module example.test\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "webhook.go"), []byte(`package example

// +kubebuilder:webhook:verbs=create;update,mutating=true,groups=example.io,resources=widgets,versions=v1,name=widget-mutator,path=/mutate
`), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "crd.yaml"), []byte(`apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: gadgets.example.io
spec:
  group: example.io
  names:
    kind: Gadget
    plural: gadgets
  scope: Namespaced
  conversion:
    strategy: Webhook
    webhook:
      conversionReviewVersions: [v1, v1beta1]
      clientConfig:
        service:
          name: conversion-service
          path: /convert
`), 0o644); err != nil {
		t.Fatal(err)
	}

	input, err := Extract(root, Options{Distribution: "rhoai.next"})
	if err != nil {
		t.Fatal(err)
	}
	if len(input.Webhooks) != 2 {
		t.Fatalf("webhook count = %d, want 2: %#v", len(input.Webhooks), input.Webhooks)
	}

	seen := map[string]bool{}
	for _, webhook := range input.Webhooks {
		seen[webhook.Name] = true
		if len(webhook.Sources) != 1 || webhook.Sources[0].File == "" || webhook.Sources[0].Line == 0 {
			t.Errorf("webhook %q lacks source evidence: %#v", webhook.Name, webhook.Sources)
		}
	}
	if !seen["widget-mutator"] || !seen["gadgets.example.io"] {
		t.Errorf("webhooks = %#v, want Go marker and conversion entries", input.Webhooks)
	}
	if !strings.HasPrefix(input.DataCoverage["webhooks_source"], "partial:") {
		t.Errorf("webhook source coverage = %q, want explicit partial coverage", input.DataCoverage["webhooks_source"])
	}
}
