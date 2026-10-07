workspace {
    model {
        modelOwner = person "Model Owner" "Creates ModelService CRs to deploy inference serving stacks for base models"
        platformOperator = person "Platform Operator" "Defines BaseConfig presets with default pod specs, images, and routing configuration"

        modelServiceOperator = softwareSystem "llm-d-model-service" "Kubernetes operator that declaratively provisions the full inference serving stack for a base model via ModelService CR" {
            controllerManager = container "modelservice-controller-manager" "Reconciles ModelService CRs, performs template interpolation and semantic merging, creates/manages child resources" "Go Operator (controller-runtime v0.20.4)"
            generateCLI = container "generate CLI" "Offline manifest generation from ModelService and BaseConfig YAML files" "Go CLI"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource CRUD and RBAC enforcement" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for HTTPRoute-based traffic routing" "External"
        gatewayInfExt = softwareSystem "Gateway API Inference Extension" "Extends Gateway API with InferencePool and InferenceModel resources for intelligent inference routing" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        modelOwner -> modelServiceOperator "Creates ModelService CR via kubectl" "HTTPS/6443"
        platformOperator -> modelServiceOperator "Creates BaseConfig ConfigMaps" "HTTPS/6443"
        modelServiceOperator -> k8sAPI "CRUD on Deployments, Services, ConfigMaps, RBAC resources" "HTTPS/6443"
        modelServiceOperator -> gatewayAPI "Creates/manages HTTPRoute resources" "HTTPS/6443"
        modelServiceOperator -> gatewayInfExt "Creates/manages InferencePool and InferenceModel resources" "HTTPS/6443"
        prometheus -> modelServiceOperator "Scrapes metrics" "HTTPS/8443"
    }

    views {
        systemContext modelServiceOperator "SystemContext" {
            include *
            autoLayout
        }

        container modelServiceOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
