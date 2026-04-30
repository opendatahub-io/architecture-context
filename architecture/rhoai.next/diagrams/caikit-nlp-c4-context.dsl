workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, trains, and deploys NLP models for inference"
        mlEngineer = person "ML Engineer" "Configures model serving and runtime settings"

        caikitNlp = softwareSystem "caikit-nlp" "NLP runtime module providing text generation, embeddings, reranking, classification, and tokenization for the Caikit AI framework" {
            textGeneration = container "TextGeneration Module" "Local text generation using HuggingFace CausalLM/Seq2SeqLM models" "Python / PyTorch"
            textGenerationTGIS = container "TextGenerationTGIS Module" "Remote text generation via TGIS backend with streaming" "Python / gRPC"
            peftPromptTuning = container "PeftPromptTuning Module" "PEFT-based prompt tuning with local training and multi-GPU support" "Python / PyTorch / PEFT"
            peftPromptTuningTGIS = container "PeftPromptTuningTGIS Module" "PEFT prompt tuning with remote TGIS inference and prompt caching" "Python / gRPC"
            embeddingModule = container "EmbeddingModule" "Text embeddings, similarity, reranking, tokenization using sentence-transformers" "Python / sentence-transformers"
            crossEncoderModule = container "CrossEncoderModule" "Cross-encoder reranking" "Python / sentence-transformers"
            sequenceClassification = container "SequenceClassification" "Text classification using HuggingFace models" "Python / transformers"
            filteredSpanClassification = container "FilteredSpanClassification" "Token-level span classification with bidirectional streaming" "Python / transformers"
            regexSentenceSplitter = container "RegexSentenceSplitter" "Regex-based sentence tokenization" "Python"
            tgisClient = container "TGISGenerationClient" "gRPC client wrapper for TGIS backend communication" "Python / gRPC"
        }

        caikitRuntime = softwareSystem "Caikit Runtime" "Core AI runtime framework providing gRPC and HTTP serving infrastructure" "Internal RHOAI"
        kserve = softwareSystem "KServe / ModelMesh" "Model serving orchestration platform" "Internal RHOAI"
        tgis = softwareSystem "TGIS" "Text Generation Inference Server for remote LLM inference" "Internal RHOAI"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model and tokenizer download repository" "External"
        pytorchDistributed = softwareSystem "PyTorch Distributed" "Multi-GPU distributed training coordination (torchrun/FSDP)" "External"

        # User interactions
        dataScientist -> caikitNlp "Sends inference requests (text generation, embeddings, classification)" "gRPC :8085 / HTTP :8080"
        mlEngineer -> kserve "Deploys and configures model serving" "kubectl / RHOAI Dashboard"

        # System interactions
        caikitRuntime -> caikitNlp "Loads as RUNTIME_LIBRARY" "Python in-process"
        kserve -> caikitRuntime "Deploys container (odh-caikit-nlp-rhel9)" "Container orchestration"

        # caikit-nlp egress
        textGenerationTGIS -> tgisClient "Delegates inference" "Python in-process"
        peftPromptTuningTGIS -> tgisClient "Delegates inference + prompt cache" "Python in-process"
        tgisClient -> tgis "Remote text generation, streaming, tokenization" "gRPC / Optional mTLS"
        textGeneration -> huggingfaceHub "Downloads models (when enabled)" "HTTPS :443"
        peftPromptTuning -> pytorchDistributed "Multi-GPU training coordination" "TCP :29550"
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
                background #4a90e2
                color #ffffff
                shape person
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}
