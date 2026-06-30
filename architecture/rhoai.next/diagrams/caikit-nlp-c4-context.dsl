workspace {
    model {
        dataScientist = person "Data Scientist" "Creates inference requests and fine-tunes models via prompt tuning"
        mlEngineer = person "ML Engineer" "Deploys and configures Caikit runtime with caikit-nlp library"

        caikitNlp = softwareSystem "Caikit-NLP" "Python NLP module library providing text generation, embedding, reranking, classification, and tokenization for the Caikit runtime" {
            embeddingModule = container "EmbeddingModule" "Text embedding, sentence similarity, and semantic reranking using sentence-transformers" "Python / PyTorch"
            crossEncoderModule = container "CrossEncoderModule" "Cross-encoder based reranking and tokenization" "Python / PyTorch"
            textGeneration = container "TextGeneration" "Local text generation using HuggingFace CausalLM and Seq2Seq models" "Python / PyTorch"
            textGenerationTGIS = container "TextGenerationTGIS" "Remote text generation via TGIS backend over gRPC" "Python / gRPC"
            peftPromptTuning = container "PeftPromptTuning" "PEFT-based prompt tuning for text generation fine-tuning" "Python / PyTorch / Accelerate"
            peftPromptTuningTGIS = container "PeftPromptTuningTGIS" "Remote inference of PEFT-tuned models via TGIS" "Python / gRPC"
            sequenceClassification = container "SequenceClassification" "Text classification using AutoModelForSequenceClassification" "Python / PyTorch"
            tgisAutoFinder = container "TGISAutoFinder" "Auto-discovery of text generation models on remote TGIS servers" "Python / gRPC"
            pretrainedModelBase = container "PretrainedModelBase" "Abstract base for HuggingFace pretrained model loading" "Python"
        }

        caikitRuntime = softwareSystem "Caikit Runtime" "Core AI framework providing gRPC/HTTP serving, module registry, and data model" "Internal RHOAI"
        tgis = softwareSystem "TGIS" "Text Generation Inference Server for remote model inference" "Internal RHOAI"
        caikitTgisBackend = softwareSystem "caikit-tgis-backend" "Backend integration library for TGIS connections and model management" "Internal RHOAI"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Public model repository for downloading pretrained models" "External"
        localModelStorage = softwareSystem "Local Model Storage" "Filesystem storage for pretrained and fine-tuned model artifacts" "External"
        pytorchCuda = softwareSystem "PyTorch CUDA / IPEX" "GPU acceleration runtime for inference and training" "External"

        # Relationships
        dataScientist -> caikitRuntime "Sends inference/training requests" "HTTP/8080, gRPC/8085"
        mlEngineer -> caikitRuntime "Configures and deploys" "RUNTIME_LIBRARY=caikit_nlp"

        caikitRuntime -> caikitNlp "Loads as runtime library and dispatches task requests" "In-process Python"

        textGenerationTGIS -> tgis "Remote text generation inference" "gRPC/8033 (TLS optional, mTLS configurable)"
        peftPromptTuningTGIS -> tgis "Remote PEFT model inference" "gRPC/8033 (TLS optional)"
        tgisAutoFinder -> tgis "Discovers available models" "gRPC/8033"

        caikitNlp -> caikitTgisBackend "Uses TGISBackend for connection management" "In-process Python"
        pretrainedModelBase -> huggingfaceHub "Downloads pretrained models (disabled by default)" "HTTPS/443"
        pretrainedModelBase -> localModelStorage "Loads model weights and configurations" "Filesystem"
        peftPromptTuning -> localModelStorage "Saves fine-tuned prompt vectors and training metadata" "Filesystem"

        embeddingModule -> pytorchCuda "GPU-accelerated embedding inference" "In-process"
        peftPromptTuning -> pytorchCuda "GPU-accelerated training with mixed precision" "In-process"
        textGeneration -> pytorchCuda "GPU-accelerated text generation" "In-process"
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
