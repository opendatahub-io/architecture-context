// +groupName=infrastructure.opendatahub.io
package v1alpha1

import "k8s.io/apimachinery/pkg/runtime/schema"

var GroupVersion = schema.GroupVersion{Group: "infrastructure.opendatahub.io", Version: "v1alpha1"}

// +kubebuilder:object:root=true
// +kubebuilder:resource:scope=Cluster
type AWSKubernetesEngine struct{}

// +kubebuilder:object:root=true
type AWSKubernetesEngineList struct{}
