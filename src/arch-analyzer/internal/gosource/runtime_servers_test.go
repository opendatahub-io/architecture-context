package gosource

import (
	"strings"
	"testing"

	"github.com/jctanner/arch-analyzer/internal/model"
)

const standaloneRuntimeServersSource = `package main

import (
	"context"
	"net/http"

	runnable "example.com/runnable"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"google.golang.org/grpc"
	health "google.golang.org/grpc/health/grpc_health_v1"
	ctrlmetrics "sigs.k8s.io/controller-runtime/pkg/metrics"
)

type manager interface { Add(any) error }

func registerHealth(m manager) {
	srv := grpc.NewServer()
	health.RegisterHealthServer(srv, nil)
	_ = m.Add(runnable.GRPCServer("health", srv, 9003))
}

func serveMetrics(ctx context.Context) error {
	mux := http.NewServeMux()
	mux.Handle("/metrics", promhttp.HandlerFor(ctrlmetrics.Registry, promhttp.HandlerOpts{}))
	srv := &http.Server{Handler: mux}
	return srv.ListenAndServe()
}

func main() {
	var m manager
	registerHealth(m)
	go serveMetrics(context.Background())
}
`

const constructorMetricsServerSource = `package main

import (
	"net/http"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

type MetricsServer struct {
	httpServer *http.Server
}

func NewMetricsServer() *MetricsServer {
	mux := http.NewServeMux()
	mux.Handle("/metrics", withRequestID(promhttp.Handler()))
	return &MetricsServer{
		httpServer: &http.Server{Handler: mux},
	}
}

func withRequestID(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		next.ServeHTTP(w, r)
	})
}

func (m *MetricsServer) Start() error {
	return m.httpServer.ListenAndServe()
}

func main() {
	ms := NewMetricsServer()
	go ms.Start()
}
`

func TestConstructorMetricsServerDetectsCrossMethodLifecycle(t *testing.T) {
	result, err := Extract(writeSecurityRepository(t, constructorMetricsServerSource))
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, server := range result.RuntimeServers {
		if server.Surface == "metrics" && server.Protocol == "HTTP" && server.Source != "" {
			found = true
		}
	}
	if !found {
		t.Fatalf("runtime servers = %#v, want cross-method metrics server detected", result.RuntimeServers)
	}
}

func TestConstructorMetricsServerRejectsIncompleteLifecycle(t *testing.T) {
	tests := []struct {
		name string
		old  string
		new  string
	}{
		{name: "no mux", old: `mux := http.NewServeMux()`, new: `mux := (*http.ServeMux)(nil)`},
		{name: "no prometheus handler", old: `promhttp.Handler()`, new: `http.NotFoundHandler()`},
		{name: "no http.Server in return", old: `httpServer: &http.Server{Handler: mux}`, new: `httpServer: nil`},
		{name: "no ListenAndServe method", old: `return m.httpServer.ListenAndServe()`, new: `return nil`},
		{name: "unreachable constructor", old: "func main() {\n\tms := NewMetricsServer()", new: "func main() {\n\t_ = NewMetricsServer"},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			source := strings.Replace(constructorMetricsServerSource, test.old, test.new, 1)
			if source == constructorMetricsServerSource {
				t.Fatalf("mutation %q did not alter fixture", test.name)
			}
			result, err := Extract(writeSecurityRepository(t, source))
			if err != nil {
				t.Fatal(err)
			}
			for _, server := range result.RuntimeServers {
				if server.Surface == "metrics" {
					t.Fatalf("runtime servers = %#v, want incomplete cross-method metrics lifecycle rejected", result.RuntimeServers)
				}
			}
		})
	}
}

func TestStandaloneHealthServerSelectsItsOwnTransportPolicy(t *testing.T) {
	services := preferStandaloneGRPCServices(
		[]model.GRPCService{
			{Service: "ExternalProcessor", Encryption: "Optional TLS", Source: "runserver.go:210"},
			{Service: "Health", Encryption: "Optional TLS", Source: "runserver.go:214"},
			{Service: "Health", Encryption: "None", Source: "runner.go:728"},
		},
		[]model.RuntimeServer{{
			Surface: "health", Protocol: "gRPC", Lifecycle: "manager Runnable", Source: "runner.go:728",
		}},
	)
	if len(services) != 2 {
		t.Fatalf("services = %#v, want ExternalProcessor and dedicated Health", services)
	}
	for _, service := range services {
		if service.Service == "Health" && (service.Encryption != "None" || service.Source != "runner.go:728") {
			t.Fatalf("health service = %#v, want dedicated plaintext runtime", service)
		}
	}
}

func TestStandaloneRuntimeServersRequireCompleteLifecycle(t *testing.T) {
	result, err := Extract(writeSecurityRepository(t, standaloneRuntimeServersSource))
	if err != nil {
		t.Fatal(err)
	}
	if len(result.RuntimeServers) != 2 {
		t.Fatalf("runtime servers = %#v, want health and metrics", result.RuntimeServers)
	}
	want := map[string]string{"health": "gRPC", "metrics": "HTTP"}
	for _, server := range result.RuntimeServers {
		if want[server.Surface] != server.Protocol || server.Lifecycle == "" || server.Source == "" {
			t.Errorf("runtime server = %#v, want complete source-backed lifecycle", server)
		}
		delete(want, server.Surface)
	}
	if len(want) != 0 {
		t.Errorf("missing runtime servers = %#v", want)
	}
}

func TestStandaloneHealthServerRejectsIncompleteLifecycle(t *testing.T) {
	tests := []struct {
		name string
		old  string
		new  string
	}{
		{name: "construction", old: `srv := grpc.NewServer()`, new: `srv := any(nil)`},
		{name: "registration", old: `health.RegisterHealthServer(srv, nil)`, new: `_ = health.RegisterHealthServer`},
		{name: "manager lifecycle", old: `_ = m.Add(runnable.GRPCServer("health", srv, 9003))`, new: `_ = runnable.GRPCServer("health", srv, 9003)`},
		{name: "runtime reachability", old: "func main() {\n\tvar m manager\n\tregisterHealth(m)", new: "func main() {\n\tvar m manager\n\t_ = registerHealth"},
	}
	assertRuntimeServerMutationsRejected(t, "health", tests)
}

func TestStandaloneMetricsServerRejectsIncompleteLifecycle(t *testing.T) {
	tests := []struct {
		name string
		old  string
		new  string
	}{
		{name: "listener construction", old: `mux := http.NewServeMux()`, new: `mux := (*http.ServeMux)(nil)`},
		{name: "handler registration", old: `promhttp.HandlerFor(ctrlmetrics.Registry, promhttp.HandlerOpts{})`, new: `http.NotFoundHandler()`},
		{name: "server construction", old: `srv := &http.Server{Handler: mux}`, new: `srv := any(nil)`},
		{name: "serve lifecycle", old: `return srv.ListenAndServe()`, new: `_ = srv; return nil`},
		{name: "runtime reachability", old: `go serveMetrics(context.Background())`, new: `_ = serveMetrics`},
	}
	assertRuntimeServerMutationsRejected(t, "metrics", tests)
}

func assertRuntimeServerMutationsRejected(t *testing.T, surface string, tests []struct {
	name string
	old  string
	new  string
}) {
	t.Helper()
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			source := strings.Replace(standaloneRuntimeServersSource, test.old, test.new, 1)
			if source == standaloneRuntimeServersSource {
				t.Fatalf("mutation %q did not alter fixture", test.name)
			}
			result, err := Extract(writeSecurityRepository(t, source))
			if err != nil {
				t.Fatal(err)
			}
			for _, server := range result.RuntimeServers {
				if server.Surface == surface {
					t.Fatalf("runtime servers = %#v, want incomplete %s lifecycle rejected", result.RuntimeServers, surface)
				}
			}
		})
	}
}
