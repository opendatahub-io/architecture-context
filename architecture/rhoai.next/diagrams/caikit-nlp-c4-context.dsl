workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, trains, and deploys NLP models for inference"
        mlEngineer = person "ML Engineer" "Configures and operates the NLP serving infrastructure"

        caikitNlp = softwareSystem "caikit-nlp" "Python NLP library providing text generation, embeddings, reranking, classification, and tokenization modules for the caikit runtime" {
            textGeneration = container "TextGeneration" "Local text generation using HuggingFace CausalLM/Seq2Seq models" "Caikit Module (Python)"
            textGenerationTGIS = container "TextGenerationTGIS" "Remote text generation delegating to TGIS backend over gRPC" "Caikit Module (Python)"
            embeddingModule = container "EmbeddingModule" "Bi-encoder embeddings, similarity, and reranking using sentence-transformers" "Caikit Module (Python)"
            crossEncoderModule = container "CrossEncoderModule" "Cross-encoder reranking and tokenization using sentence-transformers CrossEncoder" "Caikit Module (Python)"
            peftPromptTuning = container "PeftPromptTuning" "PEFT prompt tuning with local training and inference (multi-GPU via torchrun)" "Caikit Module (Python)"
            peftPromptTuningTGIS = container "PeftPromptTuningTGIS" "PEFT prompt tuning inference via remote TGIS backend" "Caikit Module (Python)"
            sequenceClassification = container "SequenceClassification" "Text classification using HuggingFace SequenceClassification models" "Caikit Module (Python)"
            filteredSpanClassification = container "FilteredSpanClassification" "Token classification by splitting text into spans" "Caikit Module (Python)"
            regexSentenceSplitter = container "RegexSentenceSplitter" "Sentence splitting using configurable regular expressions" "Caikit Module (Python)"
            tgisAutoFinder = container "TGISAutoFinder" "Automatic discovery of TGIS-compatible text generation models" "Model Finder (Python)"
        }

        caikitRuntime = softwareSystem "Caikit Runtime" "AI toolkit runtime server exposing NLP modules via gRPC/HTTP" "Internal Platform"
        tgisServer = softwareSystem "TGIS" "Text Generation Inference Server for high-performance remote model serving" "Internal Platform"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Model repository for downloading pretrained models and tokenizers" "External"

        caikitCore = softwareSystem "Caikit Core" "Core AI toolkit framework providing module system, data model, and runtime infrastructure" "Internal Platform"
        caikitTgisBackend = softwareSystem "caikit-tgis-backend" "TGIS backend integration managing model connections and gRPC communication" "Internal Platform"

        pytorch = softwareSystem "PyTorch" "Deep learning framework for model inference and distributed training" "External"
        transformers = softwareSystem "HuggingFace Transformers" "Transformer model library for NLP" "External"
        sentenceTransformers = softwareSystem "sentence-transformers" "Bi-encoder and cross-encoder models for embeddings and reranking" "External"
        peft = softwareSystem "PEFT" "Parameter-Efficient Fine-Tuning library" "External"

        # Relationships
        dataScientist -> caikitRuntime "Sends inference/training requests" "gRPC :8085 / HTTP :8080"
        mlEngineer -> caikitRuntime "Configures and deploys" "runtime_config.yaml"

        caikitRuntime -> caikitNlp "Loads as runtime library" "RUNTIME_LIBRARY=caikit_nlp"
        caikitNlp -> caikitCore "Extends module system" "Python import"
        caikitNlp -> caikitTgisBackend "Uses TGIS client" "Python import"

        textGenerationTGIS -> tgisServer "Remote inference" "gRPC :8033, Optional TLS/mTLS"
        peftPromptTuningTGIS -> tgisServer "Remote inference" "gRPC :8033, Optional TLS/mTLS"
        tgisAutoFinder -> tgisServer "Discovers models" "gRPC"

        textGeneration -> transformers "Loads models" "Python import"
        textGeneration -> pytorch "Runs inference" "Python import"
        embeddingModule -> sentenceTransformers "Loads models" "Python import"
        crossEncoderModule -> sentenceTransformers "Loads models" "Python import"
        peftPromptTuning -> peft "Fine-tunes models" "Python import"
        peftPromptTuning -> pytorch "Distributed training" "torchrun / elastic_launch"

        caikitNlp -> huggingFaceHub "Downloads models (optional)" "HTTPS :443, allow_downloads=true"
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
