// +groupName=services.platform.opendatahub.io
package v1alpha1

import "k8s.io/apimachinery/pkg/runtime/schema"

var GroupVersion = schema.GroupVersion{Group: "services.platform.opendatahub.io", Version: "v1alpha1"}

// +kubebuilder:object:root=true
// +kubebuilder:resource:scope=Cluster
type Auth struct{}

// +kubebuilder:object:root=true
type AuthList struct{}
