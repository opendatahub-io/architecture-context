workspace {
    model {
        clusterAdmin = person "Cluster Administrator" "Runs diagnostic data collection for RHOAI/RHAII troubleshooting"

        mustGather = softwareSystem "must-gather" "Diagnostic data collection tool that gathers logs, resource definitions, and cluster state from RHOAI and RHAII deployments" {
            gatherSh = container "gather.sh" "Main orchestrator that detects K8s distribution, dispatches to per-component collection scripts, manages parallel execution" "Bash Script"
            commonSh = container "common.sh" "Shared functions: run_mustgather, get_all_namespace, rhoai_version, collect_helm_releases" "Bash Library"
            xksUtil = container "xks_util.sh" "xKS platform support: detect_k8s_distro, kubectl_inspect, auto_discover_resources" "Bash Library"
            componentCollectors = container "Component Collectors" "14 per-component gather scripts running in parallel (KServe, DSP, KubeRay, Kueue, KFTO, etc.)" "Bash Scripts"
            llmdCollectors = container "LLM-D Collectors" "LLM-D specific collection with dependency scripts for cert-manager, Sail/Istio, LeaderWorkerSet" "Bash Scripts"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane providing resource and log access" "Infrastructure"
        helm = softwareSystem "Helm" "Captures Helm release configuration and rendered manifests" "Tool"

        rhoaiOperator = softwareSystem "RHOAI Operator" "Manages RHOAI platform components via DSCInitialization and DataScienceCluster CRs" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal RHOAI"
        kuberay = softwareSystem "KubeRay" "Ray cluster management" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queueing system" "Internal RHOAI"
        kfto = softwareSystem "Training Operator" "Distributed training job management" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata storage" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI trustworthiness and evaluation" "Internal RHOAI"
        dashboard = softwareSystem "Dashboard" "RHOAI web interface" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management" "External"
        istio = softwareSystem "Istio / Sail" "Service mesh for traffic and security" "External"
        gatewayApi = softwareSystem "Gateway API" "Kubernetes ingress and routing" "External"

        clusterAdmin -> mustGather "Runs diagnostic collection via oc adm must-gather or Kubernetes Job"
        mustGather -> k8sApi "Queries resources and logs (GET, LIST, WATCH)" "HTTPS/443 TLS DEFAULT:PQ"
        mustGather -> helm "Captures release values and manifests" "CLI"
        mustGather -> rhoaiOperator "Collects DSCInitialization, DataScienceCluster CRs" "Read-only CRD query"
        mustGather -> kserve "Collects InferenceServices, ServingRuntimes" "Read-only CRD query"
        mustGather -> dsp "Collects DSPApplications, Argo Workflows" "Read-only CRD query"
        mustGather -> kuberay "Collects RayClusters, RayJobs, RayServices" "Read-only CRD query"
        mustGather -> kueue "Collects ClusterQueues, Workloads" "Read-only CRD query"
        mustGather -> kfto "Collects PyTorchJobs, TrainJobs" "Read-only CRD query"
        mustGather -> modelRegistry "Collects ModelRegistries" "Read-only CRD query"
        mustGather -> trustyai "Collects LMEvalJobs, TrustyAIServices" "Read-only CRD query"
        mustGather -> dashboard "Collects ODHDashboardConfigs, Profiles" "Read-only CRD query"
        mustGather -> certManager "Collects Issuers, Certificates" "Read-only CRD query"
        mustGather -> istio "Collects VirtualServices, AuthorizationPolicies" "Read-only CRD query"
        mustGather -> gatewayApi "Collects Gateways, HTTPRoutes" "Read-only CRD query"
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
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "Tool" {
                background #b8b8b8
                color #ffffff
            }
        }
    }
}
