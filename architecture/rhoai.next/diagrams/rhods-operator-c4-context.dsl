workspace {
    model {
        admin = person "Platform Admin" "Configures RHOAI platform via DSC/DSCI CRs"
        dataScientist = person "Data Scientist" "Uses AI/ML platform components (Dashboard, Notebooks, Model Serving)"

        rhodsOperator = softwareSystem "rhods-operator" "Central control plane for Red Hat OpenShift AI — orchestrates 16+ components, platform services, and multi-cloud infrastructure" {
            manager = container "Manager" "Main operator binary; reconciles DSC, DSCI, component CRs, service CRs, and module CRs" "Go Operator (controller-runtime)"
            cloudmanager = container "Cloud Manager" "Multi-cloud Kubernetes engine management; deploys dependency operators via Helm" "Go Service"
            gatewayController = container "Gateway Controller" "Deploys Gateway API ingress stack: Gateway, EnvoyFilter, kube-auth-proxy, HTTPRoutes" "Go Controller"
            authController = container "Auth Controller" "Manages RBAC groups, roles, and role bindings for platform admin/user groups" "Go Controller"
            monitoringController = container "Monitoring Controller" "Deploys MonitoringStack, Prometheus, Thanos, OTel Collector, Perses" "Go Controller"
            webhookSystem = container "Webhook System" "14 admission webhooks: singleton, defaulting, HW profile injection, connection injection, deprecation, conversion" "Go Admission Webhooks"
        }

        kubeAuthProxy = softwareSystem "kube-auth-proxy" "OAuth2/OIDC authentication proxy for Gateway API ingress" "Internal Platform"

        # Managed Components (Internal RHOAI)
        dashboard = softwareSystem "ODH Dashboard" "Web UI for RHOAI platform" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving platform" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queue management" "Internal RHOAI"
        workbenches = softwareSystem "Workbenches" "Jupyter notebook environments" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal RHOAI"
        ray = softwareSystem "KubeRay" "Ray cluster management" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata registry" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI explainability and bias detection" "Internal RHOAI"
        trainingOp = softwareSystem "Training Operator" "Distributed training jobs" "Internal RHOAI"
        maas = softwareSystem "Models as a Service" "MaaS billing and subscriptions" "Internal RHOAI"

        # External Dependencies
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for all resource management" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "OpenShift integrated authentication" "External"
        oidcProvider = softwareSystem "External OIDC Provider" "Alternative identity provider" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "External"
        istio = softwareSystem "Istio / OSSM (Sail)" "Service mesh for Gateway data plane (EnvoyFilter)" "External"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager" "External"
        prometheus = softwareSystem "Prometheus / Cluster Observability" "Metrics collection and alerting" "External"
        otelOperator = softwareSystem "OpenTelemetry Operator" "Metrics and traces collection" "External"
        quayRegistry = softwareSystem "quay.io/rhoai" "Container image registry" "External"

        # Relationships - Users
        admin -> rhodsOperator "Creates DSC/DSCI CRs via kubectl" "HTTPS/6443"
        dataScientist -> dashboard "Accesses platform UI" "HTTPS/443"
        dataScientist -> workbenches "Uses Jupyter notebooks" "HTTPS/443"
        dataScientist -> kserve "Deploys ML models" "HTTPS/443"

        # Relationships - Operator to Managed Components
        rhodsOperator -> dashboard "Deploys and manages lifecycle" "CRD + Manifests"
        rhodsOperator -> kserve "Deploys and manages lifecycle" "CRD + Manifests"
        rhodsOperator -> kueue "Deploys and manages lifecycle" "CRD + Manifests"
        rhodsOperator -> workbenches "Deploys and manages lifecycle" "Manifests"
        rhodsOperator -> dsPipelines "Deploys and manages lifecycle" "CRD + Manifests"
        rhodsOperator -> ray "Deploys and manages lifecycle" "Manifests"
        rhodsOperator -> modelRegistry "Deploys and manages lifecycle" "CRD + Manifests"
        rhodsOperator -> trustyai "Deploys and manages lifecycle" "CRD + Manifests"
        rhodsOperator -> trainingOp "Deploys and manages lifecycle" "Manifests"
        rhodsOperator -> maas "Deploys and manages lifecycle" "CRD + Manifests + Kustomize"

        # Relationships - Operator to External
        rhodsOperator -> k8sApi "All controller reconciliation" "HTTPS/6443"
        rhodsOperator -> certManager "Certificate issuance for webhook TLS" "HTTPS/6443"
        rhodsOperator -> istio "Creates EnvoyFilter, DestinationRule" "HTTPS/6443"
        rhodsOperator -> olm "Watches Subscriptions/CSVs" "HTTPS/6443"
        rhodsOperator -> prometheus "Creates ServiceMonitors, PrometheusRules" "HTTPS/6443"
        rhodsOperator -> otelOperator "Creates OTel Collector CRs" "HTTPS/6443"
        rhodsOperator -> quayRegistry "Pulls component images" "HTTPS/443"

        # Gateway / Auth flow
        rhodsOperator -> kubeAuthProxy "Deploys and configures" "Manifests"
        kubeAuthProxy -> openshiftOAuth "Authenticates users" "HTTPS/443"
        kubeAuthProxy -> oidcProvider "Authenticates users (OIDC mode)" "HTTPS/443"

        # Cloud Manager
        cloudmanager -> k8sApi "Deploys Helm charts" "HTTPS/6443"

        # Internal container relationships
        manager -> gatewayController "Runs as sub-controller"
        manager -> authController "Runs as sub-controller"
        manager -> monitoringController "Runs as sub-controller"
        manager -> webhookSystem "Serves webhooks"
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
            element "Internal Platform" {
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
