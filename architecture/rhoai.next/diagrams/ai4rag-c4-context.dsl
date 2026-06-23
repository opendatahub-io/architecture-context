workspace {
    model {
        dataScientist = person "Data Scientist" "Defines RAG templates, benchmark data, and search space parameters for optimization"
        kfpPipeline = softwareSystem "Kubeflow Pipelines" "Orchestrates ML workflows including RAG optimization steps" "Internal RHOAI"

        ai4rag = softwareSystem "ai4rag" "Provider-agnostic RAG optimization engine that finds optimal hyperparameters for RAG pipelines via automated experimentation" {
            experimentEngine = container "AI4RAGExperiment" "Orchestrates the full optimization lifecycle: pre-selection, HPO loop, evaluation" "Python"
            modelsPreSelector = container "ModelsPreSelector" "Pre-screens foundation and embedding models on sample data to narrow search space" "Python"
            gamOptimizer = container "GAMOptimizer" "Uses Generalized Additive Models to predict promising parameter combinations" "Python / pygam"
            randomOptimizer = container "RandomOptimizer" "Baseline random search optimizer for comparison" "Python"
            searchSpace = container "AI4RAGSearchSpace" "Defines parameter space with constraint rules (chunk size, overlap, search mode consistency)" "Python / pydantic"
            ragTemplate = container "SimpleRAGTemplate" "Executes single RAG evaluation: chunk → embed → store → retrieve → generate → evaluate" "Python"
            retriever = container "Retriever" "Performs similarity and hybrid search against vector stores" "Python"
            chunker = container "LangChainChunker" "Splits documents using RecursiveCharacterTextSplitter" "Python / langchain"
            evaluator = container "UnitxtEvaluator" "Computes RAG quality metrics: faithfulness, answer correctness, context correctness" "Python / unitxt"
            ogxProviders = container "OGX Provider Layer" "OGXFoundationModel, OGXEmbeddingModel, OGXVectorStore — abstractions over OGX API" "Python / ogx-client"
            chromaStore = container "ChromaDB Vector Store" "In-memory vector store for models pre-selection and local experiments" "Python / langchain-chroma"
            eventHandler = container "EventHandler" "Emits experiment progress events (LocalEventHandler, KFPEventHandler)" "Python"
        }

        ogxServer = softwareSystem "OGX Server" "Foundation model inference, embedding generation, and vector store operations (Milvus, Qdrant)" "External"
        chromaDB = softwareSystem "ChromaDB" "In-memory vector database for local experiments" "Embedded"

        # User interactions
        dataScientist -> ai4rag "Defines search space, provides documents & benchmarks" "Python API"
        kfpPipeline -> ai4rag "Invokes as pipeline component" "Python API"

        # Internal flows
        experimentEngine -> modelsPreSelector "Pre-selects top models"
        experimentEngine -> gamOptimizer "Runs GAM-based HPO"
        experimentEngine -> randomOptimizer "Runs random search HPO"
        experimentEngine -> ragTemplate "Evaluates single RAG configuration"
        experimentEngine -> searchSpace "Iterates parameter combinations"
        experimentEngine -> evaluator "Computes quality metrics"
        experimentEngine -> eventHandler "Emits progress events"
        ragTemplate -> chunker "Splits documents"
        ragTemplate -> retriever "Retrieves relevant chunks"
        ragTemplate -> ogxProviders "Generates answers, embeds text"
        retriever -> ogxProviders "Queries vector store"
        modelsPreSelector -> chromaStore "Uses for quick local evaluation"
        modelsPreSelector -> evaluator "Evaluates model pairs"
        eventHandler -> kfpPipeline "Streams results via KFPEventHandler" "Python API"

        # External flows
        ogxProviders -> ogxServer "Chat completions, embeddings, vector store CRUD" "HTTPS/TLS, API Key (Bearer)"
        searchSpace -> ogxServer "Auto-discover available models" "HTTPS/TLS, API Key (Bearer)"
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
            element "Embedded" {
                background #b8d4e3
                color #333333
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
