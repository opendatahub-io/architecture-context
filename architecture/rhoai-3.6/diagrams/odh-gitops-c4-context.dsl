workspace {
    model {
        admin = person "Platform Administrator" "Deploys and configures RHOAI platform on Kubernetes clusters"

        odhGitops = softwareSystem "odh-gitops" "GitOps repository providing Kustomize manifests and Helm charts for deploying RHOAI platform dependencies" {
            kustomizeLayer = container "Kustomize Layer" "Reusable components, dependency overlays, and post-install configurations" "Kustomize v5+"
            ocpChart = container "rhai-on-openshift-chart" "OLM-based deployment for OpenShift with tri-state dependency resolution" "Helm Chart"
            xksChart = container "rhai-on-xks-chart" "Non-OLM deployment bundling operator, CRDs, RBAC, cloud-provider resources" "Helm Chart"
            depCharts = container "Dependency Sub-Charts" "Standalone charts for cert-manager, Gateway API, LWS, RHCL, SAIL" "Helm Charts"
            scripts = container "Shell Scripts" "Cluster validation, Authorino TLS prep, snapshot management" "Bash"
            tekton = container "Tekton Pipeline" "End-to-end cluster validation via Konflux EaaS" "Tekton"
        }

        rhaiOperator = softwareSystem "ODH / RHOAI Operator" "Core platform operator managing DataScienceCluster lifecycle" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Certificate management and TLS provisioning" "Platform Dependency"
        kueue = softwareSystem "Kueue" "Job queue management for distributed workloads" "Platform Dependency"
        lws = softwareSystem "Leader Worker Set" "Distributed inference workflows" "Platform Dependency"
        rhcl = softwareSystem "Red Hat Connectivity Link" "API management and Authorino auth (Kuadrant)" "Platform Dependency"
        observability = softwareSystem "Observability Stack" "Cluster Observability, OpenTelemetry, Tempo, Loki" "Platform Dependency"
        nvidia = softwareSystem "NVIDIA GPU Operator" "GPU workload enablement" "Platform Dependency"
        gatewayAPI = softwareSystem "Gateway API / Istio" "Traffic routing for inference and MaaS endpoints" "Platform Dependency"
        olm = softwareSystem "Operator Lifecycle Manager" "Operator installation and lifecycle on OpenShift" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster control plane" "External"

        admin -> odhGitops "Deploys platform using kubectl/helm/ArgoCD"
        odhGitops -> k8sAPI "Applies manifests via" "HTTPS/6443"
        odhGitops -> olm "Creates OLM Subscriptions for" "Kubernetes API"
        odhGitops -> rhaiOperator "Installs and configures" "OLM / Direct Deployment"
        odhGitops -> certManager "Installs and creates Certificate CRs" "OLM / Helm"
        odhGitops -> kueue "Installs and configures" "OLM / Helm"
        odhGitops -> lws "Installs and configures" "OLM / Helm"
        odhGitops -> rhcl "Installs Kuadrant, configures Authorino TLS" "OLM / Helm"
        odhGitops -> observability "Installs monitoring, tracing, logging" "OLM / Helm"
        odhGitops -> nvidia "Installs GPU operator and ClusterPolicy" "OLM / Helm"
        odhGitops -> gatewayAPI "Creates Gateway and HTTPRoute resources" "Kubernetes API"

        ocpChart -> depCharts "References as sub-charts"
        xksChart -> depCharts "References as sub-charts"
        tekton -> kustomizeLayer "Validates"
        tekton -> ocpChart "Validates"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform Dependency" {
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
