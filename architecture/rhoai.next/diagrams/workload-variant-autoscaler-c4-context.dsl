workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Deploys and manages LLM inference workloads with autoscaling annotations"
        sre = person "SRE / Platform Admin" "Configures WVA thresholds, monitors scaling behavior"

        wva = softwareSystem "Workload Variant Autoscaler (WVA)" "Kubernetes controller that performs intelligent autoscaling for LLM inference model servers based on GPU saturation, queueing theory, and throughput analysis" {
            controllerManager = container "WVA Controller Manager" "Main controller binary managing HPA/ScaledObject discovery, ConfigMap reconciliation, InferencePool sync, and optimization engines" "Go (controller-runtime)"
            saturationV1 = container "Saturation Engine V1" "Percentage-based KV cache and queue saturation analysis" "Go"
            saturationV2 = container "Saturation Engine V2" "Token-capacity-aware saturation analysis with per-replica capacity tracking" "Go"
            queueingEngine = container "Queueing Model Engine" "M/M/1/K queueing theory analysis using arrival rate, TTFT, and ITL" "Go"
            scaleFromZero = container "Scale-from-Zero Engine" "Handles scaling model servers from zero replicas" "Go"
            metricsCollector = container "Metrics Collector" "Aggregates metrics from Prometheus and direct pod scraping with LRU caching" "Go"
            coordinator = container "Coordinator (Experimental)" "Cluster-wide coordination for ScaledObject/HPA management with GPU rebalance plugin" "Go"
        }

        prometheus = softwareSystem "Prometheus / Thanos Querier" "Metrics aggregation and query engine" "External"
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaler for Kubernetes" "External"
        lws = softwareSystem "LeaderWorkerSet (LWS)" "Multi-pod model serving orchestration" "External"
        gaie = softwareSystem "Gateway API Inference Extension" "InferencePool CRD for endpoint discovery" "External"
        promOperator = softwareSystem "Prometheus Operator" "ServiceMonitor and PrometheusRule CRD support" "External"

        inferenceServing = softwareSystem "Inference Serving (vLLM / SGLang)" "LLM model serving pods exposing KV cache, queue, and token metrics" "Internal"
        epp = softwareSystem "EPP (Endpoint Picker)" "Gateway API inference extension scheduler" "Internal"
        kserve = softwareSystem "KServe (RHOAI)" "Model serving platform - receives WVA manifests via CI sync" "Internal"
        dashboard = softwareSystem "ODH Dashboard" "User-facing platform management UI" "Internal"

        # Relationships
        dataScientist -> wva "Creates HPAs/ScaledObjects with llm-d.ai/managed annotation"
        sre -> wva "Configures saturation thresholds via ConfigMaps"

        controllerManager -> saturationV1 "Runs saturation analysis"
        controllerManager -> saturationV2 "Runs token-capacity analysis"
        controllerManager -> queueingEngine "Runs queueing model analysis"
        controllerManager -> scaleFromZero "Runs scale-from-zero checks"
        controllerManager -> metricsCollector "Fetches collected metrics"

        metricsCollector -> prometheus "PromQL queries for KV cache, queue, token metrics" "HTTPS/9090-9091"
        metricsCollector -> inferenceServing "Direct pod /metrics scraping" "HTTP(S)"
        metricsCollector -> epp "Scheduler dispatch rate metrics" "Prometheus"

        controllerManager -> k8sApi "Watch HPAs, ScaledObjects, ConfigMaps, InferencePools, Deployments, Nodes" "HTTPS/443"
        controllerManager -> k8sApi "Patch scale subresource (scale-from-zero)" "HTTPS/443"

        prometheus -> wva "Scrapes /metrics endpoint for wva_desired_replicas" "HTTPS/8443"
        keda -> prometheus "Queries wva_desired_replicas" "HTTPS"
        keda -> k8sApi "Updates scale subresource" "HTTPS/443"

        wva -> gaie "Watches InferencePool CRD for endpoint discovery"
        wva -> lws "Watches/scales LeaderWorkerSet resources"
        wva -> kserve "CI: sync manifests to prefetched-manifests-rhoai/wva/"
        wva -> promOperator "Defines ServiceMonitor and PrometheusRule resources"
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
            element "Internal" {
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
        }
    }
}
