workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML models on RHOAI/ODH platform"

        odhModelController = softwareSystem "odh-model-controller" "Extends KServe with OpenShift integration, service mesh, authorization, and monitoring" {
            inferenceServiceController = container "InferenceService Controller" "Reconciles KServe InferenceServices and creates OpenShift/mesh resources" "Go Operator"
            storageSecretController = container "StorageSecret Controller" "Aggregates data connection secrets into storage config" "Go Controller"
            customCACertController = container "KServeCustomCACert Controller" "Propagates custom CA certificates to KServe deployments" "Go Controller"
            monitoringController = container "Monitoring Controller" "Sets up Prometheus monitoring for inference services" "Go Controller"
            modelRegistryController = container "ModelRegistry Controller" "Integrates InferenceServices with Model Registry" "Go Controller"
            webhookServer = container "Knative Service Webhook" "Validates Knative Service configurations for KServe" "ValidatingWebhook"
            metricsExporter = container "Metrics Exporter" "Exposes controller metrics on /metrics endpoint" "HTTP Server"
        }

        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "External"
        knativeServing = softwareSystem "Knative Serving" "Serverless autoscaling platform for Kubernetes" "External"
        istio = softwareSystem "Istio/Service Mesh" "Service mesh providing mTLS, traffic management, and telemetry" "External"
        authorino = softwareSystem "Authorino" "Kubernetes-native authorization service" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring stack for Kubernetes" "External"
        certManager = softwareSystem "cert-manager / OCP Service CA" "TLS certificate provisioning" "External"

        odhOperator = softwareSystem "opendatahub-operator" "Orchestrates ODH/RHOAI platform components" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and versioning information" "Internal ODH"
        serviceMeshCP = softwareSystem "Service Mesh Control Plane" "Red Hat OpenShift Service Mesh management" "Internal ODH"

        openshiftRouter = softwareSystem "OpenShift Router" "Provides external ingress via Routes" "OpenShift Platform"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane API" "OpenShift Platform"

        s3Storage = softwareSystem "S3 Storage" "Object storage for model artifacts (AWS S3 or compatible)" "External"

        // User interactions
        user -> odhModelController "Creates InferenceService via kubectl/UI" "kubectl, RHOAI Dashboard"
        user -> s3Storage "Uploads model artifacts" "S3 API"

        // Controller to external dependencies
        odhModelController -> kserve "Watches InferenceService CRDs and status updates" "K8s API"
        odhModelController -> istio "Creates Gateways, VirtualServices, PeerAuthentications, AuthorizationPolicies" "K8s API"
        odhModelController -> authorino "Creates AuthConfig resources for inference endpoints" "K8s API"
        odhModelController -> prometheusOperator "Creates ServiceMonitor and PodMonitor resources" "K8s API"
        odhModelController -> certManager "Uses for webhook TLS certificates" "Service CA"
        odhModelController -> knativeServing "Depends on for serverless deployment mode" "K8s API"
        odhModelController -> openshiftRouter "Creates Routes for external access" "K8s API"
        odhModelController -> k8sAPI "Manages resources and watches CRDs" "HTTPS/6443"

        // Controller to internal ODH components
        odhModelController -> odhOperator "Reads DataScienceCluster and DSCInitialization for config" "K8s API"
        odhModelController -> modelRegistry "Fetches model metadata (optional)" "HTTP/8080"
        odhModelController -> serviceMeshCP "Enrolls inference namespaces via ServiceMeshMember" "K8s API"

        // Inference service interactions (created by controller)
        kserve -> istio "Uses for traffic routing and mTLS" "Service Mesh"
        kserve -> knativeServing "Uses for autoscaling" "K8s Integration"
        kserve -> s3Storage "Downloads model artifacts" "HTTPS/443 AWS Signature"
        kserve -> authorino "Token validation for inference requests" "HTTP/5001"

        // Monitoring
        prometheusOperator -> odhModelController "Scrapes /metrics endpoint" "HTTP/8080"
        prometheusOperator -> kserve "Scrapes inference service metrics" "HTTP/8080"
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
            element "OpenShift Platform" {
                background #ee0000
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
