package gosource

import (
	"os"
	"path/filepath"
	"testing"
)

func TestRuntimeServiceClientsRequireReachableStandardConstructors(t *testing.T) {
	root := writeRuntimeClientRepository(t, map[string]string{
		"main.go": `package main
import "example.com/runtime/internal/app"
func main() { app.Execute() }
`,
		"internal/app/app.go": `package app
import "example.com/runtime/internal/stores"
type command struct{}
func Execute() { command{}.run() }
func (command) run() { stores.Open() }
`,
		"internal/stores/stores.go": `package stores
import (
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
)
func Open() {
	_ = pgxpool.NewWithConfig()
	_ = redis.NewClient()
	_ = s3.NewFromConfig()
	_ = otlptracegrpc.New()
}
`,
	})

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	want := map[string]string{
		"PostgreSQL":              "pgx connection pool",
		"Redis/Valkey":            "go-redis client",
		"S3-compatible storage":   "AWS SDK S3 client",
		"OpenTelemetry Collector": "OTLP/gRPC trace exporter",
	}
	for _, client := range result.RuntimeClients {
		if expected, ok := want[client.Target]; ok {
			if client.Client != expected || client.Configuration == "" || client.Source == "" {
				t.Errorf("client = %#v, want source-backed %s construction", client, expected)
			}
			delete(want, client.Target)
		}
	}
	if len(want) != 0 {
		t.Fatalf("runtime clients = %#v, missing %#v", result.RuntimeClients, want)
	}
}

func TestRuntimeServiceClientsRejectDisconnectedAndSameNamedFunctions(t *testing.T) {
	root := writeRuntimeClientRepository(t, map[string]string{
		"main.go": `package main
import "example.com/runtime/internal/used"
func main() { used.Run() }
`,
		"internal/used/used.go": `package used
func Run() {}
`,
		"internal/disconnected/disconnected.go": `package disconnected
import redis "github.com/redis/go-redis/v9"
func Run() { _ = redis.NewClient() }
`,
		"internal/disconnected/disconnected_test.go": `package disconnected
import pgxpool "github.com/jackc/pgx/v5/pgxpool"
func TestOnly() { _ = pgxpool.NewWithConfig() }
`,
	})

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	for _, client := range result.RuntimeClients {
		switch client.Target {
		case "PostgreSQL", "Redis/Valkey", "S3-compatible storage", "OpenTelemetry Collector":
			t.Fatalf("runtime clients = %#v, want disconnected and test-only constructors rejected", result.RuntimeClients)
		}
	}
}

func TestRuntimeServiceClientsRejectSameNamedMethodsOnUnrelatedReceivers(t *testing.T) {
	root := writeRuntimeClientRepository(t, map[string]string{
		"main.go": `package main
import "example.com/runtime/internal/app"
func main() { app.Execute() }
`,
		"internal/app/app.go": `package app
import redis "github.com/redis/go-redis/v9"
type used struct{}
type unused struct{}
func Execute() { used{}.run() }
func (used) run() {}
func (unused) run() { _ = redis.NewClient() }
`,
	})

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	for _, client := range result.RuntimeClients {
		if client.Target == "Redis/Valkey" {
			t.Fatalf("runtime clients = %#v, want unrelated receiver method rejected", result.RuntimeClients)
		}
	}
}

func writeRuntimeClientRepository(t *testing.T, files map[string]string) string {
	t.Helper()
	root := t.TempDir()
	if _, exists := files["go.mod"]; !exists {
		files["go.mod"] = "module example.com/runtime\n\ngo 1.25.0\n"
	}
	for name, content := range files {
		path := filepath.Join(root, filepath.FromSlash(name))
		if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
			t.Fatal(err)
		}
	}
	return root
}
