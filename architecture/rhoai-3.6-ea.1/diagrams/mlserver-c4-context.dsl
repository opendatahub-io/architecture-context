workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML models for inference"

        mlserver = softwareSystem "MLServer" "Python-based model serving runtime implementing the KServe V2 Inference Protocol over REST and gRPC" {
            restServer = container "REST Server" "FastAPI/uvicorn serving V2 Inference Protocol endpoints" "Python FastAPI" "8080/TCP"
            grpcServer = container "gRPC Server" "Async gRPC server for GRPCInferenceService and ModelRepositoryService" "Python gRPC" "8081/TCP"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint" "Python HTTP" "8082/TCP"
            dataPlane = container "DataPlane Handler" "Unified request routing layer shared by REST and gRPC transports" "Python"
            runtimePlugins = container "Runtime Plugins" "Pluggable ML framework backends: sklearn, xgboost, lightgbm, onnx, mlflow, huggingface, catboost, mllib, alibi-detect, alibi-explain" "Python Packages"
            trustedRuntimes = container "Trusted Runtimes Gate" "Allowlist at /etc/mlserver/trusted-runtimes.json restricting which model implementations can be loaded" "JSON Config"
        }

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform providing ServingRuntime lifecycle management" "Internal Platform"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Sidecar container enforcing OpenShift OAuth/ServiceAccount token authentication" "Internal Platform"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection and export" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        kafka = softwareSystem "Kafka" "Optional message queue for asynchronous batch inference" "External Optional"
        openshiftRoute = softwareSystem "OpenShift Route / Istio Gateway" "External traffic ingress with TLS termination" "Internal Platform"

        # Relationships
        user -> openshiftRoute "Sends inference requests via" "HTTPS"
        openshiftRoute -> kubeRbacProxy "Routes traffic to KServe pod" "HTTP/gRPC"
        kubeRbacProxy -> mlserver "Forwards authenticated requests to" "HTTP/8080, gRPC/8081"

        user -> mlserver "Sends inference requests (after auth)" "REST/gRPC V2 Protocol"
        mlserver -> otelCollector "Exports distributed traces" "OTLP/gRPC"
        mlserver -> kafka "Consumes/produces async inference messages" "Kafka Protocol"
        prometheus -> mlserver "Scrapes metrics from" "HTTP/8082"
        kserve -> mlserver "Manages lifecycle as ServingRuntime container"

        # Internal container relationships
        restServer -> dataPlane "Routes REST requests to"
        grpcServer -> dataPlane "Routes gRPC requests to"
        dataPlane -> trustedRuntimes "Validates runtime against allowlist"
        dataPlane -> runtimePlugins "Dispatches inference to loaded model"
        restServer -> otelCollector "Exports traces" "OTLP/gRPC"
        grpcServer -> otelCollector "Exports traces" "OTLP/gRPC"
    }

    views {
        systemContext mlserver "SystemContext" {
            include *
            autoLayout
            description "MLServer system context showing external actors and platform dependencies"
        }

        container mlserver "Containers" {
            include *
            autoLayout
            description "MLServer internal container architecture showing REST, gRPC, and plugin subsystems"
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External Optional" {
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
