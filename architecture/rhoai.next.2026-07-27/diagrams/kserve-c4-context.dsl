workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models via InferenceService and LLMInferenceService CRs"
        platformAdmin = person "Platform Admin" "Manages KServe platform component via Kserve CR"

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform with InferenceService, InferenceGraph, LLMInferenceService, and LocalModelCache lifecycle management" {
            kserveControllerManager = container "KServe Controller Manager" "Reconciles InferenceService, TrainedModel, InferenceGraph CRs; manages webhooks" "Go Operator (cmd/manager)"
            llmisvcControllerManager = container "LLMInferenceService Controller Manager" "Reconciles LLMInferenceService and LLMInferenceServiceConfig CRs with v1alpha1/v1alpha2 conversion" "Go Operator (cmd/llmisvc)"
            localModelControllerManager = container "LocalModel Controller Manager" "Manages LocalModelCache, LocalModelNamespaceCache, LocalModelNode for pre-cached model distribution" "Go Operator (cmd/localmodel)"
            kserveModuleController = container "Kserve Module Controller" "ODH/RHOAI platform integration layer, reconciles Kserve platform CR, deploys child resources" "Go Operator (kserve-module)"
            odhModelController = container "ODH Model Controller" "Platform-specific model serving management, NIM Account handling" "Go Controller (odh-model-controller)"
            modelServingAPI = container "Model Serving API" "Webhook server for admission validation and mutation" "Go Service (model-serving-api)"
            agent = container "KServe Agent" "Sidecar for model pulling, request/response logging, request batching, reverse proxy" "Go Sidecar (cmd/agent)"
            router = container "InferenceGraph Router" "Implements splitter, switch, ensemble, sequence routing with optional Bearer-token auth" "Go Service (cmd/router)"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster resource management and RBAC enforcement" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "External"
        gatewayAPI = softwareSystem "Gateway API" "Ingress routing via Gateway and HTTPRoute CRDs" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic management (VirtualService, DestinationRule)" "External"
        knativeServing = softwareSystem "Knative Serving" "Serverless autoscaling platform" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling via ScaledObject CRDs" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Monitoring via ServiceMonitor and PodMonitor CRDs" "External"
        objectStorage = softwareSystem "Object Storage" "Model artifact storage (S3, GCS, Azure Blob)" "External"
        dscCluster = softwareSystem "DataScienceCluster" "ODH/RHOAI platform component state" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Dashboard configuration for model serving UI" "Internal RHOAI"

        dataScientist -> kserve "Creates InferenceService / LLMInferenceService via kubectl"
        platformAdmin -> kserve "Manages Kserve platform CR"
        kserve -> kubernetesAPI "CRUD cluster resources" "HTTPS/6443"
        kserve -> certManager "Manage TLS certificates" "CRD CRUD"
        kserve -> gatewayAPI "Manage routing" "CRD CRUD"
        kserve -> istio "Traffic management" "CRD CRUD (conditional)"
        kserve -> knativeServing "Serverless autoscaling" "CRD CRUD"
        kserve -> keda "Event-driven autoscaling" "CRD CRUD"
        kserve -> prometheusOperator "Monitoring setup" "CRD CRUD"
        kserve -> objectStorage "Download model artifacts" "HTTPS/443"
        kserve -> dscCluster "Read platform component state" "CRD Watch"
        kserve -> odhDashboard "Read dashboard config" "CRD Watch"
    }

    views {
        systemContext kserve "SystemContext" {
            include *
            autoLayout
        }

        container kserve "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
