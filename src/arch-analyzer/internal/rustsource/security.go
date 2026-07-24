package rustsource

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func extractSecurityFacts(root string, endpoints []model.HTTPEndpoint) (
	[]model.Secret,
	[]model.AuthenticationFact,
	error,
) {
	argsPath := filepath.Join(root, "src", "args.rs")
	argsContent, err := os.ReadFile(argsPath)
	if err != nil && !os.IsNotExist(err) {
		return nil, nil, fmt.Errorf("read Rust arguments: %w", err)
	}
	configPath := filepath.Join(root, "src", "config.rs")
	configContent, err := os.ReadFile(configPath)
	if err != nil && !os.IsNotExist(err) {
		return nil, nil, fmt.Errorf("read Rust configuration: %w", err)
	}
	args := string(argsContent)
	config := string(configContent)
	routesPath := filepath.Join(root, "src", "server", "routes.rs")
	routesContent, err := os.ReadFile(routesPath)
	if err != nil && !os.IsNotExist(err) {
		return nil, nil, fmt.Errorf("read Rust routes: %w", err)
	}
	routes := string(routesContent)
	var secrets []model.Secret
	if strings.Contains(args, "tls_cert_path") && strings.Contains(args, "tls_key_path") {
		secrets = append(secrets, model.Secret{
			Name: "TLS server cert/key", Type: "kubernetes.io/tls",
			ReferencedBy: []string{"Rust HTTP server TLS"}, ProvisionedBy: "Platform operator / cert-manager",
			Source: fmt.Sprintf("src/args.rs:%d", sourceLine(args, "tls_cert_path")),
		})
	}
	if strings.Contains(args, "tls_client_ca_cert_path") {
		secrets = append(secrets, model.Secret{
			Name: "TLS client CA cert", Type: "Opaque",
			ReferencedBy: []string{"Rust HTTP server mTLS"}, ProvisionedBy: "Platform operator",
			Source: fmt.Sprintf("src/args.rs:%d", sourceLine(args, "tls_client_ca_cert_path")),
		})
	}
	if strings.Contains(config, "pub api_token") {
		secrets = append(secrets, model.Secret{
			Name: "API tokens", Type: "Opaque (env var)",
			ReferencedBy: []string{"Downstream service authentication"}, ProvisionedBy: "Platform operator",
			Source: fmt.Sprintf("src/config.rs:%d", sourceLine(config, "pub api_token")),
		})
	}
	if strings.Contains(config, "pub struct TlsConfig") && strings.Contains(config, "cert_path") {
		secrets = append(secrets, model.Secret{
			Name: "Downstream TLS certs", Type: "Opaque",
			ReferencedBy: []string{"Downstream service TLS clients"}, ProvisionedBy: "Platform operator",
			Source: fmt.Sprintf("src/config.rs:%d", sourceLine(config, "pub struct TlsConfig")),
		})
	}

	if len(endpoints) == 0 {
		return secrets, nil, nil
	}
	routeSource := endpoints[0].Source
	authentication := []model.AuthenticationFact{
		{
			Endpoint: "/api/v1/*, /api/v2/*", Methods: "POST",
			Mechanism: "Header passthrough", EnforcementPoint: "Application-level filtering",
			Policy: "Configured headers are forwarded to downstream services", Source: routeSource,
		},
		{
			Endpoint: "/health, /info", Methods: "GET", Mechanism: "None",
			EnforcementPoint: "None", Policy: "Unauthenticated health server", Source: routeSource,
		},
	}
	if strings.Contains(args, "tls_client_ca_cert_path") {
		authentication = append(authentication, model.AuthenticationFact{
			Endpoint: "All endpoints", Methods: "ALL", Mechanism: "TLS / mTLS",
			EnforcementPoint: "Rust TLS acceptor", Policy: "Optional server TLS and client certificate verification",
			Source: fmt.Sprintf("src/args.rs:%d", sourceLine(args, "tls_client_ca_cert_path")),
		})
	}
	if strings.Contains(routes, "rewrite_forwarded_access_headers") {
		authentication = append(authentication, model.AuthenticationFact{
			Endpoint: "/api/v1/*, /api/v2/*", Methods: "POST",
			Mechanism: "X-Forwarded-Access-Token rewrite", EnforcementPoint: "Application-level",
			Policy: "Forwarded access token can be rewritten to an Authorization Bearer header",
			Source: fmt.Sprintf("src/server/routes.rs:%d", sourceLine(routes, "rewrite_forwarded_access_headers")),
		})
	}
	return secrets, authentication, nil
}
