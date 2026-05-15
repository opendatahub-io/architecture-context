workspace {
    model {
        dataScientist = person "Data Scientist" "Defines RAG templates, search spaces, and benchmark data for optimization"
        mlEngineer = person "ML Engineer" "Integrates ai4rag into KFP pipelines for automated RAG optimization"

        ai4rag = softwareSystem "ai4rag" "Automated hyperparameter optimization engine for RAG pipelines" {
            experiment = container "AI4RAGExperiment" "Orchestrates full HPO lifecycle: MPS, optimization iterations, evaluation" "Python Module"
            mps = container "ModelsPreSelector" "Fast screening of foundation model x embedding model pairs" "Python Module"
            gamOptimizer = container "GAMOptimizer" "GAM-based Bayesian optimization for search space exploration" "Python Module (pygam)"
            randomOptimizer = container "RandomOptimizer" "Random search baseline optimizer" "Python Module"
            simpleRAG = container "SimpleRAG" "RAG template: chunk -> embed -> retrieve -> generate" "Python Module"
            ogxModels = container "OGX Model Clients" "Foundation model + embedding model integration via ogx-client" "Python Module (ogx-client)"
            ogxVectorStore = container "OGX Vector Store" "Vector store management and similarity search via OGX" "Python Module (ogx-client)"
            chromaVectorStore = container "ChromaVectorStore" "In-memory ChromaDB for MPS fast screening" "Python Module (langchain_chroma)"
            evaluator = container "UnitxtEvaluator" "RAG evaluation metrics with confidence intervals" "Python Module (unitxt)"
            searchSpace = container "AI4RAGSearchSpace" "Search space definition with constraint rules" "Python Module"
            eventHandler = container "EventHandler" "Pluggable event streaming (Local JSON / KFP)" "Python Module"
        }

        ogxServer = softwareSystem "OGX Server" "Foundation model inference, embeddings, and vector store operations (REST API)" "External"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration platform" "Internal RHOAI"

        # User relationships
        dataScientist -> ai4rag "Defines experiments and runs optimization" "Python API"
        mlEngineer -> kubeflowPipelines "Creates KFP pipelines that use ai4rag"

        # System-level relationships
        ai4rag -> ogxServer "Chat completions, embeddings, vector store CRUD" "HTTPS/TLS, API Key Bearer"
        kubeflowPipelines -> ai4rag "Consumes as library in pipeline components" "In-process (KFPEventHandler)"

        # Container-level relationships
        experiment -> mps "Pre-selects optimal model pairs"
        experiment -> gamOptimizer "Runs GAM-based optimization"
        experiment -> randomOptimizer "Runs random search (fallback / initial)"
        experiment -> simpleRAG "Executes RAG pipeline per parameter combo"
        experiment -> evaluator "Evaluates predictions vs references"
        experiment -> eventHandler "Emits experiment status and results"
        experiment -> searchSpace "Gets valid parameter combinations"

        mps -> chromaVectorStore "Stores embeddings for fast screening"
        mps -> ogxModels "Tests model candidates"

        simpleRAG -> ogxModels "Text generation and embedding"
        simpleRAG -> ogxVectorStore "Document indexing and retrieval"

        ogxModels -> ogxServer "REST API calls" "HTTPS/TLS, API Key"
        ogxVectorStore -> ogxServer "REST API calls" "HTTPS/TLS, API Key"
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
