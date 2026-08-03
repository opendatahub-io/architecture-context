package gosource

import (
	"strings"
	"testing"
)

const endpointMetricsRuntimeSource = `package main

import (
	"context"
	"net"
	stdhttp "net/http"
	"net/url"

	framework "github.com/example/framework"
	datasourcehttp "github.com/llm-d/llm-d-inference-scheduler/pkg/epp/framework/plugins/datalayer/source/http"
)

const MetricsDataSourceType = "metrics"

type endpoint struct {
	MetricsHost string
}

func (endpoint) GetMetricsHost() string { return "127.0.0.1:9090" }

func discoverEndpoint() endpoint {
	return endpoint{MetricsHost: net.JoinHostPort("127.0.0.1", "9090")}
}

func parseMetrics([]byte) (any, error) { return nil, nil }

func MetricsDataSourceFactory() any {
	return datasourcehttp.NewHTTPDataSource(MetricsDataSourceType, "http", "/metrics", parseMetrics)
}

func endpointURL(ep endpoint) url.URL {
	return url.URL{Scheme: "http", Host: ep.GetMetricsHost(), Path: "/metrics"}
}

func fetch(ctx context.Context, client *stdhttp.Client, target string) error {
	request, err := stdhttp.NewRequestWithContext(ctx, stdhttp.MethodGet, target, nil)
	if err != nil {
		return err
	}
	_, err = client.Do(request)
	return err
}

func registerInTreePlugins() {
	framework.Register(MetricsDataSourceType, MetricsDataSourceFactory)
	framework.Register("later-plugin", parseMetrics)
}

func Run() {
	registerInTreePlugins()
}
`

func TestEndpointMetricsClientRequiresCompleteRuntimeChain(t *testing.T) {
	result, err := Extract(writeSecurityRepository(t, endpointMetricsRuntimeSource))
	if err != nil {
		t.Fatal(err)
	}
	if len(result.RuntimeClients) != 1 {
		t.Fatalf("runtime clients = %#v, want one endpoint metrics client", result.RuntimeClients)
	}
	client := result.RuntimeClients[0]
	if client.Target != "Model-serving endpoints" || client.Client != "HTTP metrics data source" || client.Source == "" {
		t.Fatalf("runtime client = %#v, want source-backed model-serving metrics client", client)
	}
}

func TestEndpointMetricsClientRejectsIncompleteRuntimeChain(t *testing.T) {
	tests := []struct {
		name string
		old  string
		new  string
	}{
		{name: "endpoint host", old: `MetricsHost: net.JoinHostPort("127.0.0.1", "9090")`, new: `MetricsHost: "127.0.0.1:9090"`},
		{name: "datasource construction", old: `return datasourcehttp.NewHTTPDataSource(MetricsDataSourceType, "http", "/metrics", parseMetrics)`, new: `return nil`},
		{name: "endpoint URL", old: `Host: ep.GetMetricsHost()`, new: `Host: "127.0.0.1:9090"`},
		{name: "executed request", old: `_, err = client.Do(request)`, new: `_ = request`},
		{name: "runtime registration", old: `framework.Register(MetricsDataSourceType, MetricsDataSourceFactory)`, new: `_ = []any{MetricsDataSourceType, MetricsDataSourceFactory}`},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			source := strings.Replace(endpointMetricsRuntimeSource, test.old, test.new, 1)
			if source == endpointMetricsRuntimeSource {
				t.Fatalf("mutation %q did not alter fixture", test.name)
			}
			result, err := Extract(writeSecurityRepository(t, source))
			if err != nil {
				t.Fatal(err)
			}
			for _, client := range result.RuntimeClients {
				if client.Target == "Model-serving endpoints" {
					t.Fatalf("runtime clients = %#v, want incomplete %s chain rejected", result.RuntimeClients, test.name)
				}
			}
		})
	}
}
