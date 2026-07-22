workspace {
    model {
        // Actors
        admin = person "Platform Admin" "Deploys and configures the RHOAI platform"
        datascientist = person "Data Scientist" "Uses AI/ML platform services (dashboard, notebooks, serving)"

        // Core System
        rhodsOperator = softwareSystem "rhods-operator" "Central platform operator for Red Hat OpenShift AI — manages lifecycle of 16+ AI/ML components, ingress, auth, and monitoring" {
            manager = container "Manager" "Main operator binary running all controllers, services, and modules" "Go (controller-runtime)"
            cloudmanager = container "CloudManager" "Manages cloud-provider-specific KubernetesEngine CRs (AWS, Azure, CoreWeave)" "Go (controller-runtime + Helm)"
            webhookServer = container "Webhook Server" "Validates DSC/DSCI mutations, singleton enforcement, deprecation warnings" "Go (controller-runtime webhook)"
            gatewayCtrl = container "Gateway Controller" "Deploys full ingress stack: Gateway API, Envoy, EnvoyFilter, kube-auth-proxy" "Go Controller"
            authCtrl = container "Auth Controller" "Manages platform RBAC: admin groups, allowed groups, namespace roles" "Go Controller"
            monitoringCtrl = container "Monitoring Controller" "Deploys Prometheus, Tempo, Perses, OpenTelemetry, Thanos, NetworkPolicies" "Go Controller"
            componentControllers = container "Component Controllers (14)" "Per-component controllers managing kustomize manifests for Dashboard, KServe, Kueue, Ray, etc." "Go Controllers"
            moduleHandlers = container "Module Handlers (3)" "AIGateway, MLflowOperator, MCPLifecycleOperator — deployed as separate operator pods" "Go Handlers"
        }

        // Internal Platform Dependencies (managed components)
        dashboard = softwareSystem "Dashboard" "RHOAI web console for data scientists" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML model serving" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job scheduling and resource management" "Internal RHOAI"
        ray = softwareSystem "Ray" "Distributed computing framework" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model metadata and artifact registry" "Internal RHOAI"
        workbenches = softwareSystem "Workbenches" "Notebook controllers and images" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines" "AI pipeline orchestration" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "Model explainability and fairness" "Internal RHOAI"

        // External Dependencies
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "OAuth2 server for platform authentication" "External"
        istio = softwareSystem "Istio / Service Mesh" "EnvoyFilter and DestinationRule for auth and TLS" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for ingress management" "External"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager for operator deployment" "External"
        certManager = softwareSystem "cert-manager" "Certificate management (optional, for CloudManager)" "External"
        coo = softwareSystem "Cluster Observability Operator" "MonitoringStack, Tempo, Perses CRDs" "External"
        kueueOperator = softwareSystem "Kueue OCP Operator" "Upstream Kueue operator installation" "External"

        // Relationships — Admin
        admin -> rhodsOperator "Configures platform via DSC/DSCI CRs"

        // Relationships — Data Scientist
        datascientist -> dashboard "Accesses via browser (through Gateway)"

        // Relationships — Operator to K8s
        rhodsOperator -> k8sAPI "Reconciles CRDs, manages resources" "HTTPS/6443"
        rhodsOperator -> openshiftOAuth "Registers OAuth client, token exchange" "HTTPS/443"
        rhodsOperator -> istio "Creates EnvoyFilter, DestinationRule for auth" "CRD API"
        rhodsOperator -> gatewayAPI "Creates Gateway, GatewayClass, HTTPRoute" "CRD API"
        olm -> rhodsOperator "Deploys and manages operator lifecycle"

        // Relationships — Operator to components
        rhodsOperator -> dashboard "Manages lifecycle" "Component CR"
        rhodsOperator -> kserve "Manages lifecycle" "Component CR"
        rhodsOperator -> kueue "Manages lifecycle" "Component CR"
        rhodsOperator -> ray "Manages lifecycle" "Component CR"
        rhodsOperator -> modelRegistry "Manages lifecycle" "Component CR"
        rhodsOperator -> workbenches "Manages lifecycle" "Component CR"
        rhodsOperator -> dsPipelines "Manages lifecycle" "Component CR"
        rhodsOperator -> trustyai "Manages lifecycle" "Component CR"

        // Relationships — Operator to external services
        rhodsOperator -> certManager "Manages certificates (CloudManager)" "CRD API"
        rhodsOperator -> coo "Deploys MonitoringStack, Tempo" "CRD API"
        rhodsOperator -> kueueOperator "Watches operator readiness" "Subscription watch"

        // Internal container relationships
        manager -> gatewayCtrl "Runs"
        manager -> authCtrl "Runs"
        manager -> monitoringCtrl "Runs"
        manager -> componentControllers "Runs"
        manager -> moduleHandlers "Runs"
        manager -> webhookServer "Runs"
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
