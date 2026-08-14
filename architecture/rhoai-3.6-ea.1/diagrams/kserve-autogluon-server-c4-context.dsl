workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        mlEngineer = person "ML Engineer" "Manages serving runtimes and model deployments"

        kserveAutogluon = softwareSystem "KServe AutoGluon Server" "Downstream fork of KServe providing the AutoGluon model serving runtime, KServe controller-manager operator, Python SDK, and 14 ClusterServingRuntime definitions for RHOAI" {
            controllerManager = container "KServe Controller Manager" "Reconciles InferenceService, InferenceGraph, TrainedModel, and LocalModel CRDs; manages Deployments, Services, and networking resources" "Go Operator (controller-runtime)"
            llmisvcController = container "LLMInferenceService Controller" "Reconciles LLMInferenceService CRDs; manages Gateway API HTTPRoutes, InferencePools, LeaderWorkerSets, KEDA ScaledObjects" "Go Operator (controller-runtime)"
            localModelController = container "LocalModel Controller" "Manages model pre-caching to node-local storage via PVs and Jobs" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates and defaults KServe CRDs via mutating and validating admission webhooks" "Go Webhook Server"
            autogluonServer = container "AutoGluon Model Server" "Serves AutoGluon TabularPredictor and TimeSeriesPredictor models via V2 Inference Protocol (REST + gRPC)" "Python FastAPI/uvicorn"
            kserveSDK = container "KServe Python SDK" "Model server framework with V2 Inference Protocol support" "Python Library"
            kubeRBACProxy = container "kube-rbac-proxy" "TLS termination and Kubernetes token authentication for metrics endpoint" "Go Sidecar"
            inferenceRouter = container "Inference Router" "Traffic splitting, canary routing, A/B testing for inference requests" "Go HTTP Server"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Cluster resource management and RBAC enforcement" "Platform"
        istio = softwareSystem "Istio" "Service mesh for traffic management and mTLS" "Platform"
        knativeServing = softwareSystem "Knative Serving" "Serverless autoscaling platform" "Platform"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for advanced traffic routing" "Platform"
        keda = softwareSystem "KEDA" "Kubernetes Event Driven Autoscaler" "Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Platform"

        s3 = softwareSystem "S3 Storage" "AWS S3 model artifact storage" "External"
        gcs = softwareSystem "Google Cloud Storage" "GCP model artifact storage" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Azure model artifact storage" "External"

        # User interactions
        dataScientist -> kserveAutogluon "Creates InferenceService/LLMInferenceService via kubectl; submits inference requests"
        mlEngineer -> kserveAutogluon "Manages ClusterServingRuntimes and model deployments"

        # Internal container relationships
        autogluonServer -> kserveSDK "Uses for model serving framework"
        controllerManager -> webhookServer "Hosts webhook endpoints"
        kubeRBACProxy -> controllerManager "Forwards authenticated metrics requests" "HTTP/8080 localhost"

        # External interactions
        controllerManager -> k8sAPI "Reconciles CRDs, creates Deployments/Services/Ingress" "HTTPS/6443"
        llmisvcController -> k8sAPI "Manages LLMInferenceService resources" "HTTPS/6443"
        llmisvcController -> gatewayAPI "Creates HTTPRoutes, InferencePools" "HTTPS/6443"
        llmisvcController -> keda "Creates ScaledObjects for autoscaling" "HTTPS/6443"
        localModelController -> k8sAPI "Manages PVs, PVCs, Jobs for model caching" "HTTPS/6443"
        controllerManager -> istio "Creates VirtualServices for traffic routing"
        controllerManager -> knativeServing "Creates Knative Services for serverless scaling"
        autogluonServer -> s3 "Downloads model artifacts" "HTTPS/443"
        autogluonServer -> gcs "Downloads model artifacts" "HTTPS/443"
        autogluonServer -> azureBlob "Downloads model artifacts" "HTTPS/443"
        prometheus -> kubeRBACProxy "Scrapes metrics" "HTTPS/8443"
        k8sAPI -> webhookServer "Sends admission reviews" "HTTPS/443"
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
            element "Platform" {
                background #999999
                color #ffffff
            }
            element "External" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
