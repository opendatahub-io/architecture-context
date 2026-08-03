// +groupName=datasciencecluster.opendatahub.io
package v1

import "k8s.io/apimachinery/pkg/runtime/schema"

var GroupVersion = schema.GroupVersion{Group: "datasciencecluster.opendatahub.io", Version: "v1"}

// +kubebuilder:object:root=true
// +kubebuilder:resource:scope=Cluster
type DataScienceCluster struct{}

// +kubebuilder:object:root=true
type DataScienceClusterList struct{}
