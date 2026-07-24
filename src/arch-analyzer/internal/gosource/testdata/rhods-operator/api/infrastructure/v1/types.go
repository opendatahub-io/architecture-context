// +groupName=infrastructure.opendatahub.io
package v1

import "k8s.io/apimachinery/pkg/runtime/schema"

var GroupVersion = schema.GroupVersion{Group: "infrastructure.opendatahub.io", Version: "v1"}

// +kubebuilder:object:root=true
// HardwareProfile defaults to namespaced scope when no resource marker overrides it.
type HardwareProfile struct{}

// +kubebuilder:object:root=true
type HardwareProfileList struct{}
