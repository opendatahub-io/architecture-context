workspace {
    model {
        sre = person "SRE / Platform Engineer" "Configures autoscaling strategies and monitors scaling behavior"
        mlEngineer = person "ML Engineer" "Deploys inference workloads that autoscaling targets"

        autoscaling = softwareSystem "llm-d-autoscaling" "KEDA autoscaling blueprints and evaluation test bed for llm-d inference, plus deprecated WVA controller" {
            blueprints = container "KEDA Scenario Blueprints" "Recommended ScaledObject configurations for prefill/decode disaggregation" "YAML Configuration"
            benchmarkBed = container "Benchmark Test Bed" "Evaluation harness that stands up scenarios, drives load, captures autoscaling behavior" "Python/Shell"
            wvaController = container "WVA Controller (legacy)" "Deprecated GPU-aware autoscaling controller with saturation engine and scale-from-zero" "Go / controller-runtime" "Deprecated"
            saturationEngine = container "Saturation Engine (legacy)" "Queries Prometheus metrics, runs analyzer pipeline, computes desired replicas" "Go" "Deprecated"
            coordinator = container "Coordinator (legacy)" "Cluster-wide GPU rebalance plugin with ResourceQuota-based caps" "Go" "Deprecated"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and query engine" "External"
        thanosQuerier = softwareSystem "Thanos Querier" "Federated metrics query layer on OpenShift" "External"
        kubernetes = softwareSystem "Kubernetes API" "Cluster resource management" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaler for Kubernetes" "Internal Platform"
        gatewayAPIInference = softwareSystem "Gateway API Inference Extension" "InferencePool CRD for pool-based inference routing" "Internal Platform"
        lws = softwareSystem "LeaderWorkerSet" "Multi-worker group orchestration" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "ServiceMonitor CRD for metrics scrape configuration" "Internal Platform"
        llmDBenchmark = softwareSystem "llm-d-benchmark" "Benchmark harness for autoscaling strategy evaluation" "External"

        # Relationships - Active (KEDA-based)
        sre -> blueprints "Selects and configures autoscaling strategies"
        blueprints -> keda "Configures ScaledObjects with Prometheus triggers"
        keda -> prometheus "Queries vLLM metrics (KV-cache, queue depth)" "HTTPS/9090"
        keda -> kubernetes "Drives HPA scaling decisions" "HTTPS/6443"
        benchmarkBed -> llmDBenchmark "Drives inference load for evaluation"
        benchmarkBed -> blueprints "Evaluates autoscaling strategies"

        # Relationships - Legacy (WVA)
        saturationEngine -> prometheus "Queries vLLM metrics for scaling decisions" "HTTPS/9090 TLS 1.2+"
        saturationEngine -> kubernetes "Patches Deployment/LWS scale" "HTTPS/6443"
        wvaController -> gatewayAPIInference "Watches InferencePool CRs" "Kubernetes API"
        wvaController -> keda "Discovers ScaledObjects (conditional)" "Kubernetes API"
        wvaController -> lws "Scales LeaderWorkerSets (conditional)" "Kubernetes API"
        coordinator -> kubernetes "GPU rebalance via ResourceQuota" "HTTPS/6443"
        prometheus -> wvaController "Scrapes /metrics endpoint" "HTTPS/8443"
        prometheusOperator -> wvaController "Configures metrics scraping via ServiceMonitor"

        mlEngineer -> kubernetes "Deploys inference workloads"
    }

    views {
        systemContext autoscaling "SystemContext" {
            include *
            autoLayout
        }

        container autoscaling "Containers" {
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
            element "Deprecated" {
                background #cccccc
                color #666666
                border dashed
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
