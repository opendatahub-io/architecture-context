package gosource

import (
	"os"
	"path/filepath"
	"testing"
)

func TestSecurityEvidenceTLSImport(t *testing.T) {
	root := writeSecurityRepository(t, `package main

import (
	"crypto/tls"
)

func main() { _ = &tls.Config{} }
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, se := range result.SecurityEvidence {
		if se.Kind == "tls-config" {
			found = true
			if se.Status != "dependency-signal" {
				t.Errorf("status = %q, want dependency-signal", se.Status)
			}
			if se.Source == "" {
				t.Error("source must not be empty")
			}
		}
	}
	if !found {
		t.Error("expected tls-config security evidence from crypto/tls import")
	}
}

func TestSecurityEvidenceRBACImport(t *testing.T) {
	root := writeSecurityRepository(t, `package main

import (
	"k8s.io/client-go/kubernetes/typed/authorization/v1"
)

func main() { _ = v1.AuthorizationV1Interface(nil) }
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, se := range result.SecurityEvidence {
		if se.Kind == "rbac-ref" {
			found = true
			if se.Status != "dependency-signal" {
				t.Errorf("status = %q, want dependency-signal", se.Status)
			}
		}
	}
	if !found {
		t.Error("expected rbac-ref security evidence from authorization import")
	}
}

func TestSecurityEvidenceDeduplicatesImportsAndRetainsSources(t *testing.T) {
	root := writeSecurityRepository(t, `package main

import "crypto/tls"
`)
	if err := os.WriteFile(filepath.Join(root, "second.go"), []byte(`package main

import "crypto/tls"
`), 0o644); err != nil {
		t.Fatal(err)
	}
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	var foundSources int
	for i := range result.SecurityEvidence {
		if result.SecurityEvidence[i].Kind == "tls-config" {
			foundSources = len(result.SecurityEvidence[i].Sources)
			break
		}
	}
	if foundSources == 0 {
		t.Fatal("expected tls-config evidence")
	}
	if foundSources != 2 {
		t.Fatalf("source count = %d, want both source files", foundSources)
	}
}

func TestSecurityEvidenceAuthMiddlewareImport(t *testing.T) {
	root := writeSecurityRepository(t, `package main

import (
	"k8s.io/apiserver/pkg/authentication"
)

func main() { _ = authentication.Request(nil) }
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, se := range result.SecurityEvidence {
		if se.Kind == "auth-middleware" {
			found = true
		}
	}
	if !found {
		t.Error("expected auth-middleware security evidence from authentication import")
	}
}

func TestSecurityEvidenceGRPCService(t *testing.T) {
	root := writeSecurityRepository(t, `package main

import (
	"crypto/tls"
	grpc "google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	extproc "github.com/envoyproxy/go-control-plane/envoy/service/ext_proc/v3"
)

func main() {
	creds := credentials.NewTLS(&tls.Config{})
	server := grpc.NewServer(grpc.Creds(creds))
	extproc.RegisterExternalProcessorServer(server, nil)
}
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.SecurityEvidence) == 0 {
		t.Fatal("expected security evidence from gRPC server with TLS")
	}
	foundTLS := false
	for _, se := range result.SecurityEvidence {
		if se.Kind == "tls-config" {
			foundTLS = true
		}
	}
	if !foundTLS {
		t.Error("expected tls-config evidence from gRPC credentials")
	}
	if len(result.GRPCServices) < 1 {
		t.Fatal("expected at least 1 gRPC service")
	}
	for _, svc := range result.GRPCServices {
		if svc.Owner == "" {
			t.Errorf("gRPC service %q missing owner", svc.Service)
		}
		if svc.Transport == "" {
			t.Errorf("gRPC service %q missing transport", svc.Service)
		}
	}
}
