workspace {
    model {
        user = person "Data Scientist / MLOps Engineer" "Creates ModelService CRs to deploy base models for inference"

        modelservice = softwareSystem "llm-d-model-service" "Kubernetes operator that declaratively provisions and maintains the resources needed to serve a base model for inference via the ModelService CRD (DEPRECATED)" {
            controller = container "modelservice-controller-manager" "Reconciles ModelService CRDs to provision the full inference serving stack" "Go Operator (kubebuilder)"
            generateCli = container "generate CLI" "Offline manifest generation from ModelService + BaseConfig YAML files" "Go CLI"
        }

        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for resource CRUD operations" "External"
        gatewayApi = softwareSystem "Gateway API" "Kubernetes Gateway API for traffic routing via HTTPRoute" "External"
        gatewayInferenceExt = softwareSystem "Gateway API Inference Extension" "Provides InferencePool and InferenceModel CRDs for inference request routing" "Internal Platform"
        epp = softwareSystem "EPP (Endpoint Picker)" "Inference pool endpoint selection component" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        user -> modelservice "Creates ModelService CR via kubectl / GitOps"
        modelservice -> k8sApi "CRUD for Deployments, Services, ConfigMaps, HTTPRoutes, InferencePools, etc." "HTTPS/6443 TLS 1.2+"
        modelservice -> gatewayApi "Creates and manages HTTPRoute resources" "HTTPS/6443 TLS 1.2+"
        modelservice -> gatewayInferenceExt "Creates InferencePool and InferenceModel resources" "HTTPS/6443 TLS 1.2+"
        modelservice -> epp "Deploys EPP pod and binds SA to EPP ClusterRole"
        prometheus -> modelservice "Scrapes /metrics endpoint" "HTTPS/8443 TLS"
    }

    views {
        systemContext modelservice "SystemContext" {
            include *
            autoLayout
        }

        container modelservice "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape person
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
