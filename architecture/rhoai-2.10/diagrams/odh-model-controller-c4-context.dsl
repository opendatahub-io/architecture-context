workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages ML model deployments on OpenShift AI"

        odhModelController = softwareSystem "ODH Model Controller" "Extends KServe and ModelMesh with OpenShift-native capabilities: Routes, Service Mesh, AuthN/AuthZ, monitoring" {
            inferenceServiceController = container "InferenceService Controller" "Routes reconciliation to ModelMesh, KServe Serverless, or KServe Raw based on deployment mode" "Go Operator"
            storageSecretController = container "StorageSecret Controller" "Aggregates data connection secrets into storage-config for model storage access" "Go Operator"
            customCACertController = container "KServeCustomCACert Controller" "Propagates custom CA certificates for secure S3 storage" "Go Operator"
            monitoringController = container "Monitoring Controller" "Creates RoleBindings for Prometheus metrics collection" "Go Operator"
            modelRegistryController = container "ModelRegistry InferenceService Controller" "Syncs InferenceService deployments with Model Registry metadata (optional)" "Go Operator"
            webhookServer = container "Knative Service Validator" "Validates Knative Services created by KServe Serverless mode" "Go Webhook Server"
        }

        kserve = softwareSystem "KServe" "Standardized model inference platform (v0.11.0)" "External"
        modelmesh = softwareSystem "ModelMesh Serving" "Multi-model serving platform" "External"
        istio = softwareSystem "Istio / OpenShift Service Mesh" "Service mesh for traffic management, mTLS, telemetry (v1.17+)" "External"
        authorino = softwareSystem "Authorino" "Authorization service for API authentication (v0.15.0)" "External"
        prometheus = softwareSystem "Prometheus Operator" "Monitoring stack for metrics collection (v0.64.1)" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform (v0.37.1)" "External"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata and lineage tracking (v0.1.1)" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller for external access" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster orchestration and API" "Platform"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for data science workflows, provides serving runtime templates" "Internal ODH"
        s3Storage = softwareSystem "S3 Storage" "Model artifact storage (AWS S3, MinIO, etc.)" "External"

        # User interactions
        user -> odhDashboard "Creates InferenceServices and data connections via UI"
        user -> k8sAPI "Creates InferenceServices via kubectl/oc CLI" "HTTPS/6443 TLS1.2+"

        # ODH Model Controller interactions
        inferenceServiceController -> k8sAPI "Watches InferenceService, ServingRuntime CRDs; creates Routes, Services, etc." "HTTPS/6443 TLS1.2+"
        storageSecretController -> k8sAPI "Watches data connection Secrets, creates storage-config Secrets" "HTTPS/6443 TLS1.2+"
        customCACertController -> k8sAPI "Watches odh-trusted-ca-bundle ConfigMap, propagates to namespaces" "HTTPS/6443 TLS1.2+"
        monitoringController -> k8sAPI "Creates RoleBindings for Prometheus access to inference namespaces" "HTTPS/6443 TLS1.2+"
        modelRegistryController -> modelRegistry "Syncs InferenceService metadata" "gRPC/8080 TLS (optional)"
        webhookServer -> k8sAPI "Validates Knative Services via admission webhook" "HTTPS/9443 TLS (Service CA)"

        # External dependencies
        odhModelController -> kserve "Extends with OpenShift Routes, Istio integration"
        odhModelController -> modelmesh "Extends with OpenShift Routes, Istio integration"
        odhModelController -> istio "Creates VirtualServices, PeerAuthentications, Telemetries for service mesh" "API Calls TLS1.2+"
        odhModelController -> authorino "Creates AuthConfig resources for inference endpoint authentication" "API Calls TLS1.2+"
        odhModelController -> prometheus "Creates ServiceMonitors, PodMonitors for metrics scraping" "API Calls TLS1.2+"
        odhModelController -> knative "Validates Knative Services for KServe Serverless mode" "Webhook HTTPS/9443"
        odhModelController -> openshiftRouter "Creates Routes for external inference access" "API Calls TLS1.2+"

        # Internal ODH dependencies
        odhModelController -> odhDashboard "Reads serving runtime templates from ConfigMaps"
        odhDashboard -> k8sAPI "Creates InferenceServices on behalf of users"

        # Inference workloads access storage
        kserve -> s3Storage "Downloads model artifacts" "HTTPS/443 TLS1.2+"
        modelmesh -> s3Storage "Downloads model artifacts" "HTTPS/443 TLS1.2+"

        # Prometheus scrapes metrics
        prometheus -> odhModelController "Scrapes /metrics endpoint" "HTTP/8080"
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

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Platform" {
                background #d79b00
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

    configuration {
        scope softwaresystem
    }
}
