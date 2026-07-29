workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Builds and optimizes RAG pipelines using ai4rag"

        ai4rag = softwareSystem "ai4rag" "Automatic and optimized RAG pattern generator — Python library for document ingestion, text extraction, vector storage, and RAG optimization" {
            s3downloader = container "S3 Downloader" "Concurrent threaded download from S3-compatible storage (max 8 threads)" "Python / boto3"
            textextractor = container "Docling Text Extractor" "Multiprocess text extraction from PDF, DOCX, PPTX, HTML, MD, TXT (max 8 workers)" "Python / Docling"
            chunker = container "Text Chunker" "Splits extracted text into chunks with deterministic SHA-256 IDs" "Python / LangChain"
            vectorstore = container "Vector Store" "Stores text chunks and embeddings in OGX or Chroma backends" "Python / ogx-client, langchain-chroma"
            optimizer = container "RAG Optimizer" "Optimizes RAG template parameters" "Python / scikit-learn, pyGAM"
            evaluator = container "Evaluator" "LLM-as-a-Judge evaluation with JSON response parsing" "Python / unitxt"
        }

        s3 = softwareSystem "AWS S3-Compatible Storage" "Object storage for document corpora" "External"
        ogxService = softwareSystem "OGX Service" "Vector store and embedding generation service" "External"
        chromaService = softwareSystem "Chroma" "Open-source vector database" "External"

        consumerApp = softwareSystem "Consumer Application" "Application that imports ai4rag as a library dependency" "Internal"

        datascientist -> consumerApp "Uses application that embeds ai4rag"
        consumerApp -> ai4rag "Imports as Python library dependency"
        ai4rag -> s3 "Downloads document artifacts" "HTTPS/443, AWS IAM Auth"
        ai4rag -> ogxService "Stores vectors and generates embeddings" "API Client"
        ai4rag -> chromaService "Alternative vector storage" "API Client"

        s3downloader -> textextractor "Passes downloaded documents"
        textextractor -> chunker "Passes extracted text"
        chunker -> vectorstore "Stores text chunks"
        vectorstore -> optimizer "Provides embeddings for optimization"
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
            element "Internal" {
                background #7ed321
            }
            element "Person" {
                shape person
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
