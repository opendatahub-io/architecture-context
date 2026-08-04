workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries ML models via InferenceService"
        sre = person "SRE / Platform Admin" "Monitors serving runtime health and metrics"

        ovms = softwareSystem "OpenVINO Model Server" "High-performance C++ inference server supporting KServe v1/v2 REST and gRPC APIs for serving ML models" {
            ovmsBinary = container "OVMS Binary" "Core inference engine serving REST and gRPC endpoints" "C++ on UBI 9"
            restApi = container "REST API" "KServe v2 REST endpoint for model inference and health checks" "HTTP/1.1 on 8080/TCP"
            grpcApi = container "gRPC API" "KServe v2 gRPC endpoint for model inference" "HTTP/2 on 9000/TCP"
            metricsEndpoint = container "Metrics Endpoint" "Prometheus metrics at /metrics" "HTTP on 8080/TCP"
            nginxSidecar = container "nginx mTLS Sidecar" "Optional reverse proxy for mTLS client certificate authentication" "nginx TLSv1.2" "Optional"
        }

        kserve = softwareSystem "KServe" "Manages InferenceService lifecycle, creates pods and services" "Internal Platform"
        istio = softwareSystem "Istio Service Mesh" "Provides transport security (mTLS) and traffic routing" "Internal Platform"
        odhDashboard = softwareSystem "ODH Dashboard" "RHOAI web UI for managing serving runtimes" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        modelStorage = softwareSystem "Model Storage" "Model artifact storage mounted at /mnt/models" "External"

        datascientist -> ovms "Sends inference requests via KServe v2 API"
        sre -> prometheus "Monitors OVMS metrics and health"

        ovmsBinary -> restApi "Serves"
        ovmsBinary -> grpcApi "Serves"
        restApi -> metricsEndpoint "Exposes"
        nginxSidecar -> ovmsBinary "Forwards authenticated requests (localhost)" "HTTP plaintext"

        kserve -> ovms "Manages pod lifecycle via ServingRuntime CRD"
        istio -> ovms "Provides mTLS and traffic routing"
        odhDashboard -> ovms "Discovers via opendatahub.io/dashboard label"
        prometheus -> ovms "Scrapes /metrics" "HTTP/8080"
        ovms -> modelStorage "Loads model artifacts" "Filesystem /mnt/models"
    }

    views {
        systemContext ovms "SystemContext" {
            include *
            autoLayout
        }

        container ovms "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Optional" {
                background #9b59b6
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
