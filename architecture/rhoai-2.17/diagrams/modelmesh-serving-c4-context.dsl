workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        developer = person "Application Developer" "Integrates ML inference into applications"
        admin = person "Platform Admin" "Manages ModelMesh infrastructure and runtime configurations"

        modelMesh = softwareSystem "ModelMesh Serving" "Kubernetes operator for multi-model serving with intelligent model placement and routing" {
            controller = container "modelmesh-controller" "Reconciles CRDs and manages ModelMesh deployments" "Go Operator" {
                reconciler = component "Reconciler" "Watches InferenceService, Predictor, ServingRuntime CRDs" "controller-runtime"
                deployer = component "Deployment Manager" "Creates and updates ModelMesh runtime deployments" "Go"
            }

            webhook = container "Webhook Server" "Validates ServingRuntime resources on CREATE/UPDATE" "Go Validating Webhook" {
                validator = component "Validation Handler" "Validates ServingRuntime/ClusterServingRuntime specs" "Go HTTP handler"
            }

            runtimePod = container "ModelMesh Runtime Pod" "Multi-container pod for model inference" "Kubernetes Pod" {
                modelMeshRouter = component "ModelMesh Router" "Routes inference requests to loaded models" "Java"
                runtimeAdapter = component "Runtime Adapter" "Adapts ModelMesh protocol to model server native protocols" "Go"
                restProxy = component "REST Proxy" "Translates KServe V2 REST API to gRPC" "Go"
                modelServer = component "Model Server" "Executes model inference (Triton/MLServer/OVMS/TorchServe)" "Python/C++"
                storageHelper = component "Storage Helper" "Downloads model artifacts from S3" "Go Init Container"
            }

            controller -> webhook "Validates resources via"
            controller -> runtimePod "Creates and manages"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Orchestrates containers and manages cluster state" "Kubernetes"
        etcd = softwareSystem "etcd" "Distributed key-value store for ModelMesh cluster coordination" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for model artifacts (AWS S3, MinIO, IBM COS)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "OpenShift Monitoring"

        kserve = softwareSystem "KServe" "Provides CRD schema definitions (InferenceService, ServingRuntime)" "Internal ODH"
        serviceMesh = softwareSystem "Istio/Service Mesh" "Optional mTLS, traffic management, and authorization" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science workloads" "Internal ODH"
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration (Kubeflow Pipelines)" "Internal ODH"

        %% User interactions
        dataScientist -> modelMesh "Creates InferenceService/Predictor via kubectl"
        admin -> modelMesh "Configures ServingRuntimes and ClusterServingRuntimes"
        developer -> modelMesh "Sends inference requests" "gRPC/REST"

        %% Core dependencies
        modelMesh -> kubernetesAPI "Watches and reconciles CRDs, creates resources" "HTTPS/6443"
        modelMesh -> etcd "Synchronizes model placement and cluster state" "HTTP/2379"
        modelMesh -> s3Storage "Downloads model artifacts" "HTTPS/443"
        modelMesh -> prometheus "Exposes metrics" "HTTPS/8443, HTTP/2112"

        %% Internal ODH dependencies
        modelMesh -> kserve "Uses CRD API definitions"
        modelMesh -> serviceMesh "Optional: mTLS encryption and AuthorizationPolicy" "Envoy sidecar"
        odhDashboard -> modelMesh "Provides UI for model deployment"
        dataSciencePipelines -> modelMesh "Auto-deploys models from pipelines"

        %% Webhook validation flow
        kubernetesAPI -> modelMesh "Validates ServingRuntime resources" "HTTPS/9443"

        deploymentViewPerspective = deploymentEnvironment "Production" {
            deploymentNode "OpenShift Cluster" {
                deploymentNode "redhat-ods-applications namespace" {
                    controllerNode = infrastructureNode "Controller Deployment" {
                        containerInstance controller
                        containerInstance webhook
                    }
                    etcdNode = infrastructureNode "etcd StatefulSet" {
                        softwareSystemInstance etcd
                    }
                }

                deploymentNode "{user-namespace}" {
                    runtimeNode = infrastructureNode "Runtime Deployment" {
                        containerInstance runtimePod 2
                    }
                }
            }

            deploymentNode "AWS Cloud" {
                s3Node = infrastructureNode "S3 Bucket" {
                    softwareSystemInstance s3Storage
                }
            }
        }
    }

    views {
        systemContext modelMesh "SystemContext" {
            include *
            autoLayout
        }

        container modelMesh "Containers" {
            include *
            autoLayout
        }

        component controller "ControllerComponents" {
            include *
            autoLayout
        }

        component runtimePod "RuntimePodComponents" {
            include *
            autoLayout
        }

        deployment modelMesh "Production" "Deployment" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape person
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
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Infrastructure Node" {
                shape RoundedBox
                background #ffffff
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
