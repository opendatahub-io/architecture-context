workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models using ServingRuntime and Predictor CRDs"
        mlEngineer = person "ML Engineer" "Manages cluster-wide serving runtimes and model deployment configurations"

        modelmeshServing = softwareSystem "ModelMesh Serving" "Kubernetes controller managing multi-model serving runtimes with model placement, scaling, and lifecycle management" {
            servingRuntimeController = container "ServingRuntime Controller" "Reconciles ServingRuntime and ClusterServingRuntime resources to manage model serving deployments" "Go Controller"
            predictorController = container "Predictor Controller" "Reconciles Predictor resources to manage individual model lifecycle" "Go Controller"
            serviceController = container "Service Controller" "Reconciles Deployments to manage headless services and monitoring" "Go Controller"
            deploymentController = container "Deployment Controller" "Reconciles Deployment resources" "Go Controller"
            endpointsController = container "Endpoints Controller" "Reconciles Endpoints resources for gRPC service discovery" "Go Controller"
            namespaceController = container "Namespace Controller" "Reconciles Namespace resources" "Go Controller"
            hpaReconciler = container "HPA Reconciler" "Manages HorizontalPodAutoscaler resources for autoscaling serving runtimes" "Go Controller"
            webhookServer = container "Webhook Server" "Validates ServingRuntime/ClusterServingRuntime and converts Predictor CRDs" "Go Webhook, port 9443/TLS"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        etcd = softwareSystem "etcd" "Distributed key-value store for ModelMesh model placement coordination" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring infrastructure via ServiceMonitor CRDs" "Internal Platform"
        kserve = softwareSystem "KServe" "ML model serving platform providing InferenceService CRD" "Internal Platform"

        dataScientist -> modelmeshServing "Creates Predictor/InferenceService via kubectl"
        mlEngineer -> modelmeshServing "Creates ServingRuntime/ClusterServingRuntime via kubectl"

        servingRuntimeController -> kubernetesAPI "Watches CRDs, manages Deployments" "HTTPS/6443, TLS 1.2+"
        servingRuntimeController -> etcd "Model placement coordination" "etcd client v3"
        predictorController -> kubernetesAPI "Watches Predictor/InferenceService" "HTTPS/6443, TLS 1.2+"
        serviceController -> kubernetesAPI "Creates Services, ServiceMonitors" "HTTPS/6443, TLS 1.2+"
        serviceController -> prometheusOperator "Creates/manages ServiceMonitor CRDs" "HTTPS, TLS 1.2+"

        modelmeshServing -> kubernetesAPI "Resource operations via ServiceAccount token" "HTTPS/6443"
        modelmeshServing -> etcd "Model placement coordination" "etcd v3"
        modelmeshServing -> kserve "Watches InferenceService CRD" "HTTPS, TLS 1.2+"
        modelmeshServing -> prometheusOperator "Manages ServiceMonitor resources" "HTTPS"

        kubernetesAPI -> webhookServer "Admission review requests" "HTTPS/9443"
    }

    views {
        systemContext modelmeshServing "SystemContext" {
            include *
            autoLayout
        }

        container modelmeshServing "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
