package extractor

import (
	"testing"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func TestPrometheusAnnotationEmitsIntegrationAndDependency(t *testing.T) {
	objects := []object{{
		data: map[string]any{
			"kind":       "Service",
			"apiVersion": "v1",
			"metadata": map[string]any{
				"name": "trustyai-service",
				"annotations": map[string]any{
					"prometheus.io/scrape": "true",
					"prometheus.io/port":   "8080",
					"prometheus.io/path":   "/q/metrics",
				},
			},
			"spec": map[string]any{
				"type": "ClusterIP",
				"ports": []any{
					map[string]any{"port": 8080, "targetPort": 8080},
				},
			},
		},
		source: "service.yaml", line: 1,
	}}
	var input model.Input
	collect(objects, &input)

	if len(input.IntegrationPoints) != 1 {
		t.Fatalf("integration points = %d, want 1 Prometheus fact", len(input.IntegrationPoints))
	}
	fact := input.IntegrationPoints[0]
	if fact.Component != "Prometheus" || fact.InteractionType != "Inbound scrape" {
		t.Errorf("integration = %q / %q, want Prometheus / Inbound scrape", fact.Component, fact.InteractionType)
	}
	if fact.Protocol != "HTTP" {
		t.Errorf("protocol = %q, want HTTP", fact.Protocol)
	}
	if fact.Port != "8080" {
		t.Errorf("port = %v, want 8080", fact.Port)
	}

	if len(input.Dependencies.Internal) != 1 {
		t.Fatalf("internal dependencies = %d, want 1 Prometheus dependency", len(input.Dependencies.Internal))
	}
	dep := input.Dependencies.Internal[0]
	if dep.Component != "Prometheus" || dep.Interaction != "monitoring" {
		t.Errorf("dependency = %q / %q, want Prometheus / monitoring", dep.Component, dep.Interaction)
	}
}

func TestPrometheusAnnotationNotEmittedWithoutScrape(t *testing.T) {
	objects := []object{{
		data: map[string]any{
			"kind":       "Service",
			"apiVersion": "v1",
			"metadata": map[string]any{
				"name": "no-scrape-service",
				"annotations": map[string]any{
					"prometheus.io/port": "8080",
				},
			},
			"spec": map[string]any{"type": "ClusterIP"},
		},
		source: "service.yaml", line: 1,
	}}
	var input model.Input
	collect(objects, &input)

	if len(input.IntegrationPoints) != 0 {
		t.Errorf("integration points = %d, want 0 without scrape annotation", len(input.IntegrationPoints))
	}
	if len(input.Dependencies.Internal) != 0 {
		t.Errorf("internal dependencies = %d, want 0 without scrape annotation", len(input.Dependencies.Internal))
	}
}

func TestPrometheusAnnotationScrapeFalse(t *testing.T) {
	objects := []object{{
		data: map[string]any{
			"kind":       "Service",
			"apiVersion": "v1",
			"metadata": map[string]any{
				"name": "disabled-scrape",
				"annotations": map[string]any{
					"prometheus.io/scrape": "false",
				},
			},
			"spec": map[string]any{"type": "ClusterIP"},
		},
		source: "service.yaml", line: 1,
	}}
	var input model.Input
	collect(objects, &input)

	if len(input.IntegrationPoints) != 0 {
		t.Errorf("integration points = %d, want 0 with scrape=false", len(input.IntegrationPoints))
	}
}

func TestServiceCAAnnotationEmitsDependency(t *testing.T) {
	objects := []object{{
		data: map[string]any{
			"kind":       "ConfigMap",
			"apiVersion": "v1",
			"metadata": map[string]any{
				"name": "planner-service-ca",
				"annotations": map[string]any{
					"service.beta.openshift.io/inject-cabundle": "true",
				},
			},
		},
		source: "service-ca-configmap.yaml", line: 1,
	}}
	var input model.Input
	collect(objects, &input)

	if len(input.Dependencies.Internal) != 1 {
		t.Fatalf("internal dependencies = %d, want 1 Service CA dependency", len(input.Dependencies.Internal))
	}
	dep := input.Dependencies.Internal[0]
	if dep.Component != "OpenShift Service CA" {
		t.Errorf("component = %q, want OpenShift Service CA", dep.Component)
	}
	if dep.Interaction != "CA bundle injection" {
		t.Errorf("interaction = %q, want CA bundle injection", dep.Interaction)
	}
}

func TestServiceCAAnnotationNotEmittedWithoutAnnotation(t *testing.T) {
	objects := []object{{
		data: map[string]any{
			"kind":       "ConfigMap",
			"apiVersion": "v1",
			"metadata": map[string]any{
				"name": "plain-configmap",
			},
		},
		source: "configmap.yaml", line: 1,
	}}
	var input model.Input
	collect(objects, &input)

	if len(input.Dependencies.Internal) != 0 {
		t.Errorf("internal dependencies = %d, want 0 without inject-cabundle annotation", len(input.Dependencies.Internal))
	}
}

func TestConfigMapWithoutServiceCAIsIgnored(t *testing.T) {
	objects := []object{{
		data: map[string]any{
			"kind":       "ConfigMap",
			"apiVersion": "v1",
			"metadata": map[string]any{
				"name": "app-config",
				"annotations": map[string]any{
					"app.kubernetes.io/name": "my-app",
				},
			},
		},
		source: "configmap.yaml", line: 1,
	}}
	var input model.Input
	collect(objects, &input)

	if len(input.Dependencies.Internal) != 0 {
		t.Errorf("internal dependencies = %d, want 0 for non-service-ca ConfigMap", len(input.Dependencies.Internal))
	}
}
