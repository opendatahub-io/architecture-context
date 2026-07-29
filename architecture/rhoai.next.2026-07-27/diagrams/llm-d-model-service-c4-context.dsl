workspace {
    model {
        platformOperator = person "Platform Operator" "Defines BaseConfig presets and configures shared infrastructure"
        modelOwner = person "Model Owner" "Creates ModelService CRs to deploy inference workloads"
        client = person "Inference Client" "Sends inference requests to deployed models"

        llmDModelService = softwareSystem "llm-d-model-service" "Kubernetes operator that declaratively provisions inference serving stacks for disaggregated prefill/decode LLM inference" {
            controllerManager = container "modelservice-controller-manager" "Reconciles ModelService CRs and manages lifecycle of child resources (Deployments, Services, Routes, InferencePools)" "Go Operator (Kubebuilder v4)"
            templateEngine = container "Template Interpolation Engine" "Sprig-powered Go template processor for BaseConfig and ModelService spec value substitution" "In-process Go library"
            mergeEngine = container "Mergo Merge Engine" "Deep merge of BaseConfig defaults with ModelService overrides using custom transformers for containers, env vars, ParentRefs, BackendRefs" "In-process Go library"
            cliInterface = container "CLI Interface" "Cobra-based CLI providing 'run' (controller) and 'generate' (offline manifests) subcommands" "Go CLI"
            metricsEndpoint = container "Metrics Endpoint" "Prometheus metrics over HTTPS with TokenReview + SubjectAccessReview authentication" "HTTPS :8443"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Central control plane for all resource CRUD and watch operations" "Infrastructure"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for HTTP routing via HTTPRoute resources" "Infrastructure"
        inferenceExtension = softwareSystem "Gateway API Inference Extension" "Provides InferencePool and InferenceModel CRDs for endpoint selection and request routing" "Infrastructure"
        huggingFace = softwareSystem "HuggingFace Hub" "Model artifact repository for hf:// URI scheme" "External"
        pvcStorage = softwareSystem "PVC Storage" "Persistent Volume Claims for pvc:// model artifact URI scheme" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Infrastructure"

        # Relationships
        platformOperator -> llmDModelService "Defines BaseConfig ConfigMaps with reusable presets"
        modelOwner -> llmDModelService "Creates ModelService CRs referencing BaseConfig"
        client -> gatewayAPI "Sends inference requests via HTTPRoute" "HTTPS"

        controllerManager -> templateEngine "Interpolates template variables"
        controllerManager -> mergeEngine "Merges BaseConfig with ModelService overrides"
        cliInterface -> controllerManager "Starts controller manager (run subcommand)"

        llmDModelService -> kubernetesAPI "CRUD operations on 13+ resource types across namespaces" "HTTPS/6443, SA token"
        llmDModelService -> gatewayAPI "Creates and manages HTTPRoute resources" "Kubernetes API"
        llmDModelService -> inferenceExtension "Creates InferencePool and InferenceModel resources" "Kubernetes API"

        gatewayAPI -> inferenceExtension "Routes to InferencePool via EPP" "HTTP/gRPC"

        prometheus -> llmDModelService "Scrapes metrics" "HTTPS/8443, TokenReview"

        # Child resource relationships (provisioned by controller)
        inferenceExtension -> huggingFace "Prefill/Decode pods load model artifacts" "HTTPS, HF_TOKEN"
        inferenceExtension -> pvcStorage "Prefill/Decode pods mount model volumes" "Volume mount"
    }

    views {
        systemContext llmDModelService "SystemContext" {
            include *
            autoLayout
        }

        container llmDModelService "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "External" {
                background #f5a623
                color #333333
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
