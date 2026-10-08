workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages AI/ML workloads through the dashboard UI"
        admin = person "Platform Administrator" "Configures dashboard settings and platform components"

        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for Red Hat OpenShift AI — modular, federated frontend with Go BFF services" {
            kubeRbacProxy = container "kube-rbac-proxy" "TLS termination and OpenShift authentication enforcement" "Go Sidecar" "8443/TCP"
            nodeBackend = container "Node.js/Fastify Backend" "API proxy for Kubernetes resources, serves React SPA, routes to module BFFs" "Node.js 22 / Fastify 5" "8080/TCP"
            coreBff = container "core-bff" "Shared BFF for NIM accounts, S3 storage, connections" "Go 1.26" "8943/TCP"
            dashboardOperator = container "dashboard-operator" "Reconciles Dashboard CR, manages deployments, RBAC, HTTPRoutes, modules" "Go controller-runtime" "9443/TCP"
            genAiBff = container "gen-ai BFF" "Generative AI features: Llama Stack, MCP, NeMo, MLflow" "Go 1.26" "8080/TCP"
            maasBff = container "maas BFF" "Model-as-a-Service: API keys, models, subscriptions" "Go 1.26" "8080/TCP"
            modelRegistryBff = container "model-registry BFF" "Model registry management and async uploads" "Go 1.26" "8080/TCP"
            agentOpsBff = container "agent-ops BFF" "Agent sandbox and MCP server management" "Go 1.26" "8080/TCP"
            otherModules = container "Other Module BFFs" "automl, autorag, eval-hub, mlflow, data-connect-hub, data-registry, notebooks" "Go 1.26" "8080/TCP"
            workspaceCtrl = container "Workspace Controller" "Kubeflow Workspaces lifecycle management" "Go controller-runtime"
        }

        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Creates and owns the Dashboard CR" "Internal ODH"
        k8sApi = softwareSystem "Kubernetes API" "Cluster resource management" "External"
        gateway = softwareSystem "data-science-gateway" "Gateway API ingress for external access" "External"
        dsPipelines = softwareSystem "DataScience Pipelines" "Pipeline execution and management" "Internal ODH"
        modelRegistrySvc = softwareSystem "Model Registry Service" "Model version tracking" "Internal ODH"
        kserve = softwareSystem "KServe" "Model serving and inference" "Internal ODH"
        mlmd = softwareSystem "ML Metadata" "Artifact and execution tracking" "Internal ODH"
        trustyai = softwareSystem "TrustyAI" "Fairness and explainability" "Internal ODH"
        prometheus = softwareSystem "Prometheus / Thanos" "Metrics and monitoring" "External"
        llamaStack = softwareSystem "Llama Stack Server" "LLM inference, vector stores" "External"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "Content moderation" "External"
        mcpServers = softwareSystem "MCP Servers" "Tool discovery and invocation" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External"

        user -> odhDashboard "Uses AI/ML features via browser" "HTTPS/443"
        admin -> odhDashboard "Configures platform settings" "HTTPS/443"

        odhDashboard -> k8sApi "Manages cluster resources" "HTTPS/6443"
        odhDashboard -> dsPipelines "Executes and manages pipelines" "HTTPS/8443"
        odhDashboard -> modelRegistrySvc "Tracks model versions" "HTTPS/8443"
        odhDashboard -> kserve "Manages inference services" "HTTPS"
        odhDashboard -> mlmd "Tracks artifacts and executions" "gRPC-web/8443"
        odhDashboard -> trustyai "Fairness and explainability" "HTTPS/443"
        odhDashboard -> prometheus "Queries metrics" "HTTPS/9092"
        odhDashboard -> llamaStack "LLM inference" "HTTPS"
        odhDashboard -> nemoGuardrails "Content moderation" "HTTPS"
        odhDashboard -> mcpServers "Tool discovery" "SSE/HTTP"

        rhodsOperator -> odhDashboard "Creates Dashboard CR"
        gateway -> odhDashboard "Routes external traffic" "HTTPS/8443"
        certManager -> odhDashboard "Provides TLS certificates"
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
            element "Person" {
                shape person
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
