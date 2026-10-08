workspace {
    model {
        user = person "API Consumer" "Sends HTTP/HTTPS/TCP requests through the proxy"
        operator = person "Platform Operator" "Deploys and configures Praxis via YAML; monitors health"

        praxis = softwareSystem "Praxis Proxy" "High-performance, composable Rust proxy server with filter-first architecture" {
            server = container "praxis-proxy" "Binary entry point: CLI, config loading, tracing, crypto provider install" "Rust Binary"
            protocol = container "praxis-proxy-protocol" "HTTP/TCP protocol adapters for Pingora; health probes, admin endpoints" "Rust Library"
            filter = container "praxis-proxy-filter" "Filter traits, pipeline engine, all built-in filter implementations" "Rust Library"
            core = container "praxis-proxy-core" "YAML config, validation, KV store, health state" "Rust Library"
            tls = container "praxis-proxy-tls" "TLS config, SNI resolution, certificate loading, OpenSSL crypto provider" "Rust Library"
        }

        upstream = softwareSystem "Upstream Services" "Backend services receiving proxied traffic" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing aggregation" "External"
        praxisAI = softwareSystem "Praxis AI Extension" "AI-specific proxy features (AI gateway)" "Internal"
        pingora = softwareSystem "Pingora Engine" "Cloudflare proxy engine: connection pooling, HTTP framing" "External"
        openssl = softwareSystem "System OpenSSL" "FIPS-validated cryptography on RHEL 9" "External"

        user -> praxis "Sends requests via HTTP/HTTPS/TCP" "8080/TCP"
        operator -> praxis "Monitors health and metrics" "9902/TCP HTTP"
        praxis -> upstream "Forwards proxied traffic" "HTTP/HTTPS/TCP"
        praxis -> prometheus "Exports Prometheus metrics" "9902/TCP HTTP"
        praxis -> otel "Exports OTLP traces" "gRPC/HTTP"
        praxisAI -> praxis "Extends with AI features" "Compile-time"
        praxis -> pingora "Uses as core proxy engine" "In-process"
        praxis -> openssl "Delegates all cryptography" "FFI"

        server -> protocol "Bootstraps protocol adapters"
        protocol -> filter "Invokes filter pipelines"
        filter -> core "Reads config, uses KV store"
        core -> tls "TLS configuration"
        tls -> openssl "OpenSSL crypto operations"
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
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
