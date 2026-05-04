workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models, runs inference and training"
        application = person "Application" "Consumes NLP inference APIs for text generation, embeddings, reranking"

        caikitNlp = softwareSystem "caikit-nlp" "Python library providing NLP capabilities (text generation, embeddings, reranking, classification) via the caikit runtime" {
            textGenerationLocal = container "TextGeneration" "Local text generation using HuggingFace transformers" "Python Module"
            textGenerationTgis = container "TextGenerationTGIS" "Remote text generation via TGIS" "Python Module"
            peftPromptTuning = container "PeftPromptTuning" "Prompt tuning training via PEFT on frozen base models" "Python Module"
            peftPromptTuningTgis = container "PeftPromptTuningTGIS" "Remote inference of PEFT-tuned prompts via TGIS" "Python Module"
            embeddingModule = container "EmbeddingModule" "Text embeddings, similarity, bi-encoder reranking" "Python Module"
            crossEncoderModule = container "CrossEncoderModule" "Cross-encoder reranking" "Python Module"
            sequenceClassification = container "SequenceClassification" "Text classification" "Python Module"
            filteredSpanClassification = container "FilteredSpanClassification" "Span-level token classification" "Python Module"
            regexSentenceSplitter = container "RegexSentenceSplitter" "Regex-based tokenization" "Python Module"
            tgisAutoFinder = container "TGISAutoFinder" "Auto-discovery of TGIS-hosted models" "Python Module"
        }

        caikitRuntime = softwareSystem "caikit Runtime" "Hosts caikit-nlp modules and exposes HTTP/gRPC APIs" "Internal Platform"
        tgis = softwareSystem "TGIS" "Text Generation Inference Server for remote model serving" "Internal Platform"
        kserve = softwareSystem "KServe" "Manages InferenceService lifecycle, ingress, auth" "Internal Platform"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Pre-trained model weights and tokenizers" "External"
        pytorchDistributed = softwareSystem "PyTorch Distributed" "Multi-GPU training coordination via torchrun" "Internal Platform"

        # Relationships
        dataScientist -> caikitRuntime "Sends training and inference requests" "HTTP/8080, gRPC/8085"
        application -> caikitRuntime "Sends inference requests" "HTTP/8080, gRPC/8085"
        caikitRuntime -> caikitNlp "Loads and invokes NLP modules" "Python in-process"
        kserve -> caikitRuntime "Manages deployment, ingress, auth" "Kubernetes API"

        textGenerationTgis -> tgis "Remote text generation inference" "gRPC/8033 (configurable), TLS optional, mTLS optional"
        peftPromptTuningTgis -> tgis "Remote prompt tuning inference" "gRPC/8033 (configurable), TLS optional, mTLS optional"
        tgisAutoFinder -> tgis "Discovers available models" "gRPC/8033 (configurable)"
        textGenerationLocal -> huggingfaceHub "Downloads models (when allow_downloads=true)" "HTTPS/443, TLS 1.2+"
        embeddingModule -> huggingfaceHub "Downloads sentence-transformer models" "HTTPS/443, TLS 1.2+"
        peftPromptTuning -> pytorchDistributed "Multi-GPU training coordination" "TCP/29550"
    }

    views {
        systemContext caikitNlp "SystemContext" {
            include *
            autoLayout
        }

        container caikitNlp "Containers" {
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6ba3d6
                color #ffffff
            }
            element "Person" {
                background #f5a623
                color #ffffff
                shape person
            }
        }
    }
}
