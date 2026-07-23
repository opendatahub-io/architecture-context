workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, trains, and deploys NLP models for inference"
        mlEngineer = person "ML Engineer" "Configures and manages model serving infrastructure"

        caikitNlp = softwareSystem "Caikit NLP" "Python library providing NLP capabilities (text generation, embeddings, reranking, classification) as a runtime extension for the Caikit AI framework" {
            textGenModules = container "Text Generation Modules" "PeftPromptTuning, TextGeneration (local PyTorch), TextGenerationTGIS (remote via gRPC)" "Python Module"
            embeddingModules = container "Embedding Modules" "EmbeddingModule (7 tasks), CrossEncoderModule (cross-attention reranking)" "Python Module"
            classificationModules = container "Classification Modules" "SequenceClassification, FilteredSpanClassification" "Python Module"
            tgisClient = container "TGISGenerationClient" "gRPC client with error mapping for remote TGIS inference" "Python gRPC Client"
            resources = container "Pretrained Model Resources" "HFAutoCausalLM, HFAutoSeq2SeqLM, HFAutoSeqClassifier wrappers" "Python Module"
            toolkit = container "Toolkit" "torch_run (distributed training), model_run_utils, verbalizer_utils" "Python Module"
        }

        caikitRuntime = softwareSystem "Caikit Runtime" "Serves caikit-nlp modules via HTTP (8080) and gRPC (8085) endpoints" "Internal RHOAI"
        tgis = softwareSystem "TGIS" "Text Generation Inference Server for remote model inference" "Internal RHOAI"
        kserve = softwareSystem "KServe / ModelMesh" "Platform operator that deploys and manages model serving instances" "Internal RHOAI"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Public model and tokenizer repository" "External"
        pytorch = softwareSystem "PyTorch" "Deep learning framework for model inference and training" "External"
        sentenceTransformers = softwareSystem "sentence-transformers" "Sentence embedding models for embedding, similarity, and reranking" "External"
        peft = softwareSystem "PEFT" "Parameter-Efficient Fine-Tuning library (prompt tuning)" "External"
        caikitFramework = softwareSystem "Caikit Framework" "Core AI framework providing runtime, module system, data models" "Internal RHOAI"
        caikitTgisBackend = softwareSystem "caikit-tgis-backend" "Backend connector for remote TGIS inference via gRPC" "Internal RHOAI"

        dataScientist -> caikitRuntime "Sends inference/training requests via" "HTTP/8080, gRPC/8085"
        mlEngineer -> kserve "Deploys InferenceService via" "kubectl"

        caikitRuntime -> caikitNlp "Loads and dispatches to modules" "Python import"
        caikitNlp -> tgis "Remote text generation" "gRPC, TLS optional mTLS"
        caikitNlp -> huggingfaceHub "Downloads models (when ALLOW_DOWNLOADS=1)" "HTTPS/443"
        caikitNlp -> pytorch "Model inference and training" "Python import"
        caikitNlp -> sentenceTransformers "Embedding and reranking models" "Python import"
        caikitNlp -> peft "Prompt tuning configuration" "Python import"
        caikitNlp -> caikitFramework "Module registration, data models, config" "Python import"
        caikitNlp -> caikitTgisBackend "TGIS connection management" "Python import"
        kserve -> caikitRuntime "Deploys and manages runtime instances" "Kubernetes API"
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
