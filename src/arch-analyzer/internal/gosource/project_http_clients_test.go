package gosource

import (
	"go/ast"
	"testing"
)

func TestProjectHTTPClientRequiresReachableTransportAndSemanticTarget(t *testing.T) {
	root := writeRuntimeClientRepository(t, projectHTTPClientFiles(`package main
import "github.com/llm-d/example/internal/gateway"
func main() {
	gateway.NewGlobalResolver()
	gateway.NewPerModelResolver()
}
`))
	files := parsedProjectHTTPClientFiles(t, root)
	graph := buildRuntimeCallGraph(files)
	declarations := map[runtimeFunctionKey]*ast.FuncDecl{}
	fileByFunction := map[runtimeFunctionKey]sourceFile{}
	var constructor runtimeFunctionKey
	for _, file := range files {
		for _, declaration := range file.file.Decls {
			function, ok := declaration.(*ast.FuncDecl)
			if !ok || function.Body == nil {
				continue
			}
			key := runtimeFunction(file, function)
			declarations[key] = function
			fileByFunction[key] = file
			if key.name == "NewHTTPClient" {
				constructor = key
			}
		}
	}
	function := declarations[constructor]
	file := fileByFunction[constructor]
	if function == nil || !graph.reachable[constructor] {
		t.Fatalf("constructor %v is not runtime reachable: %#v", constructor, graph.reachable)
	}
	if _, configured := configuredRestyClientPosition(file, function); !configured {
		t.Fatal("reachable constructor did not prove configured Resty construction")
	}
	returnedTypes := returnedLocalTypes(function)
	if !packageExecutesHTTPRequests(files, constructor.packagePath, returnedTypes) {
		t.Fatalf("returned types %#v did not prove outbound execution", returnedTypes)
	}
	if !runtimeAncestorHasSemanticWords(graph, constructor, declarations, fileByFunction, "inference", "gateway", "client") {
		t.Fatal("reachable ancestors did not prove inference gateway client semantics")
	}

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	var matched int
	for _, client := range result.RuntimeClients {
		if client.Target != "llm-d inference gateway" {
			continue
		}
		matched++
		if client.Client != "HTTP client" || client.Configuration == "" || client.Source != "internal/transport/client.go:6" {
			t.Errorf("client = %#v, want source-backed runtime gateway transport", client)
		}
	}
	if matched != 1 {
		t.Fatalf("runtime clients = %#v, want one deduplicated llm-d inference gateway", result.RuntimeClients)
	}
}

func parsedProjectHTTPClientFiles(t *testing.T, root string) []sourceFile {
	t.Helper()
	moduleRoots, err := discoverModules(root)
	if err != nil || len(moduleRoots) != 1 {
		t.Fatalf("discover modules: roots=%#v err=%v", moduleRoots, err)
	}
	modulePath, _, _, err := readModule(root, moduleRoots[0])
	if err != nil {
		t.Fatal(err)
	}
	files, err := parseFiles(root, moduleRoots[0], modulePath, moduleRoots)
	if err != nil {
		t.Fatal(err)
	}
	return files
}

func TestProjectHTTPClientRejectsDisconnectedTransport(t *testing.T) {
	files := projectHTTPClientFiles(`package main
func main() {}
`)
	root := writeRuntimeClientRepository(t, files)

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	assertNoInferenceGatewayClient(t, result)
}

func TestProjectHTTPClientRejectsGenericHTTPWrapper(t *testing.T) {
	files := projectHTTPClientFiles(`package main
import "github.com/llm-d/example/internal/transport"
func main() { transport.NewHTTPClient(transport.Config{}) }
`)
	root := writeRuntimeClientRepository(t, files)

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	assertNoInferenceGatewayClient(t, result)
}

func TestProjectHTTPClientRejectsSemanticSiblingCall(t *testing.T) {
	files := projectHTTPClientFiles(`package main
import (
	"github.com/llm-d/example/internal/gateway"
	"github.com/llm-d/example/internal/transport"
)
func main() {
	transport.NewHTTPClient(transport.Config{})
	gateway.ConfigureInferenceGatewayClient()
}
`)
	files["internal/gateway/resolver.go"] = `package gateway
func ConfigureInferenceGatewayClient() {}
`
	root := writeRuntimeClientRepository(t, files)

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	assertNoInferenceGatewayClient(t, result)
}

func TestProjectHTTPClientRejectsTransportWithoutRequestExecution(t *testing.T) {
	files := projectHTTPClientFiles(`package main
import "github.com/llm-d/example/internal/gateway"
func main() { gateway.NewGlobalResolver() }
`)
	files["internal/transport/client.go"] = `package transport
import "github.com/go-resty/resty/v2"
type Config struct { BaseURL string }
type Client struct{}
func NewHTTPClient(config Config) *Client {
	_ = resty.New().SetBaseURL(config.BaseURL)
	return &Client{}
}
`
	root := writeRuntimeClientRepository(t, files)

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	assertNoInferenceGatewayClient(t, result)
}

func TestProjectHTTPClientRejectsLiteralEndpoint(t *testing.T) {
	files := projectHTTPClientFiles(`package main
import "github.com/llm-d/example/internal/gateway"
func main() { gateway.NewGlobalResolver() }
`)
	files["internal/transport/client.go"] = `package transport
import "github.com/go-resty/resty/v2"
type Config struct { BaseURL string }
type Client struct{}
func NewHTTPClient(config Config) *Client {
	_ = resty.New().SetBaseURL("http://example.test")
	return &Client{}
}
func (*Client) Post() { var request *resty.Request; _, _ = request.Post("/v1") }
`
	root := writeRuntimeClientRepository(t, files)

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	assertNoInferenceGatewayClient(t, result)
}

func projectHTTPClientFiles(main string) map[string]string {
	return map[string]string{
		"go.mod":  "module github.com/llm-d/example\n\ngo 1.25.0\n",
		"main.go": main,
		"internal/gateway/resolver.go": `package gateway
import "github.com/llm-d/example/internal/inference"
type GatewayClientConfig struct { URL string }
// NewGlobalResolver creates an inference gateway client resolver.
func NewGlobalResolver(config GatewayClientConfig) { inference.NewInferenceClient(config) }
// NewPerModelResolver creates inference gateway clients by model.
func NewPerModelResolver(config map[string]GatewayClientConfig) { inference.NewInferenceClient(config) }
`,
		"internal/inference/client.go": `package inference
import "github.com/llm-d/example/internal/transport"
func NewInferenceClient(config interface{}) { transport.NewHTTPClient(transport.Config{}) }
`,
		"internal/transport/client.go": `package transport
import "github.com/go-resty/resty/v2"
type Config struct { BaseURL string }
type Client struct{}
func NewHTTPClient(config Config) *Client {
	_ = resty.New().SetBaseURL(config.BaseURL)
	return &Client{}
}
func (*Client) Post() { var request *resty.Request; _, _ = request.Post("/v1") }
`,
	}
}

func assertNoInferenceGatewayClient(t *testing.T, result Result) {
	t.Helper()
	for _, client := range result.RuntimeClients {
		if client.Target == "llm-d inference gateway" {
			t.Fatalf("runtime clients = %#v, want incomplete project client rejected", result.RuntimeClients)
		}
	}
}
