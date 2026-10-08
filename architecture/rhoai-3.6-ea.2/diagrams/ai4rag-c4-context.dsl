workspace {
    model {
        dataScientist = person "Data Scientist" "Optimizes RAG pipelines using ai4rag in Jupyter notebooks"
        appDeveloper = person "Application Developer" "Deploys agentic RAG starter kit as a service"

        ai4rag = softwareSystem "ai4rag" "Provider-agnostic RAG optimization engine with agentic starter kit" {
            coreLib = container "ai4rag Core Library" "HPO-driven RAG optimization: chunking, retrieval, evaluation" "Python Library"
            experiment = container "AI4RAGExperiment" "Orchestrates GAM-based hyperparameter optimization trials" "Python Class"
            hpo = container "GAM Optimizer" "Generalized Additive Models for hyperparameter search" "pygam"
            docling = container "Docling Chunker" "Structure-aware document extraction and chunking" "docling-slim"
            evaluator = container "RAGAS/Unitxt Evaluator" "Computes answer correctness, faithfulness, context metrics" "Python"
            urlPolicy = container "URL Trust Policy" "Enforces HTTPS for non-local endpoints; no unverified-TLS fallback" "Python Module"
            starterKit = container "Agentic RAG Starter Kit" "FastAPI service exposing OpenAI-compatible /v1/responses API" "FastAPI + LangChain"
            authWrapper = container "Auth Wrapper" "K8s TokenReview ASGI middleware for bearer token authentication" "Python ASGI"
        }

        maas = softwareSystem "OpenAI-compatible MaaS" "LLM inference and embedding endpoint (vLLM, TGI, Ollama)" "External"
        s3 = softwareSystem "AWS S3-compatible Storage" "Document corpus storage" "External"
        milvus = softwareSystem "Milvus" "Vector database for similarity search" "External"
        pgvector = softwareSystem "PostgreSQL/pgvector" "Relational DB with vector and full-text search" "External"
        neo4j = softwareSystem "Neo4j" "Graph database for entity/relationship RAG" "External"
        k8sApi = softwareSystem "Kubernetes API" "Authentication via TokenReview" "External"

        dataScientist -> ai4rag "Runs RAG optimization experiments"
        appDeveloper -> ai4rag "Deploys agentic RAG starter kit"

        ai4rag -> maas "LLM inference and embeddings" "HTTPS / API key"
        ai4rag -> s3 "Fetch and store document corpus" "HTTPS / AWS IAM"
        ai4rag -> milvus "Vector storage and similarity search" "gRPC/TLS / Token"
        ai4rag -> pgvector "Vector + full-text hybrid search" "TLS / Password"
        ai4rag -> neo4j "Graph-based RAG retrieval" "Bolt+TLS / Password"
        ai4rag -> k8sApi "TokenReview authentication (starter kit)" "HTTPS / Bearer"

        experiment -> hpo "Drives HPO trials"
        experiment -> docling "Extracts and chunks documents"
        experiment -> evaluator "Scores trial results"
        coreLib -> urlPolicy "Validates all external URLs"
        starterKit -> authWrapper "Authenticates requests"
        starterKit -> maas "LLM inference"
        starterKit -> milvus "Retrieves context"
        authWrapper -> k8sApi "Validates bearer tokens"
    }

    views {
        systemContext ai4rag "SystemContext" {
            include *
            autoLayout
        }

        container ai4rag "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
