workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys and manages LLM inference workloads"
        clusteradmin = person "Cluster Admin" "Configures autoscaling policies and monitors cluster health"

        wva = softwareSystem "Workload Variant Autoscaler (WVA)" "GPU-aware global autoscaler for LLM inference workloads using saturation, throughput, and queueing model analysis" {
            controller = container "Controller Manager" "Reconciles HPAs, ScaledObjects, InferencePools, ConfigMaps; orchestrates scaling engines" "Go Operator (controller-runtime)"
            saturationV1 = container "Saturation Engine V1" "Percentage-based KV cache and queue depth analysis" "Engine Loop"
            saturationV2 = container "Saturation Engine V2" "Token-based capacity modeling with memory (k1) and compute (k2) constraints" "Engine Loop"
            scalefromzero = container "Scale-from-Zero Engine" "Autonomously scales idle variants from 0 to 1 replica" "Engine Loop"
            throughputAnalyzer = container "Throughput Analyzer" "ITL model-based scaling using two-tier OLS fitting" "Analyzer Plugin"
            queueingAnalyzer = container "Queueing Model Analyzer" "SLO-driven scaling using M/M/c queueing theory with Kalman filter" "Analyzer Plugin"
            coordinator = container "Coordinator" "Experimental leader-elected loop for GPU rebalance" "Leader-Elected Loop"
            metricsEndpoint = container "Metrics Endpoint" "Exposes wva_desired_replicas and controller health metrics" "HTTPS :8443"
        }

        prometheus = softwareSystem "Prometheus / Thanos Querier" "Metrics collection, storage, and query engine" "External"
        vllm = softwareSystem "vLLM Model Servers" "LLM inference serving runtime exposing per-pod metrics" "External"
        epp = softwareSystem "EPP / Inference Scheduler" "Endpoint Picker with flow control queue metrics" "External"
        keda = softwareSystem "KEDA" "Kubernetes-based Event Driven Autoscaler" "External"
        k8sapi = softwareSystem "Kubernetes API" "Cluster control plane for resource management" "External"
        hpa = softwareSystem "HorizontalPodAutoscaler" "Native Kubernetes autoscaler reading external metrics" "Kubernetes"
        gatewayapi = softwareSystem "Gateway API Inference Extension" "InferencePool CRD providing pool metadata" "External"
        lws = softwareSystem "LeaderWorkerSet" "Multi-pod workload orchestration for distributed inference" "External"
        promOperator = softwareSystem "Prometheus Operator" "ServiceMonitor-based metrics scraping configuration" "External"

        # Relationships
        datascientist -> hpa "Creates HPA with llm-d.ai/managed=true annotation"
        datascientist -> keda "Creates ScaledObject with llm-d.ai/managed=true annotation"
        clusteradmin -> wva "Configures scaling policies via ConfigMaps"

        controller -> saturationV1 "Runs saturation analysis"
        controller -> saturationV2 "Runs token-capacity analysis"
        controller -> scalefromzero "Runs idle variant detection"
        saturationV1 -> throughputAnalyzer "Uses for ITL-based scaling"
        saturationV1 -> queueingAnalyzer "Uses for SLO-driven scaling"
        controller -> coordinator "Starts leader-elected loop"
        controller -> metricsEndpoint "Emits wva_desired_replicas"

        wva -> prometheus "Queries vLLM and EPP metrics" "HTTPS/9090-9091, Bearer Token"
        vllm -> prometheus "Exposes inference metrics" "HTTP/8080"
        epp -> prometheus "Exposes queue depth metrics"
        prometheus -> metricsEndpoint "Scrapes wva_desired_replicas" "HTTPS/8443, Bearer Token"
        hpa -> k8sapi "Reads external metric wva_desired_replicas" "HTTPS/443"
        keda -> k8sapi "Reads external metric wva_desired_replicas" "HTTPS/443"
        hpa -> k8sapi "Scales Deployments via scale subresource" "HTTPS/443"
        wva -> k8sapi "Watch/patch CRDs, Deployments, HPAs, ConfigMaps" "HTTPS/443"
        wva -> k8sapi "Patch scale subresource (scale-from-zero)" "HTTPS/443"
        wva -> gatewayapi "Watches InferencePool CRDs"
        wva -> lws "Patches LeaderWorkerSet scale subresource" "HTTPS/443"
        promOperator -> wva "Configures metrics scraping via ServiceMonitor"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Kubernetes" {
                background #326ce5
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #5b9bd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
