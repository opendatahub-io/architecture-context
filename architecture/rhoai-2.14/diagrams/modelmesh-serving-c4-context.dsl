workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML models for inference"

        modelmesh = softwareSystem "ModelMesh Serving" "Kubernetes controller for managing ModelMesh, a general-purpose model serving management and routing layer" {
            controller = container "ModelMesh Controller" "Manages ModelMesh deployments and reconciles CRs" "Go Operator" {
                tags "Controller"
            }
            webhook = container "Webhook Server" "Validates ServingRuntime CRs" "Go Service" {
                tags "Controller"
            }
            modelMesh = container "ModelMesh Container" "Model serving orchestration layer with intelligent routing" "Java/gRPC" {
                tags "Runtime"
            }
            adapter = container "Runtime Adapter" "Adapter between ModelMesh and model server" "Go/gRPC" {
                tags "Runtime"
            }
            restProxy = container "REST Proxy" "KServe V2 REST to gRPC translation" "Go/HTTP" {
                tags "Runtime"
            }
            runtime = container "Model Server" "Actual model inference runtime (MLServer, Triton, etc.)" "Python/Go" {
                tags "Runtime"
            }
        }

        etcd = softwareSystem "etcd" "Distributed coordination and metadata storage" "External"
        s3 = softwareSystem "S3 Storage" "Model artifact storage (AWS S3, MinIO, etc.)" "External"
        k8s = softwareSystem "Kubernetes API" "Cluster orchestration and resource management" "External"

        istio = softwareSystem "Istio" "Service mesh for traffic management and security" "External"
        kserve = softwareSystem "KServe" "Provides CRD definitions for ServingRuntime and InferenceService" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "User interface for model serving management" "Internal ODH"
        odhOperator = softwareSystem "ODH Operator" "Manages ModelMesh Serving installation" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # User interactions
        user -> modelmesh "Creates Predictor and ServingRuntime CRs via kubectl"
        user -> odhDashboard "Manages model deployments via UI"

        # External client interactions
        externalClient = person "External Client" "Applications consuming model inference APIs"
        externalClient -> modelmesh "Sends inference requests" "HTTPS/443, gRPC/REST"

        # Controller interactions
        controller -> k8s "Watches CRs and manages resources" "HTTPS/6443"
        controller -> etcd "Stores model metadata and coordinates" "HTTP/2379"
        controller -> webhook "Validates ServingRuntime CRs" "HTTPS/9443"

        # Runtime interactions
        modelMesh -> etcd "Coordinates model placement and routing" "HTTP/2379"
        modelMesh -> adapter "Routes inference requests" "gRPC/8085"
        adapter -> runtime "Manages model server" "gRPC/8001"
        runtime -> s3 "Downloads model artifacts" "HTTPS/443"
        restProxy -> modelMesh "Translates REST to gRPC" "gRPC/8033"

        # External dependencies
        modelmesh -> istio "Uses for traffic routing" "Service Mesh"
        modelmesh -> kserve "Imports CRD definitions" "API"
        odhDashboard -> modelmesh "Provides UI for management" "Kubernetes API"
        odhOperator -> modelmesh "Manages installation and config" "Operator Pattern"
        prometheus -> modelmesh "Scrapes metrics" "HTTP/8443, HTTP/2112"

        # Trust boundaries
        deploymentEnvironment "Production" {
            deploymentNode "Kubernetes Cluster" {
                deploymentNode "Controller Namespace" {
                    containerInstance controller
                    containerInstance webhook
                }
                deploymentNode "User Namespace" {
                    deploymentNode "Runtime Pod" {
                        containerInstance modelMesh
                        containerInstance adapter
                        containerInstance restProxy
                        containerInstance runtime
                    }
                }
                deploymentNode "Infrastructure" {
                    softwareSystemInstance etcd
                }
            }
            deploymentNode "External Services" {
                softwareSystemInstance s3
            }
        }
    }

    views {
        systemContext modelmesh "SystemContext" {
            include *
            autoLayout
        }

        container modelmesh "Containers" {
            include *
            autoLayout
        }

        deployment modelmesh "Production" "Deployment" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "Runtime" {
                background #50e3c2
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
