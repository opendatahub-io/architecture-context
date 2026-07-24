// +groupName=widgets.example.io
package v2

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime/schema"
)

var GroupVersion = schema.GroupVersion{Group: "widgets.example.io", Version: "v2"}

// +kubebuilder:object:root=true
type Widget struct {
	metav1.TypeMeta `json:",inline"`
}

// +kubebuilder:object:root=true
type WidgetList struct {
	metav1.TypeMeta `json:",inline"`
	Items           []Widget `json:"items"`
}
