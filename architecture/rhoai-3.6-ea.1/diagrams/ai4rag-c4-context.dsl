workspace {
    model {
        user = person "Data Scientist" "Builds and optimizes RAG pipelines for document retrieval and generation"

        ai4rag = softwareSystem "ai4rag" "Automatic and optimized RAG Pattern generator - Python library" {
            ingestion = container "Data Ingestion" "Downloads documents from S3 and extracts text using Docling" "Python (boto3, Docling)"
            chunking = container "Chunking Engine" "Splits text into chunks using Langchain or Docling strategies" "Python (langchain-text-splitters, docling-slim)"
            ragPipeline = container "RAG Pipeline" "Orchestrates embedding, retrieval, and generation via OGX" "Python (ogx-client)"
            optimizer = container "Hyperparameter Optimizer" "Tunes RAG parameters using Bayesian (GAM) and random search" "Python (scikit-learn, pygam)"
            evaluator = container "RAG Evaluator" "Evaluates RAG quality using LLM-as-Judge and Unitxt metrics" "Python (unitxt)"
            notebookGen = container "Notebook Generator" "Produces deployment-ready Jupyter notebook artifacts" "Python (nbformat)"
        }

        s3Storage = softwareSystem "S3-Compatible Storage" "Document storage (AWS S3, MinIO)" "External"
        ogxService = softwareSystem "OGX Inference Service" "Embeddings, chat completions, and vector store operations" "Internal Platform"

        # User interactions
        user -> ai4rag "Configures and runs RAG optimization"

        # Internal flows
        ingestion -> chunking "Raw extracted text"
        chunking -> ragPipeline "Text chunks"
        ragPipeline -> optimizer "RAG results for tuning"
        optimizer -> evaluator "Candidate configurations"
        evaluator -> optimizer "Quality scores"
        optimizer -> notebookGen "Optimized RAG configuration"

        # External integrations
        ingestion -> s3Storage "Downloads documents" "HTTPS / AWS Access Key"
        ragPipeline -> ogxService "Embeddings, chat completions, vector store" "HTTPS / API Key"
        evaluator -> ogxService "LLM-as-Judge evaluation calls" "HTTPS / API Key"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
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
        }
    }
}
