workspace {
    model {
        platformEngineer = person "Platform Engineer" "Deploys and manages RHOAI/ODH platform on OpenShift or xKS clusters"
        dataScienceAdmin = person "Data Science Admin" "Configures platform components via DSC/DSCI CRs or Helm values"

        odhGitops = softwareSystem "odh-gitops" "GitOps configuration layer providing Helm charts and Kustomize manifests for deploying RHOAI/ODH platform dependencies" {
            xksChart = container "rhai-on-xks-chart" "Helm chart for non-OpenShift Kubernetes (AWS EKS, Azure AKS, CoreWeave)" "Helm Go Templates"
            openshiftChart = container "rhai-on-openshift-chart" "Helm chart for OpenShift with OLM-based operator management" "Helm Go Templates"
            kustomizeManifests = container "Kustomize Manifests" "Layered kustomize structure for operator subscriptions and configurations" "Kustomize YAML"
            depSubCharts = container "Dependency Sub-Charts" "Non-OLM Helm-based installation of cert-manager, gateway-api, sail, lws, rhcl operators" "Helm Go Templates"
            contractSchemas = container "Contract Schemas" "JSON Schema definitions for CRD validation (~85K lines)" "JSON Schema"
            helmSyncWorkflow = container "Helm Sync Workflow" "GitHub Actions workflow syncing charts to RHOAI-Build-Config" "GitHub Actions"
        }

        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "The RHAI operator binary that reconciles platform CRs" "Internal ODH"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning and management" "External"
        sailOperator = softwareSystem "Sail Operator (Istio)" "Service mesh and Gateway API data plane" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API CRDs for ingress" "External"
        lwsOperator = softwareSystem "LeaderWorkerSet Operator" "Distributed inference workflow orchestration" "External"
        rhclKuadrant = softwareSystem "RHCL / Kuadrant" "API management with AuthPolicy, RateLimitPolicy" "External"
        kueueOperator = softwareSystem "Kueue Operator" "Job queue for distributed workloads" "External"
        jobSetOperator = softwareSystem "JobSet Operator" "Job management for training workloads" "External"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager (OpenShift)" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Kubernetes control plane" "External"
        rhoaiBuildConfig = softwareSystem "RHOAI-Build-Config" "Build configuration repository receiving chart syncs" "Internal ODH"
        nvidiaGPU = softwareSystem "NVIDIA GPU Operator" "GPU-accelerated workload enablement" "External"
        nfd = softwareSystem "NFD" "Node feature detection for GPU support" "External"

        platformEngineer -> odhGitops "Deploys RHOAI/ODH platform via Helm or kustomize"
        dataScienceAdmin -> odhGitops "Configures component profiles and dependencies"

        odhGitops -> kubernetesAPI "Creates/manages CRDs, Deployments, RBAC, Gateways" "HTTPS/443"
        odhGitops -> rhodsOperator "Deploys operator Deployment (xKS) or OLM Subscription (OpenShift)"
        odhGitops -> certManager "Creates TLS Certificates for gateways and webhooks"
        odhGitops -> sailOperator "Deploys Istio for service mesh and Gateway data plane"
        odhGitops -> gatewayAPI "Installs Gateway API CRDs and creates Gateway CRs"
        odhGitops -> lwsOperator "Installs LeaderWorkerSet for distributed inference"
        odhGitops -> rhclKuadrant "Deploys Kuadrant for AuthPolicy and RateLimitPolicy"
        odhGitops -> kueueOperator "Installs Kueue for workload queuing"
        odhGitops -> jobSetOperator "Installs JobSet for training job management"
        odhGitops -> olm "Creates OLM Subscriptions (OpenShift path)" "HTTPS/443"
        odhGitops -> nvidiaGPU "Optional: installs NVIDIA GPU Operator"
        odhGitops -> nfd "Optional: installs Node Feature Discovery"
        helmSyncWorkflow -> rhoaiBuildConfig "Syncs Helm charts on release branches" "HTTPS/443"

        xksChart -> depSubCharts "Includes as Helm dependency sub-charts"
        contractSchemas -> xksChart "Validates CRD structures in templates"
        contractSchemas -> openshiftChart "Validates CRD structures in templates"
    }

    views {
        systemContext odhGitops "SystemContext" {
            include *
            autoLayout
        }

        container odhGitops "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
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
