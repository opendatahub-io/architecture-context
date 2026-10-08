workspace {
    model {
        client = person "External Client" "Sends HTTP/HTTPS/TCP requests through the proxy"
        operator = person "Platform Operator" "Configures proxy listeners, filter pipelines, and TLS"

        praxis = softwareSystem "Praxis Proxy" "High-performance, security-first proxy server with composable filter pipeline architecture" {
            server = container "praxis-proxy" "Binary entry point: CLI, config loading, pipeline resolution, hot-reload watcher, server bootstrap" "Rust Binary"
            protocol = container "praxis-proxy-protocol" "Protocol trait, Pingora HTTP/TCP adapters, health check probes, admin endpoints, metrics exporter" "Rust Library"
            filter = container "praxis-proxy-filter" "HttpFilter and TcpFilter traits, pipeline engine, condition evaluation, all built-in filter implementations" "Rust Library"
            core = container "praxis-proxy-core" "YAML config types, validation, error types, health state, KV store registry" "Rust Library"
            tls = container "praxis-proxy-tls" "TLS config types, SNI resolution, cert loading, crypto provider installation, FIPS status" "Rust Library"
        }

        pingora = softwareSystem "Pingora" "HTTP/TCP proxy engine (Cloudflare fork: quixotic-plecostomus 0.11.0)" "External"
        openssl = softwareSystem "System OpenSSL" "libcrypto.so — cryptographic primitives (FIPS 140-3 on RHEL)" "External"
        upstreams = softwareSystem "Upstream Clusters" "Backend services receiving proxied traffic" "External"
        otlp = softwareSystem "OTLP Collector" "OpenTelemetry distributed tracing and metrics" "External"
        filesystem = softwareSystem "File System" "YAML config files, TLS certificates and keys" "External"

        # External relationships
        client -> praxis "Sends requests" "HTTP/HTTPS 8080/TCP, TLS 1.2+"
        operator -> praxis "Configures via YAML" "File"
        praxis -> upstreams "Proxies traffic" "HTTP/HTTPS/TCP, configurable TLS"
        praxis -> otlp "Exports telemetry" "gRPC/HTTP, TLS"
        praxis -> filesystem "Watches for changes" "inotify/kqueue"

        # Internal relationships
        server -> core "Loads config" ""
        server -> protocol "Bootstraps handlers" ""
        server -> tls "Installs crypto provider" ""
        protocol -> filter "Executes filter pipeline" ""
        filter -> core "Reads config types" ""
        tls -> openssl "Delegates crypto" "FFI"

        # Infrastructure
        praxis -> pingora "Delegates HTTP/TCP framing, connection pooling" "Rust API"
        tls -> openssl "All TLS cryptography" "rustls-openssl provider"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
