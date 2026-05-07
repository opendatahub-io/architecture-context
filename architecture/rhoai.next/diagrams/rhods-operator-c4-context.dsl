workspace {
    model {
        admin = person "Platform Admin" "Installs and configures the RHOAI platform via DSC/DSCI CRs"
        datascientist = person "Data Scientist" "Uses AI/ML platform services via the Gateway"

        rhodsOperator = softwareSystem "RHODS Operator" "Central platform operator managing the complete lifecycle of Red Hat OpenShift AI" {
            manager = container "manager" "Main operator binary managing DSC, DSCI, all component controllers, service controllers, and webhooks" "Go Operator (controller-runtime)"
            cloudmanager = container "cloudmanager" "Cloud infrastructure manager for non-OpenShift platforms (Azure AKS, CoreWeave)" "Go Operator (controller-runtime)"

            gatewayController = container "Gateway Controller" "Deploys and manages platform ingress stack: Gateway API, Envoy, auth proxy, EnvoyFilter, DestinationRules, NetworkPolicies" "Go Controller"
            authController = container "Auth Controller" "Manages platform RBAC: Roles, ClusterRoles, RoleBindings for admin and allowed groups" "Go Controller"
            monitoringController = container "Monitoring Controller" "Deploys observability stack: Prometheus, Thanos, OTel, Tempo, Perses" "Go Controller"
            certConfigMapGen = container "CertConfigMapGenerator" "Distributes trusted CA bundle ConfigMaps across user namespaces" "Go Controller"
            componentControllers = container "Component Controllers" "16 individual controllers for AI/ML components (Dashboard, KServe, Kueue, Ray, etc.)" "Go Controllers"

            webhooks = container "Admission Webhooks" "Validation and mutation for DSC, DSCI, HardwareProfile, notebooks, InferenceService" "Go Webhook Server"
            kubeAuthProxy = container "kube-auth-proxy" "OAuth2/OIDC authentication proxy for platform Gateway" "Go Service"
            envoyProxy = container "Envoy Proxy" "Data plane for Gateway API with EnvoyFilter ext_authz" "Envoy"
        }

        // External systems
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for all controller reconciliation" "External Infrastructure"
        istio = softwareSystem "Istio / Sail Operator" "Service mesh for EnvoyFilter and DestinationRule management" "External Operator"
        certManager = softwareSystem "cert-manager Operator" "TLS certificate management (cloudmanager on XKS)" "External Operator"
        coo = softwareSystem "Cluster Observability Operator" "Prometheus-based metrics via MonitoringStack CRD" "External Operator"
        otelOperator = softwareSystem "OpenTelemetry Operator" "Metrics and trace collection via OpenTelemetryCollector CRD" "External Operator"
        tempoOperator = softwareSystem "Tempo Operator" "Distributed tracing backend via TempoMonolithic CRD" "External Operator"
        persesOperator = softwareSystem "Perses Operator" "Monitoring visualization dashboards" "External Operator"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager for installation and upgrades" "External Infrastructure"
        oauthServer = softwareSystem "OpenShift OAuth Server" "Integrated OAuth authentication" "External Infrastructure"
        oidcProvider = softwareSystem "External OIDC Provider" "External OIDC authentication (optional)" "External Service"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress for Routes, OAuth callbacks, legacy redirects" "External Infrastructure"
        gatewayAPI = softwareSystem "Gateway API" "Gateway API implementation (envoy-gateway / openshift)" "External Infrastructure"

        // Managed components
        dashboard = softwareSystem "Dashboard" "RHOAI web UI" "Managed Component"
        kserve = softwareSystem "KServe" "Model serving platform" "Managed Component"
        kueue = softwareSystem "Kueue" "Job queuing system" "Managed Component"
        ray = softwareSystem "Ray / KubeRay" "Distributed computing" "Managed Component"
        trustyai = softwareSystem "TrustyAI" "AI explainability" "Managed Component"
        modelRegistry = softwareSystem "Model Registry" "Model metadata storage" "Managed Component"
        trainingOperator = softwareSystem "Training Operator" "ML training jobs" "Managed Component"
        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Managed Component"
        workbenches = softwareSystem "Workbenches" "Notebook environments" "Managed Component"
        otherComponents = softwareSystem "Other Components" "Feast, LlamaStack, MLflow, Spark, MaaS, Trainer, ModelController" "Managed Component"

        // Relationships
        admin -> rhodsOperator "Creates DSC/DSCI CRs via kubectl" "HTTPS/443"
        datascientist -> envoyProxy "Accesses platform services" "HTTPS/443"

        rhodsOperator -> k8sAPI "All controller reconciliation" "HTTPS/443"
        rhodsOperator -> istio "Creates EnvoyFilter, DestinationRule" "CRD"
        rhodsOperator -> coo "Creates MonitoringStack, ThanosQuerier" "CRD"
        rhodsOperator -> otelOperator "Creates OpenTelemetryCollector" "CRD"
        rhodsOperator -> tempoOperator "Creates TempoMonolithic" "CRD"
        rhodsOperator -> persesOperator "Creates Perses dashboards" "CRD"
        rhodsOperator -> gatewayAPI "Creates Gateway, GatewayClass, HTTPRoute" "CRD"

        cloudmanager -> certManager "Deploys via Helm on XKS" "Helm"
        cloudmanager -> istio "Deploys Sail via Helm on XKS" "Helm"

        kubeAuthProxy -> oauthServer "OAuth2 token exchange" "HTTPS/443"
        kubeAuthProxy -> oidcProvider "OIDC token validation" "HTTPS/443"
        kubeAuthProxy -> k8sAPI "TokenReview, SubjectAccessReview" "HTTPS/443"

        envoyProxy -> kubeAuthProxy "ext_authz authentication" "HTTPS/8443"

        componentControllers -> dashboard "Deploys manifests" "CRD Watch + Apply"
        componentControllers -> kserve "Deploys manifests" "CRD Watch + Apply"
        componentControllers -> kueue "Deploys manifests" "CRD Watch + Apply"
        componentControllers -> ray "Deploys manifests" "CRD Watch + Apply"
        componentControllers -> trustyai "Deploys manifests" "CRD Watch + Apply"
        componentControllers -> modelRegistry "Deploys manifests" "CRD Watch + Apply"
        componentControllers -> trainingOperator "Deploys manifests" "CRD Watch + Apply"
        componentControllers -> dsp "Deploys manifests" "CRD Watch + Apply"
        componentControllers -> workbenches "Deploys manifests" "CRD Watch + Apply"
        componentControllers -> otherComponents "Deploys manifests" "CRD Watch + Apply"

        olm -> rhodsOperator "Manages operator lifecycle" "Subscription/CSV"
        openshiftRouter -> envoyProxy "Routes external traffic" "HTTPS/443"
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
            element "External Infrastructure" {
                background #999999
                color #ffffff
            }
            element "External Operator" {
                background #b8b8b8
                color #ffffff
            }
            element "External Service" {
                background #cccccc
                color #333333
            }
            element "Managed Component" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
