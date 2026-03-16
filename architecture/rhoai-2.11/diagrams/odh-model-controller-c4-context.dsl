workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and manages ML model inference services"
        admin = person "Platform Administrator" "Manages ODH platform and infrastructure"

        odhModelController = softwareSystem "ODH Model Controller" "Extends KServe and ModelMesh with OpenShift-specific integrations for routing, service mesh, authorization, and monitoring" {
            mainReconciler = container "InferenceService Reconciler" "Main controller that delegates to deployment-mode-specific reconcilers" "Go/Kubebuilder" {
                tags "Controller"
            }
            serverlessReconciler = container "KServe Serverless Reconciler" "Manages Knative-based inference with Istio, routes, auth, and monitoring" "Go" {
                tags "Controller"
            }
            rawReconciler = container "KServe Raw Reconciler" "Manages direct Kubernetes deployment-based inference services" "Go" {
                tags "Controller"
            }
            modelmeshReconciler = container "ModelMesh Reconciler" "Manages ModelMesh-based inference services" "Go" {
                tags "Controller"
            }
            storageReconciler = container "StorageSecret Reconciler" "Reconciles storage configuration secrets" "Go" {
                tags "Controller"
            }
            monitoringReconciler = container "Monitoring Reconciler" "Creates ServiceMonitors and PodMonitors" "Go" {
                tags "Controller"
            }
            webhookServer = container "Webhook Server" "Validates Knative Service configurations for service mesh" "Go/HTTPS" {
                tags "Webhook"
            }
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics" "Go/HTTP" {
                tags "Metrics"
            }
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Manages all Kubernetes resources and orchestration" "External"
        kserve = softwareSystem "KServe" "Core inference serving framework (v0.12.1)" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform (v0.39.3)" "External"
        istio = softwareSystem "Istio/Maistra Service Mesh" "Service mesh for traffic management and mTLS (1.19.x)" "External"
        authorino = softwareSystem "Authorino" "API authorization framework (v0.15.0)" "External"
        prometheus = softwareSystem "Prometheus Operator" "Metrics collection and monitoring (v0.64.1)" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "External routing for InferenceServices" "External"
        certManager = softwareSystem "cert-manager / OpenShift Service CA" "TLS certificate provisioning for webhooks" "External"

        modelRegistry = softwareSystem "Model Registry" "ML model versioning and metadata management" "Internal ODH"
        dsc = softwareSystem "DataScienceCluster" "ODH platform configuration" "Internal ODH"
        dsci = softwareSystem "DSCInitialization" "ODH platform initialization and feature flags" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for ODH platform management" "Internal ODH"

        s3Storage = softwareSystem "S3 Object Storage" "Model artifact storage (AWS S3, MinIO, etc.)" "External"

        # Relationships
        dataScientist -> odhModelController "Creates and manages InferenceServices via kubectl/UI"
        admin -> odhModelController "Configures platform settings and monitors"

        odhModelController -> k8sAPI "Watches and manages Kubernetes resources" "HTTPS/6443 TLS 1.3"
        odhModelController -> modelRegistry "Registers inference service metadata" "gRPC/9090 mTLS"
        odhModelController -> prometheus "Exposes controller metrics" "HTTP/8080"

        mainReconciler -> serverlessReconciler "Delegates to (KServe Serverless mode)"
        mainReconciler -> rawReconciler "Delegates to (KServe Raw mode)"
        mainReconciler -> modelmeshReconciler "Delegates to (ModelMesh mode)"

        serverlessReconciler -> istio "Creates VirtualServices, Gateways, PeerAuthentications" "K8s CRD"
        serverlessReconciler -> authorino "Creates AuthConfigs for API auth" "K8s CRD"
        serverlessReconciler -> openshiftRouter "Creates Routes for external access" "K8s CRD"
        serverlessReconciler -> knative "Integrates with for autoscaling" "K8s CRD"

        modelmeshReconciler -> openshiftRouter "Creates Routes for ModelMesh services" "K8s CRD"
        monitoringReconciler -> prometheus "Creates ServiceMonitors and PodMonitors" "K8s CRD"

        webhookServer -> k8sAPI "Validates Knative Service configurations" "HTTPS/9443 TLS 1.2+"
        webhookServer -> certManager "Uses TLS certificates from" "K8s Secret mount"

        kserve -> odhModelController "Triggers reconciliation on InferenceService changes" "K8s Watch"
        knative -> webhookServer "Knative Service creation triggers validation" "Admission Webhook"

        odhModelController -> dsc "Reads platform configuration" "K8s CRD Watch"
        odhModelController -> dsci "Reads feature flags and initialization config" "K8s CRD Watch"

        odhDashboard -> odhModelController "Manages InferenceServices via K8s API" "Indirect via K8s API"

        kserve -> s3Storage "Loads model artifacts from" "HTTPS/443 TLS 1.2+"
    }

    views {
        systemContext odhModelController "ODHModelControllerContext" {
            include *
            autoLayout
        }

        container odhModelController "ODHModelControllerContainers" {
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
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "Webhook" {
                background #f5a623
                color #ffffff
            }
            element "Metrics" {
                background #bd10e0
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }
}
