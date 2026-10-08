workspace {
    model {
        sre = person "SRE / Support Engineer" "Runs diagnostic collection for troubleshooting RHOAI issues"

        mustGather = softwareSystem "must-gather" "Diagnostic data collection tool for RHOAI installations" {
            gatherSh = container "gather.sh" "Main dispatcher — detects K8s distribution, routes to collectors" "Bash Script"
            commonSh = container "common.sh" "Shared library for namespace discovery, resource inspection" "Bash Library"
            xksUtil = container "xks_util.sh" "xKS abstraction layer — kubectl_inspect reimplementation" "Bash Library"
            collectors = container "Component Collectors" "16 parallel collectors for RHOAI component CRDs" "Bash Scripts"
            llmdSubsystem = container "LLM-D Subsystem" "Dependency-aware meta-collector for disaggregated serving" "Bash Scripts"
            o11yCollector = container "Observability Collector" "Prometheus Operator or Azure Managed Prometheus collection" "Bash Script"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for resource queries" "External"
        openshiftApi = softwareSystem "OpenShift API" "OpenShift extensions including oc adm inspect" "External"
        containerRegistry = softwareSystem "Container Registry" "registry.redhat.io — hosts must-gather image" "External"
        helm = softwareSystem "Helm" "Extracts Helm release values and manifests" "External"

        rhoaiOperator = softwareSystem "RHOAI Operator" "Manages RHOAI platform lifecycle" "Internal RHOAI"
        kserve = softwareSystem "KServe" "ML inference serving" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "RHOAI web UI" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal RHOAI"
        kuberay = softwareSystem "KubeRay" "Ray cluster management" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queueing and scheduling" "Internal RHOAI"
        kfto = softwareSystem "Training Operator" "Distributed training jobs" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata storage" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI trustworthiness and evaluation" "Internal RHOAI"
        aiGateway = softwareSystem "AI Gateway" "API gateway for AI services" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management" "External"
        istio = softwareSystem "Sail/Istio" "Service mesh" "External"

        sre -> mustGather "Runs via oc adm must-gather or K8s Job"
        mustGather -> k8sApi "Reads all cluster resources" "HTTPS/443, ServiceAccount token"
        mustGather -> openshiftApi "Namespace inspection (OCP only)" "HTTPS/443, ServiceAccount token"
        mustGather -> helm "Extracts release values" "HTTPS/443"
        containerRegistry -> mustGather "Image pull" "HTTPS/443, pull secret"

        mustGather -> rhoaiOperator "Reads DSCI, DSC CRs" "Kubernetes API"
        mustGather -> kserve "Reads InferenceService, ServingRuntime CRs" "Kubernetes API"
        mustGather -> dashboard "Reads OdhDashboardConfig CRs" "Kubernetes API"
        mustGather -> dsp "Reads DSP Application, Argo CRs" "Kubernetes API"
        mustGather -> kuberay "Reads RayCluster, RayJob CRs" "Kubernetes API"
        mustGather -> kueue "Reads ClusterQueue, Workload CRs" "Kubernetes API"
        mustGather -> kfto "Reads PyTorchJob, TrainJob CRs" "Kubernetes API"
        mustGather -> modelRegistry "Reads ModelRegistry CRs" "Kubernetes API"
        mustGather -> trustyai "Reads TrustyAIService CRs" "Kubernetes API"
        mustGather -> aiGateway "Reads AIGuardrail, ExternalModel CRs" "Kubernetes API"
        mustGather -> certManager "Reads Certificate, Issuer CRs" "Kubernetes API"
        mustGather -> istio "Reads VirtualService, AuthPolicy CRs" "Kubernetes API"
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
        }
    }
}
