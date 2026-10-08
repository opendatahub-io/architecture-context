workspace {
    model {
        clusterAdmin = person "Cluster Admin" "Configures and manages the RHOAI platform via DSC/DSCI custom resources"
        dataScienceUser = person "Data Science User" "Accesses platform services (Dashboard, Notebooks, Model Serving) via browser"

        rhodsOperator = softwareSystem "rhods-operator" "Central platform operator for Red Hat OpenShift AI — orchestrates deployment, configuration, and lifecycle of the entire AI/ML platform stack" {
            manager = container "Manager" "Primary operator binary running all platform controllers (DSC, DSCI, Gateway, Auth, Monitoring, Module, Component)" "Go Operator (controller-runtime)" "Component"
            cloudmanager = container "CloudManager" "Secondary binary for multi-cloud Kubernetes engine provisioning (AWS EKS, Azure AKS, CoreWeave)" "Go CLI (Cobra)" "Component"
            webhookServer = container "Webhook Server" "Validates and mutates DSC, DSCI, HardwareProfile, AcceleratorProfile, and PodMonitor CRs" "Go (controller-runtime webhook)" "Component"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics over TLS with authentication" "Go (prometheus/client_golang)" "Component"
            kubeAuthProxy = container "kube-auth-proxy" "OIDC authentication proxy deployed per-component for platform ingress" "Go Deployment (dynamic)" "Component"
            moduleReconciler = container "Module Reconciler" "Renders and deploys external operator manifests from /opt/manifests-template using kustomize/Helm with RELATED_IMAGE overrides" "Go (sigs.k8s.io/kustomize)" "Component"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for all controller operations" "External"
        openshiftAPI = softwareSystem "OpenShift API" "OpenShift extensions: Routes, OAuth, Console, ImageStreams, TLS profiles" "External"
        istioEnvoy = softwareSystem "Istio / Envoy" "Service mesh for traffic routing, mTLS enforcement, and auth header injection" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for platform ingress (data-science-gateway)" "External"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management for non-OpenShift clusters" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Monitoring CRD management (PodMonitor, PrometheusRule)" "External"

        kserve = softwareSystem "KServe" "Model serving platform (InferenceService)" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model metadata registry (modelregistry.opendatahub.io)" "Internal RHOAI"
        feast = softwareSystem "Feast" "Feature store platform (feast.dev)" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for the AI/ML platform" "Internal RHOAI"
        pipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration (uses Argo CRDs)" "Internal RHOAI"
        platformUtils = softwareSystem "odh-platform-utilities" "Platform detection, manifest rendering, deployment helpers" "Internal RHOAI"

        # Relationships
        clusterAdmin -> rhodsOperator "Applies DSC/DSCI CRs via kubectl" "HTTPS/6443"
        dataScienceUser -> rhodsOperator "Accesses platform via Gateway" "HTTPS/443"

        rhodsOperator -> kubernetesAPI "All controller operations (watch, CRUD)" "HTTPS/6443"
        rhodsOperator -> openshiftAPI "Route, OAuth, Console, TLS profile reads" "HTTPS/6443"
        rhodsOperator -> istioEnvoy "Creates EnvoyFilter, DestinationRule for traffic shaping" "Config push"
        rhodsOperator -> gatewayAPI "Creates Gateway, HTTPRoute for platform ingress" "HTTPS/443"
        rhodsOperator -> certManager "Certificate lifecycle (conditional)" "HTTPS/6443"
        rhodsOperator -> prometheusOperator "Manages PodMonitor, PrometheusRule" "HTTPS/6443"

        rhodsOperator -> kserve "Watches InferenceService state" "HTTPS/6443"
        rhodsOperator -> modelRegistry "Manages ModelRegistry instances" "HTTPS/6443"
        rhodsOperator -> feast "Watches FeatureStore instances" "HTTPS/6443"

        dashboard -> rhodsOperator "Managed by module reconciler"
        pipelines -> rhodsOperator "Uses prefetched Argo CRDs"

        manager -> webhookServer "Registers webhook handlers"
        manager -> metricsServer "Serves Prometheus metrics"
        manager -> moduleReconciler "Triggers module deployment"
        manager -> kubeAuthProxy "Deploys per-component auth proxies"
    }

    views {
        systemContext rhodsOperator "SystemContext" {
            include *
            autoLayout
        }

        container rhodsOperator "Containers" {
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
            element "Component" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
