workspace {
    model {
        platformEngineer = person "Platform Engineer" "Configures and deploys RHOAI/ODH platform via GitOps"
        dataScientist = person "Data Scientist" "Consumes ML inference and MaaS endpoints"

        odhGitops = softwareSystem "odh-gitops" "GitOps repository providing Helm charts and Kustomize overlays for deploying RHOAI/ODH platform dependencies and infrastructure" {
            openshiftChart = container "rhai-on-openshift-chart" "Helm chart (v3.4.0) for OLM-based OpenShift deployments with 14 RHOAI components and 12 dependency operators" "Helm Chart"
            xksChart = container "rhai-on-xks-chart" "Helm chart (v3.5.0-ea.2) for non-OLM Kubernetes (AWS, Azure, CoreWeave) with bundled dependency charts" "Helm Chart"
            kustomizeOverlays = container "Kustomize Overlays" "Layered composition for granular or grouped installation" "Kustomize"
            postInstallHooks = container "Post-Install Hooks" "Shell scripts for gateway creation and Authorino patching" "Shell Scripts"
        }

        argocd = softwareSystem "ArgoCD" "GitOps continuous delivery tool" "External"
        flux = softwareSystem "Flux" "GitOps toolkit for Kubernetes" "External"

        openshift = softwareSystem "OpenShift" "Red Hat OpenShift Container Platform with OLM" "External"
        awsKubernetes = softwareSystem "AWS Kubernetes" "Amazon EKS or self-managed Kubernetes" "External"
        azureKubernetes = softwareSystem "Azure Kubernetes" "Azure AKS or self-managed Kubernetes" "External"
        coreweavek8s = softwareSystem "CoreWeave Kubernetes" "CoreWeave managed Kubernetes" "External"

        olm = softwareSystem "OLM" "Operator Lifecycle Manager for OpenShift operator subscriptions" "External"
        certManager = softwareSystem "cert-manager" "X.509 certificate management with internal CA (rhai-ca-issuer)" "External"
        istio = softwareSystem "Istio / Gateway API" "Service mesh and gateway infrastructure for traffic management" "External"
        authorino = softwareSystem "Kuadrant / Authorino" "Authentication and authorization policy enforcement" "External"

        rhoaiPlatform = softwareSystem "RHOAI Platform" "14 RHOAI components: KServe, Dashboard, Ray, Trainer, Kueue, TrustyAI, Workbenches, ModelRegistry, Pipelines, Feast, OGX, MLflow, Spark, TrainingOperator" "Internal ODH"
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal ODH"
        maas = softwareSystem "MaaS API" "Model-as-a-Service API services" "Internal ODH"

        platformEngineer -> odhGitops "Configures charts and overlays"
        odhGitops -> argocd "Synced by" "HTTPS/Git"
        odhGitops -> flux "Synced by" "HTTPS/Git"
        argocd -> openshift "Deploys via kubectl apply -k / helm install"
        argocd -> awsKubernetes "Deploys via kubectl apply -k / helm install"
        argocd -> azureKubernetes "Deploys via kubectl apply -k / helm install"
        argocd -> coreweavek8s "Deploys via kubectl apply -k / helm install"
        flux -> openshift "Deploys via kubectl apply -k / helm install"
        flux -> awsKubernetes "Deploys via kubectl apply -k / helm install"

        openshiftChart -> olm "Creates OLM Subscriptions for 12 operators"
        openshiftChart -> rhoaiPlatform "Configures 14 components via DataScienceCluster CR"
        xksChart -> certManager "Bundles as dependency chart"
        xksChart -> istio "Bundles sail-operator as dependency chart"
        postInstallHooks -> istio "Creates inference-gateway and maas-gateway"
        postInstallHooks -> authorino "Patches with rhai-ca-bundle for TLS trust"

        certManager -> istio "Issues TLS certs for gateway listeners"

        dataScientist -> kserve "Inference requests" "HTTPS/443"
        dataScientist -> maas "MaaS API requests" "HTTPS/443"
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
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
