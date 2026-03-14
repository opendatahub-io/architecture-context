workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML models for inference"
        admin = person "Platform Admin" "Configures NVIDIA NIM accounts and serving infrastructure"

        odhModelController = softwareSystem "ODH Model Controller" "Kubernetes operator that extends KServe with OpenShift integration, service mesh, authentication, monitoring, and automated resource management" {
            reconcilers = container "Reconcilers" "Manages InferenceService lifecycle and resource creation" "Go Operator" {
                isvcController = component "InferenceService Controller" "Creates Routes, VirtualServices, auth configs, monitoring"
                igController = component "InferenceGraph Controller" "Manages multi-model inference pipelines"
                llmController = component "LLMInferenceService Controller" "Specialized LLM inference reconciliation"
                nimController = component "NIM Account Controller" "Manages NVIDIA NIM integration, API keys, pull secrets"
                srController = component "ServingRuntime Controller" "Manages runtime templates"
                configController = component "ConfigMap/Secret Controller" "Watches configuration changes"
                podController = component "Pod Controller" "Monitors predictor Pods for metrics"
            }

            webhooks = container "Admission Webhooks" "Validates and mutates inference workloads" "Go Webhook Server" {
                podMutator = component "Pod Mutating Webhook" "Modifies Pod specs for inference workloads"
                isvcWebhook = component "InferenceService Webhook" "Validates/mutates InferenceService resources"
                nimWebhook = component "NIM Account Webhook" "Validates NIM Account resources"
            }

            metrics = container "Metrics Server" "Exposes Prometheus metrics" "HTTP Server (port 8080)"
        }

        kserve = softwareSystem "KServe" "Serverless model serving platform on Kubernetes" "External"
        istio = softwareSystem "Istio/Maistra Service Mesh" "Service mesh for mTLS, routing, telemetry" "External"
        authorino = softwareSystem "Authorino" "Authentication/authorization for inference endpoints" "External"
        prometheus = softwareSystem "Prometheus Operator" "Metrics collection and monitoring" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling for inference workloads" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External"

        openshiftRoute = softwareSystem "OpenShift Route API" "External access to inference endpoints" "OpenShift"
        openshiftTemplate = softwareSystem "OpenShift Template API" "Template processing for NIM runtime creation" "OpenShift"
        kubernetes = softwareSystem "Kubernetes API Server" "Kubernetes control plane" "Platform"

        ngc = softwareSystem "NVIDIA NGC" "NVIDIA NIM model catalog and image registry" "External Service"
        s3 = softwareSystem "S3 Storage" "Model artifact storage" "External Service"

        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and lineage" "Internal ODH"
        dscInitialization = softwareSystem "DSCInitialization" "ODH initialization configuration for service mesh and auth" "Internal ODH"
        dataScienceCluster = softwareSystem "DataScienceCluster" "ODH component enablement configuration" "Internal ODH"

        # User interactions
        user -> odhModelController "Creates InferenceService via kubectl"
        admin -> odhModelController "Creates NIM Account with NGC API key"
        user -> odhModelController "Deploys LLM inference services"

        # ODH Model Controller interactions with external dependencies
        odhModelController -> kserve "Coordinates InferenceService reconciliation"
        odhModelController -> istio "Creates VirtualServices, Gateways, PeerAuthentication, Telemetry" "HTTPS/6443 via K8s API"
        odhModelController -> authorino "Creates AuthConfig resources for inference endpoint auth" "HTTPS/6443 via K8s API"
        odhModelController -> prometheus "Creates ServiceMonitor/PodMonitor for metrics collection" "HTTPS/6443 via K8s API"
        odhModelController -> keda "Creates TriggerAuthentication for autoscaling" "HTTPS/6443 via K8s API"
        odhModelController -> certManager "Uses for webhook TLS certificates" "cert-manager managed"

        # OpenShift integrations
        odhModelController -> openshiftRoute "Creates Routes for external HTTPS access" "HTTPS/6443"
        odhModelController -> openshiftTemplate "Processes templates for NIM runtime creation" "HTTPS/6443"
        odhModelController -> kubernetes "Watches/creates/updates all Kubernetes resources" "HTTPS/6443"

        # External service integrations
        odhModelController -> ngc "Validates NIM accounts, fetches model catalog" "HTTPS/443 with NGC API Key"
        odhModelController -> modelRegistry "Registers InferenceService metadata (optional)" "HTTPS/443"

        # Internal ODH integrations
        odhModelController -> dscInitialization "Reads service mesh and auth configuration"
        odhModelController -> dataScienceCluster "Reads component enablement state"

        # Inference workload dependencies
        kserve -> kubernetes "Creates Knative Service or Deployment"
        user -> openshiftRoute "Sends inference requests" "HTTPS/443"
        openshiftRoute -> istio "Forwards to service mesh" "HTTP/8080"
        istio -> authorino "Validates auth tokens" "gRPC/5001 mTLS"

        # Monitoring
        prometheus -> metrics "Scrapes controller metrics" "HTTP/8080 (TODO: migrate to 8443 HTTPS)"
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

        component reconcilers "ReconcilersComponent" {
            include *
            autoLayout
        }

        component webhooks "WebhooksComponent" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "OpenShift" {
                background #ee0000
                color #ffffff
            }
            element "Platform" {
                background #326ce5
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
