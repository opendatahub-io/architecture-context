package gosource

import (
	"strings"
	"testing"
)

const outboundGRPCClientSource = `package main

import (
	grpc "google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	triton "example.com/internal/proto/triton"
)

type TritonAdapter struct {
	Client triton.GRPCInferenceServiceClient
}

func NewTritonAdapter() *TritonAdapter {
	conn, _ := grpc.DialContext(nil, "localhost:8001",
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	s := &TritonAdapter{}
	s.Client = triton.NewGRPCInferenceServiceClient(conn)
	return s
}

func (s *TritonAdapter) LoadModel() {
	s.Client.RepositoryModelLoad(nil, nil)
}

func main() {
	adapter := NewTritonAdapter()
	_ = adapter
}
`

func TestOutboundGRPCClientDetectsReachableDialAndConstruction(t *testing.T) {
	root := writeRuntimeClientRepository(t, map[string]string{
		"main.go": outboundGRPCClientSource,
	})
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, client := range result.RuntimeClients {
		if client.Client == "outbound gRPC client" &&
			strings.Contains(client.Target, "GRPCInference") &&
			strings.Contains(client.Configuration, "plaintext") &&
			client.Source != "" {
			found = true
		}
	}
	if !found {
		t.Fatalf("runtime clients = %#v, want outbound gRPC client for triton GRPCInferenceService", result.RuntimeClients)
	}
}

func TestOutboundGRPCClientDetectsMultipleBackends(t *testing.T) {
	root := writeRuntimeClientRepository(t, map[string]string{
		"main.go": `package main

import (
	grpc "google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	triton "example.com/internal/proto/triton"
	mlserver "example.com/internal/proto/mlserver"
)

type Server struct {
	TritonClient   triton.GRPCInferenceServiceClient
	MLServerClient mlserver.GRPCInferenceServiceClient
}

func NewServer() *Server {
	tritonConn, _ := grpc.DialContext(nil, "localhost:8001",
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	mlConn, _ := grpc.DialContext(nil, "localhost:8002",
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	s := &Server{}
	s.TritonClient = triton.NewGRPCInferenceServiceClient(tritonConn)
	s.MLServerClient = mlserver.NewGRPCInferenceServiceClient(mlConn)
	return s
}

func (s *Server) Load()   { s.TritonClient.RepositoryModelLoad(nil, nil) }
func (s *Server) Infer()  { s.MLServerClient.RepositoryModelLoad(nil, nil) }

func main() { _ = NewServer() }
`,
	})
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	found := map[string]bool{}
	for _, client := range result.RuntimeClients {
		if client.Client == "outbound gRPC client" {
			found[client.Target] = true
		}
	}
	if len(found) != 2 {
		t.Fatalf("outbound gRPC clients = %v, want 2 distinct backends", found)
	}
}

func TestOutboundGRPCClientDetectsCompositeLiteralInitialization(t *testing.T) {
	source := strings.Replace(outboundGRPCClientSource,
		"s := &TritonAdapter{}\n\ts.Client = triton.NewGRPCInferenceServiceClient(conn)",
		"s := &TritonAdapter{\n\t\tClient: triton.NewGRPCInferenceServiceClient(conn),\n\t}", 1)
	if source == outboundGRPCClientSource {
		t.Fatal("mutation did not alter fixture")
	}
	root := writeRuntimeClientRepository(t, map[string]string{"main.go": source})
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, client := range result.RuntimeClients {
		if client.Client == "outbound gRPC client" && strings.Contains(client.Target, "GRPCInference") {
			found = true
		}
	}
	if !found {
		t.Fatalf("runtime clients = %#v, want outbound gRPC client detected with composite literal initialization", result.RuntimeClients)
	}
}

func TestOutboundGRPCClientDetectsNewBuiltinAllocation(t *testing.T) {
	source := strings.Replace(outboundGRPCClientSource, `s := &TritonAdapter{}`, `s := new(TritonAdapter)`, 1)
	if source == outboundGRPCClientSource {
		t.Fatal("mutation did not alter fixture")
	}
	root := writeRuntimeClientRepository(t, map[string]string{"main.go": source})
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, client := range result.RuntimeClients {
		if client.Client == "outbound gRPC client" && strings.Contains(client.Target, "GRPCInference") {
			found = true
		}
	}
	if !found {
		t.Fatalf("runtime clients = %#v, want outbound gRPC client detected with new() allocation", result.RuntimeClients)
	}
}

func TestOutboundGRPCClientRejectsIncompleteEvidence(t *testing.T) {
	tests := []struct {
		name string
		old  string
		new  string
	}{
		{name: "no grpc.Dial", old: "conn, _ := grpc.DialContext(nil, \"localhost:8001\",\n\t\tgrpc.WithTransportCredentials(insecure.NewCredentials()),\n\t)", new: "conn := (*grpc.ClientConn)(nil)\n\t_ = insecure.NewCredentials"},
		{name: "no New*Client", old: `s.Client = triton.NewGRPCInferenceServiceClient(conn)`, new: `s.Client = nil; _ = conn`},
		{name: "unreachable constructor", old: "func main() {\n\tadapter := NewTritonAdapter()", new: "func main() {\n\t_ = NewTritonAdapter"},
		{name: "no method calls on field", old: "func (s *TritonAdapter) LoadModel() {\n\ts.Client.RepositoryModelLoad(nil, nil)\n}", new: "func (s *TritonAdapter) LoadModel() {\n}"},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			source := strings.Replace(outboundGRPCClientSource, test.old, test.new, 1)
			if source == outboundGRPCClientSource {
				t.Fatalf("mutation %q did not alter fixture", test.name)
			}
			root := writeRuntimeClientRepository(t, map[string]string{"main.go": source})
			result, err := Extract(root)
			if err != nil {
				t.Fatal(err)
			}
			for _, client := range result.RuntimeClients {
				if client.Client == "outbound gRPC client" {
					t.Fatalf("runtime clients = %#v, want incomplete outbound gRPC evidence rejected", result.RuntimeClients)
				}
			}
		})
	}
}

func TestOutboundGRPCClientRejectsDisconnectedFunction(t *testing.T) {
	root := writeRuntimeClientRepository(t, map[string]string{
		"main.go": `package main

import (
	grpc "google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	triton "example.com/internal/proto/triton"
)

type Server struct {
	Client triton.GRPCInferenceServiceClient
}

func disconnected() *Server {
	conn, _ := grpc.DialContext(nil, "localhost:8001",
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	s := &Server{}
	s.Client = triton.NewGRPCInferenceServiceClient(conn)
	return s
}

func (s *Server) Load() { s.Client.RepositoryModelLoad(nil, nil) }

func main() {}
`,
	})
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	for _, client := range result.RuntimeClients {
		if client.Client == "outbound gRPC client" {
			t.Fatalf("runtime clients = %#v, want disconnected constructor rejected", result.RuntimeClients)
		}
	}
}

func TestOutboundGRPCClientRejectsProtoImportWithoutConstruction(t *testing.T) {
	root := writeRuntimeClientRepository(t, map[string]string{
		"main.go": `package main

import (
	_ "example.com/internal/proto/triton"
)

func main() {}
`,
	})
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	for _, client := range result.RuntimeClients {
		if client.Client == "outbound gRPC client" {
			t.Fatalf("runtime clients = %#v, want proto import without construction rejected", result.RuntimeClients)
		}
	}
}
