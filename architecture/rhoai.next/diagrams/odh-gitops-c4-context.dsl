workspace {
    model {
        admin = person "Cluster Administrator" "Deploys and manages RHOAI/ODH platform"
        modelConsumer = person "Model Consumer" "Consumes ML inference endpoints"

        odhGitops = softwareSystem "odh-gitops" "GitOps repository providing Kustomize manifests and Helm charts for RHOAI/ODH platform deployment" {
            kustomizeDeps = container "Kustomize Dependency Manifests" "Layered Kustomize components and overlays for OLM-based operator dependencies" "Kustomize"
            kustomizeConfig = container "Kustomize Configuration Manifests" "Post-CRD operator configuration resources" "Kustomize"
            ocpChart = container "rhai-on-openshift-chart" "Helm chart for RHOAI on OpenShift via OLM with tri-state dependency resolution and profiles" "Helm Chart"
            xksChart = container "rhai-on-xks-chart" "Helm chart for RHAI on non-OpenShift K8s (AWS, Azure, CoreWeave) with direct operator deployment" "Helm Chart"
            subCharts = container "Dependency Sub-Charts" "Sub-charts for cert-manager, Gateway API, LWS, RHCL, SAIL" "Helm Sub-Charts"
            verifyScripts = container "Verification Scripts" "Operator readiness verification and dependency checking" "Bash"
        }

        olm = softwareSystem "OLM" "Operator Lifecycle Manager for OpenShift" "External"
        certManager = softwareSystem "cert-manager" "Certificate management and TLS provisioning" "Platform Dependency"
        kueue = softwareSystem "Kueue" "Job queue management for distributed workloads" "Platform Dependency"
        lws = softwareSystem "Leader Worker Set" "Distributed inference workflow orchestration" "Platform Dependency"
        kuadrant = softwareSystem "RHCL/Kuadrant" "API management, auth, rate limiting" "Platform Dependency"
        istio = softwareSystem "Istio/SAIL" "Service mesh for traffic management" "Platform Dependency"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for ingress" "Platform Dependency"
        odhOperator = softwareSystem "ODH/RHOAI Operator" "Core platform operator" "Internal"
        argocd = softwareSystem "ArgoCD / Flux" "GitOps reconciliation controller" "External"
        containerRegistry = softwareSystem "Container Registry" "quay.io / registry.redhat.io" "External"
        catalogSource = softwareSystem "CatalogSource" "OLM operator catalog (redhat-operators)" "External"

        admin -> odhGitops "Deploys platform using kustomize/helm"
        admin -> argocd "Configures GitOps sync" "" ""
        argocd -> odhGitops "Reconciles manifests from Git"
        odhGitops -> olm "Creates Subscription CRs" "Kubernetes API/6443"
        odhGitops -> certManager "Deploys and configures" "OLM Subscription / Helm Sub-Chart"
        odhGitops -> kueue "Deploys and configures" "OLM Subscription"
        odhGitops -> lws "Deploys and configures" "OLM Subscription / Helm Sub-Chart"
        odhGitops -> kuadrant "Deploys and configures" "OLM Subscription / Helm Sub-Chart"
        odhGitops -> istio "Deploys via sub-chart" "Helm Sub-Chart"
        odhGitops -> gatewayAPI "Deploys CRDs via sub-chart" "Helm Sub-Chart"
        odhGitops -> odhOperator "Installs and configures DSC/DSCI" "OLM / Direct Deployment"
        olm -> catalogSource "Fetches operator bundles" "HTTPS/443"
        olm -> containerRegistry "Pulls operator images" "HTTPS/443"
        modelConsumer -> odhGitops "Accesses inference via deployed Gateways" "" ""

        xksChart -> subCharts "Includes as Helm dependencies"
        kustomizeDeps -> kustomizeConfig "Phase 2: post-CRD configuration"
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
            element "Platform Dependency" {
                background #7ed321
                color #ffffff
            }
            element "Internal" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
