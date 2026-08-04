workspace {
    model {
        sre = person "SRE / Support Engineer" "Collects diagnostic data from RHOAI clusters for troubleshooting"

        mustGather = softwareSystem "must-gather" "RHOAI diagnostic data collection tool invoked via oc adm must-gather that gathers logs, resource definitions, and configuration from all RHOAI platform components" {
            gatherEntrypoint = container "gather entrypoint" "Main /usr/bin/gather script that detects distribution and dispatches collectors" "Shell Script"
            distDetection = container "Distribution Detection" "Detects OpenShift, AKS, EKS, CoreWeave, or generic Kubernetes" "Shell Script (xks_util.sh)"
            dspCollector = container "DSP Collector" "Collects Data Science Pipelines resources and logs" "Shell Script"
            kserveCollector = container "KServe Collector" "Collects InferenceService, ServingRuntime resources" "Shell Script"
            modelRegCollector = container "Model Registry Collector" "Collects Model Registry resources from rhoai-model-registries" "Shell Script"
            llmdCollector = container "llm-d Collector" "Collects LLMInferenceService, InferencePool, Gateway API resources" "Shell Script"
            otherCollectors = container "Other Component Collectors" "KubeRay, Kueue, Training, TrustyAI, Feast, MLflow, Spark, AI Gateway, MCP, OGX, Workbenches" "Shell Scripts"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Cluster API endpoint for resource and log collection" "External"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator managing DSCInitialization and DataScienceCluster CRs" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration component" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving inference platform" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata registry" "Internal RHOAI"
        llmd = softwareSystem "llm-d" "LLM inference service" "Internal RHOAI"
        authorino = softwareSystem "Authorino" "Authentication and authorization service" "Internal RHOAI"
        kuadrant = softwareSystem "Kuadrant" "Rate limiting and API management" "Internal RHOAI"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API resources" "External"
        helm = softwareSystem "Helm" "Package manager for Kubernetes" "External"

        sre -> mustGather "Runs oc adm must-gather --image=<image>"
        mustGather -> k8sApiServer "Reads resources, logs, events" "HTTPS/6443 TLS"
        mustGather -> rhodsOperator "Collects operator CSV, DSCi, DSC CRs" "via K8s API"
        mustGather -> dsp "Collects DSP namespace resources and logs" "via K8s API"
        mustGather -> kserve "Collects InferenceService, ServingRuntime" "via K8s API"
        mustGather -> modelRegistry "Collects Model Registry CRDs" "via K8s API"
        mustGather -> llmd "Collects LLMInferenceService, InferencePool" "via K8s API"
        mustGather -> authorino "Collects AuthConfig, AuthPolicy" "via K8s API"
        mustGather -> kuadrant "Collects RateLimitPolicy, TokenRateLimitPolicy" "via K8s API"
        mustGather -> gatewayAPI "Collects Gateway, HTTPRoute, GRPCRoute" "via K8s API"
        mustGather -> helm "Collects Helm release values and manifests" "CLI"
        mustGather -> sre "Returns collected artifacts tarball"
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
