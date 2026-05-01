workspace {
    model {
        clusterAdmin = person "Cluster Admin" "Manages RHOAI platform via DSCInitialization and DataScienceCluster CRs"
        dataScientist = person "Data Scientist" "Uses data science components (Dashboard, Workbenches, KServe, Pipelines) via Gateway"

        rhodsOperator = softwareSystem "rhods-operator" "Central platform operator managing full lifecycle of Red Hat OpenShift AI - 16 data science components, ingress, monitoring, auth, RBAC" {
            manager = container "manager" "Main operator binary running all controllers" "Go Operator (controller-runtime)"
            cloudmanager = container "cloudmanager" "Cloud infrastructure management CLI" "Go CLI"
            dsciController = container "DSCInitialization Controller" "Provisions platform infrastructure: namespaces, networking, monitoring, auth, gateway" "Go Controller"
            dscController = container "DataScienceCluster Controller" "Manages component CRs lifecycle and status aggregation" "Go Controller"
            gatewayController = container "Gateway Controller" "Deploys full ingress stack: Gateway API, kube-auth-proxy, EnvoyFilter, Routes" "Go Controller"
            authController = container "Auth Controller" "Manages platform RBAC: admin/allowed groups, namespace roles" "Go Controller"
            monitoringController = container "Monitoring Controller" "Deploys MonitoringStack, ThanosQuerier, Tempo, OTEL, Perses" "Go Controller"
            componentRegistry = container "Component Registry" "Plugin registry for 16 component handlers" "Go Framework"
            serviceRegistry = container "Service Registry" "Plugin registry for 5 service handlers" "Go Framework"
            webhookServer = container "Webhook Server" "Mutating and validating admission webhooks" "Go Service" "9443/TCP HTTPS"
        }

        kubeAuthProxy = softwareSystem "kube-auth-proxy" "OAuth2/OIDC authentication proxy for Gateway" "Internal"
        gatewayAPI = softwareSystem "Gateway API (Envoy)" "Kubernetes Gateway API ingress with Envoy data plane" "Internal"

        # Data Science Components (managed by operator)
        dashboard = softwareSystem "Dashboard" "RHOAI Dashboard UI" "Managed Component"
        kserve = softwareSystem "KServe" "Model serving platform" "Managed Component"
        kueue = softwareSystem "Kueue" "Job queuing system" "Managed Component"
        workbenches = softwareSystem "Workbenches" "Jupyter notebook environments" "Managed Component"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata registry" "Managed Component"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Managed Component"
        trustyAI = softwareSystem "TrustyAI" "AI explainability and bias detection" "Managed Component"
        ray = softwareSystem "Ray" "Distributed computing" "Managed Component"
        trainingOperator = softwareSystem "Training Operator" "Kubeflow Training Operator" "Managed Component"
        trainer = softwareSystem "Trainer" "Kubeflow Trainer" "Managed Component"
        feast = softwareSystem "Feast Operator" "Feature store" "Managed Component"
        llamaStack = softwareSystem "LlamaStack Operator" "LlamaStack operator" "Managed Component"
        mlflow = softwareSystem "MLflow Operator" "Experiment tracking" "Managed Component"
        modelController = softwareSystem "Model Controller" "Model controller (KServe dependency)" "Managed Component"
        maas = softwareSystem "Models-as-a-Service" "MaaS Tenant management" "Managed Component"
        spark = softwareSystem "Spark Operator" "Apache Spark operator" "Managed Component"

        # External Dependencies
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management" "External"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for traffic management and mTLS" "External"
        oauthServer = softwareSystem "OpenShift OAuth Server" "Integrated OAuth2 authentication" "External"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager for installation and versioning" "External"
        certManager = softwareSystem "cert-manager" "Certificate management (optional, xKS)" "External"
        monitoringStackOp = softwareSystem "MonitoringStack Operator" "Prometheus-compatible monitoring deployment" "External"
        tempoOperator = softwareSystem "Tempo Operator" "Distributed tracing storage" "External"
        otelOperator = softwareSystem "OpenTelemetry Operator" "Trace collection and export" "External"
        persesOperator = softwareSystem "Perses Operator" "Observability dashboards" "External"
        kueueOperator = softwareSystem "Kueue Operator" "Job queue management dependency" "External"
        jobsetOperator = softwareSystem "JobSet Operator" "JobSet CRD dependency for Trainer" "External"
        kuadrant = softwareSystem "Kuadrant" "API management namespace RBAC" "External"

        # Relationships - Admin
        clusterAdmin -> rhodsOperator "Creates DSCInitialization and DataScienceCluster CRs via kubectl/oc"
        dataScientist -> gatewayAPI "Accesses data science services via HTTPS/443"

        # Relationships - Operator internals
        dsciController -> k8sAPI "Creates namespaces, network policies, CA bundles" "HTTPS/6443"
        dscController -> k8sAPI "Creates/manages component CRs, aggregates status" "HTTPS/6443"
        gatewayController -> gatewayAPI "Creates Gateway, GatewayClass, HTTPRoute" "CRD Create"
        gatewayController -> kubeAuthProxy "Deploys and configures auth proxy" "CRD Create"
        gatewayController -> istio "Creates EnvoyFilter, DestinationRule" "CRD Create"
        authController -> k8sAPI "Manages Roles, RoleBindings, ClusterRoles" "HTTPS/6443"
        monitoringController -> monitoringStackOp "Creates MonitoringStack CR" "CRD Create"
        monitoringController -> tempoOperator "Creates TempoMonolithic/TempoStack CR" "CRD Create"
        monitoringController -> otelOperator "Creates Instrumentation, OTELCollector CR" "CRD Create"
        monitoringController -> persesOperator "Creates Perses, PersesDatasource, PersesDashboard CRs" "CRD Create"
        webhookServer -> k8sAPI "Validates and mutates CRs" "HTTPS/9443"

        # Relationships - External
        rhodsOperator -> oauthServer "Creates OAuthClient for gateway authentication" "HTTPS/443"
        rhodsOperator -> olm "Reads Subscription, CSV for version detection" "API Read"
        rhodsOperator -> certManager "Certificate management for KServe (xKS)" "CRD (optional)"
        kubeAuthProxy -> oauthServer "OAuth2 authentication flow" "HTTPS/443"
        gatewayAPI -> kubeAuthProxy "ext_authz delegation for authentication" "HTTPS/8443"

        # Relationships - Managed Components
        rhodsOperator -> dashboard "Deploys via CRD Watch + Manifest Apply" "Server-Side Apply"
        rhodsOperator -> kserve "Deploys via CRD Watch + Manifest Apply" "Server-Side Apply"
        rhodsOperator -> kueue "Deploys via CRD Watch + Manifest Apply" "Server-Side Apply"
        rhodsOperator -> workbenches "Deploys via CRD Watch + Manifest Apply" "Server-Side Apply"
        rhodsOperator -> modelRegistry "Deploys via CRD Watch + Manifest Apply" "Server-Side Apply"
        rhodsOperator -> dsPipelines "Deploys via CRD Watch + Manifest Apply" "Server-Side Apply"
        rhodsOperator -> trustyAI "Deploys via CRD Watch + Manifest Apply" "Server-Side Apply"
        rhodsOperator -> ray "Deploys via CRD Watch + Manifest Apply" "Server-Side Apply"
        rhodsOperator -> trainingOperator "Deploys via CRD Watch + Manifest Apply" "Server-Side Apply"
        rhodsOperator -> trainer "Deploys via CRD Watch + Manifest Apply" "Server-Side Apply"
        rhodsOperator -> feast "Deploys via CRD Watch + Manifest Apply" "Server-Side Apply"
        rhodsOperator -> llamaStack "Deploys via CRD Watch + Manifest Apply" "Server-Side Apply"
        rhodsOperator -> mlflow "Deploys via CRD Watch + Manifest Apply" "Server-Side Apply"
        rhodsOperator -> modelController "Deploys via CRD Watch + Manifest Apply" "Server-Side Apply"
        rhodsOperator -> maas "Deploys via CRD Watch + Manifest Apply" "Server-Side Apply"
        rhodsOperator -> spark "Deploys via CRD Watch + Manifest Apply" "Server-Side Apply"

        # Dependency checks
        trainer -> jobsetOperator "Requires JobSet CRD" "CRD Watch"
        kserve -> certManager "TLS certificates (xKS)" "CRD (optional)"
        kueue -> kueueOperator "Requires Kueue operator" "CRD Watch"
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
            element "Internal" {
                background #438dd5
                color #ffffff
            }
            element "Managed Component" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
