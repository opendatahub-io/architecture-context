workspace {
    model {
        dataScientist = person "Data Scientist" "Creates notebooks, deploys models, runs pipelines, manages experiments"
        mlEngineer = person "ML Engineer" "Configures serving runtimes, manages model lifecycle, monitors inference"
        platformAdmin = person "Platform Admin" "Manages platform configuration, RBAC, and workspace templates"

        odhDashboard = softwareSystem "ODH Dashboard" "Unified web UI for Red Hat OpenShift AI — micro-frontend platform with Go BFF services" {
            operator = container "Dashboard Operator" "Reconciles Dashboard CR; manages lifecycle of all dashboard deployments, modules, RBAC, networking" "Go controller-runtime"
            coreBFF = container "Core BFF" "Module Federation host, React SPA shell, reverse proxy to modules and platform APIs" "Go + React/TypeScript"
            legacyBackend = container "Legacy Backend" "Original Node.js API proxy and static asset server (being replaced by core-bff)" "Node.js Fastify + kube-rbac-proxy"
            genAiBFF = container "Gen AI BFF" "LLM playground, prompt engineering, MCP server integration" "Go BFF Module"
            modelRegBFF = container "Model Registry BFF" "Model version CRUD, settings management" "Go BFF Module"
            maasBFF = container "MaaS BFF" "API key management, model subscriptions" "Go BFF Module"
            evalHubBFF = container "Eval Hub BFF" "TrustyAI integration, inference service access" "Go BFF Module"
            mlflowBFF = container "MLflow BFF" "Experiment and prompt management" "Go BFF Module"
            agentOpsBFF = container "Agent Ops BFF" "Agent sandbox management, per-agent RBAC" "Go BFF Module"
            notebooksBFF = container "Notebooks BFF" "Workspace and WorkspaceKind management" "Go BFF Module"
            frontendSPA = container "Frontend SPA" "PatternFly v6 React application — Module Federation host loading feature remotes" "React 18 / TypeScript" "Web Browser"
        }

        rhodsOperator = softwareSystem "RHOAI Operator" "Parent operator that creates the Dashboard CR" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        gateway = softwareSystem "Data Science Gateway" "Gateway API ingress for dashboard traffic" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning and rotation" "External"

        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and versions" "Internal ODH"
        dsPipelines = softwareSystem "DataScience Pipelines" "ML pipeline execution and management" "Internal ODH"
        trustyAI = softwareSystem "TrustyAI" "AI fairness and explainability services" "Internal ODH"
        mlflow = softwareSystem "MLflow" "Experiment tracking server" "Internal ODH"
        feast = softwareSystem "Feast" "Feature store for ML" "Internal ODH"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Notebook workbench management" "Internal ODH"
        prometheusThanos = softwareSystem "Prometheus / Thanos" "Metrics collection and querying" "External"
        llamaStack = softwareSystem "Llama Stack" "LLM inference, vector stores, files" "External"
        mcpServers = softwareSystem "MCP Servers" "Tool discovery and invocation via Model Context Protocol" "External"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "Content moderation for LLM outputs" "External"

        # User interactions
        dataScientist -> odhDashboard "Uses dashboard for notebooks, pipelines, model serving" "HTTPS/443"
        mlEngineer -> odhDashboard "Manages models, serving runtimes, inference services" "HTTPS/443"
        platformAdmin -> odhDashboard "Configures platform settings, workspace templates" "HTTPS/443"

        # Internal container flows
        frontendSPA -> coreBFF "API calls and module federation" "HTTP/8080"
        frontendSPA -> legacyBackend "Legacy API calls" "HTTPS/8443"
        coreBFF -> genAiBFF "Module proxy" "HTTPS/8143"
        coreBFF -> modelRegBFF "Module proxy" "HTTPS/8143"
        coreBFF -> maasBFF "Module proxy" "HTTPS/8243"
        coreBFF -> notebooksBFF "Module proxy" "HTTPS/8143"
        operator -> k8sAPI "Reconcile resources" "HTTPS/6443"

        # External system interactions
        rhodsOperator -> odhDashboard "Creates Dashboard CR"
        odhDashboard -> k8sAPI "CRUD operations with user impersonation" "HTTPS/6443"
        odhDashboard -> gateway "Ingress routing" "HTTPS/443"
        odhDashboard -> certManager "TLS certificates" "CRD"

        # Platform service interactions
        odhDashboard -> kserve "Inference service management" "HTTPS"
        odhDashboard -> modelRegistry "Model version tracking" "HTTPS/8443"
        odhDashboard -> dsPipelines "Pipeline execution" "HTTPS/8443"
        odhDashboard -> trustyAI "Fairness and explainability" "HTTPS/443"
        odhDashboard -> mlflow "Experiment tracking" "HTTPS"
        odhDashboard -> feast "Feature store access" "CRD Watch"
        odhDashboard -> kubeflowNotebooks "Notebook management" "CRD CRUD"
        odhDashboard -> prometheusThanos "Metrics queries" "HTTPS/9092"
        odhDashboard -> llamaStack "LLM inference" "HTTPS"
        odhDashboard -> mcpServers "Tool discovery" "SSE/HTTP"
        odhDashboard -> nemoGuardrails "Content moderation" "HTTPS"
    }

    views {
        systemContext odhDashboard "SystemContext" {
            include *
            autoLayout
        }

        container odhDashboard "Containers" {
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
                color #ffffff
            }
            element "Web Browser" {
                shape WebBrowser
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
