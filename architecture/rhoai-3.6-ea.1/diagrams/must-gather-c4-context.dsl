workspace {
    model {
        user = person "SRE / Support Engineer" "Collects diagnostic data from RHOAI clusters for troubleshooting"

        mustGather = softwareSystem "must-gather" "Ephemeral diagnostic data collection tool for RHOAI. Runs as a pod via oc adm must-gather, collects logs, resource manifests, and configuration from all RHOAI platform components." {
            gatherOrchestrator = container "gather.sh" "Main entrypoint that detects cluster type, discovers RHOAI operator namespace, and dispatches component-specific collection scripts" "Bash Script"
            commonUtils = container "common.sh" "Shared utilities for namespace enumeration and oc adm inspect invocation" "Bash Script"
            xksUtil = container "xks_util.sh" "Cross-Kubernetes distribution abstraction layer; provides kubectl_inspect fallback for non-OpenShift clusters" "Bash Script"
            componentScripts = container "Component Gather Scripts" "Per-component collection scripts (KServe, Pipelines, Model Registry, Notebooks, KubeRay, Kueue, TrustyAI, LLM-d, AIGateway, OGX, etc.)" "Bash Scripts"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server providing access to all Kubernetes and OpenShift resources" "External"
        rhodsOperator = softwareSystem "RHOAI Operator (rhods-operator)" "Manages RHOAI platform lifecycle; provides Subscription and CSV for version detection" "Internal RHOAI"
        odhCRDs = softwareSystem "ODH Custom Resources" "DSCInitialization, DataScienceCluster, and component-specific CRDs" "Internal RHOAI"
        rhoaiComponents = softwareSystem "RHOAI Application Components" "Serving, Pipelines, Notebooks, Model Registry, and other deployed RHOAI components" "Internal RHOAI"
        helm = softwareSystem "Helm" "Package manager used to collect release values and manifests" "External"

        # Relationships
        user -> mustGather "Invokes via oc adm must-gather --image=<image>"
        mustGather -> k8sAPI "Reads cluster resources, pod logs, CRs" "HTTPS/443, ServiceAccount token"
        mustGather -> rhodsOperator "Detects operator namespace and RHOAI version" "Kubernetes API"
        mustGather -> odhCRDs "Collects DSCInitialization, DataScienceCluster CRs" "Kubernetes API"
        mustGather -> rhoaiComponents "Collects logs and namespace resources" "Kubernetes API"
        mustGather -> helm "Collects Helm release values and manifests" "CLI"
        mustGather -> user "Returns diagnostic data archive"

        # Internal relationships
        gatherOrchestrator -> commonUtils "Uses shared utilities"
        gatherOrchestrator -> xksUtil "Detects cluster type"
        gatherOrchestrator -> componentScripts "Dispatches collection (parallel or single)"
        componentScripts -> commonUtils "Uses shared utilities"
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
                background #357abd
                color #ffffff
            }
        }
    }
}
