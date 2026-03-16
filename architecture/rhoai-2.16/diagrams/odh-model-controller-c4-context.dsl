workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and deploys ML models via InferenceServices"
        admin = person "Platform Administrator" "Configures ODH platform and manages NIM accounts"

        odhModelController = softwareSystem "ODH Model Controller" "Extends KServe/ModelMesh with OpenShift-native integrations for model serving" {
            controller = container "InferenceService Controller" "Watches InferenceServices and delegates to mode-specific reconcilers" "Go Operator" {
                mmReconciler = component "ModelMesh Reconciler" "Manages Routes, ServiceAccounts, ClusterRoleBindings for ModelMesh" "Go"
                ksServerlessReconciler = component "KServe Serverless Reconciler" "Manages Istio Gateways, VirtualServices, AuthConfigs, NetworkPolicies" "Go"
                ksRawReconciler = component "KServe Raw Reconciler" "Manages Routes for raw KServe deployments" "Go"
            }
            nimController = container "NIM Account Controller" "Manages NVIDIA NIM accounts and templates" "Go Operator"
            storageController = container "Storage Secret Controller" "Aggregates data connection secrets" "Go Operator"
            caController = container "Custom CA Cert Controller" "Synchronizes ODH CA certificates" "Go Operator"
            monitoringController = container "Monitoring Controller" "Creates Prometheus RoleBindings" "Go Operator"
            webhookServer = container "Webhook Server" "Validates Knative Services and NIM Accounts" "Go HTTPS Server"
        }

        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "External"
        modelmesh = softwareSystem "ModelMesh" "Multi-model serving runtime" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform" "External"
        istio = softwareSystem "Istio / Maistra" "Service mesh for traffic management and mTLS" "External"
        authorino = softwareSystem "Authorino" "Token-based authentication service" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "External ingress via Routes" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "External"
        certManager = softwareSystem "OpenShift service-ca-operator" "TLS certificate provisioning" "External"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata and lineage tracking" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science resources" "Internal ODH"
        ngcApi = softwareSystem "NVIDIA NGC API" "NIM account validation and model catalog" "External Service"
        s3Storage = softwareSystem "S3-compatible Storage" "Model artifact storage (AWS S3, MinIO, etc.)" "External Service"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster orchestration and resource management" "Platform"

        # User interactions
        user -> odhModelController "Creates InferenceService via kubectl/oc"
        admin -> odhModelController "Creates NIM Account via kubectl/oc"
        user -> dashboard "Manages data connections"

        # Controller dependencies (via Kubernetes API)
        odhModelController -> k8sAPI "Watches CRDs and creates resources" "HTTPS/443 TLS1.2+"
        odhModelController -> kserve "Watches InferenceServices, updates status" "via K8s API"
        odhModelController -> istio "Creates Gateways, VirtualServices, PeerAuthentications" "via K8s API"
        odhModelController -> authorino "Creates AuthConfigs for authentication" "via K8s API"
        odhModelController -> openshiftRouter "Creates Routes for external access" "via K8s API"
        odhModelController -> ngcApi "Validates NIM accounts and NGC API keys" "HTTPS/443 TLS1.2+"
        odhModelController -> modelRegistry "Syncs InferenceService metadata (optional)" "gRPC/9090 mTLS"

        # External dependencies required by controller
        kserve -> knative "Uses for autoscaling (serverless mode)" "via K8s API"
        kserve -> istio "Uses for traffic routing" "via K8s API"
        knative -> istio "Integrates for serverless serving" "via K8s API"

        # Monitoring
        prometheus -> odhModelController "Scrapes metrics" "HTTP/8080"

        # Certificate provisioning
        certManager -> odhModelController "Provides webhook TLS certs" "Auto-injection"

        # Dashboard integration
        dashboard -> k8sAPI "Creates data connection secrets" "HTTPS/443"
        odhModelController -> dashboard "Watches labeled secrets" "via K8s API"

        # InferenceService runtime (not controller)
        kserve -> s3Storage "Downloads model artifacts (via pods)" "HTTPS/443"
        modelmesh -> s3Storage "Downloads model artifacts (via pods)" "HTTPS/443"

        # Internal component relationships
        controller -> mmReconciler "Delegates ModelMesh InferenceServices"
        controller -> ksServerlessReconciler "Delegates KServe Serverless InferenceServices"
        controller -> ksRawReconciler "Delegates KServe Raw InferenceServices"
        ksServerlessReconciler -> istio "Creates service mesh resources" "via K8s API"
        ksServerlessReconciler -> authorino "Creates AuthConfigs" "via K8s API"
        mmReconciler -> openshiftRouter "Creates Routes" "via K8s API"
        ksRawReconciler -> openshiftRouter "Creates Routes" "via K8s API"
        nimController -> ngcApi "Validates NGC credentials" "HTTPS/443"
        storageController -> dashboard "Watches data connection secrets" "via K8s API"
        webhookServer -> ngcApi "Validates NIM accounts on admission" "HTTPS/443"
    }

    views {
        systemContext odhModelController "SystemContext" {
            include *
            autoLayout
        }

        container odhModelController "Containers" {
            include *
            autoLayout
        }

        component controller "Components" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "External Service" {
                background #e74c3c
                color #ffffff
            }
            element "Platform" {
                background #3498db
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
            }
            element "Component" {
                shape Component
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
