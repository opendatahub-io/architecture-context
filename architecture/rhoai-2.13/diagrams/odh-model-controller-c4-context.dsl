workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML models for inference"
        admin = person "Platform Admin" "Manages ODH platform and model serving infrastructure"

        odhModelController = softwareSystem "ODH Model Controller" "Extends KServe with OpenShift-specific integrations for model serving" {
            controllerManager = container "Controller Manager" "Orchestrates reconciliation of InferenceServices" "Go Operator (Kubebuilder)" {
                oishvcReconciler = component "OpenshiftInferenceServiceReconciler" "Main reconciler - determines deployment mode" "Go Controller"
                mmReconciler = component "ModelMeshReconciler" "Handles ModelMesh-specific reconciliation" "Go Controller"
                kServerlessReconciler = component "KServeServerlessReconciler" "Handles KServe Serverless (Knative) mode" "Go Controller"
                kRawReconciler = component "KServeRawReconciler" "Handles KServe Raw deployment mode" "Go Controller"
                storageReconciler = component "StorageSecretReconciler" "Aggregates data connection secrets" "Go Controller"
                caReconciler = component "CustomCACertReconciler" "Manages custom CA certificates" "Go Controller"
                monitoringReconciler = component "MonitoringReconciler" "Creates monitoring RoleBindings" "Go Controller"
                mrReconciler = component "ModelRegistryReconciler" "Integrates with Model Registry" "Go Controller"
            }

            webhookServer = container "Webhook Server" "Validates Knative Service resources" "Go Webhook" {
                knativeValidator = component "KnativeServiceValidator" "Validates Knative Service CRs" "ValidatingWebhook"
            }
        }

        # External ODH Components
        kserve = softwareSystem "KServe" "Core model serving platform - InferenceService CRD and serving logic" "External - ODH Core"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform for KServe Serverless mode" "External - ODH Core"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for mTLS, traffic management, observability" "External - ODH Core"
        authorino = softwareSystem "Authorino" "API authorization for InferenceService endpoints" "External - Optional"
        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics collection and monitoring" "External - Optional"
        modelRegistry = softwareSystem "Model Registry" "Model versioning and metadata tracking" "Internal ODH - Optional"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for creating data connections and InferenceServices" "Internal ODH"

        # OpenShift Platform
        openshift = softwareSystem "OpenShift Platform" "Kubernetes platform with Routes, service-ca-operator" "External - Platform"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller for external access" "External - Platform"

        # External Services
        s3 = softwareSystem "S3 Storage" "Model artifact storage (AWS S3 or S3-compatible)" "External Service"
        containerRegistry = softwareSystem "Container Registry" "Serving runtime container images" "External Service"

        # Relationships - User interactions
        user -> odhDashboard "Creates InferenceServices and data connections via"
        user -> odhModelController "Deploys InferenceServices via kubectl"
        admin -> odhModelController "Configures service mesh and auth settings"

        # Relationships - ODH Model Controller interactions
        odhModelController -> kserve "Watches InferenceService CRs from" "Kubernetes API"
        odhModelController -> openshift "Creates OpenShift Routes via" "Kubernetes API"
        odhModelController -> istio "Creates VirtualServices, Gateways, PeerAuthentications via" "Kubernetes API"
        odhModelController -> authorino "Creates AuthConfigs via" "Kubernetes API"
        odhModelController -> prometheusOperator "Creates ServiceMonitors, PodMonitors via" "Kubernetes API"
        odhModelController -> modelRegistry "Queries model metadata via" "gRPC"
        odhModelController -> odhDashboard "Consumes data connection secrets from" "Kubernetes API"
        odhModelController -> knative "Validates Knative Services via webhook" "Webhook API"

        # Relationships - Runtime data flows
        user -> openshiftRouter "Sends inference requests to" "HTTPS/443"
        openshiftRouter -> istio "Routes to Istio Gateway via" "mTLS"
        istio -> knative "Routes to Knative Activator via" "mTLS"
        knative -> kserve "Routes to predictor pods via" "mTLS"
        kserve -> s3 "Loads model artifacts from" "HTTPS"
        kserve -> containerRegistry "Pulls runtime images from" "HTTPS"

        # Relationships - Monitoring
        prometheusOperator -> odhModelController "Scrapes controller metrics from" "HTTPS/8080"
        prometheusOperator -> kserve "Scrapes model metrics from" "HTTPS"

        # Relationships - Dashboard to controller
        odhDashboard -> openshift "Creates data connection secrets via" "Kubernetes API"
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

        component controllerManager "ControllerComponents" {
            include *
            autoLayout
        }

        styles {
            element "External - ODH Core" {
                background #7ed321
                color #000000
            }
            element "External - Optional" {
                background #b8e986
                color #000000
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Internal ODH - Optional" {
                background #b8e986
                color #000000
            }
            element "External - Platform" {
                background #f5a623
                color #000000
            }
            element "External Service" {
                background #999999
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
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                shape person
                color #ffffff
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
