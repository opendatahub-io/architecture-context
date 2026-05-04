workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLM inference services"
        mlEngineer = person "ML Engineer" "Converts models and configures serving runtimes"

        caikitTgiServing = softwareSystem "Caikit-TGIS-Serving" "Container image providing LLM inference by combining Caikit AI toolkit runtime with TGIS backend" {
            caikitRuntime = container "Caikit Runtime" "Provides HTTP/gRPC inference APIs, model management, and health probes. Translates requests to TGIS backend calls." "Python (caikit 0.28.1)" "transformer-container"
            tgisBackend = container "TGIS Backend" "GPU-accelerated text generation inference server. Loads model weights and performs inference." "Text Generation Inference Server" "kserve-container"
            convertUtility = container "convert.py" "Converts HuggingFace models to Caikit format" "Python CLI"
        }

        kserve = softwareSystem "KServe" "Orchestrates model serving lifecycle, networking, and storage access via ServingRuntime and InferenceService CRDs" "Internal RHOAI"
        knative = softwareSystem "Knative Serving" "Provides serverless autoscaling, revision management, and traffic routing" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS, traffic management, ingress gateway, and authorization policies" "Internal RHOAI"
        openshiftServiceMesh = softwareSystem "OpenShift Service Mesh (Maistra)" "Manages Istio control plane on OpenShift" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "User Workload Monitoring for metrics collection" "Internal OpenShift"
        authorino = softwareSystem "Authorino" "Token-based authorization for inference endpoints (optional)" "Internal RHOAI"

        s3Storage = softwareSystem "S3-compatible Storage" "Model artifact storage (AWS S3 / MinIO)" "External"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Public model weight repository (dev only)" "External"

        # User interactions
        dataScientist -> caikitTgiServing "Sends inference requests (HTTP/gRPC)" "HTTPS/443"
        mlEngineer -> convertUtility "Converts HuggingFace models to Caikit format" "CLI"
        mlEngineer -> kserve "Creates InferenceService / ServingRuntime CRs" "kubectl"

        # Internal container communication
        caikitRuntime -> tgisBackend "Delegates inference" "gRPC/8033 (localhost)"

        # Platform dependencies
        caikitTgiServing -> kserve "Consumed as ServingRuntime container image" "CRD"
        caikitTgiServing -> knative "Serverless scaling and routing" "Platform"
        caikitTgiServing -> istio "mTLS, ingress, authorization" "Sidecar"
        istio -> openshiftServiceMesh "Managed by" "Control plane"
        prometheus -> caikitTgiServing "Scrapes runtime metrics" "HTTP/8086 PERMISSIVE"
        authorino -> caikitTgiServing "Token authorization (optional)" "Policy"

        # External service dependencies
        tgisBackend -> s3Storage "Downloads model artifacts" "HTTPS/443"
        tgisBackend -> huggingFaceHub "Downloads model weights (dev only)" "HTTPS/443"
    }

    views {
        systemContext caikitTgiServing "SystemContext" {
            include *
            autoLayout
            description "System context showing caikit-tgis-serving in the RHOAI platform ecosystem"
        }

        container caikitTgiServing "Containers" {
            include *
            autoLayout
            description "Container view showing Caikit runtime and TGIS backend in multi-container pod"
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
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
            }
        }
    }
}
