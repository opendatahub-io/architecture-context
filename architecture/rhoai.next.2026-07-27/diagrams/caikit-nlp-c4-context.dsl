workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Sends inference requests for text generation, token classification, and tokenization"

        caikitNlp = softwareSystem "caikit-nlp" "Caikit NLP module library providing text generation, token classification, and tokenization capabilities via gRPC and REST" {
            textGeneration = container "TextGeneration Module" "Local inference using HuggingFace Transformers models" "Python / PyTorch"
            textGenerationTGIS = container "TextGenerationTGIS Module" "Remote inference delegating to TGIS backend via gRPC" "Python / gRPC"
            filteredSpanClassification = container "FilteredSpanClassification Module" "Token classification via filtered span approach" "Python"
            regexSentenceSplitter = container "RegexSentenceSplitter Module" "Tokenization via regex-based sentence splitting" "Python"
            tgisClient = container "TGISGenerationClient" "gRPC client wrapper for communicating with TGIS server" "Python / gRPC"
            pretrainedModelBase = container "PretrainedModelBase" "Abstract base for loading and managing pretrained models" "Python"
        }

        caikitRuntime = softwareSystem "Caikit Runtime" "AI runtime framework that hosts caikit-nlp modules and exposes gRPC/REST endpoints" "Internal Platform"
        tgisServer = softwareSystem "TGIS (Text Generation Inference Server)" "Remote text generation inference backend" "External"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Model repository for downloading pretrained model artifacts" "External"
        k8sPlatform = softwareSystem "OpenShift / Kubernetes Platform" "Container orchestration and service mesh infrastructure" "External"

        user -> caikitRuntime "Sends inference requests" "gRPC/8085, HTTP/8080"
        caikitRuntime -> caikitNlp "Dispatches task requests to registered modules" "Python API"
        textGenerationTGIS -> tgisClient "Delegates generation requests"
        tgisClient -> tgisServer "Sends inference requests" "gRPC, TLS/mTLS configurable"
        textGeneration -> pretrainedModelBase "Loads models"
        pretrainedModelBase -> huggingFaceHub "Downloads model artifacts" "HTTPS/443"
        caikitRuntime -> k8sPlatform "Deployed on" "Pod/Service"
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
