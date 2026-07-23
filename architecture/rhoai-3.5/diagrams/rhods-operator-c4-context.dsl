workspace {
    model {
        admin = person "Platform Admin" "Manages RHOAI platform via DataScienceCluster and DSCInitialization CRs"
        datascientist = person "Data Scientist" "Uses RHOAI components (Dashboard, Workbenches, Model Serving)"
        securityteam = person "Security Team" "Reviews RBAC, network policies, and auth configuration"

        rhodsOperator = softwareSystem "rhods-operator" "Central platform operator managing lifecycle of all RHOAI components, ingress, auth, and monitoring" {
            manager = container "manager" "Primary operator binary managing all RHOAI components, services, and platform lifecycle" "Go Operator (controller-runtime)"
            cloudmanager = container "cloudmanager" "Cloud-provider-specific operator for AWS/Azure/CoreWeave hosted deployments" "Go CLI (controller-runtime)"
            dscController = container "DSC Controller" "Orchestrates component lifecycle via DAG-based runlevel provisioning" "Controller"
            dsciController = container "DSCI Controller" "Platform initialization: namespaces, auth defaults, gateway config" "Controller"
            gatewayController = container "Gateway Controller" "Deploys RHOAI 3.x ingress stack (Gateway API, kube-auth-proxy, EnvoyFilter)" "Controller"
            authController = container "Auth Controller" "Manages RBAC roles and bindings for admin/allowed groups" "Controller"
            monitoringController = container "Monitoring Controller" "Deploys MonitoringStack, OpenTelemetry, Perses, Tempo, Thanos" "Controller"
            modulesController = container "Modules Controller" "Plugin framework for out-of-tree operator deployment" "Controller"
            componentControllers = container "Component Controllers" "Per-component manifest deployment (18 components)" "Controllers"
            webhooks = container "Admission Webhooks" "Validation and mutation for DSC, DSCI, HardwareProfile, Notebooks, InferenceServices" "Admission Webhooks"
        }

        # Internal RHOAI Components (managed by this operator)
        dashboard = softwareSystem "Dashboard" "RHOAI web UI for data science workspaces" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving runtime with serverless inference" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Workload queue management and scheduling" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model metadata tracking and versioning" "Internal RHOAI"
        workbenches = softwareSystem "Workbenches" "Interactive data science workspaces (Jupyter)" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "ML pipeline infrastructure (Argo Workflows)" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI fairness and bias monitoring" "Internal RHOAI"
        aigateway = softwareSystem "AI Gateway" "AI API gateway (MaaS + BatchGateway)" "Internal RHOAI"
        mlflow = softwareSystem "MLflow Operator" "MLflow experiment tracking" "Internal RHOAI"

        # External Dependencies
        kubeAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        openshiftAPI = softwareSystem "OpenShift API" "Route, OAuth, Config, Infrastructure APIs" "External"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for traffic management and mTLS" "External"
        gatewayAPI = softwareSystem "Gateway API Controller" "Gateway, GatewayClass, HTTPRoute management" "External"
        certManager = softwareSystem "cert-manager" "PKI and certificate lifecycle management" "External"
        oauthProvider = softwareSystem "OAuth/OIDC Provider" "Authentication provider (OpenShift OAuth or external OIDC)" "External"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager for operator deployment" "External"
        coo = softwareSystem "cluster-observability-operator" "MonitoringStack, ThanosQuerier CRDs" "External"
        tempoOp = softwareSystem "tempo-operator" "Distributed tracing with Tempo" "External"
        otelOp = softwareSystem "opentelemetry-operator" "OpenTelemetry instrumentation and collection" "External"
        segment = softwareSystem "Segment.IO" "Telemetry data reporting (self-managed only)" "External"

        # Relationships
        admin -> rhodsOperator "Creates DSC/DSCI CRs via kubectl"
        datascientist -> dashboard "Uses web UI" "HTTPS/443"
        datascientist -> kserve "Deploys inference services"
        datascientist -> workbenches "Uses Jupyter notebooks"

        rhodsOperator -> dashboard "Deploys via kustomize" "CRD Watch + Manifest Deploy"
        rhodsOperator -> kserve "Deploys via kustomize + Helm module" "CRD Watch + Manifest + Module"
        rhodsOperator -> kueue "Deploys and configures queues" "CRD Watch + Dynamic Resources"
        rhodsOperator -> modelRegistry "Deploys operator" "CRD Watch + Manifest Deploy"
        rhodsOperator -> workbenches "Deploys notebook controllers" "CRD Watch + Manifest Deploy"
        rhodsOperator -> dsp "Deploys pipeline infrastructure" "CRD Watch + Manifest Deploy"
        rhodsOperator -> trustyai "Deploys fairness operator" "CRD Watch + Manifest Deploy"
        rhodsOperator -> aigateway "Deploys via Helm module" "Module CR + Helm Deploy"
        rhodsOperator -> mlflow "Deploys via Helm module" "Module CR + Helm Deploy"

        rhodsOperator -> kubeAPI "CRD CRUD, SSA apply, resource management" "HTTPS/6443"
        rhodsOperator -> openshiftAPI "Route, OAuth, Config APIs" "HTTPS/6443"
        rhodsOperator -> istio "Creates EnvoyFilter, DestinationRule" "CRD Create"
        rhodsOperator -> gatewayAPI "Creates Gateway, GatewayClass, HTTPRoute" "CRD Create"
        rhodsOperator -> certManager "PKI for cloud deployments" "Helm Deploy"
        rhodsOperator -> oauthProvider "OAuth client registration, token validation" "HTTPS/443"
        rhodsOperator -> olm "Subscription, CSV status detection" "API Watch"
        rhodsOperator -> coo "MonitoringStack, ThanosQuerier" "CRD Watch + CR Create"
        rhodsOperator -> tempoOp "TempoMonolithic, TempoStack" "CRD Watch + CR Create"
        rhodsOperator -> otelOp "OpenTelemetryCollector, Instrumentation" "CRD Watch + CR Create"
        rhodsOperator -> segment "Telemetry reporting" "HTTPS/443"
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
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
