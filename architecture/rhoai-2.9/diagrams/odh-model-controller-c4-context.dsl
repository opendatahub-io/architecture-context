workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and deploys ML models via InferenceService CRs"
        externalClient = person "External API Client" "Sends inference requests to deployed models"

        odhModelController = softwareSystem "ODH Model Controller" "OpenShift integration controller that extends KServe with Routes, Istio, and Authorino" {
            mainController = container "OpenshiftInferenceService Reconciler" "Main controller that delegates to sub-reconcilers" "Go Operator"
            modelMeshReconciler = container "ModelMesh Reconciler" "Manages ModelMesh deployments" "Go Sub-Reconciler"
            serverlessReconciler = container "KServe Serverless Reconciler" "Manages Knative-based deployments" "Go Sub-Reconciler"
            rawReconciler = container "KServe RawDeployment Reconciler" "Manages non-Knative deployments" "Go Sub-Reconciler"
            webhook = container "Knative Service Validator" "Validates Knative Service resources" "Go Webhook Server"
            storageReconciler = container "Storage Secret Reconciler" "Manages storage credentials" "Go Controller"
            monitoringReconciler = container "Monitoring Reconciler" "Creates Prometheus RoleBindings" "Go Controller"
        }

        kserve = softwareSystem "KServe" "Model serving platform providing InferenceService CRDs" "External - Required"
        kubernetes = softwareSystem "Kubernetes API Server" "Container orchestration control plane" "External - Required"
        openshiftRouter = softwareSystem "OpenShift Router" "OpenShift-specific ingress for external access" "External - Required"
        istio = softwareSystem "Istio / Red Hat Service Mesh" "Service mesh for mTLS, routing, and telemetry" "External - Conditional"
        authorino = softwareSystem "Authorino" "Authentication and authorization service" "External - Conditional"
        knative = softwareSystem "Knative Serving" "Serverless platform for autoscaling" "External - Conditional"
        prometheus = softwareSystem "Prometheus Operator" "Monitoring and metrics collection" "External - Conditional"
        modelRegistry = softwareSystem "Model Registry" "Model metadata registry" "Internal ODH - Conditional"
        storage = softwareSystem "Model Storage (S3/PVC)" "Storage for model artifacts" "External"

        dsc = softwareSystem "DataScienceCluster Operator" "OpenDataHub platform configuration" "Internal ODH"

        %% User interactions
        user -> kubernetes "Creates InferenceService CR via kubectl/UI"
        externalClient -> openshiftRouter "Sends HTTPS inference requests" "443/TCP HTTPS TLS 1.3"

        %% Controller interactions
        odhModelController -> kubernetes "Watches InferenceServices, creates Routes/NetworkPolicies/etc." "6443/TCP HTTPS"
        odhModelController -> kserve "Watches InferenceService CRDs" "via Kubernetes API"
        odhModelController -> openshiftRouter "Creates Route resources for external access" "via Kubernetes API"
        odhModelController -> istio "Creates VirtualServices, PeerAuthentication, Telemetry" "via Kubernetes API"
        odhModelController -> authorino "Creates AuthConfig resources for JWT validation" "via Kubernetes API"
        odhModelController -> prometheus "Creates ServiceMonitor/PodMonitor resources" "via Kubernetes API"
        odhModelController -> dsc "Reads platform capabilities (service mesh, auth)" "via Kubernetes API"
        odhModelController -> modelRegistry "Fetches model metadata (optional)" "gRPC/HTTP"

        %% External request flow
        openshiftRouter -> istio "Forwards requests via VirtualService" "HTTP/HTTPS"
        istio -> authorino "Validates JWT tokens (if auth enabled)" "50051/TCP gRPC mTLS"
        istio -> kserve "Routes to InferenceService pods" "HTTP/gRPC mTLS"
        kserve -> storage "Loads model artifacts" "443/TCP HTTPS or local PVC"

        %% Monitoring
        prometheus -> kserve "Scrapes metrics from InferenceService pods" "HTTP/HTTPS via ServiceMonitor"
        prometheus -> odhModelController "Scrapes controller metrics" "8080/TCP HTTP"

        %% Dependencies
        kserve -> knative "Uses for autoscaling (Serverless mode)" "via Kubernetes API"
        kserve -> istio "Uses for traffic management and mTLS" "Service Mesh"
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
            element "External - Required" {
                background #999999
                color #ffffff
            }
            element "External - Conditional" {
                background #cccccc
                color #333333
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Internal ODH - Conditional" {
                background #a8e063
                color #333333
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6ba3e8
                color #ffffff
            }
        }
    }
}
