workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML experiments, models, and deployments"
        mlEngineer = person "ML Engineer" "Deploys and monitors ML models in production"
        appDeveloper = person "Application Developer" "Integrates LLM capabilities via AI Gateway"

        mlflow = softwareSystem "MLflow" "Open source platform for the complete machine learning lifecycle including tracking, model registry, AI gateway, and serving (v3.14.0)" {
            aiGateway = container "AI Gateway" "OpenAI-compatible reverse proxy with dynamic endpoint configuration, rate limiting, and multi-provider routing" "FastAPI (Python)"
            agentServer = container "Agent Server" "Model invocation server with sync/streaming support and optional chat app proxy" "FastAPI (Python)" {
                tags "Port 8000"
            }
            trackingServer = container "Tracking Server" "Experiment tracking, job management, and assistant APIs" "Flask/FastAPI (Python)"
            mcpRegistry = container "MCP Registry" "Model/version/endpoint/alias/tag CRUD operations" "FastAPI (Python)"
        }

        mlflowSkinny = softwareSystem "mlflow-skinny" "Lightweight distribution with CLI, auth app, and deployment plugin entry points" "Internal Distribution"
        mlflowTracing = softwareSystem "mlflow-tracing" "Minimal tracing SDK with auto-instrumentation for 15+ AI/ML frameworks" "SDK"

        openai = softwareSystem "OpenAI" "LLM provider (api.openai.com)" "External Provider"
        azureOpenai = softwareSystem "Azure OpenAI" "Microsoft-hosted LLM provider" "External Provider"
        awsBedrock = softwareSystem "AWS Bedrock" "AWS managed LLM provider" "External Provider"
        anthropic = softwareSystem "Anthropic" "LLM provider" "External Provider"
        cohere = softwareSystem "Cohere" "LLM provider" "External Provider"
        databricks = softwareSystem "Databricks" "ML platform with model serving" "External Provider"

        s3 = softwareSystem "AWS S3" "Model artifact and experiment data storage" "External Storage"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage" "External Storage"
        k8s = softwareSystem "Kubernetes" "Container orchestration platform" "Platform"

        # User relationships
        appDeveloper -> mlflow "Sends LLM requests via OpenAI-compatible API"
        dataScientist -> mlflow "Tracks experiments, manages models"
        mlEngineer -> mlflow "Deploys models, manages endpoints"

        # Internal container relationships
        aiGateway -> openai "Proxies LLM requests" "HTTPS/443, Bearer Token"
        aiGateway -> azureOpenai "Proxies LLM requests" "HTTPS/443, API Key / Azure AD"
        aiGateway -> awsBedrock "Proxies LLM requests" "HTTPS/443, IAM / STS / Bearer"
        aiGateway -> anthropic "Proxies LLM requests" "HTTPS/443, API Key"
        aiGateway -> cohere "Proxies LLM requests" "HTTPS/443, API Key"

        trackingServer -> s3 "Stores/retrieves model artifacts" "HTTPS, AWS IAM (boto3)"
        trackingServer -> gcs "Stores/retrieves model artifacts" "HTTPS, GCS SDK"
        trackingServer -> databricks "Fetches model metadata" "HTTPS/443, Auth Chain"

        mlflow -> k8s "Resource operations" "Python client library"

        # SDK relationship
        mlflowTracing -> mlflow "Sends trace data"
    }

    views {
        systemContext mlflow "SystemContext" {
            include *
            autoLayout
        }

        container mlflow "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External Provider" {
                background #999999
                color #ffffff
            }
            element "External Storage" {
                background #f5a623
                color #ffffff
            }
            element "Platform" {
                background #82b366
                color #ffffff
            }
            element "Internal Distribution" {
                background #6bb5e0
                color #ffffff
            }
            element "SDK" {
                background #9b59b6
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
            }
        }
    }
}
