package gosource

import (
	"testing"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func TestControllerComponentsEmitWhenMultipleControllersExist(t *testing.T) {
	watches := []model.ControllerWatch{
		{Type: "For", GVK: "example.io/v1/Widget", Controller: "WidgetReconciler", Source: "widget.go:10"},
		{Type: "For", GVK: "example.io/v1/Gadget", Controller: "GadgetReconciler", Source: "gadget.go:15"},
		{Type: "Owns", GVK: "/v1/Pod", Controller: "WidgetReconciler", Source: "widget.go:11"},
	}
	components := extractControllerComponents(watches)
	if len(components) != 2 {
		t.Fatalf("components = %#v, want 2 controller components", components)
	}
	names := map[string]bool{}
	for _, c := range components {
		names[c.Name] = true
		if c.Type != "Controller" {
			t.Errorf("component %s type = %q, want Controller", c.Name, c.Type)
		}
	}
	if !names["Widget controller"] || !names["Gadget controller"] {
		t.Errorf("components = %#v, want Widget and Gadget controllers", components)
	}
}

func TestControllerComponentsSuppressSingleController(t *testing.T) {
	watches := []model.ControllerWatch{
		{Type: "For", GVK: "example.io/v1/Widget", Controller: "WidgetReconciler", Source: "widget.go:10"},
		{Type: "Owns", GVK: "/v1/Pod", Controller: "WidgetReconciler", Source: "widget.go:11"},
	}
	components := extractControllerComponents(watches)
	if len(components) != 0 {
		t.Fatalf("components = %#v, want no components for single controller", components)
	}
}

func TestControllerComponentsIgnoreNonForWatches(t *testing.T) {
	watches := []model.ControllerWatch{
		{Type: "For", GVK: "example.io/v1/Widget", Controller: "WidgetReconciler", Source: "widget.go:10"},
		{Type: "Owns", GVK: "example.io/v1/Gadget", Controller: "WidgetReconciler", Source: "widget.go:11"},
		{Type: "Watches", GVK: "example.io/v1/Sprocket", Controller: "WidgetReconciler", Source: "widget.go:12"},
	}
	components := extractControllerComponents(watches)
	if len(components) != 0 {
		t.Fatalf("components = %#v, want no components when only one For watch exists", components)
	}
}
