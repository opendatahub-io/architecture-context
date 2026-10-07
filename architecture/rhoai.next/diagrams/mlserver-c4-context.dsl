workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models via InferenceService"
        sre = person "SRE / Platform Admin" "Monitors MLServer health and performance"

        mlserver = softwareSystem "MLServer" "Multi-model inference server implementing V2 Inference Protocol via REST and gRPC" {
            restServer = container "REST Server" "Serves V2 Inference Protocol endpoints" "FastAPI + uvicorn, 8080/TCP"
            grpcServer = container "gRPC Server" "Serves V2 Inference Protocol RPCs" "grpc.aio, 8081/TCP"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics" "uvicorn, 8082/TCP"
            dataPlane = container "DataPlane Handler" "Routes inference requests to model registry" "Python"
            modelRegistry = container "MultiModelRegistry" "Manages model lifecycle (load/reload/unload)" "Python"
            trustedRuntimes = container "Trusted Runtimes Validator" "Enforces allowlist of permitted model implementations" "JSON allowlist, build-time baked"
            batchHandler = container "Adaptive Batching" "Batches inference requests for throughput" "Python"
            workerPool = container "Parallel Worker Pool" "CPU-bound inference in worker processes" "gevent"
            runtimePlugins = container "Runtime Plugins" "ML framework backends (sklearn, xgboost, lightgbm, onnx, mlflow, huggingface, alibi, catboost, mllib)" "Python plugins"
        }

        kserve = softwareSystem "KServe" "Manages serving runtime pods, injects sidecars, mounts model artifacts" "Platform"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Sidecar proxy for TLS termination and OAuth/SA token validation" "Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "Observability"
        otlpCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "Observability"
        kafka = softwareSystem "Kafka" "Async inference messaging (optional)" "External"
        modelStorage = softwareSystem "Model Storage" "Model artifacts via KServe volume mounts (/mnt/models)" "Storage"

        # External relationships
        dataScientist -> kubeRBACProxy "Sends inference requests" "HTTPS/443, Bearer Token"
        kubeRBACProxy -> restServer "Forwards validated REST requests" "HTTP/8080"
        kubeRBACProxy -> grpcServer "Forwards validated gRPC requests" "gRPC H2C/8081"
        sre -> prometheus "Monitors metrics dashboards"

        # Internal relationships
        restServer -> dataPlane "Routes requests"
        grpcServer -> dataPlane "Routes requests"
        dataPlane -> modelRegistry "Lookups and invokes models"
        modelRegistry -> trustedRuntimes "Validates model implementation class"
        modelRegistry -> batchHandler "Queues for batched inference"
        batchHandler -> workerPool "Distributes to workers"
        modelRegistry -> runtimePlugins "Loads and invokes ML models"
        runtimePlugins -> modelStorage "Reads model artifacts" "Filesystem /mnt/models"

        # Platform relationships
        kserve -> mlserver "Manages pod lifecycle, scaling, sidecar injection"
        kserve -> modelStorage "Mounts model artifacts as volumes"

        # Egress
        mlserver -> otlpCollector "Exports trace spans" "gRPC (insecure)"
        mlserver -> kafka "Async inference messages (optional)" "TCP"
        prometheus -> metricsServer "Scrapes /metrics" "HTTP/8082"
    }

    views {
        systemContext mlserver "SystemContext" {
            include *
            autoLayout
        }

        container mlserver "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Platform" {
                background #f5a623
                color #000000
            }
            element "Observability" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Storage" {
                background #e8e8e8
                color #000000
            }
        }
    }
}
