workspace {
    model {
        datascientist = person "Data Scientist" "Configures RAG search space and runs optimization experiments"
        pipelineRunner = person "KFP Pipeline" "Automated pipeline orchestrating document discovery, indexing, and optimization"

        ai4rag = softwareSystem "ai4rag" "Python library for HPO-driven RAG pipeline optimization" {
            experimentEngine = container "Experiment Engine" "Orchestrates end-to-end RAG experiments with HPO" "Python (ai4rag.core.experiment)"
            hpoOptimizer = container "HPO Optimizer" "GAM-based and random search strategies for hyperparameter optimization" "Python (ai4rag.core.hpo)"
            ragPipeline = container "RAG Pipeline" "Chunking, embedding, retrieval, generation building blocks" "Python (ai4rag.rag)"
            evaluator = container "Evaluator" "Unitxt metrics and LLM-as-a-Judge for RAG evaluation" "Python (ai4rag.evaluator)"
            searchSpace = container "Search Space" "Search space definition, constraint validation, OGX model discovery" "Python (ai4rag.search_space)"
            kfpComponents = container "KFP Components" "Pipeline components for document discovery, indexing, optimization" "Python (ai4rag.components)"
        }

        ogxServer = softwareSystem "OGX Server" "Foundation model inference, embeddings, and vector store platform" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Document and benchmark data storage" "External"
        chromaDB = softwareSystem "ChromaDB" "In-memory vector store for local model pre-selection" "In-Process"

        # User relationships
        datascientist -> ai4rag "Configures search space and runs experiments" "Python API"
        pipelineRunner -> ai4rag "Triggers document discovery, indexing, and optimization" "KFP Component API"

        # Internal container relationships
        experimentEngine -> hpoOptimizer "Requests next configuration, reports scores"
        experimentEngine -> ragPipeline "Chunks, embeds, retrieves, generates"
        experimentEngine -> evaluator "Evaluates RAG output quality"
        experimentEngine -> searchSpace "Explores validated search space"
        kfpComponents -> experimentEngine "Runs full optimization"
        kfpComponents -> ragPipeline "Indexes documents"

        # External system relationships
        ragPipeline -> ogxServer "Embedding generation, vector store CRUD, chat completions" "HTTPS/443 API Key"
        searchSpace -> ogxServer "Model and provider discovery" "HTTPS/443 API Key"
        evaluator -> ogxServer "LLM-as-a-Judge evaluation" "HTTPS/443 API Key"
        kfpComponents -> s3Storage "Document discovery and download" "HTTPS/443 AWS IAM"
        ragPipeline -> chromaDB "Local vector store for pre-selection" "In-memory"
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
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "In-Process" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
