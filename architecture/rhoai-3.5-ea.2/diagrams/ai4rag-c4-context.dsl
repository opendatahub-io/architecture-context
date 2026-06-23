workspace {
    model {
        dataScientist = person "Data Scientist" "Tunes RAG pipelines for optimal performance"
        mlEngineer = person "ML Engineer" "Integrates ai4rag into production pipelines"

        ai4rag = softwareSystem "ai4rag" "RAG hyperparameter optimization engine that automatically discovers optimal configurations for RAG pipelines" {
            experiment = container "AI4RAGExperiment" "Orchestrates the full optimization loop: MPS, search space construction, HPO iterations, evaluation" "Python Class"
            mps = container "ModelsPreSelector" "Lightweight evaluation to narrow down foundation and embedding models before full HPO" "Python Class"
            gamOptimizer = container "GAMOptimizer" "Bayesian-like optimization using Generalized Additive Models to predict promising parameter combinations" "Python Class (pyGAM)"
            randomOptimizer = container "RandomOptimizer" "Random search baseline optimizer" "Python Class"
            searchSpace = container "SearchSpace" "Manages tunable parameters with 7 constraint rules to prune invalid combinations" "Python Class"
            simpleRAG = container "SimpleRAGTemplate" "RAG pipeline template: chunk → embed → index → retrieve → generate" "Python Class"
            retriever = container "Retriever" "Performs similarity search against vector stores" "Python Class"
            evaluator = container "UnitxtEvaluator" "Evaluates RAG quality: answer_correctness, faithfulness, context_correctness" "Python Class (Unitxt)"
            ogxAdapter = container "OGX Adapters" "OGXFoundationModel, OGXEmbeddingModel, OGXVectorStore - REST API clients" "Python Classes (ogx-client)"
            chromaAdapter = container "ChromaVectorStore" "In-memory vector store for MPS pre-selection and development" "Python Class (langchain-chroma)"
            chunkers = container "Chunkers" "LangChainChunker (token-based) and DoclingChunker (structure-aware)" "Python Classes"
            eventHandlers = container "Event Handlers" "LocalEventHandler (JSON to disk), KFPEventHandler (Kubeflow Pipelines integration)" "Python Classes"
        }

        ogxServer = softwareSystem "OGX Server" "Provides foundation models (chat), embedding models, and vector store backends (Milvus, Qdrant)" "External"
        chromaDB = softwareSystem "ChromaDB" "In-memory vector store for lightweight evaluation" "External - In-Process"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration platform" "Internal RHOAI"
        unitxt = softwareSystem "Unitxt" "RAG evaluation framework with standardized metrics" "External"
        langchain = softwareSystem "LangChain" "RAG pipeline orchestration and text splitting" "External"
        docling = softwareSystem "Docling" "Document representation and structure-aware chunking" "External"

        # Person relationships
        dataScientist -> ai4rag "Defines search space, benchmark data, and runs experiments"
        mlEngineer -> ai4rag "Integrates into KFP components for automated tuning"

        # Internal container relationships
        experiment -> mps "Pre-selects models"
        experiment -> gamOptimizer "Gets next parameter combination"
        experiment -> randomOptimizer "Gets next parameter combination (alternative)"
        experiment -> searchSpace "Manages parameter space"
        experiment -> simpleRAG "Evaluates RAG patterns"
        experiment -> evaluator "Scores RAG outputs"
        experiment -> eventHandlers "Reports progress and results"
        simpleRAG -> retriever "Performs retrieval"
        retriever -> ogxAdapter "Queries vector store"
        retriever -> chromaAdapter "Queries vector store (MPS/dev)"
        simpleRAG -> ogxAdapter "Generates answers"
        mps -> chromaAdapter "Uses for lightweight eval"
        searchSpace -> ogxAdapter "Discovers available models"

        # External relationships
        ai4rag -> ogxServer "REST API calls: chat, embeddings, vector_stores, vector_io, models" "HTTPS/TLS 1.2+, API Key"
        ai4rag -> chromaDB "In-process vector operations" "Python API"
        kubeflowPipelines -> ai4rag "Executes as pipeline component via KFPEventHandler"
        ai4rag -> unitxt "Evaluates RAG quality metrics" "In-process"
        ai4rag -> langchain "Text splitting and RAG orchestration" "In-process"
        ai4rag -> docling "Document chunking" "In-process"
    }

    views {
        systemContext ai4rag "SystemContext" {
            include *
            autoLayout
            description "ai4rag in the context of its ecosystem - a Python library consumed by KFP and other services"
        }

        container ai4rag "Containers" {
            include *
            autoLayout
            description "Internal structure of the ai4rag library showing orchestration, optimization, and RAG pipeline components"
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External - In-Process" {
                background #cccccc
                color #333333
            }
            element "Internal RHOAI" {
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
