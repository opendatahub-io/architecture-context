workspace {
    model {
        platformAdmin = person "Platform Admin" "Configures BaseConfig presets and deploys ModelService CRs"
        dataScientist = person "Data Scientist" "Creates ModelService CRs to deploy inference models"
        client = person "Inference Client" "Sends inference requests to deployed models"

        llmdModelService = softwareSystem "llm-d-model-service" "Kubernetes operator that declaratively provisions and manages the full inference serving stack for a single base model using the ModelService CR" {
            controller = container "ModelService Controller" "Reconciles ModelService CRs to create/manage inference infrastructure" "Go Operator (controller-runtime v0.20.4)"
            templateEngine = container "Template Engine" "Interpolates Go template variables in BaseConfig using Sprig functions" "Go (Sprig v3.3.0)"
            mergeLayer = container "Merge Layer" "Performs semantic merge of BaseConfig and ModelService specs with custom transformers" "Go (Mergo v1.0.1)"
            generateCLI = container "generate CLI" "Offline manifest generation from ModelService + BaseConfig YAML files" "Go CLI (cobra)"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for traffic routing (HTTPRoute)" "External"
        gatewayAPIInferenceExtension = softwareSystem "Gateway API Inference Extension (GIE)" "InferencePool and InferenceModel CRDs for model-aware routing" "Internal Platform"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Model artifact repository for hf:// URI scheme" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection system" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management (optional)" "External"

        # Managed inference workloads (created by controller)
        prefillDeployment = softwareSystem "Prefill Deployment" "vLLM prefill inference workload" "Managed Workload"
        decodeDeployment = softwareSystem "Decode Deployment" "vLLM decode inference workload" "Managed Workload"
        eppDeployment = softwareSystem "Endpoint Picker (EPP)" "Intelligent request routing for disaggregated inference" "Managed Workload"

        # Relationships
        dataScientist -> llmdModelService "Creates ModelService CR via kubectl"
        platformAdmin -> llmdModelService "Manages BaseConfig ConfigMaps"
        client -> eppDeployment "Sends inference requests via Gateway/HTTPRoute"

        llmdModelService -> kubernetesAPI "CRUD on Deployments, Services, HTTPRoutes, CRs, ConfigMaps, RBAC" "HTTPS/443"
        llmdModelService -> gatewayAPI "Creates HTTPRoute CRs for inference traffic routing"
        llmdModelService -> gatewayAPIInferenceExtension "Creates InferencePool and InferenceModel CRs"

        prefillDeployment -> huggingFaceHub "Downloads model artifacts" "HTTPS/443"
        decodeDeployment -> huggingFaceHub "Downloads model artifacts" "HTTPS/443"
        prometheus -> llmdModelService "Scrapes controller metrics" "HTTPS/8443"
        certManager -> llmdModelService "Provides TLS certificates (optional)" "Kubernetes secrets"

        llmdModelService -> prefillDeployment "Creates and manages"
        llmdModelService -> decodeDeployment "Creates and manages"
        llmdModelService -> eppDeployment "Creates and manages"

        # Internal container relationships
        controller -> templateEngine "Invokes for BaseConfig interpolation"
        controller -> mergeLayer "Invokes for config merge"
    }

    views {
        systemContext llmdModelService "SystemContext" {
            include *
            autoLayout
        }

        container llmdModelService "Containers" {
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
            element "Managed Workload" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
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
        }
    }
}
