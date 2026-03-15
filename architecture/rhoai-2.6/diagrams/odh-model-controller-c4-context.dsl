workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys ML models using InferenceServices"
        externalClient = person "External Client" "Consumes ML inference predictions via HTTPS"

        odhModelController = softwareSystem "odh-model-controller" "Extends KServe InferenceService with OpenShift-specific networking, monitoring, and security capabilities" {
            manager = container "Manager Pod" "Runs controller with 3 replicas and leader election" "Go Operator" {
                openshiftReconciler = component "OpenshiftInferenceServiceReconciler" "Main reconciliation loop, delegates to mode-specific reconcilers"
                kserveReconciler = component "KserveInferenceServiceReconciler" "Manages OpenShift/Istio resources for KServe Serverless"
                modelmeshReconciler = component "ModelMeshInferenceServiceReconciler" "Manages OpenShift resources for ModelMesh"
                storageReconciler = component "StorageSecretReconciler" "Aggregates data connection secrets into storage-config"
                monitoringReconciler = component "MonitoringReconciler" "Creates RoleBindings for Prometheus access"
            }
        }

        kserve = softwareSystem "KServe" "Model serving platform - provides InferenceService and ServingRuntime CRDs" "External"
        istio = softwareSystem "Istio" "Service mesh for mTLS and traffic management" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform for KServe mode" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Provides external ingress via Routes API" "External OpenShift"
        openshiftServiceMesh = softwareSystem "OpenShift Service Mesh (Maistra)" "Enterprise service mesh integration" "External OpenShift"
        prometheus = softwareSystem "Prometheus Operator" "Monitoring and metrics collection" "External"
        s3Storage = softwareSystem "S3 / Object Storage" "Stores ML model artifacts" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Core Kubernetes control plane" "External"

        odhDashboard = softwareSystem "ODH Dashboard" "Creates data connection secrets for model storage" "Internal ODH"
        kserveController = softwareSystem "KServe Controller" "Creates InferenceService CRDs for model deployments" "Internal ODH"
        openshiftMonitoring = softwareSystem "OpenShift Monitoring Stack" "Prometheus deployment for metrics scraping" "Internal ODH"

        inferenceService = softwareSystem "InferenceService Pods" "Runtime pods serving ML model predictions" "Workload"

        # Relationships - Users
        dataScientist -> kserveController "Creates InferenceService via kubectl/UI"
        externalClient -> openshiftRouter "Sends inference requests" "HTTPS/443"

        # Relationships - Core functionality
        dataScientist -> odhDashboard "Creates data connections for model storage"
        kserveController -> kserve "Uses InferenceService and ServingRuntime CRDs"
        kserve -> k8sAPI "Registers CRDs"

        # Relationships - odh-model-controller watches
        odhModelController -> k8sAPI "Watches InferenceService, ServingRuntime, Secrets" "HTTPS/6443"
        manager -> openshiftReconciler "Delegates reconciliation"
        openshiftReconciler -> kserveReconciler "Delegates KServe mode"
        openshiftReconciler -> modelmeshReconciler "Delegates ModelMesh mode"
        manager -> storageReconciler "Aggregates storage secrets"
        manager -> monitoringReconciler "Configures Prometheus access"

        # Relationships - odh-model-controller creates resources
        kserveReconciler -> openshiftRouter "Creates OpenShift Routes" "API"
        kserveReconciler -> istio "Creates VirtualServices, PeerAuthentications" "API"
        kserveReconciler -> openshiftServiceMesh "Adds namespaces to ServiceMeshMemberRoll" "API"
        kserveReconciler -> prometheus "Creates ServiceMonitors, PodMonitors" "API"
        kserveReconciler -> k8sAPI "Creates NetworkPolicies, Services, Telemetry" "HTTPS/6443"
        modelmeshReconciler -> openshiftRouter "Creates OpenShift Routes for ModelMesh" "API"
        modelmeshReconciler -> k8sAPI "Creates ServiceAccounts, ClusterRoleBindings" "HTTPS/6443"
        storageReconciler -> k8sAPI "Creates/updates storage-config Secret" "HTTPS/6443"
        monitoringReconciler -> k8sAPI "Creates RoleBindings for prometheus-custom SA" "HTTPS/6443"

        # Relationships - data connections
        odhDashboard -> k8sAPI "Creates labeled Secrets (data connections)" "HTTPS/6443"
        storageReconciler -> odhDashboard "Watches Secrets with opendatahub.io/managed label"

        # Relationships - runtime flows
        openshiftRouter -> istio "Routes traffic to Istio Gateway" "HTTP/8080"
        istio -> inferenceService "Forwards to InferenceService pods (KServe)" "HTTP/8080, mTLS"
        openshiftRouter -> inferenceService "Direct routing (ModelMesh)" "HTTP/8080"
        inferenceService -> s3Storage "Downloads model artifacts" "HTTPS/443, AWS Signature v4"
        inferenceService -> storageReconciler "Mounts storage-config Secret"

        # Relationships - monitoring
        openshiftMonitoring -> prometheus "Deploys Prometheus instance"
        prometheus -> inferenceService "Scrapes metrics" "HTTP/8080, Bearer Token"
        prometheus -> istio "Scrapes Envoy sidecar metrics" "HTTP/15020"
        monitoringReconciler -> openshiftMonitoring "Grants namespace access via RoleBinding"
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

        component manager "Components" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External OpenShift" {
                background #cc0000
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Workload" {
                background #4a90e2
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
