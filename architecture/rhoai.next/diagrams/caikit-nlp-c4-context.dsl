workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, deploys, and queries ML models for NLP tasks"
        mlEngineer = person "ML Engineer" "Configures model serving infrastructure and training pipelines"

        caikitNlp = softwareSystem "Caikit-NLP" "NLP model-serving runtime providing text generation, embeddings, reranking, classification, and tokenization via Caikit framework" {
            grpcRuntime = container "gRPC Runtime Server" "Hosts Caikit modules and serves gRPC API for all NLP tasks" "Python / Caikit Runtime" "8085/TCP"
            restGateway = container "REST Gateway" "REST-to-gRPC proxy providing HTTP API access" "Python / Caikit HTTP Server" "8080/TCP"
            textGenModules = container "Text Generation Modules" "PeftPromptTuning, TextGeneration, PeftPromptTuningTGIS, TextGenerationTGIS" "Python / PEFT / Transformers"
            embeddingModules = container "Embedding & Reranking Modules" "EmbeddingModule, CrossEncoderModule using sentence-transformers" "Python / Sentence Transformers"
            classificationModules = container "Classification Modules" "SequenceClassification, FilteredSpanClassification" "Python / Transformers"
            tgisAutoFinder = container "TGISAutoFinder" "Automatic discovery of TGIS-connectable models via gRPC probing" "Python"
        }

        tgis = softwareSystem "TGIS" "Text Generation Inference Server for remote model inference with prompt caching" "Internal"
        kserve = softwareSystem "KServe / ModelMesh" "Model serving platform that deploys caikit-nlp as InferenceService containers" "Internal RHOAI"
        caikitRuntime = softwareSystem "Caikit Runtime" "Core AI framework providing module system, data models, and server infrastructure" "Library"
        caikitTgisBackend = softwareSystem "caikit-tgis-backend" "TGIS backend integration, connection management, prompt artifact loading" "Library"

        huggingfaceHub = softwareSystem "HuggingFace Hub" "Public model registry for downloading pre-trained NLP models" "External"
        pytorch = softwareSystem "PyTorch" "Deep learning framework for model training and local inference" "Library"
        konfluxCI = softwareSystem "Konflux CI" "Tekton pipeline that builds and pushes container images to quay.io" "External"

        # User interactions
        dataScientist -> caikitNlp "Sends inference requests (text generation, embeddings, reranking)" "HTTP/gRPC"
        mlEngineer -> kserve "Deploys InferenceService with caikit-nlp runtime" "kubectl"

        # Internal container relationships
        restGateway -> grpcRuntime "Proxies HTTP requests" "gRPC/8085 localhost"
        grpcRuntime -> textGenModules "Dispatches text generation tasks"
        grpcRuntime -> embeddingModules "Dispatches embedding/reranking tasks"
        grpcRuntime -> classificationModules "Dispatches classification tasks"
        tgisAutoFinder -> tgis "Probes for model availability" "gRPC"

        # External dependencies
        caikitNlp -> tgis "Remote text generation inference" "gRPC/configurable, Optional TLS/mTLS"
        caikitNlp -> huggingfaceHub "Downloads pre-trained models" "HTTPS/443, TLS 1.2+"
        caikitNlp -> caikitRuntime "Uses module system and server framework" "Library"
        caikitNlp -> caikitTgisBackend "Uses TGIS connection management" "Library"
        caikitNlp -> pytorch "Model training and local inference" "Library"

        # Platform dependencies
        kserve -> caikitNlp "Deploys as container in InferenceService"
        konfluxCI -> caikitNlp "Builds container image" "Tekton pipeline"
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
                background #438dd5
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Library" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
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
