workspace {
    model {
        user = person "SRE / Support Engineer" "Collects diagnostic data from RHOAI clusters for troubleshooting"

        mustGather = softwareSystem "must-gather" "Diagnostic data collection tool for RHOAI/RHAII platforms; collects cluster state, logs, and CR snapshots" {
            gatherOrchestrator = container "gather.sh" "Main orchestrator — detects K8s distro, sets namespaces, dispatches per-component scripts in parallel" "Bash Script"
            commonLib = container "common.sh" "Shared functions: run_mustgather, get_all_namespace, collect_helm_releases, rhoai_version" "Bash Library"
            xksUtilLib = container "xks_util.sh" "Kubernetes-native inspection: kubectl_inspect, detect_k8s_distro, auto_discover_resources" "Bash Library"
            componentScripts = container "Per-Component Gather Scripts" "15 scripts: KServe, DSP, Dashboard, KubeRay, Kueue, Training, ModelRegistry, TrustyAI, Feast, Llama-stack, MLflow, Spark, AIGateway, MCP, Notebooks" "Bash Scripts"
            llmdScripts = container "LLM-D Gather Scripts" "LLM-D inference collection + dependency operators (cert-manager, Sail/Istio, LeaderWorkerSet)" "Bash Scripts"
        }

        kubeApiServer = softwareSystem "Kubernetes API Server" "Cluster control plane — provides REST API for all resource operations" "External"
        rhoaiOperator = softwareSystem "RHOAI Operator (rhods-operator)" "Manages RHOAI platform lifecycle — DSCInitialization, DataScienceCluster CRs" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving infrastructure — InferenceService, ServingRuntime CRDs" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "Pipeline orchestration — DataSciencePipelinesApplication, Workflow CRDs" "Internal RHOAI"
        dashboard = softwareSystem "Dashboard" "RHOAI web console — OdhDashboardConfig, AcceleratorProfile CRDs" "Internal RHOAI"
        kuberay = softwareSystem "KubeRay" "Ray cluster management — RayCluster, RayJob, RayService CRDs" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queueing — ClusterQueue, LocalQueue, Workload CRDs" "Internal RHOAI"
        trainingOp = softwareSystem "Training Operator" "Distributed training — PyTorchJob, TrainJob CRDs" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model metadata storage — ModelRegistry CRD" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI trustworthiness — TrustyAIService, LMEvalJob CRDs" "Internal RHOAI"
        gatewayAPI = softwareSystem "Gateway API" "Ingress infrastructure — Gateway, HTTPRoute, GRPCRoute CRDs" "External"
        istio = softwareSystem "Istio / Sail Operator" "Service mesh — Istio, VirtualService, AuthorizationPolicy CRDs" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management — Certificate, Issuer CRDs" "External"
        lws = softwareSystem "LeaderWorkerSet" "Distributed inference topology — LeaderWorkerSet CRD" "External"
        helm = softwareSystem "Helm" "Release management — helm get values/manifest for chart introspection" "External"

        user -> mustGather "Runs via oc adm must-gather (OCP) or kubectl apply Job (xKS)"
        mustGather -> kubeApiServer "GET/LIST all RHOAI CRDs and namespace resources" "HTTPS/443, SA Bearer Token, TLS 1.2+"
        mustGather -> rhoaiOperator "Reads DSCInitialization, DataScienceCluster CRs" "via kube-apiserver"
        mustGather -> kserve "Reads InferenceService, ServingRuntime CRs" "via kube-apiserver"
        mustGather -> dsp "Reads DataSciencePipelinesApplication, Workflow CRs" "via kube-apiserver"
        mustGather -> dashboard "Reads OdhDashboardConfig, AcceleratorProfile CRs" "via kube-apiserver"
        mustGather -> kuberay "Reads RayCluster, RayJob, RayService CRs" "via kube-apiserver"
        mustGather -> kueue "Reads ClusterQueue, LocalQueue, Workload CRs" "via kube-apiserver"
        mustGather -> trainingOp "Reads PyTorchJob, TrainJob CRs" "via kube-apiserver"
        mustGather -> modelRegistry "Reads ModelRegistry CRs" "via kube-apiserver"
        mustGather -> trustyai "Reads TrustyAIService, LMEvalJob CRs" "via kube-apiserver"
        mustGather -> gatewayAPI "Reads Gateway, HTTPRoute, GRPCRoute CRs" "via kube-apiserver"
        mustGather -> istio "Reads Istio, VirtualService, AuthorizationPolicy CRs" "via kube-apiserver"
        mustGather -> certManager "Reads Certificate, Issuer CRs" "via kube-apiserver"
        mustGather -> lws "Reads LeaderWorkerSet CRs" "via kube-apiserver"
        mustGather -> helm "Reads Helm release values and manifests" "via kube-apiserver (Helm secrets)"
        mustGather -> user "Returns diagnostic tarball" "oc rsync (OCP) / kubectl cp (xKS)"

        gatherOrchestrator -> commonLib "Uses shared functions"
        gatherOrchestrator -> xksUtilLib "Uses on non-OpenShift"
        gatherOrchestrator -> componentScripts "Dispatches in parallel"
        gatherOrchestrator -> llmdScripts "Dispatches for LLM-D"
        componentScripts -> commonLib "Delegates to run_mustgather"
        llmdScripts -> xksUtilLib "Delegates to kubectl_inspect"
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
                background #4a90e2
                color #ffffff
                shape Person
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
