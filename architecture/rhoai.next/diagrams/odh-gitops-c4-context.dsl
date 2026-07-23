workspace {
    model {
        admin = person "Platform Administrator" "Deploys and configures RHOAI/ODH platform on OpenShift or vanilla Kubernetes"
        inferenceUser = person "Inference Client" "Sends prediction requests to deployed models via Gateway API"
        maasUser = person "MaaS Client" "Consumes Models-as-a-Service API endpoints"

        odhGitops = softwareSystem "odh-gitops" "GitOps repository providing Kustomize manifests and Helm charts for deploying RHOAI/ODH dependencies and platform configuration" {
            openshiftChart = container "rhai-on-openshift-chart" "Deploys RHOAI operator and dependencies on OpenShift via OLM with tri-state dependency resolution and profile system" "Helm Chart"
            xksChart = container "rhai-on-xks-chart" "Deploys RHAI operator, cloud managers, and infrastructure on non-OpenShift Kubernetes (EKS, AKS, CoreWeave)" "Helm Chart"
            kustomizeLayer = container "Kustomize Dependencies" "Granular OLM Subscription manifests for each dependency operator on OpenShift" "Kustomize"
            dependencySubcharts = container "Dependency Subcharts" "Standalone Helm charts for cert-manager, gateway-api, sail-operator, rhcl-operator, lws-operator" "Helm Charts"
            contractSchemas = container "Contract Schemas" "78 JSON schemas for CRD validation of Gateway API, Istio, Kuadrant, cloud engine resources" "JSON Schema"
            lifecycleHooks = container "Lifecycle Hooks" "Post-install and pre-delete Kubernetes Jobs for CR creation, Gateway setup, and cleanup" "Bash + Helm Hooks"
        }

        # External Dependencies
        openshift = softwareSystem "OpenShift" "Container platform with OLM for operator lifecycle management" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration for non-OpenShift deployments" "External"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager - manages operator installation via Subscriptions" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management and provisioning" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes ingress standard for inference and MaaS traffic routing" "External"
        istioSAIL = softwareSystem "Istio / SAIL Operator" "Service mesh and Gateway API implementation" "External"
        kuadrantRHCL = softwareSystem "Kuadrant / RHCL" "API management, rate limiting, and Authorino authentication" "External"
        kueue = softwareSystem "Kueue" "Job queue management for distributed workloads" "External"

        # Internal ODH/RHOAI Components
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI operator - source for xKS chart templates" "Internal RHOAI"
        rhoaiBuildConfig = softwareSystem "RHOAI-Build-Config" "Release engineering repository - receives synced Helm charts" "Internal RHOAI"
        odhBuildConfig = softwareSystem "ODH-Build-Config" "Source for xKS container image references" "Internal RHOAI"

        # External Services
        containerRegistries = softwareSystem "Container Registries" "quay.io, registry.redhat.io - container image hosting" "External Service"
        github = softwareSystem "GitHub" "Source code hosting, CI/CD workflows, PR automation" "External Service"

        # Relationships - Users
        admin -> odhGitops "Deploys platform using helm install or kubectl apply -k"
        inferenceUser -> gatewayAPI "Sends inference requests via HTTPS/443"
        maasUser -> kuadrantRHCL "Sends MaaS API requests via HTTPS/443 with Authorino auth"

        # Relationships - Internal
        openshiftChart -> olm "Creates OLM Subscriptions for dependency operators" "HTTPS/443"
        openshiftChart -> kustomizeLayer "References Kustomize components for dependency definitions"
        xksChart -> dependencySubcharts "Uses as Helm subcharts for non-OLM installation"
        xksChart -> lifecycleHooks "Runs post-install/pre-delete Jobs"
        openshiftChart -> contractSchemas "Validates CR schemas before creation"
        xksChart -> contractSchemas "Validates CR schemas before creation"

        # Relationships - External Dependencies
        odhGitops -> openshift "Deploys on OpenShift 4.19.9+" "HTTPS/443"
        odhGitops -> kubernetes "Deploys on Kubernetes 1.29+" "HTTPS/443"
        odhGitops -> certManager "Provisions TLS certificates for gateways, webhooks, MaaS" "HTTPS/443"
        odhGitops -> gatewayAPI "Creates GatewayClass and Gateway resources" "HTTPS/443"
        odhGitops -> istioSAIL "Configures service mesh and Gateway API controller" "HTTPS/443"
        odhGitops -> kuadrantRHCL "Configures Kuadrant CR and Authorino for MaaS auth" "HTTPS/443"
        odhGitops -> kueue "Creates Kueue CR for workload management" "HTTPS/443"

        # Relationships - Internal RHOAI
        rhodsOperator -> xksChart "Templates extracted via update-bundle.sh" "Git/HTTPS"
        odhGitops -> rhoaiBuildConfig "Charts synced via helm-sync.yml workflow" "HTTPS/443"
        odhBuildConfig -> xksChart "Image references updated via xks-values-patch.yaml" "HTTPS/443"

        # Relationships - External Services
        odhGitops -> containerRegistries "Pulls operator and hook container images" "HTTPS/443"
        odhGitops -> github "CI/CD workflows, PR automation, chart sync" "HTTPS/443"
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
            element "External Service" {
                background #f5a623
                color #333333
            }
            element "Internal RHOAI" {
                background #7ed321
                color #333333
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
