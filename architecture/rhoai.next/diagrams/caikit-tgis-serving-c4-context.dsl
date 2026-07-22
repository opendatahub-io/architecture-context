workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLM models via KServe InferenceService"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform, configures ServingRuntimes"
        developer = person "Developer" "Converts models to Caikit format using convert.py utility"

        caikitTgisServing = softwareSystem "Caikit-TGIS-Serving" "API translation layer that bridges Caikit NLP APIs to the TGIS inference backend for LLM serving" {
            caikitRuntime = container "Caikit Runtime" "Python application providing REST/gRPC API surface for model inference" "Python 3.11 / caikit 0.28.1" {
                httpHandler = component "HTTP Handler" "Serves /api/v1/task/* endpoints on port 8080" "caikit.runtime"
                grpcHandler = component "gRPC Handler" "Serves caikit.runtime.Nlp service on port 8085" "caikit.runtime"
                tgisConnector = component "TGIS Backend Connector" "Translates Caikit API calls to TGIS gRPC protocol" "caikit-tgis-backend 0.1.39"
                nlpModule = component "NLP Module" "Text generation task implementations" "caikit-nlp 0.5.14"
                healthProbe = component "Health Probe" "Readiness/liveness checks including TGIS backend verification" "caikit_health_probe"
                metricsExporter = component "Metrics Exporter" "Exposes runtime metrics on port 8086" "caikit.runtime"
            }
            convertTool = container "convert.py" "CLI utility to convert HuggingFace models to Caikit format" "Python Script"
        }

        tgis = softwareSystem "TGIS" "Text Generation Inference Server — loads model weights and executes LLM inference" "Co-located"
        kserve = softwareSystem "KServe" "Model serving platform that orchestrates ServingRuntime lifecycle, creates Knative services" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS, traffic management, PeerAuthentication enforcement" "External"
        knative = softwareSystem "Knative Serving" "Provides autoscaling, revision management, and traffic splitting" "External"
        modelStorage = softwareSystem "Model Storage" "S3/MinIO/PVC for model artifact storage" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model repository for downloading pre-trained models" "External"
        prometheus = softwareSystem "Prometheus" "User Workload Monitoring for metrics collection" "Internal RHOAI"
        rhodsOperator = softwareSystem "RHODS Operator" "Platform operator managing RHOAI component lifecycle" "Internal RHOAI"
        konflux = softwareSystem "Konflux CI" "Multi-arch container build system via Tekton PipelineRuns" "External"

        # Relationships
        dataScientist -> caikitTgisServing "Sends inference requests via HTTP/gRPC" "HTTPS/443 → HTTP/8080"
        platformAdmin -> kserve "Configures ServingRuntime CRs referencing caikit-tgis-serving image"
        developer -> convertTool "Runs model conversion" "CLI"

        caikitTgisServing -> tgis "Forwards inference requests" "gRPC/8033 (localhost, plaintext)"
        caikitTgisServing -> modelStorage "Reads model artifacts (via KServe storage initializer)" "S3/PVC"
        convertTool -> huggingface "Downloads models for conversion" "HTTPS/443"

        kserve -> caikitTgisServing "Deploys as transformer-container in ServingRuntime pod"
        istio -> caikitTgisServing "Provides mTLS sidecar injection and PeerAuthentication"
        knative -> caikitTgisServing "Manages autoscaling and traffic routing"
        prometheus -> caikitTgisServing "Scrapes metrics" "HTTP/8086 (PERMISSIVE)"
        rhodsOperator -> kserve "Manages KServe deployment and configuration"
        konflux -> caikitTgisServing "Builds multi-arch container image (x86_64, arm64)" "Tekton"

        # Internal component relationships
        httpHandler -> tgisConnector "Delegates inference"
        grpcHandler -> tgisConnector "Delegates inference"
        tgisConnector -> nlpModule "Uses NLP task implementations"
        healthProbe -> tgisConnector "Checks TGIS backend connectivity"
    }

    views {
        systemContext caikitTgisServing "SystemContext" {
            include *
            autoLayout
            description "System context showing caikit-tgis-serving in the RHOAI ecosystem"
        }

        container caikitTgisServing "Containers" {
            include *
            autoLayout
            description "Container view showing Caikit Runtime and convert.py utility"
        }

        component caikitRuntime "Components" {
            include *
            autoLayout
            description "Component view showing internal structure of the Caikit Runtime"
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
            element "Co-located" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
