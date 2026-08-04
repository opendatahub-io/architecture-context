package gosource

import (
	"strings"
	"testing"
)

func TestConstructedKubeRBACProxyRetainsCompleteRuntimeGraph(t *testing.T) {
	root := writeSecurityRepository(t, completeConstructedProxySource())
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.RuntimeProxies) != 1 {
		t.Fatalf("runtime proxies = %#v, want one complete control", result.RuntimeProxies)
	}
	proxy := result.RuntimeProxies[0]
	if proxy.Surface != "Evalhub API" || proxy.Methods != "REST" || proxy.ListenPort != 8443 ||
		proxy.Upstream != "http://127.0.0.1:8080/" || proxy.ServiceAccount != "{name}-service" ||
		proxy.TLSSecret != "{name}-tls" || proxy.ServicePort != 443 || proxy.ServiceTargetPort != 8443 ||
		proxy.ReviewRole != "auth-reviewer" {
		t.Errorf("runtime proxy = %#v, want retained workload, Service, TLS, and RBAC evidence", proxy)
	}
	if len(result.ConstructedBindings) != 1 || result.ConstructedBindings[0].Subjects[0].Name != "{name}-service" {
		t.Errorf("bindings = %#v, want created ServiceAccount binding", result.ConstructedBindings)
	}
}

func TestConstructedKubeRBACProxyRejectsPartialSourceGraphs(t *testing.T) {
	complete := completeConstructedProxySource()
	tests := []struct {
		name   string
		remove string
	}{
		{name: "container without TLS key", remove: `"--tls-private-key-file=/etc/tls/tls.key",`},
		{name: "workload without Secret volume", remove: `{Name: tlsName, VolumeSource: corev1.VolumeSource{Secret: &corev1.SecretVolumeSource{SecretName: tlsName}}},`},
		{name: "service spec not deployed", remove: `_ = buildServiceSpec()`},
		{name: "review binding not created", remove: `client.Create(ctx, binding)`},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			source := strings.Replace(complete, test.remove, "", 1)
			result, err := Extract(writeSecurityRepository(t, source))
			if err != nil {
				t.Fatal(err)
			}
			if len(result.RuntimeProxies) != 0 {
				t.Fatalf("runtime proxies = %#v, want partial graph rejected", result.RuntimeProxies)
			}
		})
	}
}

func TestRuntimeWebhookServerRetainsConditionalConstruction(t *testing.T) {
	root := writeSecurityRepository(t, `package main
import ctrlwebhook "sigs.k8s.io/controller-runtime/pkg/webhook"
func configure(enabled bool) {
	if enabled {
		server := ctrlwebhook.NewServer(ctrlwebhook.Options{Port: 9443})
		_ = server
	}
}
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.RuntimeWebhooks) != 1 || result.RuntimeWebhooks[0].Port != 9443 || !result.RuntimeWebhooks[0].Conditional {
		t.Fatalf("runtime webhooks = %#v, want conditional port 9443 server", result.RuntimeWebhooks)
	}
}

func completeConstructedProxySource() string {
	return `package evalhub
import (
	"context"
	"fmt"
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/intstr"
)
const (
	proxyName = "kube-rbac-proxy"
	listenPort = 8443
	appPort = 8080
	authRole = "auth-reviewer"
)
type Instance struct { Name string; Namespace string }
type fakeClient struct{}
var client fakeClient
var ctx context.Context
func (fakeClient) Create(context.Context, any) error { return nil }
func serviceAccountName(instance *Instance) string { return instance.Name + "-service" }
func buildServiceSpec() corev1.ServiceSpec {
	return corev1.ServiceSpec{Ports: []corev1.ServicePort{{Port: 443, TargetPort: intstr.FromString("https")}}}
}
func reconcileService() { _ = buildServiceSpec() }
func createBinding(instance *Instance, serviceAccount string) {
	binding := &rbacv1.ClusterRoleBinding{
		ObjectMeta: metav1.ObjectMeta{Name: instance.Name + "-auth"},
		Subjects: []rbacv1.Subject{{Kind: "ServiceAccount", Name: serviceAccount, Namespace: instance.Namespace}},
		RoleRef: rbacv1.RoleRef{Kind: "ClusterRole", Name: authRole},
	}
	client.Create(ctx, binding)
}
func reconcile(instance *Instance) {
	serviceAccount := serviceAccountName(instance)
	createBinding(instance, serviceAccount)
}
func buildDeploymentSpec(instance *Instance) corev1.PodSpec {
	tlsName := instance.Name + "-tls"
	app := corev1.Container{Name: "evalhub"}
	upstream := fmt.Sprintf("http://127.0.0.1:%d/", appPort)
	proxy := corev1.Container{
		Name: proxyName,
		Args: []string{
			"--secure-listen-address=0.0.0.0:" + fmt.Sprintf("%d", listenPort),
			"--upstream=" + upstream,
			"--config-file=/etc/proxy/config.yaml",
			"--tls-cert-file=/etc/tls/tls.crt",
			"--tls-private-key-file=/etc/tls/tls.key",
		},
		Ports: []corev1.ContainerPort{{Name: "https", ContainerPort: listenPort}},
		VolumeMounts: []corev1.VolumeMount{{Name: tlsName, MountPath: "/etc/tls"}},
	}
	volumes := []corev1.Volume{
		{Name: tlsName, VolumeSource: corev1.VolumeSource{Secret: &corev1.SecretVolumeSource{SecretName: tlsName}}},
	}
	return corev1.PodSpec{ServiceAccountName: serviceAccountName(instance), Containers: []corev1.Container{app, proxy}, Volumes: volumes}
}
`
}
