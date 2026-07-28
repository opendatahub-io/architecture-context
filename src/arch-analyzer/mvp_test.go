package main

import (
	"bytes"
	"strings"
	"testing"

	"github.com/jctanner/arch-analyzer/internal/model"
	"github.com/jctanner/arch-analyzer/internal/normalize"
	"github.com/jctanner/arch-analyzer/internal/renderer"
)

func TestRenderFirstMVP(t *testing.T) {
	input := model.Input{
		Component: "example",
		Repo:      "example/example",
		CommitSHA: "abc123",
		Summary:   "Example component.",
		CRDs: []model.CRD{{
			Group: "example.io", Version: "v1", Kind: "Widget", Scope: "Namespaced",
			Source: "config/crd/widget.yaml",
		}},
		Deployments: []model.Deployment{{
			Name: "example", Kind: "Deployment", Source: "config/deployment.yaml",
			Containers: []model.Container{{
				Name: "api", Image: "example/api:latest",
				LivenessProbe: &model.Probe{Type: "httpGet", Path: "/healthz", Port: float64(8080)},
			}},
		}},
		Services: []model.Service{{
			Name: "example", Type: "ClusterIP", Source: "config/service.yaml",
			Ports: []model.ServicePort{{Port: float64(8443), TargetPort: float64(8080), Protocol: "TCP"}},
		}},
		RBAC: model.RBAC{
			ClusterRoles: []model.Role{{
				Name: "manager", Source: "config/rbac.yaml",
				Rules: []model.RoleRule{{APIGroups: []string{"example.io"}, Resources: []string{"widgets"}, Verbs: []string{"get", "list"}}},
			}},
			ClusterRoleBindings: []model.Binding{{
				Name: "manager", RoleRef: "manager", Source: "config/binding.yaml",
				Subjects: []model.Subject{{Kind: "ServiceAccount", Name: "example", Namespace: "system"}},
			}},
		},
		Secrets: []model.Secret{{
			Name: "server-cert", Type: "kubernetes.io/tls", ProvisionedBy: "cert-manager",
			ReferencedBy: []string{"deployment/example"}, Source: "config/deployment.yaml",
		}},
		HTTPEndpoints: []model.HTTPEndpoint{{
			Method: "GET", Path: "/v1/widgets", Port: float64(8080), Protocol: "HTTP",
			Description: "List widgets | filtered", Source: "internal/http/widgets.go:42",
		}},
		GRPCServices: []model.GRPCService{{
			Service: "example.v1.WidgetService/GetWidget", Port: float64(9090), Protocol: "gRPC",
			Purpose: "Retrieve a widget", Source: "api/widget.proto:12",
		}},
		Dependencies: model.Dependencies{
			GoVersion: "1.25",
			GoModules: []model.GoModule{{Module: "sigs.k8s.io/controller-runtime", Version: "v0.22.0", Purpose: "Controller framework"}},
			Internal:  []model.InternalDependency{{Component: "platform-api", Interaction: "REST", Purpose: "Platform metadata"}},
		},
		ControllerWatches: []model.ControllerWatch{{
			Type: "For", GVK: "example.io/v1/Widget", Controller: "WidgetReconciler",
			Source: "internal/controller/widget.go:30",
		}},
		Webhooks: []model.Webhook{{
			Name: "vwidget", Type: "validating", Path: "/validate-example-io-v1-widget",
			Port: float64(9443), FailurePolicy: "Fail", Purpose: "Validate widgets",
			Rules:   []model.WebhookRule{{Resources: []string{"widgets"}, Operations: []string{"CREATE", "UPDATE"}}},
			Sources: []model.WebhookSource{{File: "internal/webhook/widget.go", Line: 21}},
		}},
		IngressRouting: []model.Ingress{{
			Kind: "HTTPRoute", Name: "example", Host: "example.test", TLS: true,
			Source: "config/httproute.yaml",
		}},
		ExternalConnections: []model.ExternalConnection{{
			Type: "object-storage", Service: "s3", Target: "s3://models", Protocol: "HTTPS",
			Port: float64(443), Function: "Store models", Source: "internal/storage/s3.go:18",
		}},
		IntegrationPoints: []model.IntegrationFact{{
			Component: "audit-api", InteractionType: "REST", Port: float64(443), Protocol: "HTTPS", Purpose: "Audit events",
		}},
		RecentChanges: []model.RecentChange{{Version: "abc123", Date: "2026-07-17", Changes: "Add analyzer facts"}},
	}

	document := normalize.Input(input, normalize.Options{Distribution: "RHOAI", GeneratedBy: "test"})
	if len(document.CRDs) != 1 || len(document.Services) != 1 || len(document.ClusterRoles) != 1 {
		t.Fatalf("normalized fact counts = CRDs %d, services %d, roles %d", len(document.CRDs), len(document.Services), len(document.ClusterRoles))
	}
	if len(document.HTTPEndpoints) != 3 {
		t.Fatalf("HTTP endpoint count = %d, want explicit + probe + webhook", len(document.HTTPEndpoints))
	}

	var output bytes.Buffer
	if err := renderer.Markdown(&output, document); err != nil {
		t.Fatalf("Markdown() error = %v", err)
	}
	markdown := output.String()
	for _, expected := range []string{
		"# Component: example",
		"## Architecture Components",
		"### Custom Resource Definitions (CRDs)",
		"| example.io | v1 | Widget | Namespaced |",
		"| /healthz | GET | 8080 | HTTP |",
		"| /validate-example-io-v1-widget | POST | 9443 | HTTPS | Unknown | TLS |",
		"| example.v1.WidgetService/GetWidget | 9090 | gRPC |",
		"| example | ClusterIP | 8443/TCP | 8080 | TCP |",
		"| example.test |",
		"| s3://models | 443 | HTTPS |",
		"| manager | example.io | widgets | get, list |",
		"| server-cert | kubernetes.io/tls | deployment/example | cert-manager |",
		"| platform-api | REST |",
		"| example.io/v1/Widget | Controller watch (For) |",
		"| audit-api | REST |  | 443 | HTTPS |",
		"| abc123 | 2026-07-17 | Add analyzer facts |",
		"Pending analyzer-assisted synthesis.",
		"List widgets \\| filtered",
	} {
		if !strings.Contains(markdown, expected) {
			t.Errorf("Markdown missing %q", expected)
		}
	}
	if strings.Contains(markdown, "## Source References") {
		t.Errorf("Markdown should not render source-reference audit tables")
	}
}

func BenchmarkRenderExistingModel(b *testing.B) {
	document := normalize.Input(model.Input{
		Component: "example",
		Repo:      "example/example",
		Services:  []model.Service{{Name: "api", Ports: []model.ServicePort{{Port: float64(8080)}}}},
	}, normalize.Options{})
	for range b.N {
		var output bytes.Buffer
		if err := renderer.Markdown(&output, document); err != nil {
			b.Fatal(err)
		}
	}
}
