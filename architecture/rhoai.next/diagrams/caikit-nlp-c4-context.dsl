workspace {
    model {
        dataScientist = person "Data Scientist" "Creates inference requests and trains prompt-tuned models"
        mlEngineer = person "ML Engineer" "Deploys and manages serving runtimes"

        caikitNlp = softwareSystem "caikit-nlp" "Python library providing NLP modules (text generation, embeddings, reranking, classification) for the caikit runtime" {
            textGenLocal = container "TextGeneration" "Local text generation and fine-tuning using HuggingFace transformers" "Python Module"
            textGenTGIS = container "TextGenerationTGIS" "Remote text generation via TGIS with streaming support" "Python Module"
            peftPromptTuning = container "PeftPromptTuning" "Prompt tuning and multi-task prompt tuning via PEFT on frozen base models" "Python Module"
            peftPromptTuningTGIS = container "PeftPromptTuningTGIS" "Remote inference of PEFT-tuned prompt vectors via TGIS" "Python Module"
            embeddingModule = container "EmbeddingModule" "Text embeddings, sentence similarity, bi-encoder reranking via sentence-transformers" "Python Module"
            crossEncoderModule = container "CrossEncoderModule" "Cross-encoder reranking via sentence-transformers CrossEncoder" "Python Module"
            sequenceClassification = container "SequenceClassification" "Text sequence classification via HuggingFace transformers" "Python Module"
            filteredSpanClassification = container "FilteredSpanClassification" "Span-level token classification with score filtering" "Python Module"
            regexSentenceSplitter = container "RegexSentenceSplitter" "Regex-based sentence tokenization" "Python Module"
            tgisAutoFinder = container "TGISAutoFinder" "Automatic discovery of models on remote TGIS servers" "Python Module"
        }

        caikitRuntime = softwareSystem "Caikit Runtime" "Hosts caikit-nlp modules, exposes HTTP (8080) and gRPC (8085) APIs" "Internal Platform"
        tgis = softwareSystem "TGIS" "Text Generation Inference Server for remote model inference" "Internal Platform"
        kserve = softwareSystem "KServe" "Serverless inference platform managing InferenceService CRs" "Internal Platform"
        rhodsOperator = softwareSystem "RHODS Operator" "Platform operator creating ServingRuntime CRs" "Internal Platform"

        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model and tokenizer download repository" "External"
        pytorch = softwareSystem "PyTorch" "Deep learning framework for inference and training" "External"
        sentenceTransformers = softwareSystem "sentence-transformers" "Sentence embedding and semantic search library" "External"

        # Relationships
        dataScientist -> caikitRuntime "Sends inference/training requests via" "HTTP/gRPC"
        mlEngineer -> rhodsOperator "Configures ServingRuntime CRs"

        caikitRuntime -> caikitNlp "Loads NLP modules via RUNTIME_LIBRARY=caikit_nlp" "Python import"
        caikitNlp -> tgis "Delegates remote inference to" "gRPC (configurable port, TLS/mTLS optional)"
        caikitNlp -> huggingfaceHub "Downloads models and tokenizers" "HTTPS/443"
        caikitNlp -> pytorch "Uses for inference and training" "Python import"
        caikitNlp -> sentenceTransformers "Uses for embeddings and reranking" "Python import"

        kserve -> caikitRuntime "Routes inference traffic to"
        rhodsOperator -> caikitRuntime "Creates and manages runtime containers"

        textGenTGIS -> tgis "gRPC inference" "gRPC"
        peftPromptTuningTGIS -> tgis "gRPC inference with prompt vectors" "gRPC"
        tgisAutoFinder -> tgis "Discovers available models" "gRPC"
        textGenLocal -> pytorch "Local inference" "Python"
        peftPromptTuning -> pytorch "Training with Accelerate" "Python"
        embeddingModule -> sentenceTransformers "Embeddings" "Python"
        crossEncoderModule -> sentenceTransformers "Cross-encoder scoring" "Python"
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
