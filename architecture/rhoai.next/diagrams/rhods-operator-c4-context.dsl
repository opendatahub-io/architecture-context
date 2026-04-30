workspace {
    model {
        clusterAdmin = person "Cluster Admin" "Manages RHOAI platform via DSCInitialization and DataScienceCluster CRs"
        dataScientist = person "Data Scientist" "Uses RHOAI components (notebooks, pipelines, model serving) via Gateway"

        rhodsOperator = softwareSystem "rhods-operator" "Platform operator managing RHOAI lifecycle - 16 data science components, gateway, auth, monitoring" {
            manager = container "manager" "Main operator binary - DSCInitialization, DataScienceCluster, 16 component controllers, 5 service controllers" "Go Operator (controller-runtime)"
            cloudmanager = container "cloudmanager" "Cloud infrastructure management - Azure AKS, CoreWeave" "Go CLI"
            gatewayController = container "Gateway Controller" "Deploys Gateway API, kube-auth-proxy, EnvoyFilter, Routes" "Go Controller"
            authController = container "Auth Controller" "Manages platform RBAC, admin/allowed groups" "Go Controller"
            monitoringController = container "Monitoring Controller" "Deploys MonitoringStack, ThanosQuerier, Tempo, OTEL, Perses" "Go Controller"
            componentRegistry = container "Component Registry" "Plugin registry for 16 component handlers with enable/disable/unmanaged" "Go Framework"
        }

        kubeAuthProxy = softwareSystem "kube-auth-proxy" "OAuth2/OIDC proxy for gateway authentication" "Internal Platform" {
            authProxyPod = container "kube-auth-proxy" "Handles OAuth2/OIDC authentication, cookie management, token validation" "Go Service"
        }

        dashboardRedirect = softwareSystem "dashboard-redirect" "Nginx-based 301 redirect for legacy URLs" "Internal Platform"

        kubeAPI = softwareSystem "Kubernetes API Server" "Cluster API for CRD watches, resource management, token review" "Infrastructure"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "Integrated OAuth2 provider for user authentication" "Infrastructure"
        openshiftIngress = softwareSystem "OpenShift Ingress Controller" "Cluster ingress domain detection, default certificate" "Infrastructure"
        openshiftServiceCA = softwareSystem "OpenShift Service CA Operator" "Auto-generates TLS certs for annotated services" "Infrastructure"
        olm = softwareSystem "Operator Lifecycle Manager" "Operator installation, version detection, dependency management" "Infrastructure"
        istio = softwareSystem "Istio / Service Mesh" "EnvoyFilter, DestinationRule for traffic shaping and TLS" "Infrastructure"
        gatewayAPI = softwareSystem "Gateway API (Envoy)" "Kubernetes Gateway API ingress entry point" "Infrastructure"
        certManager = softwareSystem "cert-manager" "Certificate management (optional, KServe xKS)" "Infrastructure"

        monitoringStackOp = softwareSystem "MonitoringStack Operator" "Deploys Prometheus-compatible monitoring" "External Dependency"
        tempoOp = softwareSystem "Tempo Operator" "Distributed tracing storage and query" "External Dependency"
        otelOp = softwareSystem "OpenTelemetry Operator" "Trace collection and export" "External Dependency"
        persesOp = softwareSystem "Perses Operator" "Observability dashboards" "External Dependency"
        kueueOp = softwareSystem "Kueue Operator" "Job queue management" "External Dependency"
        jobsetOp = softwareSystem "JobSet Operator" "JobSet CRD for Trainer" "External Dependency"
        kuadrant = softwareSystem "Kuadrant" "API management, namespace RBAC" "External Dependency"

        externalOIDC = softwareSystem "External OIDC Provider" "External authentication provider (when configured)" "External"

        // Component systems managed by the operator
        dashboard = softwareSystem "Dashboard" "RHOAI Dashboard UI" "Managed Component"
        kserve = softwareSystem "KServe" "Model serving platform" "Managed Component"
        kueue = softwareSystem "Kueue" "Job queuing system" "Managed Component"
        workbenches = softwareSystem "Workbenches" "Jupyter notebook workbenches" "Managed Component"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata registry" "Managed Component"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Managed Component"
        trustyAI = softwareSystem "TrustyAI" "AI explainability and bias detection" "Managed Component"
        ray = softwareSystem "Ray" "Distributed computing" "Managed Component"

        // Relationships
        clusterAdmin -> rhodsOperator "Creates DSCInitialization and DataScienceCluster CRs" "kubectl / HTTPS 6443"
        dataScientist -> gatewayAPI "Accesses RHOAI services" "HTTPS/443"

        rhodsOperator -> kubeAPI "Watches CRDs, applies manifests, token review" "HTTPS/6443"
        rhodsOperator -> istio "Creates EnvoyFilter, DestinationRule" "CRD Create"
        rhodsOperator -> gatewayAPI "Creates Gateway, GatewayClass, HTTPRoute" "CRD Create"
        rhodsOperator -> openshiftOAuth "Creates OAuthClient" "HTTPS/443"
        rhodsOperator -> openshiftIngress "Detects cluster domain, ingress cert" "API Read"
        rhodsOperator -> openshiftServiceCA "Triggers TLS cert generation" "Annotation"
        rhodsOperator -> olm "Reads Subscription, CSV for version detection" "API Read"
        rhodsOperator -> monitoringStackOp "Creates MonitoringStack CRs" "CRD Create"
        rhodsOperator -> tempoOp "Creates TempoMonolithic/TempoStack CRs" "CRD Create"
        rhodsOperator -> otelOp "Creates Instrumentation, OTELCollector CRs" "CRD Create"
        rhodsOperator -> persesOp "Creates Perses, PersesDatasource CRs" "CRD Create"

        rhodsOperator -> dashboard "Deploys and manages lifecycle" "CRD + Manifests"
        rhodsOperator -> kserve "Deploys and manages lifecycle" "CRD + Manifests"
        rhodsOperator -> kueue "Deploys and manages lifecycle" "CRD + Manifests"
        rhodsOperator -> workbenches "Deploys and manages lifecycle" "CRD + Manifests"
        rhodsOperator -> modelRegistry "Deploys and manages lifecycle" "CRD + Manifests"
        rhodsOperator -> dsPipelines "Deploys and manages lifecycle" "CRD + Manifests"
        rhodsOperator -> trustyAI "Deploys and manages lifecycle" "CRD + Manifests"
        rhodsOperator -> ray "Deploys and manages lifecycle" "CRD + Manifests"

        gatewayAPI -> kubeAuthProxy "ext_authz delegation" "HTTPS/8443"
        kubeAuthProxy -> openshiftOAuth "OAuth2 code exchange" "HTTPS/443"
        kubeAuthProxy -> externalOIDC "OIDC token validation" "HTTPS/443"
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
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "External Dependency" {
                background #b8860b
                color #ffffff
            }
            element "External" {
                background #cc6600
                color #ffffff
            }
            element "Managed Component" {
                background #7ed321
                color #000000
            }
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
