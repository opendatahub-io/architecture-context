workspace {
    model {
        dataScientist = person "Data Scientist" "Defines RAG search space and benchmark data, runs optimization experiments"
        mlEngineer = person "ML Engineer" "Integrates ai4rag into Kubeflow Pipelines for automated RAG optimization"

        ai4rag = softwareSystem "ai4rag" "Python library that automates hyperparameter optimization for RAG pipelines using GAM-based surrogate models" {
            experiment = container "AI4RAGExperiment" "Orchestrates search space exploration, model pre-selection, and result aggregation" "Python Module"
            hpo = container "HPO Engine" "GAM-based and random hyperparameter optimization algorithms" "Python Module (pygam, scikit-learn)"
            ragPipeline = container "RAG Pipeline" "Composable building blocks: foundation models, embeddings, vector stores, chunkers, retriever" "Python Module"
            evaluator = container "Evaluator" "RAG quality evaluation using Unitxt metrics and LLM-as-a-Judge" "Python Module (unitxt)"
            searchSpace = container "Search Space" "Parameter definitions, constraint validation, and OGX model discovery" "Python Module"
            docPipeline = container "Document Pipeline" "S3 document discovery, Docling text extraction, multi-process conversion" "Python Module (docling, boto3)"
            assetsGen = container "Assets Generator" "Pattern JSON builder and Jupyter notebook template generator" "Python Module"
            eventHandler = container "Event Handler" "Local file output and KFP event aggregation" "Python Module"
        }

        ogxServer = softwareSystem "OGX Server" "LLM inference, embedding generation, and vector store operations (formerly llama-stack)" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for document discovery and download" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Public model artifact hosting for Docling OCR/table models" "External"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration platform" "Internal RHOAI"

        # Person relationships
        dataScientist -> ai4rag "Defines search space, runs experiments, reviews RAG Patterns"
        mlEngineer -> ai4rag "Integrates into KFP components for automated optimization"

        # System context relationships
        ai4rag -> ogxServer "Chat completions, embeddings, vector store CRUD, vector I/O" "HTTPS/443, API Key"
        ai4rag -> s3Storage "Document discovery (list_objects), document download" "HTTPS/443, AWS IAM"
        ai4rag -> huggingfaceHub "Docling model artifact download (optional)" "HTTPS/443, Public"
        ai4rag -> kubeflowPipelines "Event status and pattern results via KFPEventHandler" "In-process Python API"

        # Container relationships
        experiment -> hpo "Requests next parameter set, updates with scores"
        experiment -> ragPipeline "Builds and configures RAG pipeline per parameter set"
        experiment -> evaluator "Evaluates RAG pipeline predictions against ground truth"
        experiment -> searchSpace "Validates constraints, generates parameter combinations"
        experiment -> eventHandler "Emits optimization progress and results"

        ragPipeline -> ogxServer "Chat completions, embeddings, vector store operations" "HTTPS/443"
        docPipeline -> s3Storage "Document listing and download" "HTTPS/443"
        docPipeline -> huggingfaceHub "Model artifact download" "HTTPS/443"
        searchSpace -> ogxServer "Discovers available models" "HTTPS/443"
        eventHandler -> kubeflowPipelines "Aggregates experiment results" "Python API"
        assetsGen -> experiment "Reads optimization results to generate deployment artifacts"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
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
        }
    }
}
