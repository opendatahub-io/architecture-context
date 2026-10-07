workspace {
    model {
        dataScientist = person "Data Scientist" "Runs RAG optimization experiments and deploys optimized services"
        externalClient = person "External Client" "Sends inference requests to the deployed agentic RAG service"

        ai4rag = softwareSystem "ai4rag" "Provider-agnostic RAG optimization engine that discovers optimal hyperparameters for RAG pipelines" {
            optimizationEngine = container "Optimization Engine" "GAM-based hyperparameter optimizer with warm-start, collection reuse via indexing-parameter fingerprinting" "Python (ai4rag.core)"
            ragBackend = container "RAG Backend" "Pluggable RAG templates (AgenticRAG, SimpleRAG), chunking strategies, embedding integration" "Python (ai4rag.rag)"
            vectorStoreLayer = container "Vector Store Layer" "Milvus (BM25 fusion), pgvector (RRF fusion), Neo4j (graph RAG), Milvus Lite (embedded)" "Python"
            evaluators = container "Evaluators" "unitxt, RAGAS, and LLM-as-a-Judge evaluation metrics" "Python"
            assetsGenerator = container "Assets Generator" "Generates starter kit ZIP, Jupyter notebooks, pattern leaderboard" "Python (ai4rag.assets_generator)"
            networkSafety = container "Network Safety" "ensure_safe_url — enforces HTTPS for all non-local, non-cluster endpoints" "Python (ai4rag.utils.network)"
            starterKit = container "Agentic RAG Starter Kit" "Generated FastAPI service with OpenAI Responses API and K8s TokenReview auth" "Python FastAPI"
        }

        maas = softwareSystem "MaaS (OpenAI-Compatible)" "Foundation model inference and embeddings endpoint" "External"
        milvus = softwareSystem "Milvus" "Distributed vector database for dense and hybrid search" "External"
        pgvector = softwareSystem "PostgreSQL / pgvector" "PostgreSQL with pgvector extension for vector similarity search" "External"
        neo4j = softwareSystem "Neo4j" "Graph database for knowledge graph-based RAG retrieval" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Object storage for document discovery and extraction" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API for TokenReview authentication" "External"

        dataScientist -> ai4rag "Runs optimization experiments via Python API"
        externalClient -> starterKit "POST /v1/responses with Bearer token" "HTTP/8080"

        optimizationEngine -> ragBackend "Instantiates RAG pipeline per trial"
        optimizationEngine -> evaluators "Evaluates trial results"
        ragBackend -> vectorStoreLayer "Indexes and retrieves documents"
        assetsGenerator -> starterKit "Generates deployable service"

        vectorStoreLayer -> networkSafety "Validates endpoint URLs"
        ragBackend -> networkSafety "Validates MaaS URL"

        ai4rag -> maas "Inference, embeddings, evaluation" "HTTPS"
        vectorStoreLayer -> milvus "Dense + hybrid BM25 search" "gRPC+TLS/19530"
        vectorStoreLayer -> pgvector "Dense + hybrid tsvector search" "TLS/5432"
        vectorStoreLayer -> neo4j "Graph-aware retrieval" "Bolt+TLS/7687"
        ai4rag -> s3 "Document discovery and extraction" "HTTPS/443"
        starterKit -> k8sAPI "TokenReview authentication" "HTTPS/443"
        starterKit -> maas "Chat/completions for inference" "HTTPS"
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
