// +groupName=components.platform.opendatahub.io
package v1alpha1

import "k8s.io/apimachinery/pkg/runtime/schema"

var GroupVersion = schema.GroupVersion{Group: "components.platform.opendatahub.io", Version: "v1alpha1"}

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
// +kubebuilder:resource:scope=Cluster

// Dashboard is the Schema for the dashboards API.
type Dashboard struct{}

// +kubebuilder:object:root=true
type DashboardList struct{}

type DashboardSpec struct{}
