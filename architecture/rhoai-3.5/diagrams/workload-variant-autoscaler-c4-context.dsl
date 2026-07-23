workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys and manages LLM inference models on Kubernetes"
        platformengineer = person "Platform Engineer" "Configures autoscaling policies and GPU quotas"

        wva = softwareSystem "Workload Variant Autoscaler (WVA)" "Intelligent autoscaler for LLM inference model servers based on GPU saturation, KV cache utilization, and queueing theory" {
            controllerManager = container "WVA Controller Manager" "Reconciles HPAs, ScaledObjects, ConfigMaps, and InferencePools; orchestrates optimization engines" "Go (controller-runtime / kubebuilder)"
            saturationEngine = container "Saturation Engine" "Periodic optimization loop (15-60s) that collects replica metrics and computes optimal replica counts per variant" "Go"
            scaleFromZeroEngine = container "Scale-From-Zero Engine" "Fast polling loop (100ms) that detects idle models with pending requests and scales from 0 to 1" "Go"
            coordinator = container "Coordinator" "Leader-elected experimental plugin framework for GPU rebalancing across inference pools" "Go"
            metricsCollector = container "Metrics Collector" "Collects per-replica metrics from Prometheus and direct EPP pod scraping with query registration and caching" "Go"
            gpuDiscovery = container "GPU Discovery" "Discovers GPU accelerator capacity and usage from cluster nodes via GPU Operator labels" "Go"
            analyzerPipeline = container "Analyzer Pipeline" "V2 token/capacity, queueing model (M/M/1 + Kalman filter), and throughput analyzers producing VariantCapacity" "Go"
            metricsEndpoint = container "/metrics Endpoint" "Exposes 25+ custom WVA metrics including wva_desired_replicas via HTTPS on port 8443" "HTTPS 8443/TCP"
        }

        prometheus = softwareSystem "Prometheus" "Metrics aggregation and query platform" "External" {
            tags "External"
        }
        hpa = softwareSystem "HPA / KEDA" "Kubernetes Horizontal Pod Autoscaler and KEDA external autoscaler" "External" {
            tags "External"
        }
        k8sapi = softwareSystem "Kubernetes API Server" "Cluster control plane API" "External" {
            tags "External"
        }
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for traffic management and mTLS" "External" {
            tags "External"
        }
        epp = softwareSystem "EPP (Endpoint Picker Proxy)" "Gateway inference extension for request routing and queue management" "Internal RHOAI" {
            tags "Internal"
        }
        inferencePool = softwareSystem "InferencePool" "Gateway API inference extension defining endpoint pools for model servers" "Internal RHOAI" {
            tags "Internal"
        }
        modelServers = softwareSystem "Model Servers (vLLM / SGLang)" "LLM inference model server deployments" "Internal RHOAI" {
            tags "Internal"
        }
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform (manifest sync target)" "Internal RHOAI" {
            tags "Internal"
        }
        gpuOperator = softwareSystem "GPU Operator (NVIDIA/AMD/Intel)" "GPU device plugin and feature discovery" "External" {
            tags "External"
        }
        kalmanFilter = softwareSystem "Kalman Filter (llm-inferno)" "Online parameter learning library for queueing model" "Library" {
            tags "Library"
        }

        # User interactions
        datascientist -> modelServers "Deploys inference models"
        platformengineer -> wva "Configures autoscaling via ConfigMaps and HPA annotations"

        # WVA internal flows
        controllerManager -> saturationEngine "Runs optimization loop"
        controllerManager -> scaleFromZeroEngine "Runs zero-detection loop"
        controllerManager -> coordinator "Runs coordinator loop"
        saturationEngine -> metricsCollector "Requests replica metrics"
        saturationEngine -> analyzerPipeline "Invokes analyzers"
        analyzerPipeline -> metricsEndpoint "Emits wva_desired_replicas"
        scaleFromZeroEngine -> metricsCollector "Requests EPP queue metrics"
        controllerManager -> gpuDiscovery "Requests GPU inventory"

        # External interactions
        metricsCollector -> prometheus "PromQL queries for KV cache, queue, TTFT, ITL metrics" "HTTPS/9090 or 9091"
        metricsCollector -> epp "Direct pod scraping for queue size metrics" "HTTP/configurable"
        controllerManager -> k8sapi "Watch HPAs, ScaledObjects, InferencePools, ConfigMaps, Nodes, Pods" "HTTPS/443 mTLS"
        scaleFromZeroEngine -> k8sapi "Patch Deployment scale 0→1" "HTTPS/443 mTLS"
        coordinator -> k8sapi "Patch HPA maxReplicas, ScaledObject maxReplicaCount" "HTTPS/443 mTLS"
        prometheus -> metricsEndpoint "Scrapes /metrics endpoint" "HTTPS/8443"
        hpa -> prometheus "Reads wva_desired_replicas external metric" "HTTPS"
        hpa -> k8sapi "Patches scale subresource" "HTTPS/443 mTLS"
        modelServers -> prometheus "Exposes KV cache and request metrics" "HTTP/9090"
        gpuDiscovery -> gpuOperator "Reads GPU node labels" "via K8s API"
        analyzerPipeline -> kalmanFilter "Online parameter learning (alpha, beta, gamma)" "In-process"
        wva -> kserve "Manifest sync workflow on push to main" "GitHub Actions"
        inferencePool -> controllerManager "Watched for endpoint pool discovery" "via K8s API"
    }

    views {
        systemContext wva "SystemContext" {
            include *
            autoLayout
        }

        container wva "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Library" {
                background #f5a623
                color #ffffff
            }
        }
    }
}
