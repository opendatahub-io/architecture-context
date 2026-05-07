workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys ML models via InferenceService CRs"
        platformadmin = person "Platform Admin" "Configures NIM accounts and model serving infrastructure"
        dashboarduser = person "Dashboard User" "Uses RHOAI Dashboard to discover and manage model serving gateways"

        odhModelController = softwareSystem "odh-model-controller" "Kubernetes operator automating model serving infrastructure for KServe InferenceServices, LLM auth, and NIM integration" {
            controllerManager = container "Controller Manager" "Reconciles InferenceService, LLMInferenceService, Gateway, ServingRuntime, NIM Account, ConfigMap, Secret, and Pod resources" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates and mutates Pods (Ray TLS), InferenceGraphs (URL validation), InferenceServices (name length), and NIM Accounts (singleton)" "Go Admission Webhook"
            modelServingAPI = container "model-serving-api" "HTTPS gateway discovery API with per-user RBAC authorization via SelfSubjectAccessReview" "Go HTTP Server (FIPS TLS)"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for all resource operations" "Infrastructure"
        kserve = softwareSystem "KServe" "Provides InferenceService, ServingRuntime, LLMInferenceService CRDs and serverless inference" "Internal ODH"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller exposing Routes for model endpoints" "Infrastructure"
        kuadrant = softwareSystem "Kuadrant / Authorino" "Auth policy enforcement on Gateway API routes and gateways" "Optional"
        istio = softwareSystem "Istio Service Mesh" "Provides EnvoyFilter CRD for proxy and TLS configuration" "Optional"
        keda = softwareSystem "KEDA" "Provides TriggerAuthentication for Prometheus-based autoscaling" "Optional"
        prometheus = softwareSystem "Prometheus Operator" "Provides ServiceMonitor and PodMonitor CRDs for metrics scraping" "Optional"
        gatewayAPI = softwareSystem "Gateway API" "Gateway and HTTPRoute CRDs for inference routing" "Optional"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform for model pods" "Optional"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for managing model serving" "Internal ODH"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator providing DataScienceCluster and DSCInitialization config" "Internal ODH"
        modelRegistry = softwareSystem "Kubeflow Model Registry" "Stores model metadata and inference service mappings" "Internal ODH"
        ngcAPI = softwareSystem "NVIDIA NGC API" "NIM runtime discovery, API key validation, and model catalog" "External"
        nvcrRegistry = softwareSystem "nvcr.io Container Registry" "NVIDIA container registry for NIM runtime images" "External"

        # User interactions
        datascientist -> odhModelController "Creates InferenceService via kubectl" "HTTPS/443"
        platformadmin -> odhModelController "Creates NIM Account via kubectl" "HTTPS/443"
        dashboarduser -> rhoaiDashboard "Discovers gateways and manages models" "HTTPS"

        # Controller → K8s API
        controllerManager -> kubernetesAPI "CRUD: Routes, Secrets, ServiceMonitors, AuthPolicies, EnvoyFilters, Templates, ClusterRoleBindings" "HTTPS/443, SA Token"
        modelServingAPI -> kubernetesAPI "SelfSubjectAccessReview, List Gateways, Get Namespaces" "HTTPS/443, Bearer + SA Token"
        webhookServer -> kubernetesAPI "Admission responses" "HTTPS/9443"

        # Internal ODH integrations
        odhModelController -> kserve "Watches InferenceService, ServingRuntime, LLMInferenceService CRDs" "CRD Watch"
        odhModelController -> kuadrant "Creates AuthPolicies for HTTPRoutes and Gateways" "CRD Create"
        odhModelController -> istio "Creates EnvoyFilters for Authorino TLS bootstrap" "CRD Create"
        odhModelController -> keda "Creates TriggerAuthentications for Prometheus autoscaling" "CRD Create"
        odhModelController -> prometheus "Creates ServiceMonitors per InferenceService" "CRD Create"
        odhModelController -> gatewayAPI "Watches and updates Gateways" "CRD Watch/Update"
        odhModelController -> openshiftRouter "Creates per-ISVC Routes (edge/reencrypt TLS)" "CRD Create"
        odhModelController -> rhodsOperator "Reads DataScienceCluster and DSCInitialization config" "CRD Watch"
        odhModelController -> modelRegistry "Syncs InferenceService metadata" "HTTP/HTTPS, Bearer Token"
        odhModelController -> knative "Creates Knative Services for serverless inference" "CRD Create"
        rhoaiDashboard -> modelServingAPI "Gateway discovery API" "HTTPS/443, Bearer Token"

        # External egress
        controllerManager -> ngcAPI "NIM API key validation, model data, runtime catalog" "HTTPS/443, NGC API Key"
        controllerManager -> nvcrRegistry "NIM pull token acquisition for Docker auth" "HTTPS/443, NGC API Key"
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
            element "Infrastructure" {
                background #326ce5
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Optional" {
                background #999999
                color #ffffff
            }
            element "External" {
                background #f5a623
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
