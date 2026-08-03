package gosource

import (
	"strings"
	"testing"
)

func TestResourceOperationsRetainExternalPlatformCRDsAndCreateOrUpdate(t *testing.T) {
	root := writeSecurityRepository(t, `package controller
import (
	certmanagerv1 "github.com/cert-manager/cert-manager/pkg/apis/certmanager/v1"
	gatewayv1 "sigs.k8s.io/gateway-api/apis/v1"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
)
type Reconciler struct { Client fakeClient }
type fakeClient struct{}
func (fakeClient) Create(any, any) error { return nil }
func (r *Reconciler) reconcile(ctx any) {
	certificate := &certmanagerv1.Certificate{}
	_ = r.Client.Create(ctx, certificate)
	route := &gatewayv1.HTTPRoute{}
	_, _ = controllerutil.CreateOrUpdate(ctx, r.Client, route, func() error { return nil })
}
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.ComponentRefs) != 2 {
		t.Fatalf("component refs = %#v, want cert-manager and Gateway API operations", result.ComponentRefs)
	}
	want := map[string]string{
		"cert-manager.io/v1/Certificate":         "create operations by Reconciler",
		"gateway.networking.k8s.io/v1/HTTPRoute": "create, update operations by Reconciler",
	}
	for _, reference := range result.ComponentRefs {
		if want[reference.Component] != reference.Reference || reference.Interaction != "Resource CRUD" || reference.Source == "" {
			t.Errorf("reference = %#v, want source-backed platform CRD mutation", reference)
		}
		delete(want, reference.Component)
	}
	if len(want) != 0 {
		t.Errorf("missing component refs = %#v", want)
	}
}

func TestResourceOperationsRejectPlatformTypesWithoutMutation(t *testing.T) {
	root := writeSecurityRepository(t, `package controller
import (
	certmanagerv1 "github.com/cert-manager/cert-manager/pkg/apis/certmanager/v1"
	gatewayv1 "sigs.k8s.io/gateway-api/apis/v1"
)
func reconcile() {
	_ = &certmanagerv1.Certificate{}
	_ = &gatewayv1.HTTPRoute{}
}
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	for _, reference := range result.ComponentRefs {
		if strings.Contains(reference.Component, "cert-manager") || strings.Contains(reference.Component, "gateway.networking") {
			t.Fatalf("component refs = %#v, want imports and type literals alone rejected", result.ComponentRefs)
		}
	}
}

func TestResourceOperationsRetainDynamicGVKClientOperations(t *testing.T) {
	root := writeSecurityRepository(t, `package controller
import (
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime/schema"
)
type Reconciler struct { Client fakeClient }
type fakeClient struct{}
func (fakeClient) Get(any, any, any) error { return nil }
func (r *Reconciler) reconcile(ctx any) {
	apiServer := &unstructured.Unstructured{}
	apiServer.SetGroupVersionKind(schema.GroupVersionKind{
		Group: "config.openshift.io", Version: "v1", Kind: "APIServer",
	})
	_ = r.Client.Get(ctx, "cluster", apiServer)
}
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.ComponentRefs) != 1 {
		t.Fatalf("component refs = %#v, want one dynamic Kubernetes API read", result.ComponentRefs)
	}
	reference := result.ComponentRefs[0]
	if reference.Component != "config.openshift.io/v1/APIServer" ||
		reference.Reference != "get operations by Reconciler" || reference.Interaction != "Resource read" || reference.Source == "" {
		t.Errorf("reference = %#v, want canonical dynamic GVK read", reference)
	}
}

func TestResourceOperationsRejectDisconnectedOrUnresolvedDynamicGVKs(t *testing.T) {
	tests := []struct {
		name string
		body string
	}{
		{name: "no client operation", body: `
	resource := &unstructured.Unstructured{}
	resource.SetGroupVersionKind(schema.GroupVersionKind{Group: "config.openshift.io", Version: "v1", Kind: "APIServer"})`},
		{name: "different object", body: `
	resource := &unstructured.Unstructured{}
	resource.SetGroupVersionKind(schema.GroupVersionKind{Group: "config.openshift.io", Version: "v1", Kind: "APIServer"})
	other := &unstructured.Unstructured{}
	_ = client.Get(ctx, "cluster", other)`},
		{name: "unresolved kind", body: `
	resource := &unstructured.Unstructured{}
	resource.SetGroupVersionKind(schema.GroupVersionKind{Group: "config.openshift.io", Version: "v1", Kind: kind})
	_ = client.Get(ctx, "cluster", resource)`},
		{name: "operation precedes binding", body: `
	resource := &unstructured.Unstructured{}
	_ = client.Get(ctx, "cluster", resource)
	resource.SetGroupVersionKind(schema.GroupVersionKind{Group: "config.openshift.io", Version: "v1", Kind: "APIServer"})`},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			root := writeSecurityRepository(t, `package controller
import (
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime/schema"
)
type fakeClient struct{}
func (fakeClient) Get(any, any, any) error { return nil }
func reconcile(ctx any, client fakeClient, kind string) {`+test.body+`}
`)
			result, err := Extract(root)
			if err != nil {
				t.Fatal(err)
			}
			if len(result.ComponentRefs) != 0 {
				t.Fatalf("component refs = %#v, want disconnected dynamic GVK rejected", result.ComponentRefs)
			}
		})
	}
}

func TestGVRDynamicResourceOperationsDetectPackageLevelGVR(t *testing.T) {
	root := writeSecurityRepository(t, `package main
import (
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/client-go/dynamic"
)

const (
	hardwareProfileAPIGroup   = "infrastructure.opendatahub.io"
	hardwareProfileAPIVersion = "v1"
	hardwareProfileResource   = "hardwareprofiles"
)

var hardwareProfileGVR = schema.GroupVersionResource{
	Group:    hardwareProfileAPIGroup,
	Version:  hardwareProfileAPIVersion,
	Resource: hardwareProfileResource,
}

type KubernetesHelper struct {
	dynamicClient dynamic.Interface
}

func (h *KubernetesHelper) GetHardwareProfile(ns, name string) (any, error) {
	return h.dynamicClient.Resource(hardwareProfileGVR).Namespace(ns).Get(nil, name, nil)
}

func (h *KubernetesHelper) DeleteHardwareProfile(ns, name string) error {
	return h.dynamicClient.Resource(hardwareProfileGVR).Namespace(ns).Delete(nil, name, nil)
}

func main() {
	h := &KubernetesHelper{}
	h.GetHardwareProfile("ns", "name")
	h.DeleteHardwareProfile("ns", "name")
}
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.ComponentRefs) != 1 {
		t.Fatalf("component refs = %#v, want one merged GVR resource operation", result.ComponentRefs)
	}
	ref := result.ComponentRefs[0]
	if ref.Component != "infrastructure.opendatahub.io/v1/hardwareprofiles" {
		t.Errorf("component = %q, want infrastructure.opendatahub.io/v1/hardwareprofiles", ref.Component)
	}
	if ref.Type != "Kubernetes API" || ref.Source == "" {
		t.Errorf("reference = %#v, want source-backed Kubernetes API reference", ref)
	}
	if !strings.Contains(ref.Reference, "delete") || !strings.Contains(ref.Reference, "get") {
		t.Errorf("reference = %q, want get and delete operations", ref.Reference)
	}
}

func TestGVRDynamicResourceOperationsRejectUnreachableFunctions(t *testing.T) {
	root := writeSecurityRepository(t, `package main
import (
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/client-go/dynamic"
)
var gvr = schema.GroupVersionResource{Group: "test.io", Version: "v1", Resource: "things"}
type Helper struct { dynamicClient dynamic.Interface }
func (h *Helper) get(ns, name string) (any, error) {
	return h.dynamicClient.Resource(gvr).Namespace(ns).Get(nil, name, nil)
}
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.ComponentRefs) != 0 {
		t.Fatalf("component refs = %#v, want unreachable GVR operations rejected", result.ComponentRefs)
	}
}

func TestGVRDynamicResourceOperationsRejectUnresolvedConstants(t *testing.T) {
	root := writeSecurityRepository(t, `package main
import (
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/client-go/dynamic"
)
var gvr = schema.GroupVersionResource{Group: group, Version: version, Resource: resource}
type Helper struct { dynamicClient dynamic.Interface }
func (h *Helper) get(ns, name string) (any, error) {
	return h.dynamicClient.Resource(gvr).Namespace(ns).Get(nil, name, nil)
}
func main() { h := &Helper{}; h.get("ns", "name") }
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.ComponentRefs) != 0 {
		t.Fatalf("component refs = %#v, want unresolved GVR constants rejected", result.ComponentRefs)
	}
}

func TestDynamicResourceOperationsExcludeFixtureDirectories(t *testing.T) {
	if !ignoredDirectory("fixture") || !ignoredDirectory("fixtures") {
		t.Fatal("fixture directories must be excluded from production Go source extraction")
	}
}
