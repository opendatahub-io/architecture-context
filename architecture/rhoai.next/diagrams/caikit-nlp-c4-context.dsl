workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, trains, and deploys NLP models for inference"
        mlEngineer = person "ML Engineer" "Configures model serving infrastructure and runtime"

        caikitNlp = softwareSystem "Caikit-NLP" "Python library providing NLP capabilities (text generation, embeddings, reranking, classification, tokenization) as runtime modules for the Caikit AI framework" {
            textGenLocal = container "TextGeneration (Local)" "Local text generation using HuggingFace CausalLM/Seq2SeqLM models" "Python / PyTorch"
            textGenTGIS = container "TextGenerationTGIS (Remote)" "Remote text generation via TGIS gRPC backend with streaming" "Python / gRPC"
            peftLocal = container "PeftPromptTuning" "PEFT-based prompt tuning with local training and inference, multi-GPU support" "Python / PyTorch / PEFT"
            peftTGIS = container "PeftPromptTuningTGIS" "PEFT prompt tuning with remote TGIS inference and prompt caching" "Python / gRPC"
            embeddingModule = container "EmbeddingModule" "Text embedding, similarity, reranking, and tokenization using sentence-transformers" "Python / sentence-transformers"
            crossEncoder = container "CrossEncoderModule" "Cross-encoder reranking" "Python / sentence-transformers"
            seqClassification = container "SequenceClassification" "Text classification using HuggingFace models" "Python / Transformers"
            spanClassification = container "FilteredSpanClassification" "Token-level span classification with bidi streaming" "Python / Transformers"
            regexSplitter = container "RegexSentenceSplitter" "Regex-based sentence tokenization" "Python"
            tgisClient = container "TGISGenerationClient" "gRPC client for TGIS backend communication (unary, streaming, tokenization)" "Python / gRPC"
        }

        caikitRuntime = softwareSystem "Caikit Runtime" "Core AI runtime framework hosting NLP modules for gRPC and HTTP serving" "Internal RHOAI"
        tgisBackend = softwareSystem "TGIS" "Text Generation Inference Server for remote model inference" "Internal RHOAI"
        kserve = softwareSystem "KServe / ModelMesh" "Container orchestration for deploying inference servers" "Internal RHOAI"
        hfHub = softwareSystem "HuggingFace Hub" "Model and tokenizer repository" "External"
        pyTorchDistributed = softwareSystem "PyTorch Distributed" "Multi-GPU distributed training coordination" "External"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar for RHOAI model serving" "Internal RHOAI"

        # User interactions
        dataScientist -> caikitRuntime "Sends inference requests via gRPC/HTTP" "gRPC/8085, HTTP/8080"
        mlEngineer -> kserve "Deploys and manages model serving" "Kubernetes API"

        # Runtime hosting
        caikitRuntime -> caikitNlp "Loads as RUNTIME_LIBRARY=caikit_nlp" "in-process"

        # Internal flows
        textGenTGIS -> tgisClient "Delegates inference" "in-process"
        peftTGIS -> tgisClient "Delegates inference" "in-process"
        tgisClient -> tgisBackend "Remote generation, streaming, tokenization" "gRPC / Optional mTLS"

        # External dependencies
        caikitNlp -> hfHub "Downloads models and tokenizers (when enabled)" "HTTPS/443"
        peftLocal -> pyTorchDistributed "Multi-GPU training coordination" "TCP/29550"

        # Platform integration
        kserve -> caikitRuntime "Deploys and manages runtime containers"
        kubeRbacProxy -> caikitRuntime "Enforces authentication" "Sidecar proxy"
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
