// +groupName=widgets.example.io
package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime/schema"
)

var GroupVersion = schema.GroupVersion{Group: "widgets.example.io", Version: "v1"}

// +kubebuilder:object:root=true
// +kubebuilder:resource:scope=Cluster
type Widget struct {
	metav1.TypeMeta `json:",inline"`
	Spec            WidgetSpec `json:"spec,omitempty"`
}

// +kubebuilder:object:root=true
type WidgetList struct {
	metav1.TypeMeta `json:",inline"`
	Items           []Widget `json:"items"`
}

type NotACustomResource struct{}

type EndpointSpec struct {
	//+kubebuilder:default=9443

	// Port used by the endpoint.
	Port *int32 `json:"port,omitempty"`
}

type WidgetSpec struct {
	Endpoint EndpointSpec `json:"endpoint"`
}
