workspace {
    model {
        sre = person "SRE / Support Engineer" "Runs must-gather to collect diagnostic data for support cases"

        mustGather = softwareSystem "must-gather" "Diagnostic container image that collects cluster state, logs, and CR data for all RHOAI components" {
            gatherScript = container "gather.sh" "Main entry point; detects K8s distribution, dispatches component gatherers" "Bash Script"
            commonLib = container "common.sh" "Shared functions for namespace discovery, resource inspection, version detection" "Bash Library"
            xksUtil = container "xks_util.sh" "K8s distribution detection and kubectl-based inspect for non-OpenShift" "Bash Library"
            componentGatherers = container "Component Gatherers" "13 parallel scripts collecting component-specific CRs, pods, logs" "Bash Scripts"
            llmdGatherers = container "LLM-D Gatherers" "LLM-D orchestrator with nested parallelism for dependency collection" "Bash Scripts"
            depCollectors = container "Dependency Collectors" "cert-manager, LWS, Sail/Istio resource collection" "Bash Scripts"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane providing resource read access" "External"
        ocCLI = softwareSystem "oc / kubectl CLI" "Command-line tools for cluster interaction and must-gather invocation" "External"

        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator managing DSC and DSCI resources" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving platform with InferenceService CRDs" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "Pipeline orchestration with DSPA and Argo Workflow CRDs" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "Web UI configuration with AcceleratorProfile and HardwareProfile CRDs" "Internal RHOAI"
        kuberay = softwareSystem "KubeRay" "Distributed compute with RayCluster, RayJob, RayService CRDs" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queuing with ClusterQueue, LocalQueue, Workload CRDs" "Internal RHOAI"
        kfto = softwareSystem "Kubeflow Training Operator" "Training jobs with PyTorchJob, TrainJob CRDs" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model metadata storage with ModelRegistry CRDs" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI safety with TrustyAIService, LMEvalJob, GuardrailsOrchestrator CRDs" "Internal RHOAI"
        feast = softwareSystem "Feast Operator" "Feature store with FeatureStore CRDs" "Internal RHOAI"
        llamaStack = softwareSystem "Llama-stack Operator" "LlamaStackDistribution CRDs" "Internal RHOAI"
        mlflow = softwareSystem "MLflow Operator" "MLflow experiment tracking CRDs" "Internal RHOAI"
        sparkOperator = softwareSystem "Spark Operator" "SparkApplication, ScheduledSparkApplication CRDs" "Internal RHOAI"
        maas = softwareSystem "Models as a Service" "MaaS ModelRef, AuthPolicy, Subscription CRDs" "Internal RHOAI"

        istio = softwareSystem "Istio / Sail Operator" "Service mesh with EnvoyFilter, VirtualService, AuthorizationPolicy" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management with Certificate, Issuer CRDs" "External"
        lws = softwareSystem "LeaderWorkerSet" "Distributed inference workload management" "External"
        gatewayAPI = softwareSystem "Gateway API" "Ingress routing with Gateway, HTTPRoute, GRPCRoute CRDs" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "Monitoring with ServiceMonitor, PodMonitor, PrometheusRule CRDs" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling with ScaledObject, TriggerAuthentication CRDs" "External"
        helm = softwareSystem "Helm" "Package manager for RHAII chart release inspection" "External"

        # Relationships
        sre -> ocCLI "Invokes must-gather via"
        ocCLI -> mustGather "Launches must-gather pod"
        mustGather -> k8sAPI "Reads all cluster resources via HTTPS/443" "HTTPS/TLS 1.2+"

        # Internal structure
        gatherScript -> commonLib "Loads shared functions"
        gatherScript -> xksUtil "Detects K8s distribution"
        gatherScript -> componentGatherers "Dispatches 13 parallel gatherers"
        componentGatherers -> llmdGatherers "LLM-D collection path"
        llmdGatherers -> depCollectors "Parallel dependency collection"

        # What it collects from
        mustGather -> rhodsOperator "Reads DSC, DSCI CRs" "oc adm inspect"
        mustGather -> kserve "Reads InferenceService, ServingRuntime CRs" "oc adm inspect"
        mustGather -> dsp "Reads DSPA, Workflow CRs" "oc adm inspect"
        mustGather -> dashboard "Reads DashboardConfig, AcceleratorProfile CRs" "oc adm inspect"
        mustGather -> kuberay "Reads RayCluster, RayJob CRs" "oc adm inspect"
        mustGather -> kueue "Reads ClusterQueue, Workload CRs" "oc adm inspect"
        mustGather -> kfto "Reads PyTorchJob, TrainJob CRs" "oc adm inspect"
        mustGather -> modelRegistry "Reads ModelRegistry CRs" "oc adm inspect"
        mustGather -> trustyai "Reads TrustyAIService, LMEvalJob CRs" "oc adm inspect"
        mustGather -> feast "Reads FeatureStore CRs" "oc adm inspect"
        mustGather -> llamaStack "Reads LlamaStackDistribution CRs" "oc adm inspect"
        mustGather -> mlflow "Reads MLflow CRs" "oc adm inspect"
        mustGather -> sparkOperator "Reads SparkApplication CRs" "oc adm inspect"
        mustGather -> maas "Reads MaaSModelRef, Subscription CRs" "oc adm inspect"
        mustGather -> istio "Reads Istio networking and security CRs" "oc adm inspect"
        mustGather -> certManager "Reads Certificate, Issuer CRs" "oc adm inspect"
        mustGather -> lws "Reads LeaderWorkerSet CRs" "oc adm inspect"
        mustGather -> gatewayAPI "Reads Gateway, HTTPRoute CRs" "oc adm inspect"
        mustGather -> prometheusOp "Reads ServiceMonitor, PrometheusRule CRs" "oc adm inspect"
        mustGather -> keda "Reads ScaledObject CRs (optional WVA)" "oc adm inspect"
        mustGather -> helm "Reads Helm release values and manifests" "helm get"
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
                shape person
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
