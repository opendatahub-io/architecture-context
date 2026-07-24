package v1

type RestSpec struct {
	//+kubebuilder:default=8080
	Port  *int32 `json:"port,omitempty"`
	Image string `json:"image,omitempty"`
}

type ProxySpec struct {
	//+kubebuilder:default=8443

	// Port used by the proxy listener.
	Port  *int32 `json:"port,omitempty"`
	Image string `json:"image,omitempty"`
}

type RegistrySpec struct {
	Rest  RestSpec   `json:"rest"`
	Proxy *ProxySpec `json:"proxy,omitempty"`
}
