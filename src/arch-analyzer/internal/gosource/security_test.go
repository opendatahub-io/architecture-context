package gosource

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestExtractControllerRuntimeAuthentication(t *testing.T) {
	root := writeSecurityRepository(t, `package main

import (
	"flag"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/healthz"
	metricsserver "sigs.k8s.io/controller-runtime/pkg/metrics/server"
)

func run(mgr interface {
	AddHealthzCheck(string, any) error
	AddReadyzCheck(string, any) error
}) {
	var metricsAddr string
	var probeAddr string
	flag.StringVar(&metricsAddr, "metrics-bind-address", ":8080", "")
	flag.StringVar(&probeAddr, "health-probe-bind-address", ":8081", "")
	_ = ctrl.Options{
		Metrics: metricsserver.Options{BindAddress: metricsAddr, SecureServing: false},
		HealthProbeBindAddress: probeAddr,
	}
	_ = mgr.AddHealthzCheck("healthz", healthz.Ping)
	_ = mgr.AddReadyzCheck("readyz", healthz.Ping)
}
`)

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Authentication) != 3 {
		t.Fatalf("authentication = %#v, want metrics and two probe facts", result.Authentication)
	}
	want := map[string]bool{
		":8080/metrics": false,
		":8081/healthz": false,
		":8081/readyz":  false,
	}
	for _, fact := range result.Authentication {
		if _, exists := want[fact.Endpoint]; !exists {
			t.Errorf("unexpected authentication fact %#v", fact)
			continue
		}
		want[fact.Endpoint] = true
		if fact.Methods != "GET" || fact.Mechanism != "None" || fact.Source == "" {
			t.Errorf("authentication fact = %#v, want source-backed unauthenticated GET", fact)
		}
	}
	for endpoint, found := range want {
		if !found {
			t.Errorf("missing authentication fact %q", endpoint)
		}
	}
}

func TestControllerRuntimeMetricsRequireExplicitFalse(t *testing.T) {
	root := writeSecurityRepository(t, `package main

import metricsserver "sigs.k8s.io/controller-runtime/pkg/metrics/server"

func register(router interface { GET(string, ...any) }) {
	secure := false
	_ = metricsserver.Options{BindAddress: ":8443", SecureServing: true}
	_ = metricsserver.Options{BindAddress: ":8080"}
	_ = metricsserver.Options{BindAddress: ":9090", SecureServing: secure}
	router.GET("/healthz")
}
`)

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Authentication) != 0 {
		t.Fatalf("authentication = %#v, want dynamic, secure, and omitted settings unresolved", result.Authentication)
	}
}

func TestExtractSecureControllerRuntimeMetricsControl(t *testing.T) {
	root := writeSecurityRepository(t, `package main

import (
	"flag"
	filters "sigs.k8s.io/controller-runtime/pkg/metrics/filters"
	metricsserver "sigs.k8s.io/controller-runtime/pkg/metrics/server"
)

func run() {
	var metricsAddr string
	var secureMetrics bool
	flag.StringVar(&metricsAddr, "metrics-bind-address", "0", "")
	flag.BoolVar(&secureMetrics, "metrics-secure", true, "")
	metricsServerOptions := metricsserver.Options{
		BindAddress: metricsAddr,
		SecureServing: secureMetrics,
	}
	if secureMetrics {
		metricsServerOptions.FilterProvider = filters.WithAuthenticationAndAuthorization
	}
}
`)

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.RuntimeSecurity) != 1 {
		t.Fatalf("runtime security = %#v, want one secure metrics control", result.RuntimeSecurity)
	}
	control := result.RuntimeSecurity[0]
	if control.Surface != "controller-runtime metrics" || control.AddressFlag != "metrics-bind-address" ||
		control.AddressDefault != "0" || control.SecureFlag != "metrics-secure" || !control.SecureDefault {
		t.Errorf("control = %#v, want statically resolved metrics flags", control)
	}
	if control.Mechanism != "Kubernetes TokenReview and SubjectAccessReview" || control.Source == "" {
		t.Errorf("control = %#v, want source-backed authn/authz filter", control)
	}
	if control.CertificateMode != "controller-runtime-default" {
		t.Errorf("control = %#v, want controller-runtime default certificate behavior", control)
	}
}

func TestExtractViperBackedControllerRuntimeMetricsControl(t *testing.T) {
	root := writeSecurityRepository(t, `package main
import (
  filters "sigs.k8s.io/controller-runtime/pkg/metrics/filters"
  metricsserver "sigs.k8s.io/controller-runtime/pkg/metrics/server"
  "example.com/security/internal/config"
)
func run(cfg *config.Config) {
  options := metricsserver.Options{BindAddress: cfg.MetricsAddr(), SecureServing: cfg.SecureMetrics()}
  if cfg.SecureMetrics() { options.FilterProvider = filters.WithAuthenticationAndAuthorization }
  if len(cfg.MetricsCertPath()) > 0 { options.TLSOpts = append(options.TLSOpts, nil) }
}
`)
	configDir := filepath.Join(root, "internal", "config")
	if err := os.MkdirAll(configDir, 0o700); err != nil {
		t.Fatal(err)
	}
	configSource := `package config
import "github.com/spf13/viper"
var flagBindings = map[string]string{"METRICS_BIND_ADDRESS": "metrics-bind-address", "METRICS_SECURE": "metrics-secure", "METRICS_CERT_PATH": "metrics-cert-path"}
type infrastructureConfig struct { metricsAddr string; secureMetrics bool; metricsCertPath string }
type Config struct { infrastructure infrastructureConfig }
func load(v *viper.Viper, cfg *Config) {
  v.SetDefault("METRICS_BIND_ADDRESS", "0")
  v.SetDefault("METRICS_SECURE", true)
  v.SetDefault("METRICS_CERT_PATH", "")
  cfg.infrastructure = infrastructureConfig{metricsAddr: v.GetString("METRICS_BIND_ADDRESS"), secureMetrics: v.GetBool("METRICS_SECURE"), metricsCertPath: v.GetString("METRICS_CERT_PATH")}
}
func (c *Config) MetricsAddr() string { return c.infrastructure.metricsAddr }
func (c *Config) SecureMetrics() bool { return c.infrastructure.secureMetrics }
func (c *Config) MetricsCertPath() string { return c.infrastructure.metricsCertPath }
`
	if err := os.WriteFile(filepath.Join(configDir, "config.go"), []byte(configSource), 0o600); err != nil {
		t.Fatal(err)
	}

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.RuntimeSecurity) != 1 {
		t.Fatalf("runtime security = %#v, want one Viper-backed control", result.RuntimeSecurity)
	}
	control := result.RuntimeSecurity[0]
	if control.AddressFlag != "metrics-bind-address" || control.AddressDefault != "0" ||
		control.SecureFlag != "metrics-secure" || !control.SecureDefault {
		t.Fatalf("control = %#v, want repository-resolved getter bindings", control)
	}
	if control.CertificatePathFlag != "metrics-cert-path" || control.CertificateMode != "optional-external" {
		t.Fatalf("control = %#v, want optional external certificate binding", control)
	}
}

func TestExtractViperBackedControllerRuntimeProbeAuthentication(t *testing.T) {
	root := writeSecurityRepository(t, `package main
import (
  ctrl "sigs.k8s.io/controller-runtime"
  "example.com/security/internal/config"
)
func run(cfg *config.Config, mgr interface {
  AddHealthzCheck(string, any) error
  AddReadyzCheck(string, any) error
}) {
  _ = ctrl.Options{HealthProbeBindAddress: cfg.ProbeAddr()}
  _ = mgr.AddHealthzCheck("healthz", nil)
  _ = mgr.AddReadyzCheck("readyz", nil)
}
`)
	configDir := filepath.Join(root, "internal", "config")
	if err := os.MkdirAll(configDir, 0o700); err != nil {
		t.Fatal(err)
	}
	configSource := `package config
import "github.com/spf13/viper"
var flagBindings = map[string]string{"HEALTH_PROBE_BIND_ADDRESS": "health-probe-bind-address"}
type infrastructureConfig struct { probeAddr string }
type Config struct { infrastructure infrastructureConfig }
func load(v *viper.Viper, cfg *Config) {
  v.SetDefault("HEALTH_PROBE_BIND_ADDRESS", ":8081")
  cfg.infrastructure = infrastructureConfig{probeAddr: v.GetString("HEALTH_PROBE_BIND_ADDRESS")}
}
func (c *Config) ProbeAddr() string { return c.infrastructure.probeAddr }
`
	if err := os.WriteFile(filepath.Join(configDir, "config.go"), []byte(configSource), 0o600); err != nil {
		t.Fatal(err)
	}

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	want := map[string]bool{":8081/healthz": false, ":8081/readyz": false}
	for _, fact := range result.Authentication {
		if _, exists := want[fact.Endpoint]; exists {
			want[fact.Endpoint] = true
		}
	}
	for endpoint, found := range want {
		if !found {
			t.Errorf("missing authentication fact %q in %#v", endpoint, result.Authentication)
		}
	}
}

func TestSecureControllerRuntimeMetricsRejectsIncompleteSourceEvidence(t *testing.T) {
	tests := []struct {
		name   string
		source string
	}{
		{
			name: "filter imported but not assigned",
			source: `package main
import (
	"flag"
	filters "sigs.k8s.io/controller-runtime/pkg/metrics/filters"
	metricsserver "sigs.k8s.io/controller-runtime/pkg/metrics/server"
)
func run() {
	var address string
	var secure bool
	flag.StringVar(&address, "metrics-bind-address", ":8443", "")
	flag.BoolVar(&secure, "metrics-secure", true, "")
	_ = filters.WithAuthenticationAndAuthorization
	_ = metricsserver.Options{BindAddress: address, SecureServing: secure}
}`,
		},
		{
			name: "secure metrics without filter",
			source: `package main
import (
	"flag"
	metricsserver "sigs.k8s.io/controller-runtime/pkg/metrics/server"
)
func run() {
	var address string
	var secure bool
	flag.StringVar(&address, "metrics-bind-address", ":8443", "")
	flag.BoolVar(&secure, "metrics-secure", true, "")
	_ = metricsserver.Options{BindAddress: address, SecureServing: secure}
}`,
		},
		{
			name: "dynamic secure setting",
			source: `package main
import (
	"os"
	filters "sigs.k8s.io/controller-runtime/pkg/metrics/filters"
	metricsserver "sigs.k8s.io/controller-runtime/pkg/metrics/server"
)
func run() {
	secure := os.Getenv("SECURE") == "true"
	opts := metricsserver.Options{BindAddress: ":8443", SecureServing: secure}
	opts.FilterProvider = filters.WithAuthenticationAndAuthorization
}`,
		},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			root := writeSecurityRepository(t, test.source)
			result, err := Extract(root)
			if err != nil {
				t.Fatal(err)
			}
			if len(result.RuntimeSecurity) != 0 {
				t.Fatalf("runtime security = %#v, want incomplete source evidence rejected", result.RuntimeSecurity)
			}
		})
	}
}

func TestBoundedProxyHandlerAuthenticationRequiresCompleteInvokedChain(t *testing.T) {
	complete := `package proxy
import filters "example.com/security/pkg/filters"
func Run() {
	handler := func() {}
	handler = filters.WithAuthorization(nil, nil, handler)
	handler = filters.WithAuthentication(nil, nil, handler)
	handler()
}
`
	result, err := Extract(writeSecurityRepository(t, complete))
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Authentication) != 1 || result.Authentication[0].Endpoint != "Proxied HTTP requests" ||
		!strings.Contains(result.Authentication[0].Mechanism, "TokenReview") ||
		!strings.Contains(result.Authentication[0].Policy, "SubjectAccessReview") {
		t.Fatalf("authentication = %#v, want bounded proxy handler chain", result.Authentication)
	}

	tests := []struct {
		name   string
		source string
	}{
		{name: "authentication wrapper alone", source: strings.Replace(complete, "\thandler = filters.WithAuthorization(nil, nil, handler)\n", "", 1)},
		{name: "authorization wrapper alone", source: strings.Replace(complete, "\thandler = filters.WithAuthentication(nil, nil, handler)\n", "", 1)},
		{name: "wrapped handler never invoked", source: strings.Replace(complete, "\thandler()\n", "", 1)},
		{name: "unrelated middleware package", source: strings.Replace(complete, "/pkg/filters", "/middleware", 1)},
		{name: "different handler variables", source: strings.Replace(complete,
			"handler = filters.WithAuthorization(nil, nil, handler)",
			"other := handler\n\tother = filters.WithAuthorization(nil, nil, other)\n\tother()", 1)},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			candidate, err := Extract(writeSecurityRepository(t, test.source))
			if err != nil {
				t.Fatal(err)
			}
			if len(candidate.Authentication) != 0 {
				t.Fatalf("authentication = %#v, want incomplete chain rejected", candidate.Authentication)
			}
		})
	}
}

func writeSecurityRepository(t *testing.T, source string) string {
	t.Helper()
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, "go.mod"), []byte("module example.com/security\n\ngo 1.25.0\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "main.go"), []byte(source), 0o600); err != nil {
		t.Fatal(err)
	}
	return root
}
