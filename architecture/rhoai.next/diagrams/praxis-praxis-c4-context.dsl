workspace {
    model {
        client = person "Client Application" "Sends HTTP/HTTPS/gRPC requests through the proxy"
        operator = person "Platform Operator" "Configures proxy routes, filters, TLS, and deploys instances"

        praxis = softwareSystem "Praxis Proxy" "High-performance Rust-based proxy server with composable filter pipeline, TLS termination, hot-reload, and FIPS 140-3 compliance" {
            server = container "praxis-proxy" "Binary entry point: CLI, config loading, pipeline resolution, server bootstrap, hot-reload watcher" "Rust Binary"
            core = container "praxis-proxy-core" "YAML configuration, validation, error types, health state, KV store registry" "Rust Library"
            filter = container "praxis-proxy-filter" "HttpFilter and TcpFilter traits, pipeline engine, condition evaluation, all built-in filter implementations, FilterRegistry" "Rust Library"
            protocol = container "praxis-proxy-protocol" "Protocol trait, Pingora HTTP/TCP adapters, health check probes, admin endpoints, metrics" "Rust Library"
            tls = container "praxis-proxy-tls" "TLS config types, SNI resolution, cert loading, OpenSSL crypto provider installation, FIPS checking" "Rust Library"
        }

        upstream = softwareSystem "Upstream Backend Servers" "Backend services receiving proxied HTTP/HTTPS/gRPC traffic" "External"
        openssl = softwareSystem "System OpenSSL" "Cryptographic operations provider (sole crypto backend, FIPS 140-3 validated module)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry distributed tracing collector" "External"
        certProvider = softwareSystem "Certificate Provider" "cert-manager / certbot / operator providing TLS certificates" "External"
        pingora = softwareSystem "Pingora (quixotic-plecostomus)" "Underlying proxy engine for HTTP/TCP connection handling" "External Library"

        # Relationships
        client -> praxis "Sends HTTP/HTTPS requests" "HTTP/HTTPS 8080/TCP, TLS 1.2+/1.3"
        operator -> praxis "Configures via YAML, manages TLS certs" "YAML config files, PEM certificates"

        praxis -> upstream "Proxies requests to backend" "HTTP/HTTPS/gRPC, configurable TLS + mTLS"
        praxis -> openssl "All cryptographic operations" "Dynamic linking (libcrypto.so)"
        praxis -> otlpCollector "Exports traces" "gRPC/HTTP (optional, otel feature)"
        prometheus -> praxis "Scrapes metrics" "HTTP 9902/TCP /metrics"
        certProvider -> praxis "Provides TLS certificates" "File-based PEM, filesystem watch"

        # Internal container relationships
        server -> core "Loads and validates configuration" ""
        server -> protocol "Registers HTTP/TCP handlers with Pingora" ""
        server -> tls "Installs OpenSSL crypto provider, enforces FIPS" ""
        server -> filter "Resolves filter pipelines from config" ""
        protocol -> filter "Invokes filter pipeline on each request" ""
        filter -> core "Reads config, uses KV store" ""
        tls -> core "Reads TLS configuration" ""

        # Pingora relationship
        protocol -> pingora "Uses for HTTP/TCP connection lifecycle" "Rust crate dependency"
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
            element "External Library" {
                background #775599
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
