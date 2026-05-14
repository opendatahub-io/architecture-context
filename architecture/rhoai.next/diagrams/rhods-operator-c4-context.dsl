workspace {
    model {
        admin = person "Platform Admin" "Configures and manages the RHOAI platform via DSC/DSCI CRs"
        datascientist = person "Data Scientist" "Uses platform components for AI/ML workflows"

        rhodsOperator = softwareSystem "RHODS Operator" "Central platform operator managing the complete lifecycle of Red Hat OpenShift AI" {
            manager = container "manager" "Main operator binary managing DSC, DSCI, all component and service controllers, and webhooks" "Go Operator (controller-runtime)"
            cloudmanager = container "cloudmanager" "Cloud infrastructure manager for non-OpenShift platforms (Azure AKS, CoreWeave)" "Go Operator (controller-runtime)"

            dsciController = container "DSCInitialization Controller" "Manages platform initialization: namespaces, monitoring, auth, gateway" "Controller"
            dscController = container "DataScienceCluster Controller" "Orchestrates component lifecycle via component CRs" "Controller"

            gatewayController = container "Gateway Controller" "Deploys platform ingress: Gateway API, Envoy, auth proxy, routes" "Controller"
            authController = container "Auth Controller" "Manages platform RBAC: roles, bindings, groups" "Controller"
            monitoringController = container "Monitoring Controller" "Deploys observability: Prometheus, Thanos, OTel, Tempo, Perses" "Controller"
            certController = container "CertConfigMapGenerator" "Distributes trusted CA bundles across user namespaces" "Controller"

            componentControllers = container "Component Controllers (16)" "Individual controllers for Dashboard, KServe, Kueue, Ray, TrustyAI, ModelRegistry, TrainingOperator, Trainer, DSP, Feast, LlamaStack, MLflow, Spark, MaaS, ModelController, Workbenches" "Controllers"

            webhooks = container "Admission Webhooks" "14 webhooks: validation, mutation, conversion for DSC, DSCI, notebooks, ISVCs, HardwareProfiles" "Webhook Server"

            envoyGateway = container "Envoy Gateway" "Platform ingress data plane with TLS termination and auth enforcement" "Envoy Proxy"
            kubeAuthProxy = container "kube-auth-proxy" "Centralized OAuth2/OIDC authentication proxy" "Go Service"
        }

        // Internal Platform Dependencies
        istio = softwareSystem "Istio / Sail Operator" "Service mesh: EnvoyFilter for auth, DestinationRule for mTLS" "Internal Platform"
        certManager = softwareSystem "cert-manager Operator" "TLS certificate management (cloudmanager deploys on non-OpenShift)" "Internal Platform"
        coo = softwareSystem "Cluster Observability Operator" "Prometheus-based metrics via MonitoringStack/ThanosQuerier CRDs" "Internal Platform"
        otelOperator = softwareSystem "OpenTelemetry Operator" "Metrics and trace collection via OpenTelemetryCollector CRDs" "Internal Platform"
        tempoOperator = softwareSystem "Tempo Operator" "Distributed tracing backend via TempoMonolithic/TempoStack CRDs" "Internal Platform"
        persesOperator = softwareSystem "Perses Operator" "Monitoring visualization via Perses/PersesDatasource/PersesDashboard CRDs" "Internal Platform"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager for installation and upgrades" "Internal Platform"

        // Managed Components (deployed by operator)
        dashboard = softwareSystem "Dashboard" "RHOAI web UI" "Managed Component"
        kserve = softwareSystem "KServe" "Serverless ML inference" "Managed Component"
        kueue = softwareSystem "Kueue" "Job queuing system" "Managed Component"
        ray = softwareSystem "KubeRay" "Ray distributed computing" "Managed Component"
        trustyai = softwareSystem "TrustyAI" "AI explainability and LMEval" "Managed Component"
        modelRegistry = softwareSystem "Model Registry" "Model metadata storage" "Managed Component"
        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Managed Component"
        workbenches = softwareSystem "Workbenches" "Notebook environments" "Managed Component"

        // External Dependencies
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "Integrated OAuth authentication" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller for Routes" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for all reconciliation" "External"

        // Relationships
        admin -> rhodsOperator "Manages platform via DSC/DSCI CRs" "kubectl/oc"
        datascientist -> rhodsOperator "Accesses platform via Gateway" "HTTPS/443"

        rhodsOperator -> istio "Creates EnvoyFilter, DestinationRule CRs" "CRD"
        rhodsOperator -> certManager "Deploys via Helm (cloudmanager)" "Helm"
        rhodsOperator -> coo "Creates MonitoringStack, ThanosQuerier CRs" "CRD"
        rhodsOperator -> otelOperator "Creates OpenTelemetryCollector, Instrumentation CRs" "CRD"
        rhodsOperator -> tempoOperator "Creates TempoMonolithic/TempoStack CRs" "CRD"
        rhodsOperator -> persesOperator "Creates Perses, PersesDatasource, PersesDashboard CRs" "CRD"
        rhodsOperator -> olm "Managed by OLM for lifecycle" "Subscription/CSV"

        rhodsOperator -> dashboard "Deploys and manages via kustomize manifests" "CRD Watch + Manifest Deploy"
        rhodsOperator -> kserve "Deploys and manages via kustomize manifests" "CRD Watch + Manifest Deploy"
        rhodsOperator -> kueue "Deploys and manages via kustomize manifests" "CRD Watch + Manifest Deploy"
        rhodsOperator -> ray "Deploys and manages via kustomize manifests" "CRD Watch + Manifest Deploy"
        rhodsOperator -> trustyai "Deploys and manages via kustomize manifests" "CRD Watch + Manifest Deploy"
        rhodsOperator -> modelRegistry "Deploys and manages via kustomize manifests" "CRD Watch + Manifest Deploy"
        rhodsOperator -> dsp "Deploys and manages via kustomize manifests" "CRD Watch + Manifest Deploy"
        rhodsOperator -> workbenches "Deploys and manages via kustomize manifests" "CRD Watch + Manifest Deploy"

        rhodsOperator -> openshiftOAuth "OAuth2 token exchange" "HTTPS/443"
        rhodsOperator -> openshiftRouter "Creates Routes for ingress and redirects" "Route CRs"
        rhodsOperator -> k8sAPI "All controller reconciliation" "HTTPS/443"
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
            element "Internal Platform" {
                background #438dd5
                color #ffffff
            }
            element "Managed Component" {
                background #7ed321
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
