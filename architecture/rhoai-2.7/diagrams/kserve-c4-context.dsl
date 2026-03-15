workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and deploys machine learning models for inference"

        kserve = softwareSystem "KServe" "Kubernetes Custom Resource Definition operator for serving ML models with serverless inference, autoscaling, and multi-framework support" {
            controller = container "KServe Controller Manager" "Reconciles InferenceService, ServingRuntime, InferenceGraph CRDs; creates Knative Services or Kubernetes Deployments; manages webhooks" "Go Operator" {
                reconciler = component "CRD Reconciler" "Watches and reconciles KServe CRDs"
                webhookServer = component "Webhook Server" "Validates and mutates InferenceService CRDs"
            }

            modelServer = container "Model Server Pods" "Runtime containers for serving ML models with different frameworks" "Python/Go" {
                storageInit = component "Storage Initializer" "Downloads models from S3/GCS/Azure before pod starts" "Python Init Container"
                sklearn = component "SKLearn Server" "Serves scikit-learn models via REST/gRPC" "Python"
                xgboost = component "XGBoost Server" "Serves XGBoost models via REST/gRPC" "Python"
                agent = component "Agent Sidecar" "Model pulling, logging, batching, lifecycle management" "Go"
                router = component "Router Sidecar" "Routes inference requests for InferenceGraph pipelines" "Go"
            }

            explainer = container "Explainer Pods" "Model interpretability and adversarial testing" "Python" {
                alibi = component "Alibi Explainer" "Model interpretability using Alibi library"
                art = component "ART Explainer" "Adversarial robustness testing using ART library"
            }
        }

        # External Dependencies
        knative = softwareSystem "Knative Serving" "Serverless deployment platform with scale-to-zero and request-based autoscaling" "External Dependency"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for advanced networking, traffic splitting, VirtualServices, and mTLS" "External Dependency"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate provisioning for webhook servers" "External Dependency"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform providing CRDs, webhooks, and controllers" "External Dependency"

        # Storage Backends
        s3 = softwareSystem "AWS S3" "Cloud object storage for ML model artifacts" "External Service"
        gcs = softwareSystem "Google Cloud Storage" "Cloud object storage for ML model artifacts" "External Service"
        azure = softwareSystem "Azure Blob Storage" "Cloud object storage for ML model artifacts" "External Service"

        # Internal ODH Dependencies
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata, versions, and lineage" "Internal ODH Component"
        serviceMesh = softwareSystem "Service Mesh (Istio)" "ODH service mesh configuration for traffic routing and canary deployments" "Internal ODH Component"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH Component"
        cloudEvents = softwareSystem "CloudEvents Broker" "Event broker for prediction request/response logs" "Internal ODH Component"

        # User Interactions
        user -> kserve "Creates InferenceService CRDs via kubectl/OpenShift Console"
        user -> modelServer "Sends inference requests via REST/gRPC" "HTTPS/443 → HTTP/8080"

        # External Dependencies
        kserve -> knative "Creates Knative Services for serverless model serving" "K8s API (HTTPS/6443)"
        kserve -> istio "Creates Istio VirtualServices for traffic routing, canary deployments, A/B testing" "K8s API (HTTPS/6443)"
        kserve -> certManager "Requests TLS certificates for webhook server" "K8s API (HTTPS/6443)"
        kserve -> kubernetes "Manages Deployments, Services, Secrets, ConfigMaps, HPA" "K8s API (HTTPS/6443)"

        # Storage Backends
        modelServer -> s3 "Downloads ML model artifacts during pod initialization" "HTTPS/443 (AWS IAM)"
        modelServer -> gcs "Downloads ML model artifacts during pod initialization" "HTTPS/443 (GCP Service Account)"
        modelServer -> azure "Downloads ML model artifacts during pod initialization" "HTTPS/443 (Azure Storage Key)"

        # Internal ODH Integration
        kserve -> modelRegistry "Queries model metadata, versions, and storage URIs" "HTTPS/443"
        kserve -> serviceMesh "Uses Istio VirtualServices for traffic management" "K8s API (HTTPS/6443)"
        modelServer -> prometheus "Exposes /metrics endpoint for scraping" "HTTP/8080"
        modelServer -> cloudEvents "Sends prediction request/response logs" "HTTP/80"

        # Ingress Flow
        knative -> modelServer "Routes serverless traffic via Knative Activator" "HTTP/8012 → HTTP/8080"
        istio -> modelServer "Routes traffic via Istio Gateway and VirtualService" "HTTPS/443 → HTTP/8080"
    }

    views {
        systemContext kserve "KServeSystemContext" {
            include *
            autoLayout
        }

        container kserve "KServeContainers" {
            include *
            autoLayout
        }

        component controller "KServeControllerComponents" {
            include *
            autoLayout
        }

        component modelServer "KServeModelServerComponents" {
            include *
            autoLayout
        }

        styles {
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #000000
            }
            element "Internal ODH Component" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
