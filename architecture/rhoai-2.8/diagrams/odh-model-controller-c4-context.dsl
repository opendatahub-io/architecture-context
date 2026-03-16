workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and deploys ML models via InferenceServices"
        dashboard = person "Platform Admin" "Manages data connections and storage configurations"

        odhModelController = softwareSystem "ODH Model Controller" "Extends KServe and ModelMesh with OpenShift integrations (Routes, Service Mesh, Monitoring)" {
            controllerManager = container "Controller Manager" "Leader-elected deployment with 3 replicas" "Go 1.21" {
                isvcController = component "InferenceService Controller" "Watches InferenceServices and provisions OpenShift resources" "Reconciler"
                storageController = component "StorageSecret Controller" "Aggregates data connection secrets into storage-config" "Reconciler"
                caController = component "KServeCustomCACert Controller" "Injects custom CA certificates for enterprise trust stores" "Reconciler"
                monitoringController = component "Monitoring Controller" "Creates RoleBindings for Prometheus access" "Reconciler"
                kserveReconciler = component "KServe Reconciler" "Handles KServe Serverless/RawDeployment mode resources" "Sub-Reconciler"
                modelMeshReconciler = component "ModelMesh Reconciler" "Handles ModelMesh mode resources" "Sub-Reconciler"
            }

            metricsService = container "Metrics Service" "Exposes Prometheus metrics" "HTTP :8080"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        kserve = softwareSystem "KServe" "Provides InferenceService CRD and model serving runtime" "External ODH Component"
        modelMesh = softwareSystem "ModelMesh Serving" "Multi-model serving runtime" "External ODH Component"
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS, traffic management, and telemetry" "External (v1.17.4)"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External (Operator v0.64.1)"
        openshiftRouter = softwareSystem "OpenShift Router" "External ingress for Routes" "External (OpenShift)"
        s3Storage = softwareSystem "S3-Compatible Storage" "Model artifact storage" "External"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science resources" "Internal ODH Component"

        // User interactions
        user -> k8sAPI "Creates InferenceService CRs via kubectl/oc"
        user -> odhDashboard "Manages data connections and deployments"
        dashboard -> k8sAPI "Creates data connection secrets"

        // ODH Model Controller interactions
        odhModelController -> k8sAPI "Watches InferenceServices, ServingRuntimes, Secrets; creates Routes, Service Mesh resources, monitoring resources" "HTTPS/6443 TLS 1.2+"
        odhModelController -> kserve "Coordinates reconciliation (watches CRDs)" "Via K8s API"
        odhModelController -> modelMesh "Coordinates reconciliation (watches CRDs)" "Via K8s API"
        odhModelController -> istio "Creates ServiceMeshMemberRoll, PeerAuthentication, Telemetry" "Via K8s API"
        odhModelController -> prometheus "Creates ServiceMonitors, PodMonitors, RoleBindings" "Via K8s API"
        odhModelController -> openshiftRouter "Creates Routes for external access" "Via K8s API"

        // Monitoring flow
        prometheus -> odhModelController "Scrapes /metrics endpoint" "HTTP/8080"
        prometheus -> kserve "Scrapes InferenceService metrics (if ServiceMonitor exists)" "HTTP/8080"

        // Storage flow
        odhDashboard -> k8sAPI "Creates data connection secrets"
        storageController -> k8sAPI "Reads data connection secrets, creates storage-config" "Via Controller Manager"
        kserve -> s3Storage "Downloads model artifacts using storage-config credentials" "HTTPS/443"
        modelMesh -> s3Storage "Downloads model artifacts using storage-config credentials" "HTTPS/443"

        // External access
        user -> openshiftRouter "Sends inference requests" "HTTPS/443"
        openshiftRouter -> kserve "Routes to InferenceService endpoints" "Via Service Mesh"
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

        component controllerManager "Components" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External ODH Component" {
                background #7ed321
                color #000000
            }
            element "Internal ODH Component" {
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
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #f5a623
                color #ffffff
                shape person
            }
        }
    }
}
