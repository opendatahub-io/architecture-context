workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys ML models for inference"
        developer = person "Developer" "Integrates ML models into applications"

        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform on Kubernetes" {
            controller = container "KServe Controller Manager" "Reconciles InferenceService lifecycle and orchestrates model deployments" "Go Operator" {
                reconciler = component "Reconciler" "Watches and reconciles InferenceService CRDs" "Go"
                deployer = component "Deployer" "Creates Knative Services, Istio resources, and Deployments" "Go"
            }

            webhook = container "Webhook Server" "Validates and mutates InferenceServices and injects sidecars" "Go Service" {
                validator = component "Validator" "Validates InferenceService specs" "Go"
                mutator = component "Mutator" "Injects storage-initializer and agent sidecars" "Go"
            }

            predictor = container "Predictor Pod" "Serves inference requests for deployed models" "Python/Go" {
                storageInit = component "storage-initializer" "Downloads model artifacts from cloud storage" "Python Init Container"
                agent = component "Agent Sidecar" "Handles batching, logging, health probing" "Go Sidecar"
                modelServer = component "Model Server" "Framework-specific inference server (MLServer, TorchServe, Triton)" "Python/C++"
            }

            router = container "InferenceGraph Router" "Routes requests through multi-step inference pipelines" "Go Service"
        }

        knative = softwareSystem "Knative Serving" "Serverless deployment platform with autoscaling and traffic splitting" "External Dependency"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management, mTLS, and telemetry" "External Dependency"
        keda = softwareSystem "KEDA" "Event-driven autoscaling with custom metrics" "External Dependency"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks and services" "External Dependency"

        dashboard = softwareSystem "ODH Dashboard" "RHOAI web UI for managing InferenceServices" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and versioning information" "Internal ODH"
        serviceMesh = softwareSystem "Service Mesh (RHOAI)" "RHOAI service mesh for secure inference endpoint exposure" "Internal ODH"

        s3 = softwareSystem "S3-Compatible Storage" "Model artifact storage (AWS S3, MinIO, etc.)" "External Service"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage on GCP" "External Service"
        azure = softwareSystem "Azure Blob Storage" "Model artifact storage on Azure" "External Service"

        kubernetes = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Observability"

        // User interactions
        datascientist -> kserve "Creates InferenceService via kubectl or SDK"
        developer -> predictor "Sends inference requests via HTTP/gRPC" "HTTPS/443, HTTP/80"

        // KServe internal interactions
        controller -> webhook "Validates and mutates resources"
        controller -> predictor "Creates and manages predictor pods"
        controller -> router "Creates router for InferenceGraphs"

        // KServe to external dependencies
        kserve -> knative "Creates Knative Services for serverless deployment" "Kubernetes API / HTTPS/6443"
        kserve -> istio "Creates VirtualServices and DestinationRules for traffic management" "Kubernetes API / HTTPS/6443"
        kserve -> keda "Creates ScaledObjects for event-driven autoscaling" "Kubernetes API / HTTPS/6443"
        webhook -> certManager "Uses TLS certificates for HTTPS endpoint" "Certificate mount"

        // KServe to internal ODH components
        dashboard -> kserve "Manages InferenceServices via Python SDK" "Kubernetes API / HTTPS/6443"
        kserve -> modelRegistry "References model metadata and storage URIs" "gRPC/9090"
        predictor -> serviceMesh "Secured by service mesh mTLS" "mTLS"

        // KServe to external services
        predictor -> s3 "Downloads model artifacts" "HTTPS/443, TLS 1.2+, AWS IAM"
        predictor -> gcs "Downloads model artifacts" "HTTPS/443, TLS 1.2+, GCP Service Account"
        predictor -> azure "Downloads model artifacts" "HTTPS/443, TLS 1.2+, Azure credentials"

        // Platform interactions
        kserve -> kubernetes "Watches resources and updates status" "HTTPS/6443, TLS 1.2+, Service Account Token"
        kserve -> prometheus "Exposes metrics for monitoring" "HTTP/8080, Prometheus scrape"

        deploymentEnvironment "Production" {
            deploymentNode "Kubernetes Cluster" {
                deploymentNode "kserve namespace" {
                    containerInstance controller
                    containerInstance webhook
                }

                deploymentNode "User namespaces" {
                    deploymentNode "Predictor Pods (autoscaled)" {
                        containerInstance predictor
                    }
                    deploymentNode "Router Pods (InferenceGraphs)" {
                        containerInstance router
                    }
                }

                deploymentNode "knative-serving namespace" {
                    softwareSystemInstance knative
                }

                deploymentNode "istio-system namespace" {
                    softwareSystemInstance istio
                }
            }

            deploymentNode "External Cloud" {
                softwareSystemInstance s3
                softwareSystemInstance gcs
                softwareSystemInstance azure
            }
        }
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

        component predictor "KServePredictorComponents" {
            include *
            autoLayout
        }

        deployment kserve "Production" "KServeDeployment" {
            include *
            autoLayout
        }

        styles {
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "External Service" {
                background #f5a623
                color #000000
            }
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Observability" {
                background #bd10e0
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
        }
    }
}
