package gosource

import (
	"strings"
	"testing"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func TestRegisteredGRPCServicesRequireConstructionAndRegistration(t *testing.T) {
	root := writeSecurityRepository(t, `package main
import (
	"crypto/tls"
  grpc "google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
  extproc "github.com/envoyproxy/go-control-plane/envoy/service/ext_proc/v3"
  health "google.golang.org/grpc/health/grpc_health_v1"
)
func main() { run(false, nil) }
func run(secure bool, handler any) {
  var server *grpc.Server
  if secure {
    creds := credentials.NewTLS(&tls.Config{Certificates: []tls.Certificate{{}}})
    server = grpc.NewServer(grpc.Creds(creds))
  } else { server = grpc.NewServer() }
  extproc.RegisterExternalProcessorServer(server, handler)
  health.RegisterHealthServer(server, handler)
}
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.GRPCServices) != 2 {
		t.Fatalf("gRPC services = %#v, want external processor and health", result.GRPCServices)
	}
	for _, service := range result.GRPCServices {
		if service.Encryption != "Optional TLS" || service.Auth != "None" || service.Source == "" {
			t.Errorf("service = %#v, want source-backed optional TLS without application auth", service)
		}
	}
	if len(result.Authentication) != 2 {
		t.Fatalf("authentication = %#v, want both registered services accounted", result.Authentication)
	}
}

func TestRegisteredGRPCServicesMergeSecurityModesAcrossRuntimes(t *testing.T) {
	services := dedupeRegisteredGRPCServices([]model.GRPCService{
		{Service: "Health", Encryption: "None", Auth: "None", Source: "plain.go:1"},
		{Service: "Health", Encryption: "Optional TLS", Auth: "None", Source: "secure.go:1"},
	})
	if len(services) != 1 || services[0].Encryption != "Optional TLS" {
		t.Fatalf("services = %#v, want merged optional TLS surface", services)
	}
	facts := registeredGRPCAuthentication(services)
	if len(facts) != 1 || !strings.Contains(facts[0].Policy, "configuration-dependent") {
		t.Fatalf("authentication = %#v, want merged optional TLS policy", facts)
	}
}

func TestRegisteredGRPCServicesResolveConditionalLocalOptionSlice(t *testing.T) {
	root := writeSecurityRepository(t, `package main
import (
	"crypto/tls"
  grpc "google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
  extproc "github.com/envoyproxy/go-control-plane/envoy/service/ext_proc/v3"
)
func main() { run(false, nil) }
func run(secure bool, handler any) {
  options := []grpc.ServerOption{}
  if secure {
    creds := credentials.NewTLS(&tls.Config{Certificates: []tls.Certificate{{}}})
    options = append(options, grpc.Creds(creds))
  }
  server := grpc.NewServer(options...)
  extproc.RegisterExternalProcessorServer(server, handler)
}
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.GRPCServices) != 1 || result.GRPCServices[0].Encryption != "Optional TLS" ||
		result.GRPCServices[0].Auth != "None" {
		t.Fatalf("gRPC services = %#v, want resolved conditional TLS option slice", result.GRPCServices)
	}
}

func TestRegisteredGRPCServicesAllowBoundedTransportAndObservabilityOptions(t *testing.T) {
	root := writeSecurityRepository(t, `package main
import (
	"crypto/tls"
  grpc "google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
  extproc "github.com/envoyproxy/go-control-plane/envoy/service/ext_proc/v3"
)
func main() { run(false, nil) }
func run(secure bool, handler any) {
  var options []grpc.ServerOption
  if secure {
    creds := credentials.NewTLS(&tls.Config{Certificates: []tls.Certificate{{}}})
    options = append(options, grpc.Creds(creds))
  }
  options = append(options, grpc.MaxRecvMsgSize(1024))
  options = append(options, grpc.ChainStreamInterceptor(streamMetricsInterceptor))
  server := grpc.NewServer(options...)
  extproc.RegisterExternalProcessorServer(server, handler)
}
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.GRPCServices) != 1 || result.GRPCServices[0].Encryption != "Optional TLS" ||
		result.GRPCServices[0].Auth != "None" {
		t.Fatalf("gRPC services = %#v, want transport and metrics options treated as non-auth", result.GRPCServices)
	}
}

func TestRegisteredGRPCServicesRejectDeclarationsAndUnresolvedOptions(t *testing.T) {
	root := writeSecurityRepository(t, `package main
import (
  grpc "google.golang.org/grpc"
  extproc "github.com/envoyproxy/go-control-plane/envoy/service/ext_proc/v3"
)
func disconnected(handler any) { _ = extproc.RegisterExternalProcessorServer }
func main() { unresolved(nil, nil) }
func unresolved(options []grpc.ServerOption, handler any) {
  server := grpc.NewServer(options...)
  extproc.RegisterExternalProcessorServer(server, handler)
}
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.GRPCServices) != 1 || result.GRPCServices[0].Auth != "Unknown" {
		t.Fatalf("gRPC services = %#v, want visible unresolved registered server", result.GRPCServices)
	}
	for _, fact := range result.Authentication {
		if strings.Contains(fact.Endpoint, "External Processor") {
			t.Fatalf("authentication = %#v, unresolved server must not claim an auth result", result.Authentication)
		}
	}
}

func TestRegisteredGRPCServicesRejectDisconnectedRegistration(t *testing.T) {
	root := writeSecurityRepository(t, `package main
import (
  grpc "google.golang.org/grpc"
  extproc "github.com/envoyproxy/go-control-plane/envoy/service/ext_proc/v3"
)
func helper(handler any) {
  server := grpc.NewServer()
  extproc.RegisterExternalProcessorServer(server, handler)
}
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.GRPCServices) != 0 {
		t.Fatalf("gRPC services = %#v, disconnected registration must not imply a runtime", result.GRPCServices)
	}
}
