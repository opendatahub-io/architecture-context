workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and deploys InferenceServices for ML model serving"
        admin = person "Platform Administrator" "Manages NIM accounts and serving infrastructure"

        odhModelController = softwareSystem "ODH Model Controller" "Extends KServe with OpenShift integration, service mesh, auth, and automated resource management" {
            reconcilers = container "Reconcilers" "Manages InferenceService lifecycle and creates OpenShift/Istio resources" "Go Operator" {
                isvcController = component "InferenceService Controller" "Creates Routes, VirtualServices, AuthConfigs, monitoring" "Go Controller"
                igraphController = component "InferenceGraph Controller" "Manages multi-model inference pipelines" "Go Controller"
                llmController = component "LLMInferenceService Controller" "Handles LLM-specific inference services" "Go Controller"
                nimController = component "NIM Account Controller" "Manages NVIDIA NIM integration, API keys, pull secrets" "Go Controller"
                srController = component "ServingRuntime Controller" "Manages runtime templates" "Go Controller"
            }

            webhooks = container "Admission Webhooks" "Validates and mutates inference workload resources" "Go Webhook Server" {
                podWebhook = component "Pod Mutating Webhook" "Mutates inference Pod specs" "Webhook"
                isvcWebhook = component "InferenceService Webhook" "Validates/mutates InferenceServices" "Webhook"
                nimWebhook = component "NIM Account Webhook" "Validates NIM Account resources" "Webhook"
            }

            metricsServer = container "Metrics Server" "Exposes Prometheus metrics" "HTTP Endpoint" "Port: 8080/TCP (TODO: 8443 HTTPS)"
        }

        kserve = softwareSystem "KServe" "Core model serving platform - creates Knative Services or Deployments" "External"
        istio = softwareSystem "Istio/Maistra Service Mesh" "Service mesh for mTLS, routing, telemetry" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform" "External"
        authorino = softwareSystem "Authorino" "Authentication/authorization for inference endpoints" "External"
        kuadrant = softwareSystem "Kuadrant" "Alternative auth mechanism (AuthPolicy)" "External"
        prometheus = softwareSystem "Prometheus Operator" "Metrics collection and monitoring" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling for inference workloads" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks" "External"
        ngc = softwareSystem "NVIDIA NGC" "NVIDIA NIM model catalog and image registry" "External"
        s3 = softwareSystem "S3/Object Storage" "Model artifact storage" "External"

        modelRegistry = softwareSystem "Model Registry" "Tracks model metadata and versions" "Internal ODH"
        dsc = softwareSystem "DataScienceCluster" "ODH cluster configuration and component enablement" "Internal ODH"
        dscInit = softwareSystem "DSCInitialization" "Service mesh and auth initialization config" "Internal ODH"

        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane" "Infrastructure"
        openshiftRoute = softwareSystem "OpenShift Route API" "External HTTPS access to services" "Infrastructure"

        // User relationships
        user -> odhModelController "Creates InferenceService via kubectl/UI"
        admin -> odhModelController "Creates NIM Account with NGC API key"

        // Controller to external dependencies
        odhModelController -> kserve "Coordinates InferenceService reconciliation" "Watch CRDs"
        odhModelController -> istio "Creates VirtualServices, Gateways, PeerAuthentication" "CRD Management"
        odhModelController -> authorino "Creates AuthConfig resources" "CRD Management"
        odhModelController -> kuadrant "Creates AuthPolicy resources (optional)" "CRD Management"
        odhModelController -> prometheus "Exposes metrics, creates ServiceMonitors" "HTTP/8080"
        odhModelController -> keda "Creates TriggerAuthentication for autoscaling" "CRD Management"
        odhModelController -> certManager "Uses for webhook certificate rotation" "Certificate consumer"
        odhModelController -> ngc "Validates accounts, fetches model catalog (NIM)" "HTTPS/443"
        odhModelController -> openshiftRoute "Creates Routes for external access" "REST API"
        odhModelController -> k8sAPI "Watches/creates all Kubernetes resources" "HTTPS/6443"

        // Controller to internal ODH
        odhModelController -> modelRegistry "Registers InferenceService metadata (optional)" "REST API"
        odhModelController -> dsc "Reads component enablement state" "Watch CRD"
        odhModelController -> dscInit "Reads service mesh and auth settings" "Watch CRD"

        // External services
        kserve -> knative "Uses for serverless autoscaling" "Serverless mode"
        kserve -> k8sAPI "Creates Knative Services or Deployments"

        // Deployment relationships
        deploymentEnvironment "Production" {
            deploymentNode "OpenShift Cluster" {
                deploymentNode "odh-model-controller namespace" {
                    containerInstance odhModelController.reconcilers
                    containerInstance odhModelController.webhooks
                    containerInstance odhModelController.metricsServer
                }
                deploymentNode "User namespaces" {
                    softwareSystemInstance kserve
                }
                deploymentNode "istio-system namespace" {
                    softwareSystemInstance istio
                }
                deploymentNode "knative-serving namespace" {
                    softwareSystemInstance knative
                }
            }
        }
    }

    views {
        systemContext odhModelController "ODHModelControllerContext" {
            include *
            autoLayout lr
        }

        container odhModelController "ODHModelControllerContainers" {
            include *
            autoLayout lr
        }

        component reconcilers "ReconcilersComponents" {
            include *
            autoLayout lr
        }

        deployment odhModelController "Production" "ODHModelControllerDeployment" {
            include *
            autoLayout lr
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
            element "Infrastructure" {
                background #4a90e2
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
        }

        theme default
    }
}
