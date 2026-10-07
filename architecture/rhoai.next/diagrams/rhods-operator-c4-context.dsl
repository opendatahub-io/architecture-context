workspace {
    model {
        admin = person "Platform Admin" "Configures RHOAI platform via DSCInitialization, DataScienceCluster, GatewayConfig, and Auth CRs"
        dataScientist = person "Data Scientist" "Accesses AI/ML platform components via the platform gateway"

        rhodsOperator = softwareSystem "rhods-operator" "Central RHOAI platform operator — orchestrates component lifecycle, ingress infrastructure, authentication, and RBAC" {
            manager = container "manager" "Primary operator binary running DSCInitialization, DataScienceCluster, module, and service controllers" "Go Operator (controller-runtime)"
            cloudmanager = container "cloudmanager" "Cloud infrastructure management CLI for AWS EKS, Azure AKE, CoreWeave" "Go CLI (Cobra)"
            webhookServer = container "Webhook Server" "Validates, mutates, and converts CRDs (DSC, DSCI, Platform, Auth, HardwareProfile)" "Go (controller-runtime webhooks)" "9443/TCP"
            metricsEndpoint = container "Metrics Endpoint" "Prometheus metrics with TLS and Kubernetes auth" "Go (prometheus/client_golang)" "8443/TCP"
            kubeAuthProxy = container "kube-auth-proxy" "OIDC/OAuth authentication proxy deployed dynamically by gateway controller" "Go (oauth2-proxy)" "HTTPS"
            manifestRenderer = container "Manifest Renderer" "Renders component kustomize/Helm manifests from /opt/manifests at runtime" "Go (kustomize/api, renderer-helm)"
        }

        # Internal RHOAI Components (managed by operator)
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science projects" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML model inference platform" "Internal RHOAI"
        ray = softwareSystem "Ray" "Distributed computing framework" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queueing and resource management" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI model explainability and fairness" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata catalog" "Internal RHOAI"
        workbenches = softwareSystem "Workbenches" "Jupyter notebook environments" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "ML experiment tracking (module)" "Internal RHOAI"

        # External Dependencies
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for all resource operations" "External"
        istio = softwareSystem "Istio" "Service mesh — EnvoyFilter, DestinationRule for traffic shaping" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for ingress management" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management (conditional)" "External"
        serviceCA = softwareSystem "OpenShift service-ca" "Automatic TLS certificate provisioning via annotations" "External"
        prometheusOp = softwareSystem "prometheus-operator" "Monitoring CRD management" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "Integrated OAuth server for authentication" "External"
        oidcProvider = softwareSystem "OIDC Identity Provider" "External identity provider for user authentication" "External"

        # Relationships - Admin
        admin -> rhodsOperator "Configures platform via kubectl (DSC, DSCI, GatewayConfig, Auth CRs)" "HTTPS/6443"
        dataScientist -> kubeAuthProxy "Accesses platform via browser" "HTTPS/443"

        # Operator -> Components (deploys)
        manager -> dashboard "Deploys via kustomize manifests"
        manager -> kserve "Deploys via kustomize manifests"
        manager -> ray "Deploys via kustomize manifests"
        manager -> kueue "Deploys via kustomize manifests"
        manager -> trustyai "Deploys via kustomize manifests"
        manager -> modelRegistry "Deploys via kustomize manifests"
        manager -> workbenches "Deploys via kustomize manifests"
        manager -> mlflow "Deploys via Helm chart rendering"

        # Operator -> External
        manager -> k8sAPI "CRUD on CRDs, RBAC, Deployments, Secrets" "HTTPS/6443"
        manager -> istio "Creates EnvoyFilter, DestinationRule (conditional)" "HTTPS/6443"
        manager -> gatewayAPI "Creates Gateway, GatewayClass, HTTPRoute" "HTTPS/6443"
        manager -> certManager "Creates Certificate resources (XKS mode)" "HTTPS/6443"
        manager -> prometheusOp "Creates PodMonitor, PrometheusRule, ServiceMonitor" "HTTPS/6443"
        manager -> openshiftOAuth "Creates OAuthClient CR (OpenShift mode)" "HTTPS/6443"

        # kube-auth-proxy flows
        kubeAuthProxy -> oidcProvider "Authenticates users via OIDC" "HTTPS/443"
        kubeAuthProxy -> k8sAPI "Validates tokens via TokenReview" "HTTPS/6443"
        kubeAuthProxy -> dashboard "Forwards authenticated requests"
        kubeAuthProxy -> kserve "Forwards authenticated requests"

        # Cert providers
        serviceCA -> webhookServer "Provisions TLS certificates via annotations"
        serviceCA -> metricsEndpoint "Provisions TLS certificates via annotations"

        # Internal container relationships
        manager -> webhookServer "Hosts webhook handlers"
        manager -> metricsEndpoint "Exposes Prometheus metrics"
        manager -> manifestRenderer "Renders component manifests"
        manager -> kubeAuthProxy "Deploys and configures dynamically"
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
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
