workspace {
    model {
        platformAdmin = person "Platform Admin" "Deploys and configures RHOAI/ODH platform using Helm"

        odhGitops = softwareSystem "odh-gitops" "GitOps repository providing Helm charts and Kustomize manifests for deploying RHOAI/ODH" {
            openShiftChart = container "rhai-on-openshift-chart" "Full RHOAI/ODH deployment on OpenShift via OLM Subscriptions, DSC, and DSCI CRs" "Helm Chart"
            xksChart = container "rhai-on-xks-chart" "RHOAI deployment on non-OpenShift Kubernetes (AWS/Azure/CoreWeave) with direct operator deployment" "Helm Chart"
            depCharts = container "Dependency Sub-Charts" "Extracted OLM bundles for installing dependency operators without OLM (cert-manager, gateway-api, lws, rhcl, sail)" "Helm Sub-Charts"
            kustomizeComponents = container "Kustomize Components" "Granular operator installation manifests (Namespace, OperatorGroup, Subscription)" "Kustomize"
            kustomizeConfigs = container "Kustomize Configurations" "Post-install operator configuration CRs (Kueue, JobSet, LWS, RHCL, NFD, NVIDIA)" "Kustomize"
            contractSchemas = container "Contract Schemas" "75+ JSON Schema files validating CRDs consumed by the platform" "JSON Schema"
        }

        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that reconciles DSC, DSCI, and Platform CRs" "Internal RHOAI"

        certManager = softwareSystem "cert-manager" "TLS certificate provisioning" "Dependency Operator"
        kueue = softwareSystem "Kueue" "Job queue for distributed workloads" "Dependency Operator"
        rhcl = softwareSystem "RHCL / Kuadrant" "API management, Authorino-based auth, rate limiting" "Dependency Operator"
        sail = softwareSystem "Sail / Istio" "Service mesh, Gateway API implementation, GatewayClass controller" "Dependency Operator"
        lws = softwareSystem "Leader Worker Set" "Distributed inference orchestration" "Dependency Operator"
        jobset = softwareSystem "JobSet" "Job management for training workloads" "Dependency Operator"
        nfd = softwareSystem "NFD" "Node hardware feature discovery for GPU/accelerator detection" "Dependency Operator"
        nvidiaGpu = softwareSystem "NVIDIA GPU Operator" "GPU driver and device plugin management" "Dependency Operator"
        clusterObservability = softwareSystem "Cluster Observability" "Platform monitoring and alerting" "Dependency Operator"

        olm = softwareSystem "OLM" "Operator Lifecycle Manager for OpenShift subscription management" "External"
        k8sApi = softwareSystem "Kubernetes API" "Kubernetes control plane API server" "External"
        buildConfig = softwareSystem "RHOAI-Build-Config" "Downstream release pipeline receives chart updates" "External"
        odhBuildConfig = softwareSystem "ODH-Build-Config" "Source of operator and related images for xKS chart" "External"

        # Relationships
        platformAdmin -> odhGitops "Deploys platform using helm install"
        odhGitops -> k8sApi "Creates CRs, Deployments, Services via" "HTTPS/443"
        odhGitops -> olm "Creates operator Subscriptions via" "CRD creation"
        odhGitops -> rhodsOperator "Deploys and triggers reconciliation of"
        odhGitops -> certManager "Installs and configures"
        odhGitops -> kueue "Installs and configures"
        odhGitops -> rhcl "Installs and configures"
        odhGitops -> sail "Installs and configures"
        odhGitops -> lws "Installs and configures"
        odhGitops -> jobset "Installs and configures"
        odhGitops -> nfd "Installs and configures"
        odhGitops -> nvidiaGpu "Installs and configures"
        odhGitops -> clusterObservability "Installs and configures"
        odhGitops -> buildConfig "Syncs charts via helm-sync.yml" "HTTPS/443"
        odhGitops -> odhBuildConfig "Fetches operator images via update-image" "HTTPS/443"

        rhodsOperator -> k8sApi "Reconciles component deployments"

        # Container relationships
        openShiftChart -> olm "Creates OLM Subscriptions"
        openShiftChart -> kustomizeComponents "Leverages for operator installation"
        xksChart -> depCharts "Includes dependency charts"
        xksChart -> k8sApi "Creates KubernetesEngine, Platform, component CRs"
        kustomizeComponents -> kustomizeConfigs "Requires before applying configs"
        contractSchemas -> k8sApi "Validates CRDs against schemas"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Dependency Operator" {
                background #999999
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
        }
    }
}
