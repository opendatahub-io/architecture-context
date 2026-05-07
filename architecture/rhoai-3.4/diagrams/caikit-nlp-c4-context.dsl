workspace {
    model {
        datascientist = person "Data Scientist" "Sends inference requests and fine-tuning jobs for NLP models"
        mlEngineer = person "ML Engineer" "Deploys and configures model serving infrastructure"

        caikitNlp = softwareSystem "Caikit-NLP" "Python NLP runtime library providing text generation, embeddings, reranking, classification, and tokenization via the Caikit framework" {
            textGenModules = container "Text Generation Modules" "PeftPromptTuning, PeftPromptTuningTGIS, TextGeneration, TextGenerationTGIS" "Python"
            embeddingModules = container "Embedding Modules" "EmbeddingModule (sentence-transformers), CrossEncoderModule (cross-encoder)" "Python"
            classificationModules = container "Classification Modules" "SequenceClassification, FilteredSpanClassification" "Python"
            tokenizationModules = container "Tokenization Modules" "RegexSentenceSplitter" "Python"
            resources = container "Pretrained Model Resources" "HFAutoCausalLM, HFAutoSeq2SeqLM, HFAutoSequenceClassifier" "Python"
            modelManagement = container "Model Management" "TGISAutoFinder - detects local vs remote serving" "Python"
            toolkit = container "Toolkit" "tgis_utils, model_run_utils, torch_run, trainer_utils, verbalizer_utils" "Python"
        }

        caikitRuntime = softwareSystem "Caikit Runtime" "Core serving framework providing gRPC (8085) and HTTP (8080) servers" "Internal"
        caikitTgisBackend = softwareSystem "caikit-tgis-backend" "TGIS backend client library and protobuf definitions" "Internal"

        tgis = softwareSystem "TGIS" "Text Generation Inference Server for optimized text generation" "Internal"
        kserve = softwareSystem "KServe / ModelMesh" "Model serving platform managing pod deployment, routing, and ingress" "Internal RHOAI"
        hfHub = softwareSystem "HuggingFace Hub" "Public model and tokenizer repository" "External"
        pytorch = softwareSystem "PyTorch" "Deep learning framework for model inference and training" "External"

        # User interactions
        datascientist -> caikitNlp "Sends inference requests (text generation, embedding, reranking)" "HTTP/8080, gRPC/8085"
        mlEngineer -> kserve "Deploys and configures model serving" "kubectl / Dashboard"

        # Internal library relationships
        textGenModules -> resources "Loads pretrained models" "In-process"
        textGenModules -> toolkit "Uses tgis_utils, model_run_utils" "In-process"
        embeddingModules -> toolkit "Uses model_run_utils" "In-process"
        modelManagement -> textGenModules "Routes to local or TGIS modules" "In-process"

        # Platform integrations
        caikitRuntime -> caikitNlp "Discovers and serves registered modules" "In-process library"
        caikitNlp -> caikitTgisBackend "Uses TGIS client and protobuf definitions" "In-process library"
        caikitNlp -> tgis "Remote text generation inference" "gRPC (configurable port), optional TLS/mTLS"
        caikitNlp -> hfHub "Downloads models and tokenizers" "HTTPS/443, TLS 1.2+"
        caikitNlp -> pytorch "Model inference and training" "In-process"
        kserve -> caikitRuntime "Deploys as serving container" "Kubernetes"
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
            element "Internal" {
                background #4a90e2
                color #ffffff
            }
            element "Internal RHOAI" {
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
