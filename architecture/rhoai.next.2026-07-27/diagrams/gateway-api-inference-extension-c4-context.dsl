workspace {
    model {
        datascientist = person "Data Scientist" "Sends inference requests to deployed models"
        platformAdmin = person "Platform Admin" "Configures inference pools, routing, and scheduling policies"

        gatewayApiInferenceExtension = softwareSystem "Gateway API Inference Extension" "Intelligent request routing to model-serving inference pools with plugin-based scheduling, flow control, and priority-aware traffic management" {
            epp = container "Endpoint Picker (EPP)" "gRPC ExternalProcessor service that selects optimal backend endpoints using configurable scheduling profiles, plugins, and flow control policies" "Go gRPC Service"
            inferencePoolController = container "InferencePool Controller" "Reconciles InferencePool resources and maintains pod membership" "Go Controller"
            inferenceObjectiveController = container "InferenceObjective Controller" "Reconciles InferenceObjective resources for priority-based flow control" "Go Controller"
            inferenceModelRewriteController = container "InferenceModelRewrite Controller" "Reconciles InferenceModelRewrite resources for model name rewriting with weighted traffic distribution" "Go Controller"
            podController = container "Pod Controller" "Watches model-serving Pods and updates in-memory datastore" "Go Controller"
            configMapController = container "ConfigMap Controller" "Reconciles ConfigMap resources" "Go Controller"
            datastore = container "In-Memory Datastore" "Live backend state synchronized by controllers" "In-Memory"
        }

        gatewayApi = softwareSystem "Gateway API" "Kubernetes Gateway API (data-science-gateway) for ingress routing" "External"
        envoyProxy = softwareSystem "Envoy Proxy" "L7 proxy that calls EPP via ExtProc for endpoint selection" "External"
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for resource operations and watch events" "External"
        modelServingPods = softwareSystem "Model-Serving Pods" "Backend pods running ML inference workloads (e.g., vLLM, TGI)" "Internal Platform"

        # User interactions
        datascientist -> gatewayApi "Sends inference requests" "HTTPS/8443"
        platformAdmin -> k8sApi "Creates InferencePool, InferenceObjective, InferenceModelRewrite, EndpointPickerConfig CRs" "kubectl"

        # Gateway and Envoy flow
        gatewayApi -> envoyProxy "Routes via HTTPRoute to InferencePool backendRef"
        envoyProxy -> epp "gRPC ExtProc callout for endpoint selection" "gRPC, Optional TLS"
        epp -> envoyProxy "Returns selected podIP:port"
        envoyProxy -> modelServingPods "Forwards inference request to selected endpoint"

        # EPP internal
        epp -> datastore "Reads endpoint state for scheduling decisions"
        epp -> modelServingPods "Scrapes Prometheus metrics for utilization data" "HTTP"

        # Controller interactions
        inferencePoolController -> k8sApi "Watches InferencePool resources" "HTTPS/6443, TLS 1.2+"
        inferenceObjectiveController -> k8sApi "Watches InferenceObjective resources" "HTTPS/6443, TLS 1.2+"
        inferenceModelRewriteController -> k8sApi "Watches InferenceModelRewrite resources" "HTTPS/6443, TLS 1.2+"
        podController -> k8sApi "Watches Pod resources" "HTTPS/6443, TLS 1.2+"
        configMapController -> k8sApi "Watches ConfigMap resources" "HTTPS/6443, TLS 1.2+"

        # Datastore updates
        inferencePoolController -> datastore "Updates pool membership"
        podController -> datastore "Updates pod state"
        inferenceObjectiveController -> datastore "Updates priority levels"
        inferenceModelRewriteController -> datastore "Updates rewrite rules"
    }

    views {
        systemContext gatewayApiInferenceExtension "SystemContext" {
            include *
            autoLayout
        }

        container gatewayApiInferenceExtension "Containers" {
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
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #5b9bd5
                color #ffffff
            }
        }
    }
}
