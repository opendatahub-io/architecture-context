workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries ML models for NLP tasks"
        developer = person "Developer" "Integrates NLP capabilities into applications"

        caikitNlp = softwareSystem "caikit-nlp" "Python library providing NLP modules (text generation, embeddings, reranking, classification) for the Caikit AI runtime" {
            textGenModules = container "Text Generation Modules" "PeftPromptTuning, TextGeneration — local inference and training via PyTorch/Transformers" "Python / Caikit Module"
            tgisModules = container "TGIS Modules" "PeftPromptTuningTGIS, TextGenerationTGIS — remote inference via TGIS backend" "Python / Caikit Module"
            embeddingModules = container "Embedding Modules" "EmbeddingModule, CrossEncoderModule — embedding, similarity, reranking via sentence-transformers" "Python / Caikit Module"
            classificationModules = container "Classification Modules" "SequenceClassification, FilteredSpanClassification — text/token classification (WIP)" "Python / Caikit Module"
            modelManagement = container "Model Management" "TGISAutoFinder — automatic TGIS endpoint discovery and connection management" "Python"
        }

        caikitRuntime = softwareSystem "Caikit Runtime" "Core AI runtime framework that loads caikit-nlp and serves modules via HTTP/gRPC" "Internal Platform"
        tgis = softwareSystem "TGIS" "Text Generation Inference Server for remote model inference" "Internal Platform"
        caikitTgisBackend = softwareSystem "caikit-tgis-backend" "Backend abstraction for TGIS connections and gRPC error translation" "Internal Platform"
        hfHub = softwareSystem "HuggingFace Hub" "Model repository for downloading pre-trained models" "External"
        pytorch = softwareSystem "PyTorch / Transformers" "Deep learning framework and model architectures" "External"
        sentenceTransformers = softwareSystem "sentence-transformers" "Sentence embedding library" "External"

        datascientist -> caikitRuntime "Sends inference/training requests" "HTTP :8080 / gRPC :8085"
        developer -> caikitRuntime "Integrates via API" "HTTP :8080 / gRPC :8085"
        caikitRuntime -> caikitNlp "Loads as library" "Python import (RUNTIME_LIBRARY=caikit_nlp)"
        tgisModules -> tgis "Remote text generation" "gRPC (configurable TLS)"
        tgisModules -> caikitTgisBackend "Uses backend abstraction" "Python import"
        modelManagement -> tgis "Discovers endpoints" "gRPC"
        textGenModules -> pytorch "Local inference and training" "Python import"
        embeddingModules -> sentenceTransformers "Embedding computation" "Python import"
        caikitNlp -> hfHub "Downloads models (optional)" "HTTPS :443"
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
        }
    }
}
