workspace {
    model {
        dataScientist = person "Data Scientist" "Runs RAG optimization experiments via notebooks"
        appClient = person "Application Client" "Sends inference requests to deployed starter kit"

        ai4rag = softwareSystem "ai4rag" "Provider-agnostic RAG optimization engine with deployable starter kits" {
            library = container "ai4rag Library" "RAG optimization engine: experiment orchestration, HPO, chunking, retrieval, evaluation" "Python Package"
            experiment = container "AI4RAGExperiment" "Orchestrates optimization loop over RAG templates" "Python Class"
            hpo = container "HPO Engine" "GAM-based Bayesian optimization and random search" "Python Module"
            simpleRAG = container "SimpleRAG Template" "Single retrieve-then-generate pass" "Python Module"
            agenticRAG = container "AgenticRAG Template" "LangChain agent with query rewriting and budgeted retrieval" "Python Module"
            evaluators = container "Evaluators" "RAGAS, Unitxt, LLM-as-Judge evaluation frameworks" "Python Module"
            assetsGenerator = container "Assets Generator" "Generates starter kit ZIP archives and notebooks" "Python Module"
            starterKit = container "Agentic RAG Starter Kit" "FastAPI service with OpenAI-compatible Responses API" "Python FastAPI, 8080/TCP"
            authWrapper = container "Auth Wrapper" "ASGI middleware for K8s TokenReview authentication" "Python ASGI"
        }

        maas = softwareSystem "MaaS (OpenAI-Compatible)" "LLM and embedding model endpoint (vLLM, TGI, MaaS)" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Document artifact storage" "External"
        milvus = softwareSystem "Milvus" "Vector database for document retrieval" "External"
        pgvector = softwareSystem "PostgreSQL + pgvector" "Vector database for document retrieval" "External"
        neo4j = softwareSystem "Neo4j" "Graph database for knowledge graph RAG" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Authentication via TokenReview" "External"

        # User interactions
        dataScientist -> ai4rag "Runs optimization experiments" "Python API"
        appClient -> ai4rag "Sends inference requests" "HTTP POST /v1/responses"

        # Internal flows
        experiment -> hpo "Iterates hyperparameters"
        hpo -> simpleRAG "Configures RAG template"
        hpo -> agenticRAG "Configures RAG template"
        experiment -> evaluators "Evaluates results"
        experiment -> assetsGenerator "Generates deployable artifacts"
        assetsGenerator -> starterKit "Produces"
        starterKit -> authWrapper "Validates requests"

        # External integrations
        ai4rag -> maas "LLM inference and embeddings" "HTTPS/443, API key"
        ai4rag -> s3 "Downloads documents" "HTTPS/443, AWS credentials"
        ai4rag -> milvus "Vector storage and retrieval" "gRPC/19530, Token"
        ai4rag -> pgvector "Vector storage and retrieval" "PostgreSQL/5432, Password"
        ai4rag -> neo4j "Graph storage and retrieval" "Bolt/7687, Password"
        starterKit -> maas "Runtime inference" "HTTPS/443, API key"
        authWrapper -> k8sAPI "Token validation" "HTTPS/443, Bearer token"
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
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}
