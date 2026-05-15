workspace {
    model {
        user = person "SRE / Support Engineer" "Collects diagnostic data from RHOAI/RHAII clusters for troubleshooting"

        mustGather = softwareSystem "must-gather" "Diagnostic data collection tool for RHOAI/RHAII — collects cluster state, logs, and custom resources" {
            gatherSH = container "gather.sh" "Main entrypoint — detects K8s distribution, dispatches component collectors" "Bash Script"
            commonSH = container "common.sh" "Shared functions for namespace inspection, resource collection, version detection" "Bash Library"
            xksUtilSH = container "xks_util.sh" "Non-OpenShift utilities — kubectl_inspect, distribution detection" "Bash Library"
            componentCollectors = container "Component Collectors" "14 parallel scripts collecting RHOAI component CRDs" "Bash Scripts"
            llmdCollectors = container "LLM-D Collectors" "LLM-D specific collection — inference, dependencies, observability, cluster info" "Bash Scripts"
            helmIntegration = container "Helm Integration" "Collects Helm release values and rendered manifests" "helm CLI"
        }

        kubeAPI = softwareSystem "Kubernetes API Server" "Cluster control plane — source of all resource and log data" "External"
        ocInspect = softwareSystem "oc adm inspect" "OpenShift resource inspection framework" "External"
        kubectlCLI = softwareSystem "kubectl" "Kubernetes CLI for non-OpenShift platforms" "External"
        helmCLI = softwareSystem "Helm CLI" "Kubernetes package manager — reads release values" "External"

        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator managing DSCInitialization, DataScienceCluster" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving — InferenceService, ServingRuntime CRDs" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "Pipeline orchestration — DSP Application, Argo Workflow CRDs" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "UI configuration — DashboardConfig, AcceleratorProfile CRDs" "Internal RHOAI"
        kuberay = softwareSystem "KubeRay" "Ray cluster management — RayCluster, RayJob CRDs" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Batch scheduling — ClusterQueue, LocalQueue, Workload CRDs" "Internal RHOAI"
        kfto = softwareSystem "Kubeflow Training Operator" "Distributed training — PyTorchJob, TrainJob CRDs" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model metadata storage — ModelRegistry CRDs" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI trustworthiness — TrustyAIService, LMEvalJob, EvalHub CRDs" "Internal RHOAI"
        maas = softwareSystem "Models as a Service" "Multi-tenant model serving — MaaSModelRef, Tenant CRDs" "Internal RHOAI"
        llmd = softwareSystem "LLM-D" "LLM inference — LLMInferenceService, InferencePool CRDs" "Internal RHOAI"

        istio = softwareSystem "Istio / Sail" "Service mesh — VirtualService, DestinationRule, EnvoyFilter CRDs" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management — Certificate, Issuer CRDs" "External"
        gatewayAPI = softwareSystem "Gateway API" "Gateway, HTTPRoute, GRPCRoute CRDs" "External"
        prometheus = softwareSystem "Prometheus Operator" "Monitoring — ServiceMonitor, PodMonitor, PrometheusRule CRDs" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling — ScaledObject, TriggerAuthentication CRDs" "External"
        lws = softwareSystem "LeaderWorkerSet" "Distributed workload orchestration CRDs" "External"

        # User interactions
        user -> mustGather "Invokes via oc adm must-gather or kubectl Job"

        # must-gather to K8s API
        mustGather -> kubeAPI "GET, LIST, WATCH all resources" "HTTPS/443, TLS 1.2+, SA token"
        mustGather -> ocInspect "Namespace/resource inspection" "CLI (OpenShift only)"
        mustGather -> kubectlCLI "Resource collection" "CLI (xKS only)"
        mustGather -> helmCLI "Extract Helm release values" "Local exec"

        # must-gather reads from RHOAI components (via K8s API)
        mustGather -> rhoaiOperator "Reads DSCInitialization, DataScienceCluster CRs" "HTTPS/443"
        mustGather -> kserve "Reads InferenceService, ServingRuntime CRs" "HTTPS/443"
        mustGather -> dsp "Reads DSP Application, Argo Workflow CRs" "HTTPS/443"
        mustGather -> dashboard "Reads DashboardConfig, AcceleratorProfile CRs" "HTTPS/443"
        mustGather -> kuberay "Reads RayCluster, RayJob, RayService CRs" "HTTPS/443"
        mustGather -> kueue "Reads ClusterQueue, LocalQueue, Workload CRs" "HTTPS/443"
        mustGather -> kfto "Reads PyTorchJob, TrainJob CRs" "HTTPS/443"
        mustGather -> modelRegistry "Reads ModelRegistry CRs" "HTTPS/443"
        mustGather -> trustyai "Reads TrustyAIService, LMEvalJob, EvalHub CRs" "HTTPS/443"
        mustGather -> maas "Reads MaaSModelRef, MaaSAuthPolicy, Tenant CRs" "HTTPS/443"
        mustGather -> llmd "Reads LLMInferenceService, InferencePool CRs" "HTTPS/443"

        # must-gather reads from external dependencies (via K8s API)
        mustGather -> istio "Reads VirtualService, DestinationRule, EnvoyFilter CRs" "HTTPS/443"
        mustGather -> certManager "Reads Certificate, Issuer, ClusterIssuer CRs" "HTTPS/443"
        mustGather -> gatewayAPI "Reads Gateway, HTTPRoute, GRPCRoute CRs" "HTTPS/443"
        mustGather -> prometheus "Reads ServiceMonitor, PodMonitor, PrometheusRule CRs" "HTTPS/443"
        mustGather -> keda "Reads ScaledObject, TriggerAuthentication CRs (WVA)" "HTTPS/443"
        mustGather -> lws "Reads LeaderWorkerSet CRs" "HTTPS/443"

        # Internal container relationships
        gatherSH -> commonSH "sources shared functions"
        gatherSH -> xksUtilSH "sources on non-OpenShift"
        gatherSH -> componentCollectors "dispatches in parallel"
        gatherSH -> llmdCollectors "dispatches"
        gatherSH -> helmIntegration "invokes for Helm data"
    }

    views {
        systemContext mustGather "SystemContext" {
            include *
            autoLayout
        }

        container mustGather "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
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
