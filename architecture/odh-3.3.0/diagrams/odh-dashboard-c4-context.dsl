workspace {
    model {
        user = person "Data Scientist / Admin" "Manages workbenches, model serving, and ODH components"

        dashboard = softwareSystem "ODH Dashboard" "Web-based UI for managing Open Data Hub and RHOAI components" {
            frontend = container "Frontend" "React/TypeScript SPA with PatternFly v6" "React/TypeScript"
            backend = container "Backend API" "REST API server for Kubernetes resource management" "Node.js/Fastify"
            proxy = container "kube-rbac-proxy" "OAuth authentication and authorization proxy" "Go"

            genai = component "Gen AI Plugin" "Gen AI feature package" "TypeScript"
            modelreg = component "Model Registry Plugin" "Model registry feature package" "TypeScript"
            mlflow = component "MLflow Plugin" "MLflow integration package" "TypeScript"
        }

        openshift = softwareSystem "OpenShift Platform" "Container platform with OAuth, Routes, Builds" "External"
        k8s = softwareSystem "Kubernetes API Server" "Container orchestration API" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and queries" "External"

        odhOperator = softwareSystem "ODH Operator" "Manages DataScienceCluster resources" "Internal ODH"
        notebooks = softwareSystem "Kubeflow Notebooks" "Jupyter notebook environment for data scientists" "Internal ODH"
        kserve = softwareSystem "KServe" "Serverless model serving platform" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores ML model metadata and versions" "Internal ODH"
        trustyai = softwareSystem "TrustyAI" "AI guardrails and responsible AI" "Internal ODH"
        feast = softwareSystem "Feast" "Feature store for ML features" "Internal ODH"
        llamastack = softwareSystem "LlamaStack" "LLM deployment platform" "Internal ODH"

        user -> dashboard "Manages ODH components via web UI"
        dashboard -> openshift "Authenticates users via OAuth" "HTTPS/443"
        dashboard -> k8s "Manages CRs and Kubernetes resources" "HTTPS/6443"
        dashboard -> prometheus "Queries model serving metrics" "HTTP/9091"

        dashboard -> odhOperator "Watches DataScienceCluster status" "K8s API"
        dashboard -> notebooks "Creates and manages Notebook CRs" "K8s API"
        dashboard -> kserve "Lists InferenceService CRs" "K8s API"
        dashboard -> modelRegistry "Creates and manages ModelRegistry CRs" "K8s API + HTTP/8080"
        dashboard -> trustyai "Lists GuardrailsOrchestrator CRs" "K8s API"
        dashboard -> feast "Lists FeatureStore CRs" "K8s API"
        dashboard -> llamastack "Lists LlamaStackDistribution CRs" "K8s API"

        proxy -> backend "Forwards authenticated requests" "HTTP/8080"
        frontend -> proxy "API requests via OAuth" "HTTPS/8443"
        backend -> genai "Uses Gen AI features"
        backend -> modelreg "Uses Model Registry features"
        backend -> mlflow "Uses MLflow features"
    }

    views {
        systemContext dashboard "SystemContext" {
            include *
            autoLayout
        }

        container dashboard "Containers" {
            include *
            autoLayout
        }

        component backend "BackendComponents" {
            include *
            autoLayout
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #9b59b6
                color #ffffff
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
