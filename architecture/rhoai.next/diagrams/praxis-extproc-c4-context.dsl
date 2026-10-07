workspace {
    model {
        client = person "External Client" "Sends inference requests to ML models via HTTPS"

        praxisExtproc = softwareSystem "praxis-extproc" "Envoy ExtProc gRPC server running Praxis filter pipelines for header/body inspection, mutation, and rejection in the MaaS data path" {
            preProcessing = container "payload-pre-processing" "Pre-auth ExtProc stage: promotes body-level model identifiers to routing headers" "Rust Service (gRPC)"
            postProcessing = container "payload-processing" "Post-auth ExtProc stage: runs full processing pipeline (request_id, etc.)" "Rust Service (gRPC)"
            healthService = container "Health Check Service" "gRPC health check for Kubernetes readiness probes; reports ExtProc and FIPS status" "Rust Service (gRPC)"
            metricsEndpoint = container "Metrics Endpoint" "Prometheus metrics exposition (request count, duration, rejections)" "Rust Service (HTTP)"
            fipsLayer = container "FIPS Compliance Layer" "OpenSSL crypto provider with three-layer FIPS enforcement" "Rust Module"
        }

        istioGateway = softwareSystem "Istio Gateway (Envoy)" "Envoy proxy handling ingress traffic with ExtProc filter chain integration" "External"
        kuadrant = softwareSystem "Kuadrant" "Authentication and authorization via WasmPlugin in Envoy filter chain" "External"
        kservePool = softwareSystem "KServe InferencePool" "Endpoint selection for inference backends based on model routing headers" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for reading configmaps, secrets, and CRDs" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection from openshift-monitoring namespace" "External"

        client -> istioGateway "Sends inference requests" "HTTPS/443, TLS 1.2+, Bearer Token"
        istioGateway -> preProcessing "Pre-auth ExtProc stream" "gRPC/9004, TLS (self-signed)"
        istioGateway -> kuadrant "Token validation" "In-process WasmPlugin"
        istioGateway -> postProcessing "Post-auth ExtProc stream" "gRPC/9004, TLS (self-signed)"
        istioGateway -> kservePool "Routes via X-Gateway-Model-Name header" "HTTP"
        postProcessing -> k8sAPI "Reads configmaps, secrets, ExternalProvider/ExternalModel CRs" "HTTPS/443, SA Token"
        prometheus -> metricsEndpoint "Scrapes metrics" "HTTP/9090"
        preProcessing -> fipsLayer "Uses OpenSSL FIPS provider"
        postProcessing -> fipsLayer "Uses OpenSSL FIPS provider"
    }

    views {
        systemContext praxisExtproc "SystemContext" {
            include *
            autoLayout
        }

        container praxisExtproc "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
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
