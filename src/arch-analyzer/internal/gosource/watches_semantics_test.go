package gosource

import "testing"

func TestExternalWatchGVKsRetainCanonicalAPIIdentity(t *testing.T) {
	tests := map[string]string{
		"github.com/kedacore/keda/v2/apis/keda/v1alpha1":                            "keda.sh/v1alpha1/ScaledObject",
		"sigs.k8s.io/lws/api/leaderworkerset/v1":                                    "leaderworkerset.x-k8s.io/v1/ScaledObject",
		"github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1": "monitoring.coreos.com/v1/ScaledObject",
		"sigs.k8s.io/gateway-api-inference-extension/api/v1":                        "inference.networking.k8s.io/v1/ScaledObject",
		"sigs.k8s.io/gateway-api-inference-extension/apix/v1alpha2":                 "inference.networking.x-k8s.io/v1alpha2/ScaledObject",
		"github.com/kserve/kserve/pkg/apis/serving/v1beta1":                         "serving.kserve.io/v1beta1/ScaledObject",
	}
	for packagePath, want := range tests {
		if got := formatGVK(packagePath, "ScaledObject", "example.test"); got != want {
			t.Errorf("formatGVK(%q) = %q, want %q", packagePath, got, want)
		}
	}
}

func TestWatchConditionalWhenControllerRegistrationIsConditional(t *testing.T) {
	root := writeSecurityRepository(t, `package main
import (
    keda "github.com/kedacore/keda/v2/apis/keda/v1alpha1"
    ctrl "sigs.k8s.io/controller-runtime"
)
type ScaledObjectReconciler struct{}
func (r *ScaledObjectReconciler) SetupWithManager(mgr ctrl.Manager) error {
    return ctrl.NewControllerManagedBy(mgr).For(&keda.ScaledObject{}).Complete(r)
}
func run(mgr ctrl.Manager, enabled bool) error {
    if enabled {
        return (&ScaledObjectReconciler{}).SetupWithManager(mgr)
    }
    return nil
}
`)

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.ControllerWatches) != 1 || !result.ControllerWatches[0].Conditional ||
		result.ControllerWatches[0].GVK != "keda.sh/v1alpha1/ScaledObject" {
		t.Fatalf("watches = %#v, want conditional canonical KEDA watch", result.ControllerWatches)
	}
}
