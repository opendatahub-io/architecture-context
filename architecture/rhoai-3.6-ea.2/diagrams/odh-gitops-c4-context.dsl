workspace {
    model {
        admin = person "Platform Administrator" "Deploys and configures the RHOAI/ODH platform stack"

        odhGitops = softwareSystem "odh-gitops" "GitOps configuration repository providing Kustomize manifests and Helm charts for deploying ODH/RHOAI platform dependencies" {
            kustomizePath = container "Kustomize Manifests" "Declarative operator deployment for OpenShift using OLM subscriptions and post-install CRs" "Kustomize"
            ocpChart = container "rhai-on-openshift-chart" "Helm chart with OLM subscriptions, DSC/DSCI CRs, tri-state dependency resolution, profiles" "Helm Chart v3.4.0"
            xksChart = container "rhai-on-xks-chart" "Helm chart for non-OpenShift Kubernetes with direct operator deployment and cloud provider support" "Helm Chart v3.5.0"
            validationScripts = container "Validation Scripts" "Cluster validation, dependency verification, chart snapshot testing" "Shell Scripts"
        }

        olm = softwareSystem "OLM" "Operator Lifecycle Manager for installing and managing operators" "External"
        certManager = softwareSystem "cert-manager" "Certificate management and TLS provisioning" "Internal Platform"
        kueue = softwareSystem "Kueue" "Job queue management for distributed workloads" "Internal Platform"
        rhcl = softwareSystem "RHCL / Kuadrant" "API management and Authorino authorization" "Internal Platform"
        lws = softwareSystem "Leader Worker Set" "Distributed inference workflows" "Internal Platform"
        rhoaiOperator = softwareSystem "ODH/RHOAI Operator" "Core platform operator reconciling DataScienceCluster and DSCInitialization CRs" "Internal Platform"
        sailOperator = softwareSystem "Istio Sail Operator" "Service mesh for XKS deployments" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes ingress gateway management" "External"
        cloudProviders = softwareSystem "Cloud Providers" "AWS EKS, Azure AKS, CoreWeave Kubernetes" "External"
        catalogSources = softwareSystem "OLM Catalog Sources" "redhat-operators, certified-operators catalogs" "External"
        containerRegistries = softwareSystem "Container Registries" "Operator and component container image storage" "External"
        argocd = softwareSystem "ArgoCD / Flux" "GitOps controller for automated deployment" "External"
        tekton = softwareSystem "Tekton / Pipelines-as-Code" "CI validation of Kustomize manifests and Helm charts" "External"

        admin -> odhGitops "Deploys platform via kubectl/helm"
        admin -> kustomizePath "kubectl apply -k"
        admin -> ocpChart "helm install (OpenShift)"
        admin -> xksChart "helm install (EKS/AKS/CoreWeave)"

        kustomizePath -> olm "Creates OLM Subscriptions for operator installation"
        ocpChart -> olm "Creates OLM Subscriptions via Helm templates"
        ocpChart -> rhoaiOperator "Creates DataScienceCluster and DSCInitialization CRs"
        xksChart -> rhoaiOperator "Deploys operator directly (not via OLM)"
        xksChart -> cloudProviders "Deploys cloud-specific Cloud Manager operators"
        xksChart -> certManager "Creates Certificate resources for Gateway TLS"
        xksChart -> gatewayAPI "Creates inference and MaaS Gateways"
        xksChart -> rhcl "Configures Authorino TLS and authorization"
        xksChart -> sailOperator "Installs via Helm subchart"

        odhGitops -> certManager "Installs via OLM Subscription or Helm subchart"
        odhGitops -> kueue "Installs via OLM Subscription"
        odhGitops -> rhcl "Installs via OLM Subscription or Helm subchart"
        odhGitops -> lws "Installs via OLM Subscription or Helm subchart"

        olm -> catalogSources "Resolves operator packages" "HTTPS/443"
        olm -> containerRegistries "Pulls operator images" "HTTPS/443"

        argocd -> odhGitops "Optionally drives automated deployment"
        tekton -> odhGitops "CI validation on PRs" "Kubernetes API"
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
            element "Internal Platform" {
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
