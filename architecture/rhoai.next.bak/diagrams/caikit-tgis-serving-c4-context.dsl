workspace {
    model {
        user = person "Data Scientist / Application Developer" "Deploys LLMs and sends inference requests via HTTP/gRPC"

        caikitTgisServing = softwareSystem "Caikit-TGIS-Serving" "Container image packaging Caikit AI runtime with TGIS backend for LLM inference via KServe ServingRuntimes" {
            caikitRuntime = container "Caikit Runtime" "Python runtime (caikit + caikit-nlp + caikit-tgis-backend) providing HTTP/gRPC API for model inference" "Python 3.11, transformer-container" {
                httpApi = component "HTTP REST API" "Exposes /api/v1/task/text-generation and streaming endpoints" "Port 8080/TCP"
                grpcApi = component "gRPC API" "Exposes caikit.runtime.Nlp service for inference" "Port 8085/TCP"
                metricsEndpoint = component "Metrics Endpoint" "Prometheus metrics for runtime observability" "Port 8086/TCP"
                healthProbe = component "Health Probe" "caikit_health_probe for readiness/liveness" "HTTP"
                tgisConnector = component "TGIS Backend Connector" "caikit-tgis-backend: translates Caikit requests to TGIS gRPC calls" "gRPC client"
            }
            tgis = container "TGIS (Text Generation Inference Server)" "GPU-accelerated inference engine for LLM model loading and execution" "kserve-container, Port 8033/TCP gRPC"
            modelVolume = container "Model Volume" "Shared /mnt/models volume for model artifacts" "PVC or S3-initialized"
        }

        kserve = softwareSystem "KServe" "ML model serving platform managing ServingRuntime and InferenceService lifecycle" "Internal Platform"
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS, traffic management, ingress gateway, and access control" "Internal Platform"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform with scale-to-zero capability" "Internal Platform"
        prometheus = softwareSystem "Prometheus (User Workload Monitoring)" "Metrics collection and monitoring via ServiceMonitor" "Internal Platform"
        authorino = softwareSystem "Authorino" "External authorization service for Bearer token validation" "Internal Platform"
        s3 = softwareSystem "S3-Compatible Storage" "Model artifact storage (AWS S3, MinIO, Ceph)" "External"

        # Relationships
        user -> istio "Sends inference requests" "HTTPS/443, TLS 1.2+, Bearer Token"
        istio -> caikitRuntime "Routes requests via mTLS sidecar" "HTTP/8080, gRPC/8085, mTLS STRICT"
        caikitRuntime -> tgis "Forwards inference requests" "gRPC/8033, localhost"
        tgis -> modelVolume "Loads model artifacts" "Filesystem /mnt/models"

        kserve -> caikitTgisServing "Manages pod lifecycle via ServingRuntime/InferenceService CRs"
        knative -> caikitTgisServing "Provides autoscaling and scale-to-zero"
        prometheus -> caikitRuntime "Scrapes metrics" "HTTP/8086, PERMISSIVE mTLS"
        s3 -> modelVolume "Provides model artifacts via KServe storage initializer" "HTTPS/443, TLS 1.2+, AWS IAM"
        istio -> authorino "Delegates token validation (optional)" "gRPC"
    }

    views {
        systemContext caikitTgisServing "SystemContext" {
            include *
            autoLayout
            description "System context showing caikit-tgis-serving within the RHOAI platform ecosystem"
        }

        container caikitTgisServing "Containers" {
            include *
            autoLayout
            description "Container view of the two-container pod architecture (Caikit + TGIS)"
        }

        component caikitRuntime "Components" {
            include *
            autoLayout
            description "Internal components of the Caikit Runtime container"
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Internal Platform" {
                background #27ae60
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Component" {
                background #85BBF0
                color #000000
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
        }
    }
}
