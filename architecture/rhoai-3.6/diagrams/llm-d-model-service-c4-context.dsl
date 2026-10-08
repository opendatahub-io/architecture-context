workspace {
    model {
        user = person "Platform Engineer / Data Scientist" "Creates ModelService CRs to deploy LLM inference stacks"
        cicd = person "CI/CD Pipeline" "Automates ModelService lifecycle"

        modelServiceOperator = softwareSystem "llm-d-model-service" "Kubernetes operator that declaratively provisions disaggregated prefill/decode inference stacks (DEPRECATED)" {
            controller = container "modelservice-controller-manager" "Reconciles ModelService CRs; provisions child resources" "Go Operator (controller-runtime v0.20.4)"
            runCmd = container "run subcommand" "Starts the controller-runtime manager" "Cobra CLI"
            generateCmd = container "generate subcommand" "Renders merged manifests to stdout for dry-run" "Cobra CLI"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute CRDs for traffic routing" "External"
        inferenceExtension = softwareSystem "Gateway API Inference Extension" "InferencePool and InferenceModel CRDs (v1alpha2)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # Relationships
        user -> modelServiceOperator "Creates ModelService CR via kubectl"
        cicd -> modelServiceOperator "Applies ModelService manifests"

        modelServiceOperator -> k8sAPI "CRUD on Deployments, Services, ConfigMaps, RBAC" "HTTPS/6443"
        modelServiceOperator -> gatewayAPI "Creates/updates HTTPRoute resources" "HTTPS/6443"
        modelServiceOperator -> inferenceExtension "Creates/updates InferencePool and InferenceModel" "HTTPS/6443"
        prometheus -> modelServiceOperator "Scrapes metrics" "HTTPS/8443"

        # Internal relationships
        runCmd -> controller "Starts"
        generateCmd -> controller "Shares BaseConfig merge logic"
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
