workspace {
    model {
        // Users
        datascientist = person "Data Scientist" "Deploys ML models and creates InferencePool/InferenceObjective resources"
        platformadmin = person "Platform Administrator" "Configures Gateway API, InferencePool, and model server infrastructure"
        client = person "API Client" "Sends inference requests (OpenAI-compatible API) to deployed models"

        // Primary System
        gatewayInferenceExt = softwareSystem "Gateway API Inference Extension" "Kubernetes-native inference gateway extension providing intelligent request routing, model-aware load balancing, and flow control for LLM serving" {
            epp = container "Endpoint Picker (EPP)" "Intelligent request routing with model-aware scheduling, flow control, and metrics-driven endpoint selection" "Go Service (Envoy ext-proc)" {
                controllerManager = component "Controller Manager" "Watches InferencePool, InferenceObjective, InferenceModelRewrite CRDs and Pods via controller-runtime" "Go"
                extProcServer = component "ext-proc gRPC Server" "Bidirectional gRPC streaming with Envoy proxy for request interception" "gRPC/HTTP2, TLS, 9002/TCP"
                scheduler = component "Scheduler" "Filter-Score-Pick pipeline with pluggable scheduling profiles" "Go"
                flowControl = component "Flow Control" "Priority-based queuing with fairness enforcement, supervisor-worker pattern" "Go"
                datastore = component "In-Memory Datastore" "Maintains real-time endpoint state, metrics, model metadata" "Go"
                metricsScraper = component "Metrics Scraper" "Scrapes Prometheus metrics from model server pods every 50ms" "Go"
            }
            bbr = container "Body-Based Router (BBR)" "HTTP body inspection and header mutation for model-name-based routing" "Go Service (Envoy ext-proc)" {
                bbrExtProc = component "ext-proc gRPC Server" "Body inspection and header mutation via plugin framework" "gRPC/HTTP2, TLS, 9004/TCP"
                pluginFramework = component "Plugin Framework" "Composable RequestProcessor/ResponseProcessor plugins" "Go"
                bodyFieldPlugin = component "BodyFieldToHeader Plugin" "Extracts model field from OpenAI-compatible JSON body" "Go"
                baseModelPlugin = component "BaseModelExtractor Plugin" "Resolves LoRA adapter names to base model names via ConfigMap" "Go"
            }
            latencyTraining = container "Latency Predictor Training Server" "Trains ML models (Bayesian Ridge, XGBoost, LightGBM) for request latency prediction" "Python FastAPI, 8000/TCP"
            latencyPrediction = container "Latency Predictor Prediction Server" "Serves latency predictions using trained models for scheduling decisions" "Python FastAPI, 8001/TCP"
        }

        // External Systems
        envoyGateway = softwareSystem "Gateway (Istio / GKE)" "Envoy-based ingress gateway providing traffic routing via Gateway API" "External"
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for CRD reconciliation, Pod discovery, and leader election" "External"
        modelServers = softwareSystem "Model Servers" "LLM serving infrastructure (vLLM, SGLang, Triton TensorRT-LLM, trtllm-serve)" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring system that scrapes EPP/BBR operational metrics" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace collector for distributed tracing" "External"

        // Relationships - Users
        client -> envoyGateway "Sends inference requests" "HTTP/HTTPS 80/443"
        datascientist -> k8sApi "Creates InferencePool, InferenceObjective, InferenceModelRewrite CRDs" "kubectl/HTTPS"
        platformadmin -> envoyGateway "Configures Gateway and HTTPRoute resources" "kubectl/HTTPS"

        // Relationships - Gateway to Extension
        envoyGateway -> epp "Sends ext-proc processing requests for endpoint selection" "gRPC/HTTP2, TLS, 9002/TCP"
        envoyGateway -> bbr "Sends ext-proc processing requests for body inspection" "gRPC/HTTP2, TLS, 9004/TCP"
        envoyGateway -> modelServers "Routes inference traffic to selected endpoint" "HTTP/HTTP2"

        // Relationships - Extension to Infrastructure
        epp -> k8sApi "Watches CRDs (InferencePool, InferenceObjective, InferenceModelRewrite) and Pods" "HTTPS/443, SA Token"
        epp -> modelServers "Scrapes Prometheus metrics (KV cache, queue depth, LoRA state)" "HTTP, configurable port"
        epp -> latencyPrediction "Requests latency predictions for scheduling" "HTTP/8001"
        epp -> otlpCollector "Exports OpenTelemetry traces" "gRPC/4317"
        bbr -> k8sApi "Watches ConfigMaps for LoRA adapter mappings" "HTTPS/443, SA Token"
        latencyTraining -> latencyPrediction "Provides trained model artifacts" "HTTP/8000"
        prometheus -> epp "Scrapes operational metrics" "HTTP/9090"
        prometheus -> bbr "Scrapes operational metrics" "HTTP/9090"
    }

    views {
        systemContext gatewayInferenceExt "SystemContext" {
            include *
            autoLayout
        }

        container gatewayInferenceExt "Containers" {
            include *
            autoLayout
        }

        component epp "EPPComponents" {
            include *
            autoLayout
        }

        component bbr "BBRComponents" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
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
