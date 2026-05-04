workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Imports ai4rag into notebooks or pipelines to optimize RAG configurations"

        ai4rag = softwareSystem "ai4rag" "Provider-agnostic Python library for hyperparameter optimization of RAG pipelines" {
            experiment = container "Experiment Orchestrator" "Manages end-to-end RAG optimization workflow — MPS, HPO loop, evaluation" "Python Module (ai4rag.core.experiment)"
            hpo = container "HPO Engine" "GAM-based surrogate optimizer and random search baseline" "Python Module (ai4rag.core.hpo)"
            ragPipeline = container "RAG Pipeline" "Chunking, embedding, retrieval, vector stores, and RAG templates" "Python Module (ai4rag.rag)"
            searchSpace = container "Search Space Manager" "Parameter definitions, constraints, and Llama Stack auto-discovery" "Python Module (ai4rag.search_space)"
            evaluator = container "Evaluator" "RAG evaluation using Unitxt for correctness, faithfulness, and context metrics" "Python Module (ai4rag.evaluator)"
            eventHandlers = container "Event Handlers" "Local filesystem (JSON) and Kubeflow Pipelines metadata event handlers" "Python Module (ai4rag.utils.event_handler)"
        }

        llamaStack = softwareSystem "Llama Stack Server" "Backend for foundation models, embeddings, and vector store operations" "External"
        openaiAPI = softwareSystem "OpenAI-Compatible API" "Alternative backend for foundation model chat completions and embeddings" "External"
        chromaDB = softwareSystem "ChromaDB" "In-memory vector store for local development and MPS evaluation" "External Library"

        # External libraries (in-process)
        unitxt = softwareSystem "Unitxt" "RAG evaluation metrics framework with confidence intervals" "External Library"
        langchain = softwareSystem "LangChain" "Document abstraction and text splitting (recursive, character, token)" "External Library"
        pygam = softwareSystem "pygam (LinearGAM)" "Generalized Additive Models for surrogate-based HPO" "External Library"
        scikitlearn = softwareSystem "scikit-learn" "LabelEncoder for categorical parameter encoding" "External Library"
        kfp = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration — receives experiment metadata via KFPEventHandler" "Internal Platform"

        # Relationships
        dataScientist -> ai4rag "Imports and configures RAG optimization experiments" "Python API"

        experiment -> hpo "Requests next parameter suggestion and reports observations" "In-process"
        experiment -> ragPipeline "Configures and executes index → retrieve → generate pipeline" "In-process"
        experiment -> searchSpace "Defines and samples parameter configurations" "In-process"
        experiment -> evaluator "Evaluates RAG answers against ground truth" "In-process"
        experiment -> eventHandlers "Emits PatternPayload and EvaluationRecord events" "In-process"

        ragPipeline -> llamaStack "Chat completions, embeddings, vector store CRUD, vector IO" "HTTP/HTTPS, API Key"
        ragPipeline -> openaiAPI "Chat completions and embeddings (alternative backend)" "HTTPS, API Key"
        ragPipeline -> chromaDB "In-memory vector store operations" "In-process"
        ragPipeline -> langchain "Document chunking with recursive/character/token splitters" "In-process"

        searchSpace -> llamaStack "Auto-discover available models (models.list)" "HTTP/HTTPS, API Key"

        evaluator -> unitxt "Compute answer correctness, faithfulness, context correctness" "In-process"

        hpo -> pygam "Train GAM surrogate model for guided parameter exploration" "In-process"
        hpo -> scikitlearn "Encode categorical parameters for GAM input" "In-process"

        eventHandlers -> kfp "Stream experiment results as pipeline metadata" "In-process (KFPEventHandler)"
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
            element "External Library" {
                background #bbbbbb
                color #333333
                shape RoundedBox
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #333333
            }
        }
    }
}
