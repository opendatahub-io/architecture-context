workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries NLP models for inference and training"
        developer = person "Application Developer" "Integrates NLP capabilities via REST/gRPC APIs"

        caikitNlp = softwareSystem "caikit-nlp" "Python NLP library providing text generation, embeddings, classification, reranking, and tokenization as a caikit runtime module" {
            textGenModules = container "Text Generation Modules" "TextGeneration (local) and TextGenerationTGIS (remote) with HuggingFace Transformers" "Python Module"
            peftModules = container "PEFT Prompt Tuning Modules" "PeftPromptTuning (local training) and PeftPromptTuningTGIS (remote inference)" "Python Module"
            embeddingModules = container "Embedding Modules" "EmbeddingModule (sentence-transformers) and CrossEncoderModule for embeddings, similarity, reranking" "Python Module"
            classificationModules = container "Classification Modules" "SequenceClassification and FilteredSpanClassification via HuggingFace" "Python Module"
            tgisClient = container "TGISGenerationClient" "gRPC client for communication with TGIS text generation backends" "Python gRPC Client"
            tgisFinder = container "TGISAutoFinder" "Automatic discovery and routing of models to local or TGIS remote backends" "Python Model Finder"
            resources = container "PretrainedModelBase" "Abstract base wrapping HuggingFace AutoModel classes (CausalLM, Seq2Seq, Classifier)" "Python Resource"
        }

        caikitFramework = softwareSystem "caikit Framework" "Core runtime providing gRPC/HTTP servers, module system, data models, model management" "Internal"
        caikitTgisBackend = softwareSystem "caikit-tgis-backend" "TGIS backend integration providing TGISBackend class and protobuf definitions" "Internal"
        tgis = softwareSystem "TGIS" "Text Generation Inference Server for GPU-accelerated remote model inference" "Internal"
        kserve = softwareSystem "KServe / ModelMesh" "Kubernetes model serving platform consuming caikit-nlp as a serving runtime image" "Internal Platform"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model repository for downloading pretrained model artifacts" "External"
        pytorch = softwareSystem "PyTorch" "Deep learning framework for tensor operations, model inference, distributed training" "External Library"
        sentenceTransformers = softwareSystem "sentence-transformers" "Library for sentence embeddings and cross-encoder models" "External Library"
        peft = softwareSystem "PEFT" "Parameter-efficient fine-tuning library (prompt tuning, multitask prompt tuning)" "External Library"

        # User relationships
        datascientist -> caikitNlp "Deploys models and invokes training via gRPC/HTTP"
        developer -> caikitNlp "Sends inference requests via REST/gRPC APIs"

        # Internal container relationships
        textGenModules -> resources "Loads models via"
        peftModules -> resources "Loads and fine-tunes models via"
        textGenModules -> tgisClient "Delegates remote inference (TGIS variants)"
        peftModules -> tgisClient "Delegates remote inference (TGIS variants)"
        tgisFinder -> textGenModules "Routes to local or TGIS module"
        tgisFinder -> peftModules "Routes to local or TGIS module"

        # External relationships
        caikitNlp -> caikitFramework "Loaded as runtime library by gRPC/HTTP servers"
        caikitNlp -> caikitTgisBackend "Uses for TGIS backend abstraction" "Python import"
        tgisClient -> tgis "Sends inference requests" "gRPC (configurable TLS/mTLS)"
        caikitNlp -> pytorch "Uses for tensor ops, model inference, distributed training" "Python import"
        embeddingModules -> sentenceTransformers "Loads embedding and cross-encoder models" "Python import"
        peftModules -> peft "Uses for prompt tuning configurations" "Python import"
        peftModules -> huggingfaceHub "Downloads base models" "HTTPS/443 TLS 1.2+"
        kserve -> caikitNlp "Runs as serving runtime container image" "HTTP/8080, gRPC/8085"
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
            element "External Library" {
                background #bbbbbb
                color #ffffff
                shape RoundedBox
            }
            element "Internal" {
                background #438dd5
                color #ffffff
            }
            element "Internal Platform" {
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
