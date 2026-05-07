workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and optimizes RAG pipelines using ai4rag in notebooks or scripts"

        ai4rag = softwareSystem "ai4rag" "Optimization engine that finds optimal hyperparameter configurations for RAG pipelines" {
            experiment = container "Experiment Orchestrator" "Manages end-to-end RAG optimization workflow with budget-based iteration" "Python Module"
            hpo = container "HPO Engine" "GAM-based and random search hyperparameter optimization algorithms" "Python Module (pygam)"
            ragPipeline = container "RAG Pipeline" "Template-based pipeline: chunking, embedding, retrieval, generation" "Python Module (LangChain)"
            searchSpace = container "Search Space Manager" "Parameter definitions, constraint rules, Llama Stack auto-discovery" "Python Module (Pydantic)"
            evaluator = container "Evaluator" "RAG evaluation with answer correctness, faithfulness, and context metrics" "Python Module (Unitxt)"
            eventHandler = container "Event Handlers" "Streams experiment results to filesystem or KFP metadata" "Python Module"
        }

        llamaStack = softwareSystem "Llama Stack Server" "Backend for foundation models, embeddings, and vector stores" "External"
        openaiAPI = softwareSystem "OpenAI-compatible API" "Alternative backend for foundation models and embeddings" "External"
        chromaDB = softwareSystem "ChromaDB" "In-memory vector store for local development and MPS phase" "External In-Process"
        kfp = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration — receives experiment metadata" "Internal Platform"

        # External relationships
        dataScientist -> ai4rag "Imports library, defines search space, runs optimization experiments" "Python API"
        ai4rag -> llamaStack "Chat completions, embeddings, vector store CRUD, model discovery" "HTTP/HTTPS, API Key"
        ai4rag -> openaiAPI "Chat completions and embeddings (alternative backend)" "HTTPS, API Key"
        ai4rag -> chromaDB "In-memory vector store operations" "In-process Python API"
        ai4rag -> kfp "Streams experiment results as pipeline metadata" "KFPEventHandler"

        # Internal relationships
        experiment -> hpo "Requests next parameter suggestions, reports observations"
        experiment -> ragPipeline "Executes RAG template (index, retrieve, generate)"
        experiment -> searchSpace "Prepares search space with constraints"
        experiment -> evaluator "Evaluates RAG answers against references"
        experiment -> eventHandler "Emits evaluation records and pattern payloads"
        searchSpace -> llamaStack "Auto-discovers available models" "HTTP/HTTPS"
        ragPipeline -> llamaStack "Embeddings, vector IO, chat completions" "HTTP/HTTPS"
        ragPipeline -> openaiAPI "Embeddings, chat completions" "HTTPS"
        ragPipeline -> chromaDB "Vector store insert/query" "In-process"
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
            element "External In-Process" {
                background #cccccc
                color #333333
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #9b59b6
                color #ffffff
                shape person
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6ba5e7
                color #ffffff
            }
        }
    }
}
