workspace {
    model {
        user = person "Data Scientist" "Creates and manages ML model deployments on OpenShift"

        odhModelController = softwareSystem "ODH Model Controller" "Extends KServe with OpenShift-native integrations for routing, authentication, and monitoring" {
            inferenceServiceReconciler = container "InferenceService Reconciler" "Orchestrates model serving deployments across KServe Serverless, Raw, and ModelMesh modes" "Go Controller"
            servingRuntimeReconciler = container "ServingRuntime Reconciler" "Manages ServingRuntime resources and monitoring dashboards" "Go Controller"
            inferenceGraphReconciler = container "InferenceGraph Reconciler" "Manages multi-model inference pipelines" "Go Controller"
            accountReconciler = container "Account Reconciler" "Manages NVIDIA NIM account credentials and configurations" "Go Controller"
            webhookServer = container "Webhook Server" "Provides admission webhooks for validation and defaulting" "Go Service"
            metricsServer = container "Metrics Server" "Exposes controller runtime metrics for Prometheus" "HTTP Service"
        }

        // External Dependencies (Required)
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "External Required"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External Required"
        openshiftRoute = softwareSystem "OpenShift Route" "External HTTP/HTTPS routing and ingress" "External Required"

        // External Dependencies (Conditional)
        istio = softwareSystem "Istio" "Service mesh for mTLS and traffic management" "External Conditional"
        authorino = softwareSystem "Authorino" "Token-based authentication and authorization" "External Conditional"
        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics collection via ServiceMonitor/PodMonitor" "External Conditional"
        knativeServing = softwareSystem "Knative Serving" "Serverless runtime for KServe Serverless mode" "External Conditional"
        maistra = softwareSystem "Red Hat Service Mesh" "OpenShift service mesh operator (Maistra)" "External Conditional"

        // Internal ODH Dependencies
        dataScienceCluster = softwareSystem "DataScienceCluster" "Determines platform configuration and feature enablement" "Internal ODH"
        dscInitialization = softwareSystem "DSCInitialization" "Retrieves service mesh and Authorino configuration references" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Optional integration for tracking model metadata and lineage" "Internal ODH"

        // External Services
        nvidiaAPI = softwareSystem "NVIDIA NGC API" "NIM account validation and model catalog access" "External Service"

        // Integration Points (ODH Components)
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science resources" "Internal ODH"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML workflow orchestration" "Internal ODH"

        // User interactions
        user -> odhModelController "Creates InferenceService and NIM Account resources via kubectl/oc"
        user -> odhDashboard "Manages model deployments via UI"

        // ODH Model Controller dependencies
        odhModelController -> kserve "Uses InferenceService, ServingRuntime, InferenceGraph CRDs" "Kubernetes API / 6443/TCP HTTPS"
        odhModelController -> kubernetes "Resource CRUD operations, watches, status updates" "Kubernetes API / 6443/TCP HTTPS"
        odhModelController -> openshiftRoute "Creates Route resources for external access" "Kubernetes API / 6443/TCP HTTPS"
        odhModelController -> istio "Manages Gateway, VirtualService, PeerAuthentication" "gRPC / 15010/TCP mTLS"
        odhModelController -> authorino "Creates AuthConfig resources" "Kubernetes API / 6443/TCP HTTPS"
        odhModelController -> prometheusOperator "Creates ServiceMonitor and PodMonitor" "Kubernetes API / 6443/TCP HTTPS"
        odhModelController -> knativeServing "Validates Knative Service resources via webhook" "Webhook / 9443/TCP HTTPS"
        odhModelController -> maistra "Manages ServiceMeshMember enrollment" "Kubernetes API / 6443/TCP HTTPS"
        odhModelController -> dataScienceCluster "Reads platform configuration" "Watch CRD"
        odhModelController -> dscInitialization "Reads service mesh and auth references" "Watch CRD"
        odhModelController -> modelRegistry "Fetches model metadata and updates inference service metadata" "REST API / 443/TCP HTTPS"
        odhModelController -> nvidiaAPI "Validates NIM account and accesses model catalog" "REST API / 443/TCP HTTPS"

        // Integration points
        odhDashboard -> odhModelController "Manages InferenceServices via Kubernetes API" "Indirect via CRD"
        dsPipelines -> odhModelController "Auto-deploys models as InferenceServices" "Indirect via CRD"

        // Monitoring
        prometheusOperator -> odhModelController "Scrapes /metrics endpoint" "HTTP / 8080/TCP"

        // Container interactions
        user -> webhookServer "Creates resources triggering admission webhooks"
        kubernetes -> webhookServer "Calls mutating and validating webhooks" "HTTPS / 9443/TCP"
        inferenceServiceReconciler -> kubernetes "Creates ServiceAccount, Route, Istio resources, etc."
        accountReconciler -> nvidiaAPI "Validates NGC API key"
        metricsServer -> prometheusOperator "Exposes metrics"
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
            element "External Required" {
                background #e74c3c
                color #ffffff
            }
            element "External Conditional" {
                background #f39c12
                color #000000
            }
            element "Internal ODH" {
                background #27ae60
                color #ffffff
            }
            element "External Service" {
                background #95a5a6
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6c8ebf
                color #ffffff
            }
        }

        theme default
    }
}
