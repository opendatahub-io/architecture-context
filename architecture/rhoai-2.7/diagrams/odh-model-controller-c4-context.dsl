workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and deploys ML models using InferenceServices"
        infraAdmin = person "Infrastructure Administrator" "Manages OpenShift cluster and service mesh"

        odhModelController = softwareSystem "ODH Model Controller" "Extends KServe with OpenShift-specific integrations (Routes, NetworkPolicies, mTLS)" {
            manager = container "Manager Deployment" "Controller manager with leader election (3 replicas)" "Go + Kubebuilder" {
                isvcController = component "InferenceService Controller" "Orchestrates reconciliation based on deployment mode" "Go Reconciler"
                kserveReconciler = component "KServe Reconciler" "Manages KServe-specific resources" "Go Reconciler"
                modelmeshReconciler = component "ModelMesh Reconciler" "Manages ModelMesh-specific resources" "Go Reconciler"
                monitoringController = component "Monitoring Controller" "Creates RoleBindings for Prometheus" "Go Reconciler"
                storageController = component "Storage Secret Controller" "Manages storage configuration secrets" "Go Reconciler"
            }
            metricsService = container "Metrics Service" "Prometheus metrics endpoint" "HTTP Service" "Supporting"
        }

        kserve = softwareSystem "KServe" "Serverless model inference platform" "External Dependency"
        istio = softwareSystem "Istio / OpenShift Service Mesh" "Service mesh for mTLS, routing, and observability" "External Dependency"
        openshift = softwareSystem "OpenShift Platform" "Kubernetes distribution with Routes and integrated monitoring" "Platform"
        prometheus = softwareSystem "Prometheus Operator" "Monitoring and metrics collection" "External Dependency"

        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for data science workbenches and model serving" "Internal ODH"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML workflow orchestration" "Internal ODH"

        s3Storage = softwareSystem "S3 Storage" "Model artifact storage (AWS S3, MinIO, etc.)" "External Service"

        # Relationships - User interactions
        user -> odhModelController "Creates InferenceService CRs via kubectl/UI"
        user -> kserve "Defines model serving runtimes"
        user -> s3Storage "Uploads model artifacts"
        infraAdmin -> openshift "Manages cluster infrastructure"
        infraAdmin -> istio "Configures service mesh"

        # Relationships - Controller interactions
        odhModelController -> kserve "Watches InferenceService and ServingRuntime CRDs" "Kubernetes API/6443"
        odhModelController -> openshift "Creates Routes, NetworkPolicies, RBAC" "Kubernetes API/6443"
        odhModelController -> istio "Creates VirtualServices, PeerAuthentications, Telemetries" "Kubernetes API/6443 + Istio API/15017"
        odhModelController -> prometheus "Creates ServiceMonitors and PodMonitors" "Kubernetes API/6443"

        # Relationships - Integration
        odhDashboard -> odhModelController "Allowed traffic via NetworkPolicy"
        dsPipelines -> kserve "Auto-deploys models as InferenceServices"
        prometheus -> odhModelController "Scrapes controller metrics" "HTTP/8080"
        prometheus -> kserve "Scrapes predictor metrics via ServiceMonitors" "HTTP/8086, HTTP/3000"

        # Relationships - Data flow
        kserve -> s3Storage "Downloads model artifacts" "HTTPS/443"
        kserve -> istio "Routes traffic through service mesh" "mTLS"
        user -> openshift "Accesses model endpoints" "HTTPS/443"
        openshift -> istio "Forwards traffic to Istio Ingress Gateway"
        istio -> kserve "Routes to predictor pods" "mTLS"

        # Internal component relationships
        isvcController -> kserveReconciler "Delegates KServe reconciliation"
        isvcController -> modelmeshReconciler "Delegates ModelMesh reconciliation"
        kserveReconciler -> openshift "Creates Routes in istio-system namespace"
        kserveReconciler -> istio "Creates mesh resources in ISVC namespace"
        monitoringController -> prometheus "Creates RBAC for metrics access"
    }

    views {
        systemContext odhModelController "SystemContext" {
            include *
            autoLayout lr
        }

        container odhModelController "Containers" {
            include *
            autoLayout lr
        }

        component manager "Components" {
            include *
            autoLayout tb
        }

        styles {
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #000000
            }
            element "Supporting" {
                background #e0e0e0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }

        theme default
    }
}
