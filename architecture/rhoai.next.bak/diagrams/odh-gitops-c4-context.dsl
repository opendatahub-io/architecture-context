workspace {
    model {
        admin = person "Platform Administrator" "Deploys and configures RHOAI/ODH platform and its dependencies"
        client = person "Inference Client" "Sends inference requests to deployed ML models"

        odhGitops = softwareSystem "odh-gitops" "GitOps repository providing Kustomize manifests and Helm charts for deploying RHOAI/ODH platform dependencies and operator configurations" {
            kustomizeLayer = container "Kustomize Layer" "12 operator installation components (Namespace, OperatorGroup, Subscription) + post-install CR configurations" "Kustomize Components/Overlays"
            rhaiOCPChart = container "rhai-on-openshift-chart" "Full-stack RHOAI/ODH deployment on OpenShift with OLM — 13 platform components, 11 dependency operators, profile-based defaults, tri-state dependencies" "Helm Chart v3.4.0"
            rhaiXKSChart = container "rhai-on-xks-chart" "RHAI deployment on non-OpenShift Kubernetes (Azure AKS, CoreWeave, AWS EKS) — bundles operator, cloud managers, CRDs, Gateway API, post-install hooks" "Helm Chart v3.5.0-ea.2"
            depCharts = container "Dependency Sub-Charts" "Standalone operator charts (cert-manager, gateway-api, lws, sail) extracted from OLM bundles for vanilla Kubernetes" "Helm Dependency Charts"
            crdSchemas = container "CRD Contract Schemas" "40+ JSON schemas validating CRD structures for KServe, Platform, Gateway API, Istio, cert-manager, cloud providers" "JSON Schema"
            cicd = container "CI/CD Pipelines" "Tekton pipelines for ephemeral AWS HyperShift cluster provisioning and end-to-end validation" "Tekton / Bash"
        }

        // Internal ODH/RHOAI Platform
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Main RHOAI/ODH platform operator managing DataScienceCluster and DSCInitialization" "Internal ODH"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management for Gateway, Authorino, webhooks, KServe, Kueue, Ray, Trainer" "Internal Dependency"
        kueue = softwareSystem "Kueue" "Job queueing operator with integration framework (Deployment, Pod, PyTorchJob, RayCluster, StatefulSet, TrainJob)" "Internal Dependency"
        lws = softwareSystem "Leader Worker Set" "Distributed inference and training workflows" "Internal Dependency"
        jobset = softwareSystem "JobSet" "Coordinated job management for Trainer" "Internal Dependency"
        kuadrant = softwareSystem "Kuadrant / Authorino (RHCL)" "API management and external authorization for KServe inference endpoints" "Internal Dependency"
        istioSail = softwareSystem "Istio / Sail Operator" "Service mesh for Gateway API, traffic management, mTLS between services" "Internal Dependency"
        gatewayAPI = softwareSystem "Gateway API CRDs" "Kubernetes-native ingress routing CRDs consumed by Istio and KServe" "Internal Dependency"
        coo = softwareSystem "Cluster Observability Operator" "Platform monitoring and observability" "Internal Dependency"
        otel = softwareSystem "OpenTelemetry" "Distributed tracing and metrics collection" "Internal Dependency"
        tempo = softwareSystem "Tempo" "Trace storage backend" "Internal Dependency"
        keda = softwareSystem "Custom Metrics Autoscaler (KEDA)" "Event-driven pod autoscaling for KServe" "Internal Dependency"
        nfd = softwareSystem "NFD" "Hardware capability detection on cluster nodes" "Internal Dependency"
        gpuOperator = softwareSystem "NVIDIA GPU Operator" "GPU runtime, drivers, device plugin" "Internal Dependency"
        mariadb = softwareSystem "MariaDB Operator" "Optional database backend for TrustyAI" "Internal Dependency"

        // External Systems
        openshift = softwareSystem "OpenShift" "Target platform for OLM-based deployment (4.19.9+)" "External"
        kubernetes = softwareSystem "Kubernetes" "Target platform for non-OpenShift deployment (1.28+)" "External"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager for operator subscriptions" "External"
        registries = softwareSystem "Container Registries" "registry.redhat.io, quay.io — operator image hosting" "External"
        cloudAPIs = softwareSystem "Cloud Provider APIs" "Azure, CoreWeave, AWS infrastructure management" "External"
        argocd = softwareSystem "ArgoCD / Flux" "Optional GitOps continuous delivery" "External"

        // Relationships
        admin -> odhGitops "Deploys platform using kubectl/helm/ArgoCD"
        admin -> kustomizeLayer "kubectl apply -k" "HTTPS/6443"
        admin -> rhaiOCPChart "helm install" "HTTPS/6443"
        admin -> rhaiXKSChart "helm install" "HTTPS/6443"

        odhGitops -> rhodsOperator "Installs and configures via OLM Subscription / Helm Deployment"
        odhGitops -> certManager "Installs via OLM Subscription / Helm Sub-chart"
        odhGitops -> kueue "Installs via OLM Subscription + Kueue CR"
        odhGitops -> lws "Installs via OLM Subscription / Helm Sub-chart"
        odhGitops -> jobset "Installs via OLM Subscription + JobSetOperator CR"
        odhGitops -> kuadrant "Installs via OLM Subscription + Kuadrant/Authorino CRs"
        odhGitops -> istioSail "Installs via OLM Subscription / Helm Sub-chart"
        odhGitops -> gatewayAPI "Installs CRDs via Helm Sub-chart"
        odhGitops -> coo "Installs via OLM Subscription"
        odhGitops -> otel "Installs via OLM Subscription"
        odhGitops -> tempo "Installs via OLM Subscription"
        odhGitops -> keda "Installs via OLM Subscription"
        odhGitops -> nfd "Installs via OLM Subscription + NFD CR"
        odhGitops -> gpuOperator "Installs via OLM Subscription + ClusterPolicy CR"
        odhGitops -> mariadb "Installs via OLM Subscription (optional)"

        kustomizeLayer -> olm "Creates OLM Subscriptions" "gRPC/50051"
        rhaiOCPChart -> olm "Creates OLM Subscriptions" "gRPC/50051"
        rhaiXKSChart -> kubernetes "Direct deployment (no OLM)" "HTTPS/6443"
        rhaiXKSChart -> cloudAPIs "Cloud infrastructure management" "HTTPS/443"

        rhaiXKSChart -> depCharts "Includes as Helm dependencies"

        olm -> registries "Pulls operator images" "HTTPS/443"
        odhGitops -> openshift "Deploys on OpenShift 4.19.9+" "HTTPS/6443"
        odhGitops -> kubernetes "Deploys on Kubernetes 1.28+" "HTTPS/6443"
        odhGitops -> argocd "Optional GitOps delivery"

        client -> odhGitops "Inference requests via Gateway" "HTTPS/443"

        cicd -> openshift "Provisions ephemeral HyperShift clusters"
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
            element "Internal Dependency" {
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
