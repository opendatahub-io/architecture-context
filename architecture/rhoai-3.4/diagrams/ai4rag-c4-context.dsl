workspace {
    model {
        dataScientist = person "Data Scientist" "Defines RAG benchmark data and search space, runs optimization experiments"
        mlEngineer = person "ML Engineer" "Integrates ai4rag into Kubeflow Pipelines for automated RAG tuning"

        ai4rag = softwareSystem "ai4rag" "RAG hyperparameter optimization engine using GAM-based surrogate model and Bayesian optimization" {
            experiment = container "AI4RAGExperiment" "Orchestrates full RAG optimization lifecycle: model pre-selection, HPO, evaluation" "Python Module"
            preselector = container "ModelsPreSelector" "Filters foundation and embedding models by evaluating on a data sample before full HPO" "Python Module"
            gamOptimizer = container "GAMOptimizer" "Generalized Additive Model-based surrogate optimizer using pygam and scikit-learn" "Python Module"
            randomOptimizer = container "RandomOptimizer" "Baseline random search optimizer for comparison" "Python Module"
            simpleRAG = container "SimpleRAG" "RAG pipeline: chunking, retrieval, context assembly, generation" "Python Module"
            searchSpace = container "AI4RAGSearchSpace" "Manages parameter combinations with constraint rules for valid RAG configurations" "Python Module"
            unitxtEvaluator = container "UnitxtEvaluator" "Computes RAG quality metrics via IBM Unitxt framework" "Python Module"
            eventHandlers = container "Event Handlers" "LocalEventHandler (JSON files) and KFPEventHandler (Kubeflow Pipelines)" "Python Module"
        }

        llamaStack = softwareSystem "Llama Stack Server" "LLM inference, embedding, and vector store operations server" "External"
        openaiEndpoint = softwareSystem "OpenAI-compatible Endpoint" "Alternative LLM and embedding provider" "External"
        milvus = softwareSystem "Milvus" "Vector database for similarity search (proxied via Llama Stack)" "External"
        qdrant = softwareSystem "Qdrant" "Alternative vector database (proxied via Llama Stack)" "External"
        kfp = softwareSystem "Kubeflow Pipelines" "ML workflow orchestration platform" "Internal RHOAI"

        # Person relationships
        dataScientist -> ai4rag "Runs RAG optimization experiments via Python API"
        mlEngineer -> kfp "Creates KFP pipeline components that use ai4rag"

        # System-level relationships
        ai4rag -> llamaStack "Foundation model inference, embeddings, vector store ops" "HTTPS, API Key (Bearer)"
        ai4rag -> openaiEndpoint "Alternative foundation model and embedding calls" "HTTPS, API Key (Bearer)"
        llamaStack -> milvus "Proxies vector storage operations"
        llamaStack -> qdrant "Proxies vector storage operations"
        ai4rag -> kfp "Reports experiment results via KFPEventHandler" "In-process"

        # Container-level relationships
        experiment -> preselector "Runs model pre-selection phase"
        experiment -> gamOptimizer "Gets next parameter suggestion"
        experiment -> randomOptimizer "Gets random parameter suggestion"
        experiment -> simpleRAG "Executes RAG pattern evaluation"
        experiment -> searchSpace "Gets valid parameter combinations"
        experiment -> unitxtEvaluator "Evaluates RAG quality metrics"
        experiment -> eventHandlers "Reports pattern and experiment results"

        preselector -> simpleRAG "Evaluates models on data sample"
        preselector -> searchSpace "Filters search space by model performance"

        simpleRAG -> llamaStack "Chat completions, embeddings, vector I/O" "HTTPS, API Key"
        simpleRAG -> openaiEndpoint "Chat completions, embeddings" "HTTPS, API Key"

        searchSpace -> llamaStack "Discovers available models" "HTTPS, API Key"

        eventHandlers -> kfp "KFPEventHandler integration" "In-process"
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
