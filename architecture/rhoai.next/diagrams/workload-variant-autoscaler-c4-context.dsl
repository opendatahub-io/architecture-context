workspace {
    model {
        admin = person "Platform Admin" "Configures autoscaling parameters via ConfigMaps and manages scaling policies"
        datascientist = person "Data Scientist" "Deploys ML models with HPA/KEDA annotations for autoscaling"

        wva = softwareSystem "Workload Variant Autoscaler (WVA)" "Global autoscaler for LLM inference model servers using saturation, queueing theory, and cost optimization across GPU variant configurations" {
            controllerManager = container "controller-manager" "Reconciles VAs, HPAs, ScaledObjects, ConfigMaps, InferencePools; runs saturation and scale-from-zero engines; emits scaling metrics" "Go Operator (controller-runtime)"
            saturationEngine = container "Saturation Engine" "Runs V1 (% KV cache), V2 (absolute tokens), or Queueing Model (M/M/c) analysis to determine desired replicas" "Go"
            scaleFromZeroEngine = container "Scale-from-Zero Engine" "Detects queued requests via EPP metrics and directly scales zero-replica deployments" "Go"
            datastore = container "In-Memory Datastore" "Stores variant configurations, namespace tracking, replica metrics, and decision cache" "Go"
            configSystem = container "Configuration System" "Three-tier resolution: namespace-local > global > system defaults via ConfigMap reconciler" "Go"
            metricsEndpoint = container "Metrics Endpoint" "Exposes 25+ custom Prometheus metrics for scaling decisions, saturation, capacity, and health" "HTTPS/8443"
        }

        prometheus = softwareSystem "Prometheus / Thanos Querier" "Metrics collection and querying platform; source of vLLM metrics and target for WVA metrics" "External"
        k8sapi = softwareSystem "Kubernetes API Server" "Kubernetes control plane for resource management and watch events" "External"
        hpa = softwareSystem "HPA (autoscaling/v2)" "Standard Kubernetes horizontal pod autoscaler consuming WVA external metrics" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaler consuming WVA metrics via ScaledObject" "External"
        vllm = softwareSystem "vLLM Model Servers" "LLM inference servers exposing KV cache, queue, and throughput metrics" "External"
        epp = softwareSystem "EPP (Endpoint Picker Proxy)" "Gateway API Inference Extension exposing flow control queue size for scale-from-zero" "Internal Platform"
        inferencePool = softwareSystem "InferencePool" "Gateway API Inference Extension CRD defining model endpoint pools" "Internal Platform"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Optional alternative scale target for distributed inference workloads" "External"
        certManager = softwareSystem "cert-manager" "Optional TLS certificate management for metrics and webhook endpoints" "External"
        kalmanFilter = softwareSystem "llm-d Kalman Filter" "Kalman filter library for SLO parameter tuning in queueing model analyzer" "External"

        # User interactions
        admin -> wva "Configures scaling parameters via ConfigMaps" "kubectl / HTTPS"
        datascientist -> hpa "Creates HPAs with llm-d.ai/managed=true annotation" "kubectl / HTTPS"
        datascientist -> keda "Creates ScaledObjects with llm-d.ai/managed=true annotation" "kubectl / HTTPS"

        # WVA internal flows
        controllerManager -> saturationEngine "Triggers optimization cycle" ""
        controllerManager -> scaleFromZeroEngine "Runs scale-from-zero check" ""
        controllerManager -> datastore "Reads/writes variant state" ""
        controllerManager -> configSystem "Reads configuration" ""
        saturationEngine -> datastore "Reads replica metrics" ""
        scaleFromZeroEngine -> datastore "Reads/writes decision cache" ""
        configSystem -> datastore "Updates configuration state" ""

        # WVA external interactions
        wva -> prometheus "Queries vLLM metrics (KV cache, queue, tokens)" "HTTPS/9090-9091, Bearer Token"
        wva -> k8sapi "Watches CRDs, ConfigMaps, HPAs, Deployments, Nodes" "HTTPS/6443, SA Token"
        wva -> epp "Scrapes queue_size for scale-from-zero" "HTTPS, Bearer Token"
        wva -> k8sapi "Updates scale subresource (scale-from-zero only)" "HTTPS/6443, SA Token"

        # Metrics flow
        prometheus -> metricsEndpoint "Scrapes WVA metrics" "HTTPS/8443, Bearer Token"
        vllm -> prometheus "Exposes inference metrics" "HTTP"
        hpa -> prometheus "Reads wva_desired_replicas external metric" "HTTPS/9090"
        keda -> prometheus "Reads wva_desired_replicas external metric" "HTTPS/9090"
        hpa -> k8sapi "Updates scale subresource" "HTTPS/6443"
        keda -> k8sapi "Updates scale subresource" "HTTPS/6443"

        # Optional dependencies
        wva -> certManager "TLS certificate management" "Optional"
        saturationEngine -> kalmanFilter "SLO parameter tuning" "In-process library"
        wva -> inferencePool "Discovers model endpoint pools" "CRD Watch"
        wva -> leaderWorkerSet "Alternative scale target" "CRD Watch + Scale, Optional"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
