package gosource

import "testing"

func TestShippedCommandComponentsRequireBuildMainAndRuntimeCommand(t *testing.T) {
	root := writeRuntimeClientRepository(t, map[string]string{
		"cmd/api/main.go": `// The entry point for the HTTP API server.
package main
func main() {}
`,
		"cmd/worker/main.go": `// The entry point for the background processor.
package main
func main() {}
`,
		"cmd/tool/main.go": `package main
func main() {}
`,
		"docker/Dockerfile.api": `FROM golang AS builder
RUN CGO_ENABLED=0 go build -a -o bin/product-api ./cmd/api
FROM scratch
COPY --from=builder /workspace/bin/product-api /app/product-api
ENTRYPOINT ["/app/product-api"]
`,
		"docker/Dockerfile.api.konflux": `FROM golang AS builder
RUN go build \
    -o=bin/product-api \
    ./cmd/api
FROM scratch
ENTRYPOINT ["/app/product-api"]
`,
		"docker/Dockerfile.worker": `FROM golang AS builder
RUN go build -o /out/product-worker ./cmd/worker
FROM scratch
CMD ["/app/product-worker"]
`,
		"docker/Dockerfile.tool": `FROM golang
RUN go build -o /out/support-tool ./cmd/tool
`,
	})

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Components) != 2 {
		t.Fatalf("components = %#v, want two shipped commands", result.Components)
	}
	want := map[string]string{
		"product-api": "Go HTTP Service", "product-worker": "Go Background Worker",
	}
	for _, component := range result.Components {
		if component.Type != want[component.Name] || component.Purpose == "" || component.Source == "" {
			t.Errorf("component = %#v, want documented build-correlated command", component)
		}
		if component.Name == "product-api" && component.Source != "docker/Dockerfile.api:2" {
			t.Errorf("API source = %q, want standard Dockerfile preferred over duplicate Konflux build", component.Source)
		}
		delete(want, component.Name)
	}
	if len(want) != 0 {
		t.Errorf("missing components = %#v", want)
	}
}

func TestShippedCommandComponentsRejectIncompleteCorrelations(t *testing.T) {
	root := writeRuntimeClientRepository(t, map[string]string{
		"cmd/no-main/source.go": `package main
func Run() {}
`,
		"cmd/unbuilt/main.go": `package main
func main() {}
`,
		"cmd/not-runtime/main.go": `package main
func main() {}
`,
		"cmd/test-only/main_test.go": `package main
func main() {}
`,
		"examples/demo/main.go": `package main
func main() {}
`,
		"Dockerfile": `FROM golang AS builder
RUN go build -o /out/no-main ./cmd/no-main
RUN go build -o /out/not-runtime ./cmd/not-runtime
RUN go build ./cmd/unbuilt
RUN go build -o /out/demo ./examples/demo
FROM scratch
ENTRYPOINT ["/app/no-main"]
`,
		"examples/demo/Dockerfile": `FROM golang AS builder
RUN go build -o /out/demo ./examples/demo
FROM scratch
ENTRYPOINT ["/app/demo"]
`,
	})

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Components) != 0 {
		t.Fatalf("components = %#v, want incomplete and support command correlations rejected", result.Components)
	}
}

func TestParseGoBuildAcceptsLocalFileTarget(t *testing.T) {
	name, packageDir := parseGoBuild("CGO_ENABLED=0 go build -o /out/manager cmd/main.go")
	if name != "manager" || packageDir != "cmd" {
		t.Fatalf("build = %q, %q, want manager artifact for cmd package", name, packageDir)
	}
}

func TestShippedCommandComponentsRequireMultipleRuntimeCommands(t *testing.T) {
	root := writeRuntimeClientRepository(t, map[string]string{
		"cmd/manager/main.go": `package main
func main() {}
`,
		"Dockerfile": `FROM golang AS builder
RUN go build -o /out/manager ./cmd/manager
FROM scratch
ENTRYPOINT ["/manager"]
`,
	})

	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Components) != 0 {
		t.Fatalf("components = %#v, want sole repository command left to deployment/repository identity", result.Components)
	}
}
