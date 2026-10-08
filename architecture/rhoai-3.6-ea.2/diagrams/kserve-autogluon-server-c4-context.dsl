workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for tabular and time-series prediction"
        mlEngineer = person "ML Engineer" "Manages model serving infrastructure and serving runtimes"

        kserveAutogluon = softwareSystem "KServe AutoGluon Server" "AutoGluon TabularPredictor and TimeSeriesPredictor inference runtime for KServe" {
            autogluonServer = container "autogluonserver" "AutoGluon model server with auto-detection of Tabular/TimeSeries models" "Python / FastAPI / uvicorn" "Primary Deliverable"
            kservePythonSDK = container "KServe Python SDK" "Core model serving framework with REST v1/v2 and gRPC support" "Python / FastAPI / gRPC"
            kserveStorage = container "kserve-storage" "Model download from cloud storage backends" "Python"
            controllerManager = container "kserve-controller-manager" "Reconciles InferenceService, InferenceGraph, ServingRuntime, TrainedModel CRDs" "Go / controller-runtime" "Controller"
            llmisvcController = container "llmisvc Controller" "Manages LLMInferenceService with Gateway API, KEDA, LeaderWorkerSet" "Go / controller-runtime" "Controller"
            localmodelController = container "localmodel Controller" "Manages LocalModelCache for node-local model caching" "Go / controller-runtime" "Controller"
            localmodelnodeAgent = container "localmodelnode Agent" "Node-level agent managing model download jobs" "Go / controller-runtime" "Agent"
            router = container "Router" "InferenceGraph traffic routing (splitter, switch, ensemble)" "Go"
            webhookServer = container "Webhook Server" "Validates and mutates KServe CRDs via admission webhooks" "Go" "Webhook"
            kubeRbacProxy = container "kube-rbac-proxy" "TLS termination and Kubernetes authorization proxy for metrics" "Go Sidecar" "Sidecar"
        }

        # External Systems
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource reconciliation" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic management via VirtualServices" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling via ScaledObjects" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning and rotation" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute-based traffic routing" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"

        # Storage
        s3Storage = softwareSystem "S3/GCS/Azure Blob" "Cloud object storage for model artifacts" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model repository for pretrained models" "External"

        # Relationships - Users
        dataScientist -> kserveAutogluon "Creates InferenceService CRs to deploy AutoGluon models" "kubectl / API"
        mlEngineer -> kserveAutogluon "Manages ClusterServingRuntimes and platform configuration" "kubectl / API"

        # Relationships - Internal
        autogluonServer -> kservePythonSDK "Uses for REST/gRPC serving infrastructure"
        autogluonServer -> kserveStorage "Uses for model download from cloud storage"

        controllerManager -> k8sAPI "Reconciles CRDs, creates Deployments/Services" "HTTPS/6443"
        controllerManager -> istio "Creates VirtualServices for traffic routing" "HTTPS/6443"
        controllerManager -> knative "Creates Knative Services for serverless" "HTTPS/6443"
        controllerManager -> keda "Creates ScaledObjects for autoscaling" "HTTPS/6443"
        controllerManager -> webhookServer "Delegates admission validation" "HTTPS/443"

        llmisvcController -> k8sAPI "Manages LLMInferenceService resources" "HTTPS/6443"
        llmisvcController -> gatewayAPI "Creates HTTPRoutes" "HTTPS/6443"
        llmisvcController -> keda "Creates ScaledObjects" "HTTPS/6443"

        localmodelController -> k8sAPI "Manages PV/PVC for local model caching" "HTTPS/6443"
        localmodelnodeAgent -> k8sAPI "Creates download Jobs" "HTTPS/6443"

        kserveStorage -> s3Storage "Downloads model artifacts" "HTTPS/443"
        kserveStorage -> huggingfaceHub "Downloads models from Hub" "HTTPS/443"

        certManager -> webhookServer "Provisions TLS certificates"
        prometheus -> kubeRbacProxy "Scrapes metrics" "HTTPS/8443"
        kubeRbacProxy -> controllerManager "Proxies to metrics endpoint" "HTTP/8080 localhost"
    }

    views {
        systemContext kserveAutogluon "SystemContext" {
            include *
            autoLayout
        }

        container kserveAutogluon "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Primary Deliverable" {
                background #1168bd
                color #ffffff
            }
            element "Controller" {
                background #6295c4
                color #ffffff
            }
            element "Webhook" {
                background #f5a623
                color #ffffff
            }
            element "Sidecar" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape Person
            }
        }
    }
}
