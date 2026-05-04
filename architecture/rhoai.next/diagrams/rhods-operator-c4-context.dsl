workspace {
    model {
        admin = person "Platform Admin" "Manages RHOAI platform via DSC/DSCI CRDs"
        datascientist = person "Data Scientist" "Uses AI/ML platform components"

        rhodsOperator = softwareSystem "RHODS Operator" "Central platform operator managing the complete lifecycle of Red Hat OpenShift AI" {
            manager = container "manager" "Main operator binary managing DSC, DSCI, all component controllers, service controllers, and webhooks" "Go Operator (controller-runtime)"
            cloudmanager = container "cloudmanager" "Cloud infrastructure manager for non-OpenShift platforms (Azure AKS, CoreWeave)" "Go Operator (controller-runtime)"
            dsciController = container "DSCInitialization Controller" "Manages platform initialization: namespaces, NetworkPolicies, Auth/Gateway/Monitoring CRs" "Controller"
            dscController = container "DataScienceCluster Controller" "Orchestrates component lifecycle: creates/removes component CRs based on DSC spec" "Controller"
            gatewayController = container "Gateway Controller" "Deploys platform ingress: Gateway API, Envoy, EnvoyFilter, kube-auth-proxy, DestinationRules" "Controller"
            authController = container "Auth Controller" "Manages platform RBAC: Roles, ClusterRoles, RoleBindings for admin and allowed groups" "Controller"
            monitoringController = container "Monitoring Controller" "Deploys observability stack: Prometheus, Thanos, OTel, Tempo, Perses" "Controller"
            componentControllers = container "Component Controllers (16)" "Individual controllers for Dashboard, KServe, Kueue, Ray, TrustyAI, ModelRegistry, etc." "Controllers"
            webhooks = container "Admission Webhooks" "Validation and mutation for DSC, DSCI, HardwareProfile, notebooks, InferenceService" "Go Webhook Server"
        }

        gatewayInfra = softwareSystem "Gateway Infrastructure" "Platform ingress stack deployed by Gateway Controller" {
            envoyProxy = container "Envoy Proxy (Gateway)" "Gateway API data plane handling TLS termination and routing" "Envoy"
            kubeAuthProxy = container "kube-auth-proxy" "Centralized OAuth2/OIDC authentication proxy" "Go Service"
            envoyFilter = container "EnvoyFilter" "ext_authz integration for authentication enforcement" "Istio CRD"
            httpRoutes = container "HTTPRoutes" "Per-component routing rules" "Gateway API CRD"
        }

        monitoringInfra = softwareSystem "Monitoring Infrastructure" "Observability stack deployed by Monitoring Controller" {
            prometheus = container "MonitoringStack (Prometheus)" "Metrics collection and alerting" "Prometheus"
            thanos = container "ThanosQuerier" "Federated metrics queries" "Thanos"
            otelCollector = container "OpenTelemetry Collector" "Metrics and trace collection with TargetAllocator" "OTel"
            tempo = container "Tempo" "Distributed tracing backend" "Grafana Tempo"
            perses = container "Perses" "Monitoring visualization dashboards" "Perses"
        }

        # Managed Components (deployed by operator)
        dashboard = softwareSystem "Dashboard" "ODH Dashboard for platform management UI" "RHOAI Component"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "RHOAI Component"
        kueue = softwareSystem "Kueue" "Job queuing and resource management" "RHOAI Component"
        ray = softwareSystem "KubeRay" "Ray distributed computing operator" "RHOAI Component"
        trustyai = softwareSystem "TrustyAI" "AI explainability and LMEval" "RHOAI Component"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata registry" "RHOAI Component"
        trainingOperator = softwareSystem "Training Operator" "Kubeflow Training Operator" "RHOAI Component"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration (DSPO)" "RHOAI Component"
        workbenches = softwareSystem "Workbenches" "Notebook controllers and images" "RHOAI Component"

        # External Dependencies
        istio = softwareSystem "Istio/Sail Operator" "Service mesh for traffic management and mTLS" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External"
        coo = softwareSystem "Cluster Observability Operator" "Prometheus-based metrics platform (MonitoringStack, ThanosQuerier)" "External"
        otelOperator = softwareSystem "OpenTelemetry Operator" "OTel Collector and Instrumentation management" "External"
        tempoOperator = softwareSystem "Tempo Operator" "Distributed tracing backend management" "External"
        persesOperator = softwareSystem "Perses Operator" "Monitoring dashboard management" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "Integrated OAuth authentication" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller for Routes" "External"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager for installation and upgrades" "External"
        kuadrant = softwareSystem "Kuadrant" "API gateway policies for Models-as-a-Service" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for all controller operations" "External"

        # Relationships - Admin
        admin -> rhodsOperator "Creates DSCInitialization and DataScienceCluster CRDs via kubectl"
        datascientist -> dashboard "Manages notebooks, models, pipelines via UI"
        datascientist -> gatewayInfra "Accesses platform components via HTTPS/443"

        # Operator → Infrastructure
        rhodsOperator -> gatewayInfra "Deploys and manages Gateway API, Envoy, auth proxy" "CRD Create"
        rhodsOperator -> monitoringInfra "Deploys and manages Prometheus, Thanos, OTel, Tempo, Perses" "CRD Create"

        # Operator → Components
        rhodsOperator -> dashboard "Deploys operator manifests, creates CR" "CRD Watch + Manifest Deploy"
        rhodsOperator -> kserve "Deploys operator manifests, creates CR" "CRD Watch + Manifest Deploy"
        rhodsOperator -> kueue "Deploys operator manifests, creates CR" "CRD Watch + Manifest Deploy"
        rhodsOperator -> ray "Deploys operator manifests, creates CR" "CRD Watch + Manifest Deploy"
        rhodsOperator -> trustyai "Deploys operator manifests, creates CR" "CRD Watch + Manifest Deploy"
        rhodsOperator -> modelRegistry "Deploys operator manifests, creates CR" "CRD Watch + Manifest Deploy"
        rhodsOperator -> trainingOperator "Deploys operator manifests, creates CR" "CRD Watch + Manifest Deploy"
        rhodsOperator -> dsPipelines "Deploys operator manifests, creates CR" "CRD Watch + Manifest Deploy"
        rhodsOperator -> workbenches "Deploys operator manifests, creates CR" "CRD Watch + Manifest Deploy"

        # Operator → External Dependencies
        rhodsOperator -> istio "Creates EnvoyFilter, DestinationRule CRs" "CRD Create"
        rhodsOperator -> k8sAPI "All controller reconciliation" "HTTPS/443"
        rhodsOperator -> olm "Watches Subscription, CSV, InstallPlan" "CRD Watch"
        rhodsOperator -> openshiftOAuth "Creates OAuthClient CR" "CRD Create"
        rhodsOperator -> openshiftRouter "Creates Routes for redirects and callbacks" "CRD Create"
        rhodsOperator -> coo "Creates MonitoringStack, ThanosQuerier CRDs" "CRD Create"
        rhodsOperator -> otelOperator "Creates OpenTelemetryCollector, Instrumentation CRDs" "CRD Create"
        rhodsOperator -> tempoOperator "Creates TempoMonolithic/TempoStack CRDs" "CRD Create"
        rhodsOperator -> persesOperator "Creates Perses, PersesDatasource, PersesDashboard CRDs" "CRD Create"

        # Cloudmanager → External
        cloudmanager -> certManager "Deploys via Helm charts on non-OpenShift" "Helm"
        cloudmanager -> istio "Deploys Sail via Helm charts on non-OpenShift" "Helm"

        # Gateway Infrastructure → External
        kubeAuthProxy -> openshiftOAuth "OAuth2 token exchange" "HTTPS/443"
        envoyProxy -> kubeAuthProxy "ext_authz check" "HTTPS/8443"
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

        container gatewayInfra "GatewayInfrastructure" {
            include *
            autoLayout
        }

        container monitoringInfra "MonitoringInfrastructure" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "RHOAI Component" {
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
