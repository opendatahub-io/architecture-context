package gosource

import "testing"

func TestExtractRuntimeKubernetesClients(t *testing.T) {
	root := writeSecurityRepository(t, `package main

import (
	ctrl "sigs.k8s.io/controller-runtime"
	"k8s.io/client-go/discovery"
	"k8s.io/client-go/dynamic"
)

func run() {
	mgr, _ := ctrl.NewManager(ctrl.GetConfigOrDie(), ctrl.Options{})
	cfg := mgr.GetConfig()
	_ = dynamic.NewForConfigOrDie(cfg)
	_ = discovery.NewDiscoveryClientForConfigOrDie(cfg)
}
`)

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.RuntimeClients) != 3 {
		t.Fatalf("runtime clients = %#v, want manager, dynamic, and discovery clients", result.RuntimeClients)
	}
	want := map[string]bool{
		"controller-runtime manager": false,
		"client-go dynamic client":   false,
		"client-go discovery client": false,
	}
	for _, client := range result.RuntimeClients {
		if client.Target != "Kubernetes API" || client.Configuration == "" || client.Source == "" {
			t.Errorf("runtime client = %#v, want source-backed Kubernetes client", client)
		}
		if _, exists := want[client.Client]; !exists {
			t.Errorf("unexpected runtime client %#v", client)
		} else {
			want[client.Client] = true
		}
	}
	for client, found := range want {
		if !found {
			t.Errorf("missing runtime client %q", client)
		}
	}
}

func TestExtractRuntimeKubernetesClientsNewForConfig(t *testing.T) {
	root := writeSecurityRepository(t, `package main

import (
	"k8s.io/client-go/dynamic"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/discovery"
)

func run(cfg any) {
	_, _ = kubernetes.NewForConfig(cfg)
	_, _ = dynamic.NewForConfig(cfg)
	_, _ = discovery.NewDiscoveryClientForConfig(cfg)
}
`)

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.RuntimeClients) != 3 {
		t.Fatalf("runtime clients = %#v, want typed, dynamic, and discovery clients via NewForConfig", result.RuntimeClients)
	}
	want := map[string]bool{
		"client-go typed clientset": false,
		"client-go dynamic client":  false,
		"client-go discovery client": false,
	}
	for _, client := range result.RuntimeClients {
		if client.Target != "Kubernetes API" || client.Source == "" {
			t.Errorf("runtime client = %#v, want source-backed Kubernetes client", client)
		}
		want[client.Client] = true
	}
	for client, found := range want {
		if !found {
			t.Errorf("missing runtime client %q", client)
		}
	}
}

func TestRuntimeKubernetesClientsRequireConstruction(t *testing.T) {
	root := writeSecurityRepository(t, `package client

import (
	ctrl "sigs.k8s.io/controller-runtime"
	"k8s.io/client-go/dynamic"
)

var _ = ctrl.Options{}
var _ dynamic.Interface
`)

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.RuntimeClients) != 0 {
		t.Fatalf("runtime clients = %#v, want imports and types without construction rejected", result.RuntimeClients)
	}
}

func TestPrometheusRuntimeClientRequiresConstructionWrapperAndUse(t *testing.T) {
	root := writeSecurityRepository(t, `package main
import (
    "context"
    api "github.com/prometheus/client_golang/api"
    promv1 "github.com/prometheus/client_golang/api/prometheus/v1"
)
func validate(context.Context, promv1.API) error { return nil }
func run(cfg api.Config) error {
    client, err := api.NewClient(cfg)
    if err != nil { return err }
    promAPI := promv1.NewAPI(client)
    return validate(context.Background(), promAPI)
}
`)

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.RuntimeClients) != 1 || result.RuntimeClients[0].Target != "Prometheus" {
		t.Fatalf("runtime clients = %#v, want used Prometheus API client", result.RuntimeClients)
	}
}

func TestPrometheusRuntimeClientRejectsDisconnectedConstruction(t *testing.T) {
	root := writeSecurityRepository(t, `package main
import api "github.com/prometheus/client_golang/api"
func run(cfg api.Config) error {
    _, err := api.NewClient(cfg)
    return err
}
`)

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.RuntimeClients) != 0 {
		t.Fatalf("runtime clients = %#v, want disconnected client rejected", result.RuntimeClients)
	}
}
