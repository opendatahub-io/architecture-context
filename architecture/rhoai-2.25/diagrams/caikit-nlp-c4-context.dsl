workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for NLP tasks"
        mlEngineer = person "ML Engineer" "Integrates NLP capabilities into applications"

        caikitNlp = softwareSystem "caikit-nlp" "Python library providing NLP modules (text generation, embeddings, reranking, classification, tokenization) for the Caikit runtime" {
            textGenModules = container "Text Generation Modules" "TextGeneration (local), TextGenerationTGIS (remote)" "Python / PyTorch / HuggingFace Transformers"
            peftModules = container "PEFT Prompt Tuning Modules" "PeftPromptTuning (training), PeftPromptTuningTGIS (remote inference)" "Python / PEFT / Accelerate"
            embeddingModules = container "Embedding & Reranking Modules" "EmbeddingModule, CrossEncoderModule" "Python / sentence-transformers"
            classificationModules = container "Classification & Tokenization Modules" "SequenceClassification, FilteredSpanClassification, RegexSentenceSplitter" "Python"
            tgisAutoFinder = container "TGISAutoFinder" "Automatically discovers and configures TGIS backend connections" "Python"
            pretrainedModel = container "PretrainedModelBase" "Resource for loading and managing HuggingFace pretrained models" "Python / HuggingFace"
        }

        caikitRuntime = softwareSystem "Caikit Runtime" "Core AI framework providing gRPC/HTTP servers, model management, and module lifecycle" "Internal Platform"
        caikitTgisBackend = softwareSystem "caikit-tgis-backend" "Backend adapter for TGIS connection management and prompt artifact loading" "Internal Platform"
        tgis = softwareSystem "TGIS" "Text Generation Inference Server for remote model serving" "Internal Platform"
        kserve = softwareSystem "KServe / ModelMesh" "Model serving infrastructure providing container orchestration and routing" "Internal Platform"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model and tokenizer repository" "External"
        pytorchDistributed = softwareSystem "PyTorch Distributed" "Multi-GPU training coordination via elastic launch" "External"

        # User interactions
        dataScientist -> caikitNlp "Trains prompt tuning models via gRPC Training API"
        mlEngineer -> caikitNlp "Sends inference requests via gRPC/HTTP"

        # Internal interactions
        caikitRuntime -> caikitNlp "Loads and serves NLP modules" "Python API (in-process)"
        caikitNlp -> caikitTgisBackend "Manages TGIS connections and prompt vectors" "Python API (in-process)"
        textGenModules -> tgis "Remote text generation inference" "gRPC/8033"
        peftModules -> tgis "Remote prompt-tuned inference and vector loading" "gRPC/8033"
        tgisAutoFinder -> tgis "Probes for available TGIS connections" "gRPC/8033"
        pretrainedModel -> huggingfaceHub "Downloads models and tokenizers" "HTTPS/443"
        peftModules -> pytorchDistributed "Coordinates multi-GPU training" "TCP/29550"
        kserve -> caikitNlp "Deploys as model serving container" "Container lifecycle"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
