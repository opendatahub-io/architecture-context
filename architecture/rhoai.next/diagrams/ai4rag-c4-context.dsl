workspace {
    model {
        dataScientist = person "Data Scientist" "Defines RAG templates, search spaces, and benchmark data for optimization"
        mlEngineer = person "ML Engineer" "Integrates ai4rag into ML pipelines and production workflows"

        ai4rag = softwareSystem "ai4rag" "RAG hyperparameter optimization engine using GAM-based search" {
            experiment = container "AI4RAGExperiment" "Top-level orchestrator managing the full optimization lifecycle" "Python Class"
            mps = container "ModelsPreSelector" "Pre-selection engine that evaluates model pairs on a data sample before full HPO" "Python Class"
            gamOptimizer = container "GAMOptimizer" "Primary optimizer using Generalized Additive Models to predict optimal configurations" "Python Class (pygam)"
            randomOptimizer = container "RandomOptimizer" "Fallback optimizer that performs random search over parameter space" "Python Class"
            searchSpace = container "AI4RAGSearchSpace" "Constraint-aware combinatorial search space with pruning rules" "Python Class"
            simpleRAG = container "SimpleRAG" "Default RAG template: chunking → embedding → retrieval → generation" "Python Class"
            evaluator = container "UnitxtEvaluator" "Evaluation engine for answer_correctness, faithfulness, context_correctness" "Python Class (unitxt)"
            chromaLocal = container "ChromaDB (In-memory)" "In-memory vector store for models pre-selection and local development" "Python (langchain-chroma)"
            localHandler = container "LocalEventHandler" "Writes JSON experiment artifacts to disk" "Python Class"
            kfpHandler = container "KFPEventHandler" "Accumulates results in memory for Kubeflow Pipelines integration" "Python Class"
        }

        llamaStack = softwareSystem "Llama Stack Server" "Backend server providing embeddings, vector stores (Milvus/Qdrant), and chat completions" "External"
        openaiAPI = softwareSystem "OpenAI-compatible API" "Alternative backend for embeddings and chat completions" "External"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration platform" "Internal RHOAI"

        # User interactions
        dataScientist -> ai4rag "Defines search space and runs optimization experiments" "Python API"
        mlEngineer -> ai4rag "Integrates into KFP pipelines via KFPEventHandler" "Python API"

        # Internal container relationships
        experiment -> mps "Phase 1: pre-select model pairs" "In-process"
        experiment -> gamOptimizer "Phase 2: optimize hyperparameters" "In-process"
        experiment -> randomOptimizer "Phase 2: random search fallback" "In-process"
        gamOptimizer -> searchSpace "Select next parameter node" "In-process"
        randomOptimizer -> searchSpace "Sample random node" "In-process"
        gamOptimizer -> simpleRAG "Run RAG evaluation" "In-process"
        gamOptimizer -> evaluator "Evaluate results" "In-process"
        mps -> evaluator "Evaluate pre-selection results" "In-process"
        mps -> chromaLocal "Temporary vector storage" "In-process"
        gamOptimizer -> localHandler "Emit experiment events" "In-process"
        gamOptimizer -> kfpHandler "Emit experiment events" "In-process"

        # External integrations
        ai4rag -> llamaStack "Embeddings, VectorIO, Chat Completions, Models List" "HTTP/HTTPS, API Key"
        ai4rag -> openaiAPI "Embeddings, Chat Completions (alternative)" "HTTP/HTTPS, API Key"
        kfpHandler -> kubeflowPipelines "Stream experiment status and results" "Python SDK"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
