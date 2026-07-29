workspace {
    model {
        user = person "Data Scientist / Admin" "Creates and manages TrustyAI, EvalHub, LMEvalJob, Guardrails resources"

        trustyaiOperator = softwareSystem "trustyai-service-operator" "Multi-service Kubernetes operator managing AI trustworthiness, evaluation, and guardrails infrastructure" {
            manager = container "Manager" "Primary operator binary with flag-driven controller sets (--enable-services)" "Go Operator (controller-runtime)"
            driver = container "Driver" "FIPS-enabled binary for LMEval operations (GOEXPERIMENT=strictfipsruntime)" "Go Executable"
            webhookServer = container "Webhook Server" "CRD conversion and validation webhooks (conditional)" "Go Service / 9443/TCP"

            trustyaiController = container "TrustyAI Controller" "Reconciles cluster-scoped TrustyAI CR" "Go Controller"
            trustyaiServiceController = container "TrustyAIService Controller" "Creates Deployments with kube-rbac-proxy, Routes, ServiceMonitors" "Go Controller"
            evalHubController = container "EvalHub Controller" "Manages evaluation hub lifecycle, RBAC, and MCP service" "Go Controller"
            lmEvalJobController = container "LMEvalJob Controller" "Creates driver pods for LM evaluation jobs" "Go Controller"
            gorchController = container "GuardrailsOrchestrator Controller" "Reconciles guardrails with KServe integration" "Go Controller"
            nemoController = container "NemoGuardrails Controller" "Manages NemoGuardrails with Gateway API and Istio" "Go Controller"
            jobController = container "Job Controller" "Reconciles batch Job resources" "Go Controller"
            workloadController = container "Workload Controller" "Reconciles Kueue Workload resources" "Go Controller"
        }

        kserve = softwareSystem "KServe" "Model serving platform providing InferenceService and ServingRuntime" "Internal Platform"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster resource management and RBAC enforcement" "Infrastructure"
        prometheusOperator = softwareSystem "prometheus-operator" "Monitoring infrastructure (ServiceMonitor CRDs)" "Internal Platform"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes networking (Gateway, HTTPRoute)" "Internal Platform"
        kueue = softwareSystem "Kueue" "Workload scheduling and queuing" "Internal Platform"
        mlflow = softwareSystem "MLflow" "ML experiment tracking" "Internal Platform"
        openshiftServiceCA = softwareSystem "OpenShift service-ca" "TLS certificate provisioning for webhooks" "Infrastructure"
        openshiftRoutes = softwareSystem "OpenShift Routes" "External ingress via HTTPS routes" "Infrastructure"
        istio = softwareSystem "Istio" "Service mesh (DestinationRules, VirtualServices, EnvoyFilters)" "Internal Platform"

        # User interactions
        user -> trustyaiOperator "Creates CRs via kubectl/API" "HTTPS/6443"
        user -> openshiftRoutes "Accesses TrustyAI/EvalHub services" "HTTPS/443"

        # Operator dependencies
        trustyaiOperator -> kubernetesAPI "CRUD resources, watch CRDs, leader election" "HTTPS/6443 TLS 1.2+"
        trustyaiOperator -> kserve "Watches InferenceService/ServingRuntime state" "Kubernetes API"
        trustyaiOperator -> prometheusOperator "Creates ServiceMonitor resources" "Kubernetes API"
        trustyaiOperator -> gatewayAPI "Manages Gateway/HTTPRoute for NemoGuardrails" "Kubernetes API"
        trustyaiOperator -> kueue "Watches/patches Workload for EvalHub scheduling" "Kubernetes API"
        trustyaiOperator -> mlflow "CRUD Experiments for EvalHub" "Kubernetes API"
        trustyaiOperator -> openshiftServiceCA "Provisions webhook-server-cert" "Automatic"
        trustyaiOperator -> openshiftRoutes "Creates Routes for service access" "Kubernetes API"
        trustyaiOperator -> istio "Creates DestinationRules, VirtualServices, EnvoyFilters" "Kubernetes API"

        # Route to operator services
        openshiftRoutes -> trustyaiOperator "Forwards to kube-rbac-proxy" "HTTPS/8443"

        # Internal container relationships
        manager -> trustyaiController "Starts"
        manager -> trustyaiServiceController "Starts"
        manager -> evalHubController "Starts (if EVALHUB enabled)"
        manager -> lmEvalJobController "Starts"
        manager -> gorchController "Starts"
        manager -> nemoController "Starts"
        manager -> jobController "Starts (if EVALHUB enabled)"
        manager -> workloadController "Starts (if EVALHUB enabled)"
        manager -> webhookServer "Starts conditionally"
        lmEvalJobController -> driver "Creates pods running driver binary"
    }

    views {
        systemContext trustyaiOperator "SystemContext" {
            include *
            autoLayout
        }

        container trustyaiOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
