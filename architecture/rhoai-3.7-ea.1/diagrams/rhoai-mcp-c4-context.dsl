workspace {
    model {
        agent = person "AI Agent / MCP Client User" "Data scientist or agent (Claude Desktop, Copilot, OpenShift Lightspeed) using MCP to manage RHOAI resources"

        rhoaiMcp = softwareSystem "rhoai-mcp" "MCP server exposing ~97 tools and 18 prompts for Red Hat OpenShift AI resources" {
            server = container "rhoai-mcp server" "FastMCP app over Starlette/uvicorn; stdio, SSE, streamable-http on 8000/TCP" "Python"
            auth = container "Auth subsystem" "OIDCAuthMiddleware, TokenReview/JWKS validation, SAR tool filtering, UserContext" "Python ASGI middleware"
            domains = container "Domain plugins" "CRUD tools: projects, notebooks, inference, pipelines, connections, storage, training, model_registry, prompts" "pluggy plugins"
            composites = container "Composite plugins" "Cross-domain tools: cluster summary/diagnosis, training orchestration, meta discovery, Navigator" "pluggy plugins"
            planner = container "Embedded Planner" "GPU and deployment recommendations" "llm-d-planner library"
        }

        k8s = softwareSystem "Kubernetes / OpenShift API" "Cluster API server" "External"
        oidc = softwareSystem "OIDC Issuer" "OpenID discovery and JWKS (JWT mode)" "External"
        notebooks = softwareSystem "Kubeflow Notebooks" "Workbench CRDs" "Internal RHOAI"
        kserve = softwareSystem "KServe" "InferenceService / ServingRuntime CRDs" "Internal RHOAI"
        trainer = softwareSystem "Kubeflow Trainer v2" "TrainJob / TrainingRuntime CRDs" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "DataSciencePipelinesApplication CRD" "Internal RHOAI"
        operator = softwareSystem "ODH / RHOAI Operator" "DataScienceCluster; deploys rhoai-mcp via kustomize overlays" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Registered models and versions" "Internal RHOAI"
        modelCatalog = softwareSystem "Model Catalog" "Model catalog and Planner benchmarks" "Internal RHOAI"
        remotePlanner = softwareSystem "Remote Planner backend" "Optional llm-d Planner REST service" "Internal RHOAI"
        mcpLifecycle = softwareSystem "MCP Lifecycle Operator" "Reconciles MCPServer CR (optional)" "Internal RHOAI"

        agent -> server "MCP JSON-RPC via Route" "HTTPS/443 edge TLS -> HTTP/8000; Bearer in OIDC mode, none in SA mode"
        server -> auth "Validates Bearer tokens (OIDC mode)"
        server -> domains "Dispatches tool calls"
        server -> composites "Dispatches tool calls"
        composites -> domains "Imports"
        composites -> planner "In-process recommendations"

        auth -> k8s "TokenReview, SubjectAccessReview, users lookup" "HTTPS/6443 SA token"
        auth -> oidc "OpenID discovery + JWKS" "HTTPS/443"
        domains -> k8s "Resource CRUD" "HTTPS/6443 SA token, user token, or impersonation"
        domains -> modelRegistry "Model registry queries" "HTTP/8080 or HTTPS/8443 (TLS unverified)"
        planner -> modelCatalog "Benchmark sync" "HTTPS/8443 service-CA"
        composites -> remotePlanner "Recommendations (remote mode)" "HTTP/8000"

        k8s -> notebooks "Notebook CRs"
        k8s -> kserve "InferenceService / ServingRuntime CRs"
        k8s -> trainer "TrainJob CRs"
        k8s -> dsp "DSPA CRs"
        operator -> rhoaiMcp "Deploys via kustomize; injects RELATED_IMAGE"
        mcpLifecycle -> rhoaiMcp "Reconciles Deployment/Service from MCPServer CR"
    }

    views {
        systemContext rhoaiMcp "SystemContext" {
            include *
            autoLayout
        }

        container rhoaiMcp "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
