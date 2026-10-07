workspace {
    model {
        user = person "Data Scientist" "Creates InferenceService resources to deploy and query LLM models"
        sre = person "SRE / Platform Admin" "Monitors serving infrastructure and configures runtimes"

        caikitTgisServing = softwareSystem "Caikit-TGIS-Serving" "Model serving stack combining Caikit AI toolkit with TGIS backend for LLM inference" {
            caikitRuntime = container "Caikit Runtime" "Provides gRPC and HTTP inference APIs, model management via TGIS-AUTO finder" "Python 3.11 (transformer-container)"
            tgis = container "TGIS" "Text Generation Inference Server — loads and runs LLM models on GPU" "Go/C++ (kserve-container)"
            convertUtil = container "convert.py" "CLI utility to convert HuggingFace models to Caikit format" "Python Script"
        }

        kserve = softwareSystem "KServe" "Orchestrates model serving lifecycle via ServingRuntime and InferenceService CRDs" "Internal RHOAI"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling and revision management for inference services" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "mTLS enforcement, traffic routing, and access control via Envoy sidecars" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection from openshift-user-workload-monitoring namespace" "Internal OpenShift"
        s3 = softwareSystem "S3-Compatible Storage" "Model artifact storage (e.g., MinIO, AWS S3)" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning for ingress gateways" "External"

        # Relationships
        user -> caikitTgisServing "Sends inference requests via gRPC/HTTP" "HTTPS/443"
        user -> convertUtil "Converts models" "CLI"
        sre -> prometheus "Monitors metrics" "HTTP"

        caikitRuntime -> tgis "Forwards inference to backend" "gRPC/8033 (localhost)"
        tgis -> s3 "Downloads model artifacts" "S3 API/9000 or 443"
        caikitRuntime -> prometheus "Exposes metrics" "HTTP/8086 PERMISSIVE"

        kserve -> caikitTgisServing "Creates and manages serving pods via ServingRuntime CRDs"
        caikitTgisServing -> knative "Uses for autoscaling and traffic management" "HTTP/HTTPS"
        caikitTgisServing -> istio "Traffic routed through Envoy sidecar" "mTLS STRICT"
        istio -> certManager "Provisions TLS certificates" "HTTPS"
    }

    views {
        systemContext caikitTgisServing "SystemContext" {
            include *
            autoLayout
        }

        container caikitTgisServing "Containers" {
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
            element "Internal OpenShift" {
                background #50a0e2
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
