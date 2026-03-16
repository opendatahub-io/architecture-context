workspace {
    model {
        user = person "Data Scientist / Platform Admin" "Deploys and manages RHOAI/ODH data science platform"

        rhoaiOperator = softwareSystem "RHOAI Operator (rhods-operator)" "Central operator for Red Hat OpenShift AI and Open Data Hub that deploys and manages all data science components" {
            dscController = container "DataScienceCluster Controller" "Deploys and manages data science components based on DSC CR" "Go Kubernetes Controller"
            dsciController = container "DSCInitialization Controller" "Initializes platform infrastructure (monitoring, service mesh, namespaces)" "Go Kubernetes Controller"
            webhookServer = container "Webhook Server" "Validates and mutates DataScienceCluster and DSCInitialization resources" "Go Admission Controller"
            secretGenerator = container "SecretGenerator Controller" "Generates and manages component secrets" "Go Kubernetes Controller"
            certGenerator = container "CertConfigMapGenerator Controller" "Generates TLS certificate ConfigMaps" "Go Kubernetes Controller"
            componentReconcilers = container "Component Reconcilers" "Per-component handlers for Dashboard, KServe, ModelMesh, Pipelines, etc." "Go Handlers"
            monitoringStack = container "Monitoring Stack" "Prometheus, Alertmanager, and federation for platform metrics" "Prometheus Operator"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Manages cluster resources and enforces RBAC" "External"
        serviceMesh = softwareSystem "Service Mesh (Istio)" "Service mesh for traffic management and mTLS" "External (Conditional)"
        knativeServing = softwareSystem "Knative Serving" "Serverless autoscaling platform" "External (Conditional)"
        authorino = softwareSystem "Authorino" "Authorization service for API authentication" "External (Conditional)"
        prometheusOperator = softwareSystem "Prometheus Operator" "Manages Prometheus instances" "External (Optional)"
        certManager = softwareSystem "Cert Manager" "Automated certificate management" "External (Optional)"

        dashboard = softwareSystem "ODH Dashboard" "Web UI for data science workflows" "Internal RHOAI Component"
        workbenches = softwareSystem "Workbenches" "Jupyter notebooks and IDE environments" "Internal RHOAI Component"
        kserve = softwareSystem "KServe" "Serverless model serving platform" "Internal RHOAI Component"
        modelmesh = softwareSystem "ModelMesh" "Multi-model serving infrastructure" "Internal RHOAI Component"
        pipelines = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines for ML workflows" "Internal RHOAI Component"
        codeflare = softwareSystem "CodeFlare" "Distributed workload management" "Internal RHOAI Component"
        ray = softwareSystem "Ray Operator" "Ray cluster operator for distributed computing" "Internal RHOAI Component"
        kueue = softwareSystem "Kueue" "Job queueing system" "Internal RHOAI Component"
        trainingOperator = softwareSystem "Training Operator" "Distributed training frameworks (PyTorch, TensorFlow)" "Internal RHOAI Component"
        trustyai = softwareSystem "TrustyAI" "AI explainability and bias detection" "Internal RHOAI Component"
        modelRegistry = softwareSystem "Model Registry" "Model metadata and versioning service" "Internal RHOAI Component"

        openshiftConsole = softwareSystem "OpenShift Console" "OpenShift web console" "External"

        // Relationships - User interactions
        user -> rhoaiOperator "Creates DataScienceCluster and DSCInitialization CRs via kubectl"
        user -> dashboard "Accesses data science workflows"

        // Relationships - Operator to Kubernetes API
        rhoaiOperator -> k8sAPI "Watches CRs and manages cluster resources" "HTTPS/443, ServiceAccount Token"
        k8sAPI -> webhookServer "Validates and mutates CRs" "HTTPS/9443, mTLS"

        // Relationships - Operator to components
        dscController -> dashboard "Deploys manifests" "Kubernetes API"
        dscController -> workbenches "Deploys manifests" "Kubernetes API"
        dscController -> kserve "Deploys manifests" "Kubernetes API"
        dscController -> modelmesh "Deploys manifests" "Kubernetes API"
        dscController -> pipelines "Deploys manifests" "Kubernetes API"
        dscController -> codeflare "Deploys manifests" "Kubernetes API"
        dscController -> ray "Deploys manifests" "Kubernetes API"
        dscController -> kueue "Deploys manifests" "Kubernetes API"
        dscController -> trainingOperator "Deploys manifests" "Kubernetes API"
        dscController -> trustyai "Deploys manifests" "Kubernetes API"
        dscController -> modelRegistry "Deploys manifests" "Kubernetes API"

        // Relationships - Operator to platform services
        dsciController -> monitoringStack "Deploys Prometheus and Alertmanager" "Kubernetes API"
        dsciController -> serviceMesh "Configures ServiceMeshMember" "Kubernetes API"
        dsciController -> knativeServing "Configures for KServe" "Kubernetes API"

        monitoringStack -> rhoaiOperator "Scrapes metrics" "HTTP/8443, Bearer Token"
        monitoringStack -> dashboard "Scrapes metrics" "Various ports"
        monitoringStack -> kserve "Scrapes metrics" "Various ports"
        monitoringStack -> modelmesh "Scrapes metrics" "Various ports"

        // Relationships - Component dependencies
        kserve -> serviceMesh "Uses for traffic routing and mTLS" "Service Mesh"
        kserve -> knativeServing "Uses for autoscaling" "Knative API"
        kserve -> authorino "Uses for authentication" "AuthConfig CRD"
        modelmesh -> serviceMesh "Uses for traffic routing" "Service Mesh"

        // Relationships - Console integration
        rhoaiOperator -> openshiftConsole "Adds RHOAI links" "ConsoleLink CRD"

        // Relationships - Optional integrations
        rhoaiOperator -> prometheusOperator "Uses for monitoring (if available)" "ServiceMonitor CRD"
        rhoaiOperator -> certManager "Uses for certificates (if available)" "Certificate CRD"
    }

    views {
        systemContext rhoaiOperator "SystemContext" {
            include *
            autoLayout
        }

        container rhoaiOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External (Conditional)" {
                background #cccccc
                color #000000
            }
            element "External (Optional)" {
                background #e8e8e8
                color #000000
            }
            element "Internal RHOAI Component" {
                background #7ed321
                color #000000
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
                background #f5a623
                color #ffffff
            }
        }
    }
}
