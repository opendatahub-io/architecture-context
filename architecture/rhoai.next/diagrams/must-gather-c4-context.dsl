workspace {
    model {
        user = person "SRE / Support Engineer" "Collects diagnostic data from RHOAI/RHAII clusters for troubleshooting"

        mustGather = softwareSystem "Must-Gather" "Collects comprehensive diagnostic data from RHOAI/RHAII deployments for troubleshooting and support" {
            gatherScript = container "gather.sh" "Main orchestrator — detects K8s distribution, dispatches collection scripts" "Bash Script"
            commonLib = container "common.sh" "Shared utility functions: run_mustgather, get_all_namespace, collect_helm_releases" "Bash Library"
            xksUtil = container "xks_util.sh" "Cross-platform abstraction: detect_k8s_distro, kubectl_inspect, auto_discover_resources" "Bash Library"
            ocpCollectors = container "OpenShift Collectors" "13 component-specific collection scripts running in parallel" "Bash Scripts"
            xksCollectors = container "xKS Collectors" "gather_llmd.sh + dependency scripts (cert-manager, sail, lws)" "Bash Scripts"
            helmCli = container "Helm CLI" "Collects Helm release values and manifests" "helm v4.1.4"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API endpoint for all resource operations" "External"
        ocpFramework = softwareSystem "OpenShift Must-Gather Framework" "Manages pod lifecycle, data retrieval, and tarball creation for oc adm must-gather" "External"

        # RHOAI Platform Components (read targets)
        rhodsOperator = softwareSystem "RHODS Operator" "Platform operator managing DSCInitialization, DataScienceCluster CRs" "RHOAI Component"
        kserve = softwareSystem "KServe / LLM-D" "Model serving: InferenceService, ServingRuntime, LLMInferenceService CRs" "RHOAI Component"
        dsp = softwareSystem "Data Science Pipelines" "Pipeline orchestration: DSPA, Argo Workflow CRs" "RHOAI Component"
        dashboard = softwareSystem "Dashboard" "Web UI: OdhDashboardConfig, AcceleratorProfile, HardwareProfile CRs" "RHOAI Component"
        kuberay = softwareSystem "KubeRay" "Distributed compute: RayCluster, RayJob, RayService CRs" "RHOAI Component"
        kueue = softwareSystem "Kueue" "Job scheduling: ClusterQueue, LocalQueue, Workload CRs" "RHOAI Component"
        trainingOp = softwareSystem "Training Operator" "ML training: PyTorchJob, TrainJob, TrainingRuntime CRs" "RHOAI Component"
        modelRegistry = softwareSystem "Model Registry" "Model metadata: ModelRegistry CRs" "RHOAI Component"
        trustyai = softwareSystem "TrustyAI" "AI trust: TrustyAIService, LMEvalJob, GuardrailsOrchestrator CRs" "RHOAI Component"

        # Infrastructure Components (read targets)
        istio = softwareSystem "Istio / Sail Operator" "Service mesh: Istio, VirtualService, AuthorizationPolicy CRs" "Infrastructure"
        gatewayApi = softwareSystem "Gateway API" "Ingress: Gateway, HTTPRoute, GRPCRoute, GatewayClass CRs" "Infrastructure"
        certManager = softwareSystem "cert-manager" "Certificate management: Issuer, ClusterIssuer, Certificate CRs" "Infrastructure"
        prometheus = softwareSystem "Prometheus Operator" "Monitoring: ServiceMonitor, PodMonitor, PrometheusRule CRs" "Infrastructure"
        lws = softwareSystem "LeaderWorkerSet" "Workload management: LeaderWorkerSet CRs" "Infrastructure"

        # User interactions
        user -> mustGather "Invokes via oc adm must-gather (OpenShift) or kubectl apply job.yaml (xKS)"
        mustGather -> user "Returns tarball of collected diagnostic data"

        # Must-gather internal relationships
        gatherScript -> commonLib "Sources shared functions"
        gatherScript -> xksUtil "Sources platform detection"
        gatherScript -> ocpCollectors "Dispatches on OpenShift (parallel)"
        gatherScript -> xksCollectors "Dispatches on xKS"
        gatherScript -> helmCli "Collects Helm releases"

        # External interactions
        mustGather -> k8sApi "All resource collection: GET, LIST (read-only)" "HTTPS/443, TLS 1.2+, ServiceAccount Token"
        ocpFramework -> mustGather "Manages pod lifecycle and data retrieval"

        # Read targets (all via k8sApi)
        mustGather -> rhodsOperator "Reads DSCInitialization, DataScienceCluster, Auth, Monitoring CRs" "HTTPS/443"
        mustGather -> kserve "Reads InferenceService, ServingRuntime, LLMInferenceService, InferencePool CRs" "HTTPS/443"
        mustGather -> dsp "Reads DSPA, Argo Workflow CRs" "HTTPS/443"
        mustGather -> dashboard "Reads OdhDashboardConfig, AcceleratorProfile CRs" "HTTPS/443"
        mustGather -> kuberay "Reads RayCluster, RayJob, RayService CRs" "HTTPS/443"
        mustGather -> kueue "Reads ClusterQueue, LocalQueue, Workload CRs" "HTTPS/443"
        mustGather -> trainingOp "Reads PyTorchJob, TrainJob, TrainingRuntime CRs" "HTTPS/443"
        mustGather -> modelRegistry "Reads ModelRegistry CRs" "HTTPS/443"
        mustGather -> trustyai "Reads TrustyAIService, LMEvalJob CRs" "HTTPS/443"
        mustGather -> istio "Reads Istio, VirtualService, AuthorizationPolicy CRs" "HTTPS/443"
        mustGather -> gatewayApi "Reads Gateway, HTTPRoute, GRPCRoute CRs" "HTTPS/443"
        mustGather -> certManager "Reads Issuer, ClusterIssuer, Certificate CRs" "HTTPS/443"
        mustGather -> prometheus "Reads ServiceMonitor, PodMonitor, PrometheusRule CRs" "HTTPS/443"
        mustGather -> lws "Reads LeaderWorkerSet CRs" "HTTPS/443"
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "RHOAI Component" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "Container" {
                background #6c8ebf
                color #ffffff
            }
        }
    }
}
