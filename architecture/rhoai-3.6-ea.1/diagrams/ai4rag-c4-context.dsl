workspace {
    model {
        dataScientist = person "Data Scientist" "Defines RAG optimization experiments and reviews ranked pattern results"

        ai4rag = softwareSystem "ai4rag" "Automatic RAG pattern generator and hyperparameter optimizer (Python library)" {
            ingestionLayer = container "Data Ingestion" "Reads documents from S3, extracts text via Docling" "Python (boto3, docling-slim)"
            chunkingLayer = container "Chunking Layer" "Splits text using configurable strategies (Docling hierarchical, LangChain recursive)" "Python (langchain-text-splitters)"
            embeddingLayer = container "Embedding Layer" "Generates vector embeddings via OpenAI-compatible API" "Python (openai SDK)"
            vectorStoreLayer = container "Vector Store Layer" "Indexes and retrieves vectors from pluggable backends" "Python (pymilvus, pgvector, chromadb)"
            ragQueryLayer = container "RAG Query Layer" "Retrieves context, builds prompts, calls LLM for answers" "Python (openai SDK)"
            evaluationLayer = container "Evaluation Layer" "Scores answers on faithfulness, correctness metrics" "Python (unitxt, scikit-learn)"
            optimizerLayer = container "GAM Optimizer" "Hyperparameter search using Generalized Additive Models" "Python (pygam)"
            kfpHandler = container "KFP Event Handler" "Reports status and ranked patterns to Data Science Pipelines" "Python (KFP SDK)"
        }

        dsPipelines = softwareSystem "Data Science Pipelines" "Kubeflow-based pipeline orchestration platform" "Internal RHOAI"
        modelServing = softwareSystem "Model Serving (MaaS)" "vLLM-based OpenAI-compatible model serving endpoint" "Internal RHOAI"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for source documents (AWS S3 / MinIO)" "External"
        milvus = softwareSystem "Milvus" "Distributed vector database with gRPC interface" "External"
        pgvector = softwareSystem "PGVector" "PostgreSQL extension for vector similarity search" "External"
        chroma = softwareSystem "Chroma" "Lightweight vector database (ephemeral/persistent/client-server)" "External"

        dataScientist -> dsPipelines "Submits RAG optimization pipeline run"
        dsPipelines -> ai4rag "Executes as pipeline task component"

        ingestionLayer -> s3Storage "Downloads documents" "HTTPS/443, AWS IAM keys"
        embeddingLayer -> modelServing "Generates embeddings" "HTTPS, OpenAI API"
        vectorStoreLayer -> milvus "Indexes/retrieves vectors" "gRPC + TLS"
        vectorStoreLayer -> pgvector "Indexes/retrieves vectors" "PostgreSQL + TLS"
        vectorStoreLayer -> chroma "Indexes/retrieves vectors" "HTTP"
        ragQueryLayer -> modelServing "Chat completions for answer generation" "HTTPS, OpenAI API"
        kfpHandler -> dsPipelines "Reports pattern results" "KFP SDK"

        ingestionLayer -> chunkingLayer "Structured text"
        chunkingLayer -> embeddingLayer "Text chunks"
        embeddingLayer -> vectorStoreLayer "Embedding vectors"
        vectorStoreLayer -> ragQueryLayer "Retrieved context"
        ragQueryLayer -> evaluationLayer "Generated answers"
        evaluationLayer -> optimizerLayer "Evaluation scores"
        optimizerLayer -> chunkingLayer "Next configuration"
        optimizerLayer -> kfpHandler "Ranked patterns"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
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
