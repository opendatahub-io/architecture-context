workspace {
    model {
        // People
        dataScientist = person "Data Scientist" "Creates API keys and invokes model inference endpoints"
        platformAdmin = person "Platform Admin" "Configures model access policies, subscriptions, and external model registrations"

        // Primary System
        maas = softwareSystem "Models as a Service (MaaS)" "Comprehensive platform for managing AI/ML model endpoints with policy-based access control, rate limiting, subscription management, and API key lifecycle" {
            maasController = container "maas-controller" "Manages 6 CRDs for model endpoint lifecycle, access control, rate limiting; deploys maas-api via kustomize pipeline; creates Kuadrant/Istio/Gateway API resources" "Go Operator (controller-runtime)" "controller"
            maasApi = container "maas-api" "RESTful API for API key management (hash-based show-once), model discovery with access validation, subscription selection; Authorino callback target" "Go Service (Gin HTTP)" "api"
            payloadProcessing = container "payload-processing" "Envoy ext_proc filter: model name extraction, provider credential injection, API translation between formats" "Go Service (Envoy ext_proc gRPC)" "processor"
        }

        // External Dependencies
        kuadrant = softwareSystem "Kuadrant (RHCL)" "Policy engine providing AuthPolicy, TokenRateLimitPolicy, Authorino (AuthN/AuthZ), and Limitador (rate limiting)" "External"
        kserve = softwareSystem "KServe" "Model serving platform providing LLMInferenceService CRD for deploying and serving ML models" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for API key hash storage, search, and lifecycle management" "External"
        istio = softwareSystem "Istio (Service Mesh)" "Service mesh providing mTLS, ServiceEntry, DestinationRule, and EnvoyFilter for traffic management" "External"
        gatewayApi = softwareSystem "Gateway API (OpenShift)" "Ingress via Gateway and HTTPRoute resources with TLS termination" "External"
        openshift = softwareSystem "OpenShift Platform" "Kubernetes platform with RBAC, authentication, and container orchestration" "External"

        // Internal Platform Dependencies
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that manages MaaS component enablement via DSC component state" "Internal RHOAI"
        perses = softwareSystem "Perses (COO)" "Observability dashboards and datasources" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection via PodMonitor and ServiceMonitor" "Internal RHOAI"

        // External Services
        externalLLM = softwareSystem "External LLM Providers" "Third-party AI model providers (OpenAI, Anthropic, etc.)" "External Service"

        // Relationships - People
        dataScientist -> maas "Creates API keys, lists models, invokes inference" "HTTPS/443"
        platformAdmin -> maas "Configures MaaSAuthPolicy, MaaSSubscription, ExternalModel CRs" "kubectl / HTTPS"

        // Relationships - Internal
        maasController -> maasApi "Deploys via kustomize server-side apply" "K8s API"
        maasController -> payloadProcessing "Deploys via kustomize" "K8s API"

        // Relationships - External Dependencies
        maas -> kuadrant "Creates AuthPolicy and TokenRateLimitPolicy; Authorino callbacks for API key validation and subscription selection" "CRD CRUD + HTTP/8080"
        maas -> kserve "Watches LLMInferenceService for model readiness and endpoint status" "CRD Watch"
        maasApi -> postgresql "Stores and queries API key hashes (SHA-256, constant-time compare)" "TCP/5432"
        maas -> istio "Creates ServiceEntry, DestinationRule, EnvoyFilter for external model routing and ext_proc injection" "CRD CRUD"
        maas -> gatewayApi "Creates HTTPRoute per model endpoint; watches Gateway resource" "CRD CRUD"
        maas -> openshift "CRD operations, leader election, RBAC escalation checks, TokenReview, SAR" "HTTPS/6443"

        // Relationships - Internal Platform
        rhodsOperator -> maas "Enables MaaS as a DSC component" "CRD"
        maas -> perses "Creates observability dashboards and datasources" "CRD CRUD"
        prometheus -> maas "Scrapes metrics from maas-api (9090), maas-controller (8080), payload-processing (9005)" "HTTP"

        // Relationships - External Services
        maas -> externalLLM "Routes inference requests via ServiceEntry with credential injection" "HTTPS/443"
    }

    views {
        systemContext maas "SystemContext" {
            include *
            autoLayout
        }

        container maas "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "controller" {
                background #4a90e2
                color #ffffff
            }
            element "api" {
                background #7ed321
                color #ffffff
            }
            element "processor" {
                background #f5a623
                color #ffffff
            }
        }
    }
}
