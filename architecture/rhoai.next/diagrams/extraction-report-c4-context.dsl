workspace {
    model {
        # Users
        dataScientist = person "Data Scientist" "Creates ML models, runs experiments, deploys inference services"
        mlEngineer = person "ML Engineer" "Builds pipelines, manages training jobs, monitors models"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform, configures operators"
        securityTeam = person "Security Team" "Reviews architecture, manages access policies"

        # RHOAI Platform
        rhoai = softwareSystem "Red Hat OpenShift AI (RHOAI)" "Enterprise ML platform on OpenShift with 17 components" {

            # Gateway Layer
            aiGateway = container "AI Gateway Payload Processing" "Envoy ext-proc plugin for API key injection, model routing, NeMo guardrails" "Go / gRPC"
            gwExtension = container "Gateway API Inference Extension" "EPP + BBR ext-proc for intelligent model routing" "Go / gRPC"
            batchGateway = container "Batch Gateway" "OpenAI-compatible batch inference API" "Go / HTTP REST"

            # Inference
            caikitTgis = container "Caikit-TGIS Serving" "KServe ServingRuntime for text generation with TGIS backend" "Python / KServe"
            guardrailsDetectors = container "Guardrails Detectors" "Content safety detectors (built-in, HuggingFace, LLM Judge)" "Python / KServe"

            # Orchestration
            guardrailsOrch = container "FMS Guardrails Orchestrator" "Request/response guardrails pipeline orchestration" "Rust (axum+tokio)"
            argWorkflows = container "Argo Workflows" "Workflow execution engine for ML pipelines" "Go / Controller"
            dsPipelines = container "Data Science Pipelines" "Kubeflow Pipelines v2 API with 7 sub-components" "Go / REST+gRPC"

            # Operators
            codeflareOp = container "CodeFlare Operator" "Manages AppWrappers, RayCluster provisioning with OAuth proxy" "Go / controller-runtime"
            dsPipelinesOp = container "DS Pipelines Operator" "Manages DataSciencePipelinesApplication lifecycle" "Go / controller-runtime"
            feastOp = container "Feast Operator" "Manages FeatureStore CRs and feature serving infrastructure" "Go / controller-runtime"

            # Serving & Evaluation
            feastServer = container "Feast Feature Server" "Online/offline feature serving with 20+ store backends" "Python / HTTP+gRPC"
            evalHub = container "Eval Hub" "Evaluation job management with MCP server" "Go / REST+MCP"

            # Training
            fmsTuning = container "FMS HF Tuning" "Fine-tuning container with FSDP distributed training" "Python / CUDA"

            # Libraries & SDKs
            caikit = container "Caikit" "AI runtime SDK framework with auto-generated endpoints" "Python Library"
            caikitNlp = container "Caikit NLP" "NLP module library for caikit runtime" "Python Library"
            codeFlareSdk = container "CodeFlare SDK" "Client SDK for distributed compute on OpenShift" "Python SDK"
            ai4rag = container "AI4RAG" "RAG library for Llama Stack and OpenAI" "Python Library"
        }

        # External Systems
        kubernetes = softwareSystem "Kubernetes / OpenShift" "Container orchestration platform" "External"
        istio = softwareSystem "Istio Service Mesh" "mTLS, traffic management, observability" "External"
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "External"
        envoy = softwareSystem "Envoy Proxy" "L7 proxy with ext-proc support" "External"
        kuberay = softwareSystem "KubeRay" "Kubernetes operator for Ray clusters" "External"
        kueue = softwareSystem "Kueue" "Job queueing and resource management" "External"

        # Data Stores
        postgresql = softwareSystem "PostgreSQL / MariaDB" "Relational database for metadata and state" "External Store"
        s3 = softwareSystem "S3 / Minio" "Object storage for artifacts and models" "External Store"
        redis = softwareSystem "Redis / Valkey" "In-memory cache and message queue" "External Store"

        # External Services
        huggingface = softwareSystem "HuggingFace Hub" "Model repository and downloads" "External Service"
        modelProviders = softwareSystem "Model Providers" "OpenAI, NeMo, and other LLM providers" "External Service"

        # Relationships - Users to Platform
        dataScientist -> rhoai "Creates InferenceServices, submits experiments, queries features"
        mlEngineer -> rhoai "Builds and runs ML pipelines, manages training"
        platformAdmin -> rhoai "Configures operators, manages platform settings"

        # Relationships - User to specific containers
        dataScientist -> codeFlareSdk "Submits distributed compute jobs" "Python API"
        dataScientist -> dsPipelines "Creates pipeline runs" "REST/gRPC"
        dataScientist -> feastServer "Queries feature values" "HTTP/6566"
        dataScientist -> evalHub "Manages evaluations" "HTTP/8080"

        # Relationships - Internal
        aiGateway -> modelProviders "Routes requests with API key injection" "HTTPS/443"
        gwExtension -> caikitTgis "Routes inference requests" "via Envoy"
        guardrailsOrch -> caikitTgis "Generation requests" "gRPC"
        guardrailsOrch -> guardrailsDetectors "Content screening" "HTTP/8080"
        dsPipelines -> argWorkflows "Orchestrates workflows" "K8s API"
        dsPipelinesOp -> dsPipelines "Manages lifecycle" "K8s API"
        codeflareOp -> kuberay "Provisions RayClusters" "K8s API"
        codeflareOp -> kueue "Queue management" "K8s API"
        feastOp -> feastServer "Manages feature serving" "K8s API"
        caikitTgis -> istio "mTLS sidecar" "mTLS"
        caikitTgis -> kserve "Deployed as ServingRuntime" "K8s API"
        guardrailsDetectors -> kserve "Deployed as InferenceService" "K8s API"

        # Relationships - External
        argWorkflows -> s3 "Stores artifacts" "HTTPS/443"
        dsPipelines -> postgresql "Persists metadata" "SQL/5432"
        dsPipelines -> s3 "Stores artifacts" "HTTPS/443"
        batchGateway -> postgresql "Persists batch jobs" "SQL/5432"
        batchGateway -> redis "Job queue" "TCP/6379"
        batchGateway -> s3 "Input/output files" "HTTPS/443"
        evalHub -> postgresql "Stores evaluations" "SQL/5432"
        fmsTuning -> huggingface "Downloads models" "HTTPS/443"
        guardrailsDetectors -> huggingface "Downloads models" "HTTPS/443"

        # Platform dependencies
        rhoai -> kubernetes "Runs on" "K8s API"
        rhoai -> istio "Service mesh" "mTLS"
        rhoai -> envoy "Traffic routing" "ext-proc gRPC"
    }

    views {
        systemContext rhoai "RHOAI-SystemContext" {
            include *
            autoLayout
        }

        container rhoai "RHOAI-Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Store" {
                background #f5a623
                color #ffffff
            }
            element "External Service" {
                background #7ed321
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
