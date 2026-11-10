workspace "Praxis" "C4 context for praxis-praxis (RHOAI 3.7-ea.1)" {
    model {
        client = person "API Client" "Sends HTTP/gRPC/TCP traffic through the proxy"
        operator = person "Platform Operator" "Deploys Praxis with a YAML config; uses loopback admin API"

        praxis = softwareSystem "Praxis" "Rust framework and binary for secure-by-default HTTP/TCP proxies built from composable filters" {
            server = container "praxis-proxy (praxis binary)" "Loads YAML config, builds per-listener filter pipelines, hot reload, --validate/--dump" "Rust"
            core = container "praxis-proxy-core" "Config types/validation, KV store registry, sub-request client, ServerRuntime contract" "Rust library"
            filter = container "praxis-proxy-filter" "HttpFilter/TcpFilter traits, FilterPipeline, built-in filters, Policy integration" "Rust library"
            protocol = container "praxis-proxy-protocol" "HTTP/TCP adapters for Pingora/hyper, admin/health/metrics handlers, active health checks" "Rust library"
            tls = container "praxis-proxy-tls" "OpenSSL rustls provider, SNI selection, mTLS/SPIFFE verification, cert hot reload" "Rust library"
        }

        praxisAi = softwareSystem "praxis-proxy/ai (praxis-ai)" "AI Gateway built on Praxis framework crates" "Internal RHOAI"
        upstreams = softwareSystem "Upstream Backends" "Configured upstream clusters" "External"
        otlp = softwareSystem "OpenTelemetry Collector" "Trace collection" "External"
        prometheus = softwareSystem "Prometheus / Kubelet" "Metrics scrape and health probes" "External"
        pingora = softwareSystem "Pingora fork (quixotic-plecostomus-*)" "HTTP/TCP proxy engine and rustls-openssl provider, v0.11.4" "External"
        openssl = softwareSystem "System OpenSSL (UBI 9)" "libcrypto/libssl with FIPS provider" "External"
        ppe = softwareSystem "praxis-policy (PPE 0.6.0)" "Policy engine: JWT, API key, OAuth, DPoP, rate limit" "External"
        sinks = softwareSystem "Syslog / File Sinks" "Access log destinations" "External"

        client -> server "Proxied requests" "HTTP/1.1, HTTP/2, gRPC, TCP on 8080/TCP, optional TLS"
        operator -> server "Admin API (stats, pipelines, log level, KV)" "HTTP 9901/TCP loopback, no auth"
        prometheus -> protocol "Scrapes /metrics, probes /healthy /ready" "HTTP 9902/TCP"
        server -> core "Uses"
        server -> filter "Builds pipelines with"
        server -> protocol "Registers handlers with"
        server -> tls "Configures TLS with"
        protocol -> filter "Invokes pipeline"
        protocol -> pingora "Runs on (default backend)"
        tls -> openssl "All crypto via rustls-openssl"
        filter -> ppe "Optional policy filters" "feature policy-*"
        filter -> upstreams "Forwards traffic and health checks" "HTTP/gRPC/TCP, optional TLS/mTLS"
        filter -> otlp "Exports traces" "OTLP gRPC/HTTP, optional TLS"
        filter -> sinks "Writes access logs" "UDP/TCP/Unix"
        praxisAi -> praxis "Depends on framework crates" "Rust crates"
    }

    views {
        systemContext praxis "SystemContext" {
            include *
            autoLayout
        }

        container praxis "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Person" {
                shape person
            }
        }
    }
}
