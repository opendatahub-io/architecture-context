workspace {
    model {
        admin = person "Cluster Admin" "Runs must-gather to collect diagnostic data for troubleshooting RHOAI issues"

        mustGather = softwareSystem "must-gather" "Diagnostic data collection tool for RHOAI/RHAII clusters" {
            gatherScript = container "gather.sh" "Main orchestrator — detects K8s distribution and dispatches component gatherers" "Bash Script (Entrypoint)"
            commonLib = container "common.sh" "Shared functions for namespace inspection, resource collection, and version detection" "Bash Script (Library)"
            xksUtil = container "xks_util.sh" "K8s distribution detection (OCP, AKS, EKS, CKS) and kubectl_inspect implementation" "Bash Script (Library)"
            componentGatherers = container "Component Gatherers" "14 component-specific collection scripts (gather_serving.sh, gather_dashboard.sh, etc.)" "Bash Scripts"
            llmdGatherers = container "LLM-D Gatherers" "LLM-D collection scripts with dependency collectors (cert-manager, Sail, LWS)" "Bash Scripts"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API providing resource enumeration and log collection" "External"
        ocpInspect = softwareSystem "oc adm inspect" "OpenShift built-in namespace-level resource serialization tool" "External"
        helmCLI = softwareSystem "Helm CLI" "Collects Helm release values and manifests" "External Tool"

        rhodsOperator = softwareSystem "rhods-operator" "RHOAI Operator managing DSCInitialization and DataScienceCluster" "Internal RHOAI"
        kserve = softwareSystem "KServe" "ML inference serving platform" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal RHOAI"
        kuberay = softwareSystem "KubeRay" "Ray cluster management" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queue management" "Internal RHOAI"
        trainingOp = softwareSystem "Training Operator" "ML training job management" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata storage" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI trustworthiness and evaluation" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "RHOAI web UI" "Internal RHOAI"
        aiGateway = softwareSystem "AI Gateway" "API gateway for AI services" "Internal RHOAI"
        istio = softwareSystem "Istio / Sail Operator" "Service mesh" "External"
        certManager = softwareSystem "cert-manager" "Certificate management" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API resources" "External"
        prometheus = softwareSystem "Prometheus Operator" "Monitoring and alerting" "External"

        // Relationships
        admin -> mustGather "Runs via oc adm must-gather or kubectl apply" "HTTPS/443"
        mustGather -> k8sAPI "Lists and gets all resources, collects pod logs" "HTTPS/443, TLS 1.2+, SA token"

        gatherScript -> commonLib "Sources shared functions"
        gatherScript -> xksUtil "Sources K8s distribution detection"
        gatherScript -> componentGatherers "Dispatches in parallel"
        gatherScript -> llmdGatherers "Dispatches for LLM-D collection"

        mustGather -> ocpInspect "Uses for OpenShift namespace inspection" "CLI"
        mustGather -> helmCLI "Collects Helm release info" "CLI"

        mustGather -> rhodsOperator "Collects DSCInitialization, DataScienceCluster CRs" "HTTPS/443"
        mustGather -> kserve "Collects InferenceService, ServingRuntime CRs" "HTTPS/443"
        mustGather -> dsp "Collects DataSciencePipelinesApplication CRs" "HTTPS/443"
        mustGather -> kuberay "Collects RayCluster, RayJob CRs" "HTTPS/443"
        mustGather -> kueue "Collects ClusterQueue, Workload CRs" "HTTPS/443"
        mustGather -> trainingOp "Collects PyTorchJob, TrainJob CRs" "HTTPS/443"
        mustGather -> modelRegistry "Collects ModelRegistry CRs" "HTTPS/443"
        mustGather -> trustyai "Collects LMEvalJob, TrustyAIService CRs" "HTTPS/443"
        mustGather -> dashboard "Collects ODHDashboardConfig CRs" "HTTPS/443"
        mustGather -> aiGateway "Collects AITenant, MaaSSubscription CRs" "HTTPS/443"
        mustGather -> istio "Collects VirtualService, AuthorizationPolicy CRs" "HTTPS/443"
        mustGather -> certManager "Collects Certificate, Issuer CRs" "HTTPS/443"
        mustGather -> gatewayAPI "Collects Gateway, HTTPRoute CRs" "HTTPS/443"
        mustGather -> prometheus "Collects ServiceMonitor, PrometheusRule CRs" "HTTPS/443"

        mustGather -> admin "Returns collected diagnostic data" "rsync/kubectl cp"
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
            element "External Tool" {
                background #bbbbbb
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
            }
        }
    }
}
