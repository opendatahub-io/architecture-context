workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, trains, and deploys NLP models for inference"
        mlApp = person "ML Application" "Sends inference requests to deployed models"

        caikitNlp = softwareSystem "caikit-nlp" "Python library providing NLP capabilities (text generation, embeddings, reranking, classification) via the caikit framework" {
            textGenModules = container "Text Generation Modules" "TextGeneration, TextGenerationTGIS, PeftPromptTuning, PeftPromptTuningTGIS" "Python / caikit Module"
            embeddingModules = container "Embedding & Reranking Modules" "EmbeddingModule, CrossEncoderModule with thread-safe tokenization" "Python / sentence-transformers"
            classificationModules = container "Classification Modules" "SequenceClassification, FilteredSpanClassification" "Python / HuggingFace transformers"
            tokenizationModules = container "Tokenization Modules" "RegexSentenceSplitter" "Python / caikit Module"
            tgisAutoFinder = container "TGISAutoFinder" "Automatic discovery of models on remote TGIS servers" "Python / Model Finder"
        }

        caikitRuntime = softwareSystem "caikit Runtime" "Hosts caikit-nlp modules and exposes them as HTTP/gRPC services" {
            httpServer = container "HTTP Server" "Auto-generated REST endpoints from task methods" "Python / 8080/TCP"
            grpcServer = container "gRPC Server" "Auto-generated gRPC services from task methods" "Python / 8085/TCP"
            moduleLoader = container "Module Loader" "Discovers and loads caikit-nlp modules via RUNTIME_LIBRARY env" "Python"
        }

        tgis = softwareSystem "TGIS" "Text Generation Inference Server for remote model serving" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model and tokenizer repository" "External"
        platformOperator = softwareSystem "RHOAI Operator" "Manages ServingRuntime CRs and deploys caikit runtime pods" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Manages InferenceService lifecycle and routing" "Internal RHOAI"
        pytorchDistributed = softwareSystem "PyTorch Distributed" "Multi-GPU coordination for fine-tuning via torchrun" "External"

        # Relationships - Users
        dataScientist -> caikitRuntime "Sends training requests (prompt tuning)" "HTTP/gRPC"
        mlApp -> caikitRuntime "Sends inference requests (generation, embedding, rerank)" "HTTP/gRPC"

        # Relationships - Runtime to Library
        caikitRuntime -> caikitNlp "Loads and executes NLP modules" "Python in-process"

        # Relationships - Internal containers
        moduleLoader -> textGenModules "Discovers and loads"
        moduleLoader -> embeddingModules "Discovers and loads"
        moduleLoader -> classificationModules "Discovers and loads"
        moduleLoader -> tokenizationModules "Discovers and loads"
        httpServer -> moduleLoader "Routes requests to modules"
        grpcServer -> moduleLoader "Routes requests to modules"

        # Relationships - External
        textGenModules -> tgis "Remote inference via gRPC" "gRPC / TLS+mTLS (optional)"
        textGenModules -> huggingfaceHub "Downloads models (when allowed)" "HTTPS/443"
        embeddingModules -> huggingfaceHub "Downloads sentence-transformer models" "HTTPS/443"
        textGenModules -> pytorchDistributed "Multi-GPU training coordination" "TCP/29550"
        tgisAutoFinder -> tgis "Discovers available models" "gRPC"

        # Relationships - Platform
        platformOperator -> caikitRuntime "Deploys via ServingRuntime CR"
        kserve -> caikitRuntime "Routes traffic via InferenceService"
    }

    views {
        systemContext caikitNlp "SystemContext" {
            include *
            autoLayout
        }

        container caikitNlp "CaikitNlpContainers" {
            include *
            autoLayout
        }

        container caikitRuntime "CaikitRuntimeContainers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #4a90e2
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
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
