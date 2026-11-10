workspace "llm-d-autoscaling" "KEDA autoscaling blueprints, evaluation test bed and deprecated WVA controller (RHOAI 3.7-ea.1)" {
    model {
        platformEngineer = person "Platform Engineer" "Applies KEDA ScaledObject blueprints and evaluates them"
        workloadOwner = person "Workload Owner" "Annotates HPAs/ScaledObjects with llm-d.ai/managed to opt into WVA (legacy)"

        autoscaling = softwareSystem "llm-d-autoscaling" "KEDA autoscaling blueprints and evaluation test bed for llm-d; carries the deprecated WVA controller in legacy/" {
            blueprints = container "KEDA blueprints" "Reviewed per-guide prefill/decode ScaledObject manifests (scenarios/guides/)" "YAML"
            staging = container "Staging scenarios" "Experimental trigger/threshold variants (scenarios/staging/)" "YAML / Jinja2"
            benchmark = container "Benchmark test bed" "llm-d-benchmark specs, cluster configs, Grafana dashboards" "YAML / Bash"
            kindEmulator = container "Kind GPU emulator" "Multi-node Kind cluster with emulated GPU labels" "Bash"
            wva = container "WVA controller-manager (legacy)" "Annotation-driven saturation-aware autoscaler; emits wva_desired_replicas; scale-from-zero via scale subresource. DEPRECATED, frozen." "Go controller-runtime" "Legacy"
        }

        keda = softwareSystem "KEDA" "Autoscaling engine; manages HPAs from ScaledObjects" "External"
        prometheus = softwareSystem "Prometheus / Thanos Querier" "Metric source for triggers and WVA; sink for wva_* metrics" "External"
        promAdapter = softwareSystem "prometheus-adapter" "Exposes wva_desired_replicas as external metric for plain HPAs" "External"
        llmdBenchmark = softwareSystem "llm-d-benchmark" "Load generation and evaluation harness" "External"
        k8sApi = softwareSystem "Kubernetes API" "Watches, scale subresource, leases, discovery" "External"

        gie = softwareSystem "gateway-api-inference-extension" "InferencePool and Endpoint Picker (EPP)" "Internal RHOAI"
        modelServers = softwareSystem "llm-d model servers" "vLLM Deployments / LeaderWorkerSets being scaled" "Internal RHOAI"
        ocpMonitoring = softwareSystem "OpenShift monitoring + service-ca" "Thanos Querier, UWM Prometheus, serving certs" "Internal RHOAI"
        gpuOperator = softwareSystem "NVIDIA GPU operator" "GPU node labels for inventory limiter" "External"

        platformEngineer -> blueprints "Applies ScaledObjects"
        platformEngineer -> benchmark "Runs evaluations"
        workloadOwner -> k8sApi "Annotates HPA / ScaledObject (llm-d.ai/managed)"
        benchmark -> blueprints "Evaluates"
        benchmark -> staging "Evaluates"
        benchmark -> llmdBenchmark "Uses as harness"
        kindEmulator -> benchmark "Hosts local runs"
        blueprints -> keda "Reconciled by"
        staging -> keda "Reconciled by"

        keda -> prometheus "Queries trigger metrics" "HTTPS/9090-9091, Bearer"
        keda -> modelServers "Scales via managed HPA" "Kubernetes API"

        wva -> k8sApi "Watches HPA/ScaledObject/InferencePool/ConfigMap; writes scale subresource" "HTTPS/6443, SA token"
        wva -> prometheus "Queries vLLM/EPP metrics" "HTTPS/9090 or 9091, Bearer SA token"
        wva -> gie "Watches InferencePool; scrapes EPP /metrics" "HTTP (plaintext), Bearer epp-metrics-reader"
        wva -> modelServers "Scale from zero (deployments/scale, leaderworkersets/scale)" "HTTPS/6443"
        wva -> keda "Patches ScaledObject maxReplicas (experimental Coordinator)" "Kubernetes API"
        wva -> ocpMonitoring "Thanos queries, service-ca certs" "HTTPS/9091"
        wva -> gpuOperator "Reads GPU node labels" "Kubernetes API"
        prometheus -> wva "Scrapes wva_desired_replicas" "HTTPS/8443, TokenReview + SAR"
        keda -> wva "Consumes wva_desired_replicas via Prometheus" "PromQL"
        promAdapter -> prometheus "Reads wva_desired_replicas" "HTTPS"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Legacy" {
                background #b0b0b0
                color #000000
                border dashed
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
        }
    }
}
