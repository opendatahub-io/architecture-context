workspace {
    model {
        clusterAdmin = person "Cluster Admin" "Runs must-gather to collect diagnostic data for support cases"

        mustGather = softwareSystem "must-gather" "Diagnostic data collector that gathers cluster state, logs, and CRD snapshots from all RHOAI components" {
            gatherDispatcher = container "gather.sh" "Main dispatcher: detects K8s distribution, dispatches to component collectors" "Bash Script"
            commonLib = container "common.sh" "OpenShift library: oc adm inspect wrapper, namespace discovery, version detection" "Bash Library"
            xksUtil = container "xks_util.sh" "xKS library: kubectl_inspect, auto-discover resources, distro detection" "Bash Library"
            componentCollectors = container "Component Collectors" "14 parallel collectors for KServe, LLM-D, AI Gateway, DSP, Notebooks, KubeRay, Kueue, Training, ModelReg, TrustyAI, Feast, MLflow, Spark, Dashboard" "Bash Scripts"
            llmdDeps = container "LLM-D Dependencies" "Dependency collectors for cert-manager, Sail/Istio, LWS" "Bash Scripts"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane providing REST API for all resource operations" "External"
        openshiftAPI = softwareSystem "OpenShift API" "OpenShift-specific APIs including infrastructures.config.openshift.io" "External"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager providing CSV-based version detection" "External"

        rhoaiOperator = softwareSystem "RHOAI Operator" "Red Hat OpenShift AI operator managing platform components" "Internal RHOAI"
        kserve = softwareSystem "KServe" "ML inference serving platform" "Internal RHOAI"
        llmd = softwareSystem "LLM-D" "LLM deployment and management" "Internal RHOAI"
        aiGateway = softwareSystem "AI Gateway" "AI traffic management and guardrails" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal RHOAI"
        workbench = softwareSystem "Workbench" "Interactive development notebooks" "Internal RHOAI"
        kuberay = softwareSystem "KubeRay" "Ray cluster management" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queuing and resource management" "Internal RHOAI"
        trainingOp = softwareSystem "Training Operator" "Distributed ML training jobs" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata management" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI model explainability and evaluation" "Internal RHOAI"

        clusterAdmin -> mustGather "Runs via oc adm must-gather or kubectl apply"
        mustGather -> kubernetesAPI "Reads cluster resources, CRDs, pod logs" "HTTPS/443 TLS 1.2+"
        mustGather -> openshiftAPI "Detects Kubernetes distribution" "HTTPS/443"
        mustGather -> olm "Reads CSV for RHOAI version" "HTTPS/443"

        mustGather -> rhoaiOperator "Reads operator CRDs and status" "HTTPS/443 read-only"
        mustGather -> kserve "Reads InferenceService, ServingRuntime CRDs" "HTTPS/443 read-only"
        mustGather -> llmd "Reads LLMInferenceService, InferencePool CRDs" "HTTPS/443 read-only"
        mustGather -> aiGateway "Reads AIGuardrail, ExternalModel CRDs" "HTTPS/443 read-only"
        mustGather -> dsp "Reads DSPA, Argo workflow CRDs" "HTTPS/443 read-only"
        mustGather -> workbench "Reads Notebook, ImageStream resources" "HTTPS/443 read-only"
        mustGather -> kuberay "Reads RayCluster, RayJob CRDs" "HTTPS/443 read-only"
        mustGather -> kueue "Reads ClusterQueue, Workload CRDs" "HTTPS/443 read-only"
        mustGather -> trainingOp "Reads PyTorchJob, TrainJob CRDs" "HTTPS/443 read-only"
        mustGather -> modelRegistry "Reads ModelRegistry CRDs" "HTTPS/443 read-only"
        mustGather -> trustyai "Reads TrustyAIService, LMEvalJob CRDs" "HTTPS/443 read-only"
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
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
