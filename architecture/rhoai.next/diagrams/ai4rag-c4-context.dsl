workspace {
    model {
        dataScientist = person "Data Scientist" "Defines RAG templates, benchmark data, and search space parameters"
        mlEngineer = person "ML Engineer" "Operates KFP pipelines that consume ai4rag for automated RAG optimization"

        ai4rag = softwareSystem "ai4rag" "RAG hyperparameter optimization engine that finds optimal configurations for RAG pipelines" {
            experiment = container "AI4RAGExperiment" "Top-level orchestrator coordinating model pre-selection, HPO, and evaluation" "Python Class"
            preSelector = container "ModelsPreSelector" "Evaluates foundation/embedding model pairs on benchmark samples" "Python Class"
            gamOptimizer = container "GAMOptimizer" "GAM-based guided search for optimal hyperparameters" "Python Class (pygam)"
            randomOptimizer = container "RandomOptimizer" "Random search baseline for hyperparameter exploration" "Python Class"
            searchSpace = container "AI4RAGSearchSpace" "Constrained search space with rules pruning invalid parameter combinations" "Python Class"
            simpleRAG = container "SimpleRAG" "RAG template orchestrating chunking, retrieval, and generation" "Python Class"
            chunker = container "LangChainChunker" "Document chunking via RecursiveCharacterTextSplitter" "Python Class (langchain)"
            evaluator = container "UnitxtEvaluator" "RAG metrics: faithfulness, answer correctness, context correctness" "Python Class (unitxt)"
            ogxAdapters = container "OGX Provider Adapters" "Client wrappers for foundation model, embedding, and vector store APIs" "Python Classes (ogx-client)"
            chromaStore = container "ChromaVectorStore" "In-memory vector store for local dev and model pre-selection" "Python Class (chromadb)"
            eventHandlers = container "Event Handlers" "LocalEventHandler (JSON files) and KFPEventHandler (pipeline callbacks)" "Python Classes"
        }

        ogxServer = softwareSystem "OGX Server" "Foundation model inference, embedding generation, and vector store management (formerly Llama Stack)" "External"
        kfp = softwareSystem "Kubeflow Pipelines (KFP)" "ML pipeline orchestration platform for automated RAG optimization workflows" "Internal RHOAI"
        langchain = softwareSystem "LangChain" "RAG framework for document abstraction and text splitting" "External Library"
        unitxt = softwareSystem "Unitxt" "IBM evaluation framework for RAG metrics computation" "External Library"
        pygam = softwareSystem "PyGAM" "Generalized Additive Models library for surrogate-based optimization" "External Library"

        # User interactions
        dataScientist -> ai4rag "Defines search space and runs optimization experiments" "Python API"
        mlEngineer -> kfp "Triggers RAG optimization pipeline runs" "KFP UI / CLI"

        # System interactions
        kfp -> ai4rag "Invokes ai4rag via KFPEventHandler in pipeline components" "In-process Python"
        ai4rag -> ogxServer "Foundation model inference, embeddings, vector store CRUD" "HTTPS/TLS 1.2+, API Key"

        # Library dependencies (in-process)
        ai4rag -> langchain "Document chunking and abstraction" "In-process Python"
        ai4rag -> unitxt "RAG evaluation metrics computation" "In-process Python"
        ai4rag -> pygam "GAM surrogate model training and prediction" "In-process Python"

        # Container-level interactions
        experiment -> preSelector "Triggers model pre-selection phase"
        experiment -> gamOptimizer "Delegates HPO iterations"
        experiment -> randomOptimizer "Alternative optimizer"
        experiment -> searchSpace "Builds constrained parameter space"
        experiment -> eventHandlers "Reports optimization results"
        gamOptimizer -> simpleRAG "Runs single RAG evaluation per iteration"
        preSelector -> chromaStore "Uses in-memory store for quick evaluation"
        simpleRAG -> chunker "Chunks documents"
        simpleRAG -> evaluator "Evaluates RAG output quality"
        simpleRAG -> ogxAdapters "Calls OGX for inference, embeddings, vectors"
        ogxAdapters -> ogxServer "HTTPS REST API calls" "ogx-client SDK"
    }

    views {
        systemContext ai4rag "SystemContext" {
            include *
            autoLayout
            description "ai4rag in the context of RHOAI platform and external services"
        }

        container ai4rag "Containers" {
            include *
            autoLayout
            description "Internal structure of ai4rag library showing optimization pipeline components"
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
            element "External Library" {
                background #bbbbbb
                color #333333
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
        }
    }
}
