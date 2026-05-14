workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Creates and optimizes RAG pipelines using notebooks or ML pipelines"

        ai4rag = softwareSystem "ai4rag" "Provider-agnostic Python library that automatically finds optimal hyperparameter configurations for RAG pipelines" {
            experimentModule = container "ai4rag.core.experiment" "Orchestrates end-to-end RAG optimization workflow including Models Pre-Selection" "Python Module"
            hpoModule = container "ai4rag.core.hpo" "Hyperparameter optimization algorithms: GAM-based surrogate optimizer and random search baseline" "Python Module"
            ragModule = container "ai4rag.rag" "RAG pipeline components: chunking, embedding, retrieval, vector stores, and templates (index-retrieve-generate)" "Python Module"
            searchSpaceModule = container "ai4rag.search_space" "Search space definition, parameter management, constraint rules, and Llama Stack auto-discovery" "Python Module"
            evaluatorModule = container "ai4rag.evaluator" "RAG evaluation using Unitxt: answer correctness, faithfulness, context correctness with confidence intervals" "Python Module"
            eventHandlerModule = container "ai4rag.utils.event_handler" "Event handler interfaces: LocalEventHandler (JSON to filesystem) and KFPEventHandler (pipeline metadata)" "Python Module"
        }

        llamaStack = softwareSystem "Llama Stack Server" "Backend for foundation models, embedding models, and vector stores" "External"
        openaiApi = softwareSystem "OpenAI-Compatible API" "Alternative backend for foundation models and embeddings" "External"
        chromaDB = softwareSystem "ChromaDB" "In-memory vector store for local development and Models Pre-Selection" "External - In-Process"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration system for experiment metadata" "External"

        # External library dependencies (in-process)
        langchain = softwareSystem "LangChain" "Document abstraction and text splitting (recursive, character, token)" "Library"
        unitxt = softwareSystem "Unitxt" "RAG evaluation metrics computation framework" "Library"
        pygam = softwareSystem "pygam" "Generalized Additive Models for surrogate-based hyperparameter optimization" "Library"
        scikitlearn = softwareSystem "scikit-learn" "LabelEncoder for categorical parameter encoding in GAM optimizer" "Library"

        # User relationships
        dataScientist -> ai4rag "Imports and configures, defines search space, runs optimization experiments" "Python API"

        # ai4rag to external services
        ai4rag -> llamaStack "Chat completions, embeddings, vector store CRUD, vector IO, model discovery" "HTTP/HTTPS, API Key (Bearer)"
        ai4rag -> openaiApi "Chat completions, text embeddings (alternative backend)" "HTTPS, API Key (Bearer)"
        ai4rag -> chromaDB "In-memory vector store for local dev and MPS" "In-process Python API"
        ai4rag -> kubeflowPipelines "Streams experiment results as pipeline metadata" "In-process (KFPEventHandler)"

        # ai4rag to library dependencies
        ai4rag -> langchain "Document chunking and text splitting" "In-process Python API"
        ai4rag -> unitxt "RAG evaluation metrics" "In-process Python API"
        ai4rag -> pygam "Surrogate model for GAM-based HPO" "In-process Python API"
        ai4rag -> scikitlearn "Categorical parameter encoding" "In-process Python API"

        # Internal container relationships
        experimentModule -> hpoModule "Requests next hyperparameters, updates with scores"
        experimentModule -> ragModule "Executes RAG pipeline with suggested parameters"
        experimentModule -> searchSpaceModule "Applies constraint rules, samples parameter space"
        experimentModule -> evaluatorModule "Evaluates RAG pipeline results"
        experimentModule -> eventHandlerModule "Emits iteration results and experiment events"
        ragModule -> llamaStack "Embedding, chat, vector IO operations"
        ragModule -> openaiApi "Embedding, chat operations (alternative)"
        ragModule -> chromaDB "In-memory vector operations"
        searchSpaceModule -> llamaStack "Auto-discovers available models and vector stores"
        hpoModule -> pygam "Fits surrogate GAM model for optimization"
        evaluatorModule -> unitxt "Computes evaluation metrics"
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
            element "External - In-Process" {
                background #bbbbbb
                color #ffffff
            }
            element "Library" {
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
