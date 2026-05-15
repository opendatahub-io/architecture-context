workspace {
    model {
        datascientist = person "Data Scientist" "Defines RAG templates, search spaces, and runs optimization experiments"
        mlEngineer = person "ML Engineer" "Integrates ai4rag into Kubeflow Pipelines for automated RAG optimization"

        ai4rag = softwareSystem "ai4rag" "Provider-agnostic RAG hyperparameter optimization engine (Python library)" {
            experiment = container "AI4RAGExperiment" "Orchestrates the full optimization loop: random exploration then GAM-guided search" "Python"
            mps = container "ModelsPreSelector" "Pre-selects top-N foundation model / embedding model pairs before main optimization" "Python"
            gamOptimizer = container "GAMOptimizer" "Bayesian-style optimization using Generalized Additive Models (pygam)" "Python"
            searchSpace = container "AI4RAGSearchSpace" "Constraint-based hyperparameter space definition and pruning" "Python"
            ragTemplate = container "SimpleRAGTemplate" "End-to-end RAG pipeline: chunk, embed, store, retrieve, generate" "Python"
            evaluator = container "UnitxtEvaluator" "Evaluates RAG quality: answer correctness, faithfulness, context correctness" "Python"
            eventHandler = container "EventHandler" "Emits experiment events (KFPEventHandler for pipelines, LocalEventHandler for dev)" "Python"
        }

        ogxServer = softwareSystem "OGX Server" "Unified API for embeddings, vector stores, and foundation model inference (formerly Llama Stack)" "External"
        chromadb = softwareSystem "ChromaDB" "In-memory vector store for local development and MPS pre-selection" "In-Process"
        kfp = softwareSystem "Kubeflow Pipelines" "Pipeline orchestration platform for ML workflows" "Internal RHOAI"
        unitxt = softwareSystem "Unitxt" "IBM evaluation framework for NLP metrics with confidence intervals" "External Library"
        pygam = softwareSystem "pygam" "Generalized Additive Models library for optimization" "External Library"
        langchain = softwareSystem "LangChain" "Document handling and text splitting framework" "External Library"

        # Relationships - Users
        datascientist -> ai4rag "Defines RAG templates and runs search() via Python API"
        mlEngineer -> ai4rag "Integrates into Kubeflow Pipeline steps"

        # Relationships - Internal
        experiment -> mps "Pre-selects models before main loop"
        experiment -> gamOptimizer "Requests next configuration, updates with observations"
        experiment -> searchSpace "Generates valid parameter combinations"
        experiment -> ragTemplate "Instantiates and evaluates RAG patterns"
        experiment -> evaluator "Scores predictions against references"
        experiment -> eventHandler "Emits pattern results and status events"

        # Relationships - External
        ai4rag -> ogxServer "Embeddings, vector store CRUD, chat completions" "HTTPS/TLS 1.2+, API Key (Bearer)"
        ai4rag -> chromadb "In-memory vector storage for dev and MPS" "In-process Python API"
        ai4rag -> kfp "Streams experiment status via KFPEventHandler" "In-process Python API"
        ai4rag -> unitxt "RAG evaluation metrics" "In-process Python API"
        ai4rag -> pygam "GAM model training and prediction" "In-process Python API"
        ai4rag -> langchain "Document handling and text splitting" "In-process Python API"
    }

    views {
        systemContext ai4rag "SystemContext" {
            include *
            autoLayout
            description "ai4rag in the context of the RHOAI platform and external services"
        }

        container ai4rag "Containers" {
            include *
            autoLayout
            description "Internal structure of the ai4rag optimization engine"
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
            element "External Library" {
                background #bbbbbb
                color #333333
            }
            element "In-Process" {
                background #bbbbbb
                color #333333
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
