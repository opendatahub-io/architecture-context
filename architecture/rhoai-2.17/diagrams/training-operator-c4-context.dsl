workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Creates and manages distributed ML training jobs using PyTorch, TensorFlow, MPI, XGBoost, MXNet, or PaddlePaddle"

        # Software Systems
        trainingOperator = softwareSystem "Kubeflow Training Operator" "Kubernetes operator for distributed machine learning training jobs across multiple ML frameworks" {
            manager = container "Training Operator Manager" "Main controller process managing all training job lifecycle" "Go binary" {
                pytorchController = component "PyTorchJob Controller" "Manages PyTorch distributed training with elastic support"
                tfController = component "TFJob Controller" "Manages TensorFlow distributed training"
                mpiController = component "MPIJob Controller" "Manages MPI-based distributed training"
                xgboostController = component "XGBoostJob Controller" "Manages XGBoost distributed training"
                mxController = component "MXJob Controller" "Manages Apache MXNet distributed training"
                paddleController = component "PaddleJob Controller" "Manages PaddlePaddle distributed training"
                webhook = component "Webhook Server" "Validates and mutates training job CRDs" "HTTPS 9443/TCP"
                metrics = component "Metrics Server" "Exposes Prometheus metrics" "HTTP 8080/TCP"
                health = component "Health Probe Server" "Provides liveness and readiness probes" "HTTP 8081/TCP"
            }
        }

        # External Systems
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        controllerRuntime = softwareSystem "controller-runtime" "Kubernetes operator framework" "External Library"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling for coordinated pod scheduling" "External Optional"
        schedulerPlugins = softwareSystem "Scheduler-Plugins" "Alternative gang scheduling implementation" "External Optional"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning for webhooks" "External Optional"
        containerRegistry = softwareSystem "Container Registry" "Stores training job container images" "External"

        # Internal ODH Systems
        modelController = softwareSystem "ODH Model Controller" "Model serving controller consuming trained models" "Internal ODH"
        serviceMesh = softwareSystem "Service Mesh (Istio)" "Network policy and mTLS (disabled for operator)" "Internal ODH"

        # Relationships - User to System
        dataScientist -> trainingOperator "Creates PyTorchJob, TFJob, MPIJob, etc. via kubectl or Python SDK"
        dataScientist -> kubernetes "Submits training job CRDs via API"

        # Relationships - System Context
        trainingOperator -> kubernetes "Watches CRDs, creates Pods/Services/ConfigMaps" "HTTPS 443/TCP, ServiceAccount JWT"
        trainingOperator -> volcano "Creates PodGroups for gang scheduling" "HTTPS 443/TCP, ServiceAccount JWT (optional)"
        trainingOperator -> schedulerPlugins "Creates PodGroups for alternative gang scheduling" "HTTPS 443/TCP, ServiceAccount JWT (optional)"
        trainingOperator -> containerRegistry "Pulls training job container images" "HTTPS 443/TCP, Pull secrets"
        trainingOperator -> prometheus "Exposes operator metrics" "HTTP 8080/TCP"
        trainingOperator -> certManager "Obtains webhook TLS certificates" "Kubernetes API"

        kubernetes -> trainingOperator "Validates/mutates CRDs via webhook" "HTTPS 9443/TCP, mTLS"
        kubernetes -> trainingOperator "Health checks" "HTTP 8081/TCP"

        prometheus -> trainingOperator "Scrapes /metrics endpoint" "HTTP 8080/TCP"

        # Internal ODH Integration
        trainingOperator -> modelController "Training jobs produce models for serving" "Indirect via storage"
        trainingOperator -> serviceMesh "Network policy (sidecar disabled for operator)" "Configuration"

        # Container Level Relationships
        manager -> controllerRuntime "Built on operator framework"
        pytorchController -> kubernetes "Reconciles PyTorchJob CRDs"
        tfController -> kubernetes "Reconciles TFJob CRDs"
        mpiController -> kubernetes "Reconciles MPIJob CRDs"
        webhook -> kubernetes "Validates and mutates training job CRDs"
        metrics -> prometheus "Exposes Prometheus metrics"

        # Deployment
        deploymentEnvironment "Production" {
            deploymentNode "RHOAI 2.17" {
                deploymentNode "OpenShift/Kubernetes Cluster" {
                    deploymentNode "opendatahub namespace" {
                        operatorPod = containerInstance manager {
                            properties {
                                "Image" "quay.io/opendatahub/training-operator:v1-odh-c7d4e1b"
                                "User" "UID 65532 (non-root)"
                                "Istio Sidecar" "Disabled"
                            }
                        }
                    }

                    deploymentNode "User namespaces" {
                        trainingPods = infrastructureNode "Training Job Pods" "Distributed workers (master + workers)" "Kubernetes Pods"
                    }
                }
            }
        }
    }

    views {
        systemContext trainingOperator "SystemContext" {
            include *
            autoLayout
            description "System context diagram for Kubeflow Training Operator showing external dependencies and ODH integration"
        }

        container trainingOperator "Containers" {
            include *
            autoLayout
            description "Container diagram showing Training Operator internal components and controllers"
        }

        component manager "Components" {
            include *
            autoLayout
            description "Component diagram showing six framework controllers and supporting servers"
        }

        deployment trainingOperator "Production" "Deployment" {
            include *
            autoLayout
            description "Deployment view showing operator pod in opendatahub namespace and training jobs in user namespaces"
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #cccccc
                color #333333
            }
            element "External Library" {
                background #e0e0e0
                color #333333
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #2196f3
                color #ffffff
            }
            element "Component" {
                background #64b5f6
                color #ffffff
            }
            element "Infrastructure Node" {
                background #f5a623
                color #ffffff
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
