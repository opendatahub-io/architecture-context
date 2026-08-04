workspace {
    model {
        client = person "Client Application" "Sends LLM inference requests to the serving stack"
        platformAdmin = person "Platform Admin" "Configures routing rules, objectives, and pool topology"

        llmDRouter = softwareSystem "llm-d-router" "Envoy ExtProc service and Kubernetes controller suite for intelligent LLM inference request routing" {
            epp = container "Endpoint Picker (EPP)" "Envoy External Processing gRPC service with plugin-based scheduling pipeline" "Go gRPC Service" {
                extProcServer = component "ExtProc Server" "Receives per-request processing callouts from Envoy" "gRPC Server, Port 9002"
                pluginPipeline = component "Plugin Pipeline" "Evaluates requests against EndpointPickerConfig-driven strategy" "Scheduler, FlowControl, DataLayer, Parser"
                podReconciler = component "Pod Reconciler" "Watches backend pods to maintain live endpoint datastore" "controller-runtime Controller"
                poolReconciler = component "InferencePool Reconciler" "Reconciles InferencePool CRs; conditional autoscaling integration" "controller-runtime Controller"
                modelRewriteReconciler = component "InferenceModelRewrite Reconciler" "Reconciles model routing rules" "controller-runtime Controller"
                objectiveReconciler = component "InferenceObjective Reconciler" "Reconciles optimization objectives" "controller-runtime Controller"
                datastore = component "Live Endpoint Datastore" "Maintains real-time state of backend model-server pods" "In-memory datastore"
                healthService = component "Health Service" "gRPC health checks for liveness/readiness probes" "gRPC Server, Port 9003"
                metricsEndpoint = component "Metrics Endpoint" "Exposes Prometheus metrics via controller-runtime registry" "HTTP, Port 9090"
            }
            coordinator = container "coordinator" "Configuration orchestrator for the llm-d serving stack" "Go controller-runtime operator"
            pdSidecar = container "pd-sidecar" "Routing sidecar for model-server pods (FIPS: strictfipsruntime)" "Go controller-runtime operator"
        }

        envoyProxy = softwareSystem "Envoy Proxy" "L7 proxy that intercepts inference requests and delegates routing via ExtProc" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource watch/reconciliation" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Receives distributed traces via OTLP/gRPC" "External"
        prometheus = softwareSystem "Prometheus" "Scrapes metrics from EPP metrics endpoint" "External"
        gaie = softwareSystem "gateway-api-inference-extension" "Provides pool-based autoscaling for InferencePool resources" "Internal Platform"
        kvCache = softwareSystem "llm-d-kv-cache" "KV-cache awareness library for scheduling decisions" "Internal Platform"
        backendPods = softwareSystem "Backend Model-Server Pods" "vLLM or other model-server pods serving inference workloads" "Internal Platform"

        # External interactions
        client -> envoyProxy "Sends inference requests" "HTTP/HTTPS"
        envoyProxy -> epp "ExtProc gRPC callout per request" "gRPC/9002, Optional TLS"
        envoyProxy -> backendPods "Forwards request to selected backend" "HTTP/HTTPS"

        platformAdmin -> k8sAPI "Creates/updates InferenceModelRewrite, InferenceObjective, InferencePool CRs" "kubectl"

        # EPP outbound
        epp -> k8sAPI "Watches Pods and CRDs; reconciles resources" "HTTPS/WSS, Port 6443, TLS 1.2+, SA Token"
        epp -> otelCollector "Exports distributed traces" "OTLP/gRPC"
        epp -> gaie "Conditional integration for pool autoscaling" "Go library + Controller watch"
        epp -> kvCache "KV-cache aware scheduling decisions" "Go library"

        prometheus -> epp "Scrapes metrics" "HTTP/9090"

        # Internal component interactions
        extProcServer -> pluginPipeline "Evaluates request"
        pluginPipeline -> datastore "Queries live pod state"
        podReconciler -> datastore "Updates pod availability"
    }

    views {
        systemContext llmDRouter "SystemContext" {
            include *
            autoLayout
        }

        container llmDRouter "Containers" {
            include *
            autoLayout
        }

        component epp "EPPComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
