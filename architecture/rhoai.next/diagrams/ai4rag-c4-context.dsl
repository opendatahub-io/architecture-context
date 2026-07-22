workspace {
    model {
        dataScientist = person "Data Scientist" "Defines RAG search spaces, provides benchmark data, consumes optimization results"
        kfpUser = person "KFP Pipeline Author" "Integrates ai4rag into Kubeflow Pipelines components"

        ai4rag = softwareSystem "ai4rag" "RAG template optimization engine — discovers optimal RAG pipeline parameters through hyperparameter optimization (Bayesian GAM / random search)" {
            experimentOrchestrator = container "AI4RAGExperiment" "Main experiment orchestrator managing pre-selection, optimization loop, and result aggregation" "Python Module"
            hpoEngine = container "HPO Engine" "Hyperparameter optimization: GAM-based Bayesian optimization and random search with result caching" "Python Module (pygam, scikit-learn)"
            ragPipeline = container "RAG Pipeline" "Chunking (Docling/LangChain), embedding, vector store, retrieval, and generation components" "Python Module"
            evaluator = container "Evaluator" "Unitxt metrics (answer_correctness, faithfulness, context_correctness) and LLM-as-a-Judge scoring" "Python Module (unitxt)"
            searchSpace = container "Search Space" "Parameter space definition with constraint validation, model discovery, and language detection" "Python Module (pydantic)"
            eventHandler = container "Event Handler" "Pluggable event streaming — LocalEventHandler (JSON to disk), KFPEventHandler (KFP component output)" "Python Module"
        }

        ogxServer = softwareSystem "OGX Server" "Foundation model inference, embedding generation, and vector store management (OpenAI-compatible REST API)" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for documents and experiment artifacts" "External"
        chromaDB = softwareSystem "ChromaDB" "In-memory vector store for local development and model pre-selection" "External (in-process)"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "ML workflow orchestration platform" "Internal RHOAI"
        unitxtLib = softwareSystem "Unitxt" "RAG evaluation metrics library (IBM Research)" "External (in-process)"
        docling = softwareSystem "Docling" "Document parsing and conversion library" "External (in-process)"

        # User interactions
        dataScientist -> ai4rag "Provides documents, benchmark Q&A, search space config"
        kfpUser -> ai4rag "Integrates as KFP component for automated optimization"

        # Internal interactions
        experimentOrchestrator -> hpoEngine "Requests next parameter set, updates with scores"
        experimentOrchestrator -> ragPipeline "Builds and executes RAG pipeline per iteration"
        experimentOrchestrator -> evaluator "Evaluates generated answers against ground truth"
        experimentOrchestrator -> searchSpace "Samples parameters, validates constraints"
        experimentOrchestrator -> eventHandler "Emits pattern creation and experiment end events"

        # External interactions
        ai4rag -> ogxServer "Inference, embeddings, vector store CRUD" "HTTPS / API Key (Bearer)"
        ai4rag -> s3Storage "Document and artifact persistence" "HTTPS/443 / AWS IAM"
        ai4rag -> chromaDB "Local vector store (in-process, no network)" "Python API"
        ai4rag -> unitxtLib "RAG evaluation metrics" "Python API (in-process)"
        ai4rag -> docling "Document parsing" "Python API (in-process)"
        eventHandler -> kubeflowPipelines "Streams optimization results to KFP component output" "In-process callback"
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
            element "External (in-process)" {
                background #bbbbbb
                color #ffffff
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
