workspace {
    model {
        dataScientist = person "Data Scientist" "Defines RAG pipeline templates, search space, and benchmark datasets"
        platformEngineer = person "Platform Engineer" "Configures and deploys RAG optimization pipelines on RHOAI"

        ai4rag = softwareSystem "ai4rag" "Provider-agnostic optimization engine that finds optimal hyperparameters for RAG pipelines" {
            experimentModule = container "ai4rag.core.experiment" "Orchestrates the full RAG optimization lifecycle including MPS and HPO" "Python Module"
            hpoModule = container "ai4rag.core.hpo" "Hyperparameter optimization algorithms (GAM-based surrogate model, random search)" "Python Module"
            searchSpaceModule = container "ai4rag.search_space" "Parameter definitions, constraint validation, search space composition and pruning" "Python Module"
            ragModule = container "ai4rag.rag" "RAG pipeline components: chunking, embedding, vector store, retrieval, template orchestration" "Python Module"
            evaluatorModule = container "ai4rag.evaluator" "RAG evaluation metrics via unitxt (faithfulness, answer correctness, context correctness)" "Python Module"
            utilsModule = container "ai4rag.utils" "Event handlers (Local, KFP), validators, constants" "Python Module"
        }

        ogxServer = softwareSystem "OGX Server" "Foundation model serving platform (formerly Llama Stack) providing chat, embeddings, and vector store APIs" "External"
        chromaDB = softwareSystem "ChromaDB" "In-memory vector database for local development and model pre-selection" "External Library"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration platform on RHOAI" "Internal RHOAI"
        milvus = softwareSystem "Milvus / Qdrant" "Production vector database accessed through OGX Server" "External"
        unitxt = softwareSystem "unitxt" "Evaluation framework for NLP metrics" "External Library"
        langchain = softwareSystem "LangChain" "Document loading, text splitting, and vector store abstractions" "External Library"
        pygam = softwareSystem "pygam" "Generalized Additive Models for HPO surrogate modeling" "External Library"

        # Relationships - System Context
        dataScientist -> ai4rag "Defines search space, templates, and benchmark data"
        platformEngineer -> kubeflowPipelines "Deploys RAG optimization pipeline"
        kubeflowPipelines -> ai4rag "Embeds as library dependency in pipeline components"

        ai4rag -> ogxServer "Chat completions, embeddings, vector store CRUD" "HTTPS / TLS 1.2+ / API Key (Bearer)"
        ai4rag -> chromaDB "In-memory vector indexing for model pre-selection" "In-process Python"
        ai4rag -> unitxt "RAG quality metrics evaluation" "In-process Python"
        ai4rag -> langchain "Document chunking and vector store abstraction" "In-process Python"
        ai4rag -> pygam "GAM surrogate model fitting for HPO" "In-process Python"

        ogxServer -> milvus "Vector storage backend" "Internal"

        # Relationships - Container level
        experimentModule -> hpoModule "Delegates optimization"
        experimentModule -> searchSpaceModule "Reads parameter definitions"
        experimentModule -> ragModule "Executes RAG patterns"
        experimentModule -> evaluatorModule "Evaluates metrics"
        experimentModule -> utilsModule "Streams events"

        hpoModule -> ragModule "Runs RAG iterations"
        hpoModule -> evaluatorModule "Scores patterns"

        ragModule -> ogxServer "Foundation model inference, embeddings, vector store" "HTTPS / TLS 1.2+ / API Key"
        ragModule -> chromaDB "Local in-memory vector storage" "In-process"
        evaluatorModule -> unitxt "Metric computation" "In-process"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape Person
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
