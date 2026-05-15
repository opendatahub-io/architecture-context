workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models for NLP tasks"
        mlEngineer = person "ML Engineer" "Fine-tunes models using prompt tuning"

        caikitNlp = softwareSystem "caikit-nlp" "Python NLP module library providing text generation, embedding, reranking, classification, and tokenization capabilities for the caikit runtime" {
            embeddingModule = container "EmbeddingModule" "Sentence embedding, similarity, and reranking using sentence-transformers" "Python / sentence-transformers"
            crossEncoderModule = container "CrossEncoderModule" "Cross-encoder based reranking and tokenization" "Python / sentence-transformers"
            textGeneration = container "TextGeneration" "Local text generation using HuggingFace CausalLM and Seq2SeqLM" "Python / transformers"
            textGenerationTGIS = container "TextGenerationTGIS" "Remote text generation via TGIS backend with streaming" "Python / gRPC"
            peftPromptTuning = container "PeftPromptTuning" "PEFT-based prompt tuning for text generation with local inference" "Python / PEFT + Accelerate"
            peftPromptTuningTGIS = container "PeftPromptTuningTGIS" "Remote PEFT prompt tuning inference via TGIS with prompt vector caching" "Python / gRPC"
            sequenceClassification = container "SequenceClassification" "Sequence classification using HuggingFace AutoModelForSequenceClassification" "Python / transformers"
            filteredSpanClassification = container "FilteredSpanClassification" "Token classification via span splitting and filtered classification" "Python / transformers"
            regexSentenceSplitter = container "RegexSentenceSplitter" "Regex-based sentence splitting / tokenization" "Python"
            tgisAutoFinder = container "TGISAutoFinder" "Automatic discovery of text generation models on remote TGIS servers" "Python / gRPC"
        }

        caikitRuntime = softwareSystem "caikit Runtime" "AI toolkit framework providing gRPC and HTTP serving infrastructure" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal RHOAI"
        tgis = softwareSystem "TGIS" "Text Generation Inference Server for remote model serving" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator managing component deployment" "Internal RHOAI"

        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model and tokenizer repository" "External"
        s3Storage = softwareSystem "S3 / Object Storage" "Model artifact storage" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server" "External"

        # User interactions
        dataScientist -> caikitRuntime "Sends inference requests (embedding, generation, classification)" "HTTP/8080, gRPC/8085"
        mlEngineer -> caikitRuntime "Submits training jobs (prompt tuning)" "gRPC/8085"

        # Runtime loads caikit-nlp
        caikitRuntime -> caikitNlp "Loads as runtime library" "RUNTIME_LIBRARY=caikit_nlp"

        # caikit-nlp module interactions
        textGenerationTGIS -> tgis "Remote text generation inference" "gRPC / TLS optional"
        peftPromptTuningTGIS -> tgis "Remote PEFT inference with prompt vectors" "gRPC / TLS optional"
        tgisAutoFinder -> tgis "Model discovery" "gRPC"
        embeddingModule -> huggingfaceHub "Model downloads (when allow_downloads=true)" "HTTPS/443"
        textGeneration -> s3Storage "Load model artifacts" "HTTPS/443"

        # Platform interactions
        kserve -> caikitRuntime "Deploys as InferenceService pod" "Kubernetes"
        rhodsOperator -> kserve "Manages KServe configuration" "Kubernetes API"
        kserve -> kubernetesAPI "Manages pods, services, routes" "HTTPS/6443"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
