workspace {
    model {
        admin = person "Cluster Admin" "OpenShift or xKS cluster administrator who invokes must-gather for diagnostic data collection"

        mustGather = softwareSystem "must-gather" "Diagnostic data collection tool for RHOAI and LLM-D workloads across OpenShift and xKS platforms" {
            gatherOrchestrator = container "gather.sh" "Main orchestrator: detects K8s distribution, dispatches collectors, collects platform CRs" "Shell Script"
            commonLib = container "common.sh" "Shared library: run_mustgather, get_all_namespace, rhoai_version, collect_helm_releases" "Shell Script"
            xksUtilLib = container "xks_util.sh" "xKS support: detect_k8s_distro, kubectl_inspect, auto_discover_resources" "Shell Script"
            componentCollectors = container "Component Collectors" "14 per-component gatherer scripts running in parallel on OCP" "Shell Scripts"
            llmdCollector = container "gather_llmd.sh" "LLM-D collection orchestrator for xKS platforms (CKS, AKS, EKS)" "Shell Script"
            dependencyCollectors = container "Dependency Collectors" "cert-manager.sh, sail.sh, lws.sh - collect dependency operator state" "Shell Scripts"
            optionalCollectors = container "Optional Collectors" "gather_o11y.sh, gather_wva.sh, gather_batch_gateway.sh" "Shell Scripts"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server providing access to all Kubernetes and CRD resources" "External"
        rhoaiOperator = softwareSystem "RHOAI Operator (rhods-operator)" "Platform operator managing DataScienceCluster and DSCInitialization" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving platform with InferenceService and ServingRuntime CRDs" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "Pipeline orchestration with DSPApplication and Argo Workflow CRDs" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "Web console with OdhDashboardConfig, AcceleratorProfile CRDs" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job scheduling with ClusterQueue, LocalQueue, Workload CRDs" "Internal RHOAI"
        kuberay = softwareSystem "KubeRay" "Ray cluster management with RayCluster, RayJob CRDs" "Internal RHOAI"
        trainingOp = softwareSystem "Training Operator" "Distributed training with PyTorchJob, TrainJob CRDs" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata store" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI trustworthiness with LMEvalJob, GuardrailsOrchestrator CRDs" "Internal RHOAI"
        aiGateway = softwareSystem "AI Gateway / MaaS" "Models-as-a-Service with AITenant, ExternalModel CRDs" "Internal RHOAI"
        istio = softwareSystem "Istio / Sail Operator" "Service mesh with VirtualService, DestinationRule, AuthorizationPolicy CRDs" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management with Certificate, Issuer CRDs" "External"
        gatewayAPI = softwareSystem "Gateway API" "Ingress with Gateway, HTTPRoute, GRPCRoute CRDs" "External"
        lws = softwareSystem "LeaderWorkerSet" "Distributed workload orchestration" "External"
        helm = softwareSystem "Helm" "Release management - stores values/manifests in K8s Secrets" "External"

        # Relationships
        admin -> mustGather "Invokes via oc adm must-gather or kubectl apply Job"
        mustGather -> k8sAPI "Reads all cluster resources" "HTTPS/443, TLS 1.2+, SA token"
        mustGather -> rhoaiOperator "Reads DSCInitialization, DataScienceCluster CRDs" "HTTPS/443"
        mustGather -> kserve "Reads InferenceService, ServingRuntime CRDs" "HTTPS/443"
        mustGather -> dsp "Reads DSPApplication, Workflow CRDs" "HTTPS/443"
        mustGather -> dashboard "Reads OdhDashboardConfig, AcceleratorProfile CRDs" "HTTPS/443"
        mustGather -> kueue "Reads ClusterQueue, LocalQueue, Workload CRDs" "HTTPS/443"
        mustGather -> kuberay "Reads RayCluster, RayJob, RayService CRDs" "HTTPS/443"
        mustGather -> trainingOp "Reads PyTorchJob, TrainJob CRDs" "HTTPS/443"
        mustGather -> modelRegistry "Reads ModelRegistry CRDs" "HTTPS/443"
        mustGather -> trustyai "Reads LMEvalJob, TrustyAIService CRDs" "HTTPS/443"
        mustGather -> aiGateway "Reads AITenant, ExternalModel, MaaSAuthPolicy CRDs" "HTTPS/443"
        mustGather -> istio "Reads Istio, VirtualService, AuthorizationPolicy CRDs" "HTTPS/443"
        mustGather -> certManager "Reads Certificate, Issuer, ClusterIssuer CRDs" "HTTPS/443"
        mustGather -> gatewayAPI "Reads Gateway, HTTPRoute, GRPCRoute CRDs" "HTTPS/443"
        mustGather -> lws "Reads LeaderWorkerSet CRDs" "HTTPS/443"
        mustGather -> helm "Reads Helm release values and manifests" "HTTPS/443"
        mustGather -> admin "Returns tar archive of collected diagnostic data"

        # Internal relationships
        gatherOrchestrator -> commonLib "Uses shared functions"
        gatherOrchestrator -> xksUtilLib "Uses xKS platform detection"
        gatherOrchestrator -> componentCollectors "Spawns in parallel (OCP path)"
        gatherOrchestrator -> llmdCollector "Dispatches (xKS path)"
        llmdCollector -> dependencyCollectors "Spawns in parallel"
        llmdCollector -> optionalCollectors "Optional sub-collectors"
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
