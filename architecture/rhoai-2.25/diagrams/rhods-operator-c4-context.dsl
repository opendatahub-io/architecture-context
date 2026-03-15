workspace {
    model {
        admin = person "Platform Administrator" "Manages RHOAI platform deployment and configuration"
        dataScientist = person "Data Scientist" "Uses deployed AI/ML components for model development and deployment"

        rhodsOperator = softwareSystem "RHOAI Operator (rhods-operator)" "Manages the lifecycle and configuration of Red Hat OpenShift AI data science platform components" {
            controller = container "rhods-operator Controller" "Reconciles DataScienceCluster and DSCInitialization CRs, deploys components" "Go Operator" {
                mainController = component "Main Controller" "Manages DataScienceCluster and DSCInitialization lifecycle" "controller-runtime"
                componentControllers = component "Component Controllers" "14 component-specific controllers (Dashboard, KServe, Pipelines, CodeFlare, etc.)" "Go"
                serviceControllers = component "Service Controllers" "Platform service controllers (Auth, Monitoring, ServiceMesh)" "Go"
                manifestRenderer = component "Manifest Renderer" "Renders 220+ Kustomize manifests with overlay support" "Kustomize Engine"
                featureTracker = component "Feature Tracker" "Tracks feature enablement across components" "CR Controller"
                hardwareProfileMgr = component "Hardware Profile Manager" "Manages GPU/accelerator configurations" "CR Controller"
            }

            webhookServer = container "Webhook Server" "Validates and mutates DataScienceCluster and DSCInitialization CRs" "Go Admission Webhook" {
                validatingWebhook = component "Validating Webhook" "Validates CR specifications and dependencies" "Admission Controller"
                mutatingWebhook = component "Mutating Webhook" "Sets default values on CRs" "Admission Controller"
            }

            metricsServer = container "Metrics Server" "Exposes operator and component metrics" "Prometheus Exporter" {
                prometheusExporter = component "Prometheus Exporter" "Exports controller and component metrics" "controller-runtime"
                rbacProxy = component "kube-rbac-proxy" "Authenticates metrics requests via SubjectAccessReview" "RBAC Proxy"
            }
        }

        # Kubernetes Platform
        kubernetes = softwareSystem "Kubernetes / OpenShift" "Container orchestration platform" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "External"

        # External Operator Dependencies
        prometheusOperator = softwareSystem "Prometheus Operator" "Deploys and manages Prometheus monitoring stack" "External"
        istioOperator = softwareSystem "Service Mesh Operator (Istio)" "Service mesh for traffic management and mTLS" "External"
        serverlessOperator = softwareSystem "Serverless Operator (Knative)" "Serverless autoscaling platform for KServe" "External"
        authorinoOperator = softwareSystem "Authorino Operator" "Authorization service for model serving" "External"
        certManager = softwareSystem "cert-manager" "Certificate management for KServe" "External"

        # OpenShift Platform Services
        openshiftOAuth = softwareSystem "OpenShift OAuth" "OpenShift authentication and authorization" "External"
        openshiftConsole = softwareSystem "OpenShift Console" "OpenShift web console" "External"
        openshiftServiceCA = softwareSystem "OpenShift Service CA" "Auto-rotates service certificates and injects CA bundles" "External"
        openshiftRegistry = softwareSystem "OpenShift Image Registry" "Internal container image registry" "External"

        # Deployed AI/ML Components (Internal ODH/RHOAI)
        dashboard = softwareSystem "ODH Dashboard" "Web UI for platform management" "Internal RHOAI"
        kserve = softwareSystem "KServe Controller" "Model serving infrastructure" "Internal RHOAI"
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare Operator" "Distributed computing workload management" "Internal RHOAI"
        ray = softwareSystem "Ray Operator" "Ray cluster management" "Internal RHOAI"
        modelmesh = softwareSystem "ModelMesh Controller" "Multi-model serving infrastructure" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model versioning and metadata" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI Service" "Model explainability service" "Internal RHOAI"
        trainingOperator = softwareSystem "Training Operator" "ML training job management" "Internal RHOAI"
        workbenches = softwareSystem "Workbenches" "Jupyter notebook servers" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queueing and resource quotas" "Internal RHOAI"
        feast = softwareSystem "Feast Operator" "Feature store operator" "Internal RHOAI"

        # Monitoring Stack
        prometheus = softwareSystem "Prometheus" "Metrics collection and storage (90d retention)" "Internal RHOAI"
        alertmanager = softwareSystem "Alertmanager" "Alert routing and notification" "Internal RHOAI"
        tempo = softwareSystem "Tempo" "Distributed tracing backend" "Internal RHOAI"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Traces and metrics collection" "Internal RHOAI"

        # External Services
        gitRepos = softwareSystem "External Git Repositories" "Component manifest repositories (optional runtime override)" "External"

        # Relationships - Admin
        admin -> rhodsOperator "Creates DataScienceCluster and DSCInitialization CRs via kubectl/oc" "HTTPS/6443 (Kubernetes API)"
        admin -> kubernetesAPI "Manages cluster resources" "kubectl/oc"

        # Relationships - Data Scientist
        dataScientist -> dashboard "Accesses platform UI" "HTTPS/443"
        dataScientist -> kserve "Deploys models for serving" "CR creation"
        dataScientist -> dataSciencePipelines "Creates ML pipelines" "CR creation"

        # Relationships - rhods-operator to Kubernetes
        controller -> kubernetesAPI "Creates and manages CRs, Deployments, Services, ConfigMaps, Secrets" "HTTPS/6443 (ServiceAccount Token)"
        webhookServer -> kubernetesAPI "Validates admission requests" "HTTPS/6443 (mTLS)"
        metricsServer -> kubernetesAPI "Authenticates metrics requests via SubjectAccessReview" "HTTPS/6443 (Bearer Token)"

        # Relationships - Kubernetes API to rhods-operator
        kubernetesAPI -> webhookServer "Calls admission webhooks for CR validation/mutation" "HTTPS/443→9443 (mTLS)"
        kubernetesAPI -> controller "Sends CR watch events" "Watch API"

        # Relationships - rhods-operator deploys components
        controller -> dashboard "Deploys manifests (40+ Kustomize files)" "Kubernetes API"
        controller -> kserve "Deploys manifests (30+ Kustomize files)" "Kubernetes API"
        controller -> dataSciencePipelines "Deploys manifests (35+ Kustomize files)" "Kubernetes API"
        controller -> codeflare "Deploys manifests (20+ Kustomize files)" "Kubernetes API"
        controller -> ray "Deploys manifests (15+ Kustomize files)" "Kubernetes API"
        controller -> modelmesh "Deploys manifests (25+ Kustomize files)" "Kubernetes API"
        controller -> modelRegistry "Deploys manifests (15+ Kustomize files)" "Kubernetes API"
        controller -> trustyai "Deploys manifests (10+ Kustomize files)" "Kubernetes API"
        controller -> trainingOperator "Deploys manifests (15+ Kustomize files)" "Kubernetes API"
        controller -> workbenches "Deploys manifests (10+ Kustomize files)" "Kubernetes API"
        controller -> kueue "Deploys manifests (10+ Kustomize files)" "Kubernetes API"
        controller -> feast "Deploys manifests (8+ Kustomize files)" "Kubernetes API"

        # Relationships - rhods-operator to external operators
        controller -> prometheusOperator "Creates ServiceMonitors, PrometheusRules" "HTTPS/6443 (CRD API)"
        controller -> istioOperator "Creates ServiceMeshMembers, ServiceMeshControlPlanes" "HTTPS/6443 (CRD API)"
        controller -> serverlessOperator "Manages KnativeServing for KServe" "HTTPS/6443 (CRD API)"
        controller -> authorinoOperator "Creates AuthConfigs for model serving authorization" "HTTPS/6443 (CRD API)"
        controller -> certManager "Uses for KServe certificate management" "HTTPS/6443 (CRD API)"

        # Relationships - rhods-operator to OpenShift services
        controller -> openshiftOAuth "Creates OAuthClients for component authentication" "HTTPS/6443"
        controller -> openshiftConsole "Creates ConsoleLinks for dashboard" "HTTPS/6443"
        openshiftServiceCA -> webhookServer "Rotates webhook TLS certificates" "ConfigMap watch, annotations"
        controller -> openshiftRegistry "Pulls container images" "HTTPS/5000 (Pull Secrets)"

        # Relationships - rhods-operator deploys monitoring stack
        controller -> prometheus "Deploys Prometheus StatefulSet" "Kubernetes API"
        controller -> alertmanager "Deploys Alertmanager StatefulSet" "Kubernetes API"
        controller -> tempo "Deploys Tempo StatefulSet" "Kubernetes API"
        controller -> otelCollector "Deploys OpenTelemetry Collector" "Kubernetes API"

        # Relationships - Monitoring
        prometheus -> metricsServer "Scrapes operator metrics" "HTTPS/8443 (Bearer Token + SAR)"
        prometheus -> dashboard "Scrapes component metrics" "ServiceMonitor"
        prometheus -> kserve "Scrapes component metrics" "ServiceMonitor"
        prometheus -> dataSciencePipelines "Scrapes component metrics" "ServiceMonitor"
        prometheus -> alertmanager "Sends alerts" "HTTP"

        # Relationships - External manifest downloads (optional)
        controller -> gitRepos "Downloads manifests (via devFlags.manifests)" "HTTPS/443 (optional)"

        # Relationships - Component interactions
        dashboard -> kubernetesAPI "Manages user workloads" "HTTPS/6443"
        kserve -> istioOperator "Uses service mesh for traffic routing" "CRD API"
        kserve -> serverlessOperator "Uses Knative for autoscaling" "CRD API"
        dataSciencePipelines -> workbenches "Integrates with notebooks" "CR API"
        codeflare -> ray "Manages Ray clusters" "CR API"
        codeflare -> kueue "Uses for job queueing" "CR API"
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

        component controller "ControllerComponents" {
            include *
            autoLayout
        }

        component webhookServer "WebhookComponents" {
            include *
            autoLayout
        }

        component metricsServer "MetricsComponents" {
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
                color #000000
            }
            element "Software System" {
                background #4a90e2
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
                shape person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }
}
