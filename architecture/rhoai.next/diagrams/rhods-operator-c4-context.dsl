workspace {
    model {
        admin = person "Cluster Admin" "Configures RHOAI platform via DSC and DSCI custom resources"
        datascientist = person "Data Scientist" "Uses AI/ML platform components (notebooks, model serving, pipelines)"

        rhodsOperator = softwareSystem "rhods-operator" "RHOAI Platform Operator — deploys, configures, and lifecycle-manages all platform components, services, ingress, auth, and monitoring" {
            manager = container "manager" "Platform lifecycle operator managing 15 AI/ML components, 5 platform services, ingress, auth, and monitoring" "Go Operator (controller-runtime)" {
                dsciController = component "DSCInitialization Controller" "Platform infrastructure: namespaces, network policies, CA bundles, service singletons" "controller-runtime"
                dscController = component "DataScienceCluster Controller" "Orchestrates component lifecycle — creates/deletes component CRs" "controller-runtime"
                gatewayController = component "Gateway Controller" "Deploys Gateway API, Envoy, kube-auth-proxy, dashboard redirects" "controller-runtime"
                authController = component "Auth Controller" "Manages RBAC group bindings (admin/allowed groups)" "controller-runtime"
                monitoringController = component "Monitoring Controller" "Deploys Prometheus, Tempo, OpenTelemetry, Perses" "controller-runtime"
                componentControllers = component "Component Controllers (15)" "Per-component controllers rendering kustomize manifests" "controller-runtime"
                webhookServer = component "Webhook Server" "12 webhooks: validation, defaulting, HW profile injection, connection injection" "admission webhooks"
            }
            cloudmanager = container "cloudmanager" "Dependency bootstrapper for xKS platforms (Azure AKS, CoreWeave) — installs cert-manager, Sail/Istio, LWS, Gateway API via Helm" "Go CLI (cobra)"
        }

        // Managed AI/ML Components
        dashboard = softwareSystem "Dashboard" "RHOAI web UI for managing notebooks, model serving, pipelines" "Internal RHOAI"
        workbenches = softwareSystem "Workbenches" "Jupyter notebook controller and notebook images" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Batch job queueing with resource flavors" "Internal RHOAI"
        ray = softwareSystem "Ray (KubeRay)" "Distributed computing framework" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI model explainability and evaluation" "Internal RHOAI"
        modelregistry = softwareSystem "Model Registry" "ML model metadata registry" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "Data science pipelines (Argo Workflows)" "Internal RHOAI"
        trainingOperator = softwareSystem "Training Operator" "Kubeflow Training Operator" "Internal RHOAI"
        trainer = softwareSystem "Trainer" "Kubeflow Trainer (next-gen training)" "Internal RHOAI"
        feast = softwareSystem "Feast Operator" "Feature store operator" "Internal RHOAI"
        ogx = softwareSystem "OGX" "OGX/LlamaStack operator" "Internal RHOAI"
        mlflow = softwareSystem "MLflow Operator" "Experiment tracking operator" "Internal RHOAI"
        spark = softwareSystem "Spark Operator" "Apache Spark on Kubernetes" "Internal RHOAI"
        maas = softwareSystem "ModelsAsService" "Models-as-a-Service with API keys and OIDC" "Internal RHOAI"
        modelcontroller = softwareSystem "Model Controller" "ODH model controller for inference routing" "Internal RHOAI"

        // Platform Dependencies
        istio = softwareSystem "Istio / Sail Operator" "Service mesh for EnvoyFilter, DestinationRule, mTLS" "External Dependency"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External Dependency"
        lws = softwareSystem "LeaderWorkerSet Operator" "Multi-node inference workloads" "External Dependency"
        gatewayAPI = softwareSystem "Gateway API" "Gateway, GatewayClass, HTTPRoute CRDs" "External Dependency"
        coo = softwareSystem "Cluster Observability Operator" "MonitoringStack, ThanosQuerier, OpenTelemetryCollector" "External Dependency"
        tempo = softwareSystem "Tempo Operator" "Distributed tracing backend" "External Dependency"
        perses = softwareSystem "Perses Operator" "Observability visualization dashboards" "External Dependency"
        kuadrant = softwareSystem "Kuadrant" "API gateway policies for MaaS" "External Dependency"

        // External Services
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        oauthServer = softwareSystem "OpenShift OAuth Server" "Integrated OAuth authentication" "External"
        oidcProvider = softwareSystem "External OIDC Provider" "External OIDC authentication" "External"

        // Relationships - Admin
        admin -> rhodsOperator "Creates DSC and DSCI CRs via kubectl" "HTTPS/6443"

        // Relationships - Data Scientist
        datascientist -> dashboard "Uses web UI" "HTTPS/443 via Gateway"
        datascientist -> workbenches "Creates notebooks" "HTTPS/443 via Gateway"
        datascientist -> kserve "Deploys models" "HTTPS/443 via Gateway"

        // Relationships - Operator → Managed Components
        rhodsOperator -> dashboard "Deploys and manages lifecycle" "kustomize manifests"
        rhodsOperator -> workbenches "Deploys and manages lifecycle" "kustomize manifests"
        rhodsOperator -> kserve "Deploys and manages lifecycle" "kustomize manifests"
        rhodsOperator -> kueue "Deploys and manages lifecycle" "kustomize manifests"
        rhodsOperator -> ray "Deploys and manages lifecycle" "kustomize manifests"
        rhodsOperator -> trustyai "Deploys and manages lifecycle" "kustomize manifests"
        rhodsOperator -> modelregistry "Deploys and manages lifecycle" "kustomize manifests"
        rhodsOperator -> dsp "Deploys and manages lifecycle" "kustomize manifests"
        rhodsOperator -> trainingOperator "Deploys and manages lifecycle" "kustomize manifests"
        rhodsOperator -> trainer "Deploys and manages lifecycle" "kustomize manifests"
        rhodsOperator -> feast "Deploys and manages lifecycle" "kustomize manifests"
        rhodsOperator -> ogx "Deploys and manages lifecycle" "kustomize manifests"
        rhodsOperator -> mlflow "Deploys and manages lifecycle" "kustomize manifests"
        rhodsOperator -> spark "Deploys and manages lifecycle" "kustomize manifests"
        rhodsOperator -> maas "Deploys and manages lifecycle" "kustomize manifests"
        rhodsOperator -> modelcontroller "Deploys and manages lifecycle" "kustomize manifests"

        // Relationships - Operator → Platform Deps
        rhodsOperator -> istio "Creates EnvoyFilter, DestinationRule" "Kubernetes API"
        rhodsOperator -> certManager "Watches CRDs, Helm install on xKS" "Kubernetes API"
        rhodsOperator -> lws "Watches Subscription, Helm install on xKS" "Kubernetes API"
        rhodsOperator -> gatewayAPI "Creates Gateway, HTTPRoute" "Kubernetes API"
        rhodsOperator -> coo "Deploys MonitoringStack, ThanosQuerier" "Kubernetes API"
        rhodsOperator -> tempo "Deploys TempoMonolithic/TempoStack" "Kubernetes API"
        rhodsOperator -> perses "Deploys Perses dashboards" "Kubernetes API"
        rhodsOperator -> kuadrant "RBAC for MaaS admin group" "Kubernetes API"

        // Relationships - Operator → External
        rhodsOperator -> k8sAPI "Controller-runtime API operations" "HTTPS/6443"
        rhodsOperator -> oauthServer "OAuthClient for kube-auth-proxy" "HTTPS/443"
        rhodsOperator -> oidcProvider "OIDC auth flow" "HTTPS/443"

        // Internal relationships
        dsciController -> authController "Creates Auth singleton CR" "internal"
        dsciController -> gatewayController "Creates GatewayConfig singleton CR" "internal"
        dsciController -> monitoringController "Creates Monitoring singleton CR" "internal"
        dscController -> componentControllers "Creates per-component CRs" "internal"
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

        component manager "ManagerComponents" {
            include *
            autoLayout
        }

        styles {
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #f5a623
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
