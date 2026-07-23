workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models, runs evaluations, deploys guardrails"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform components via DSC"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Multi-controller operator managing AI fairness, evaluation, and guardrails services" {
            manager = container "Operator Manager" "Hosts 6 controllers: TAS, LMES, EvalHub, GORCH, NemoGuardrails, MODULE" "Go (controller-runtime)"
            lmesDriver = container "LMES Driver" "Init container coordinating LM evaluation jobs with lm-evaluation-harness" "Go CLI"

            tasController = component "TAS Controller" "Manages TrustyAIService CRs for AI fairness/explainability monitoring" "Go Controller" {
                tags "Controller"
            }
            lmesController = component "LMES Controller" "Manages LMEvalJob CRs for language model evaluation" "Go Controller" {
                tags "Controller"
            }
            evalHubController = component "EvalHub Controller" "Manages EvalHub CRs for multi-tenant evaluation hub" "Go Controller" {
                tags "Controller"
            }
            gorchController = component "GORCH Controller" "Manages GuardrailsOrchestrator CRs with KServe auto-discovery" "Go Controller" {
                tags "Controller"
            }
            nemoController = component "NemoGuardrails Controller" "Manages NemoGuardrails CRs with Istio EnvoyFilter integration" "Go Controller" {
                tags "Controller"
            }
            moduleController = component "MODULE Controller" "Reconciles cluster-scoped TrustyAI CR for DSC module lifecycle" "Go Controller" {
                tags "Controller"
            }
        }

        # Internal Platform Systems
        rhodsOperator = softwareSystem "RHOAI Platform Operator" "Manages platform component lifecycle via DSC" "Internal RHOAI" {
            tags "Internal"
        }
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal RHOAI" {
            tags "Internal"
        }
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "Internal RHOAI" {
            tags "Internal"
        }
        kueue = softwareSystem "Kueue" "Job queuing and resource management" "Internal RHOAI" {
            tags "Internal"
        }

        # External Infrastructure
        istio = softwareSystem "Istio / Service Mesh" "Traffic management, mTLS, EnvoyFilters" "External" {
            tags "External"
        }
        certManager = softwareSystem "cert-manager / service-serving-cert" "TLS certificate lifecycle management" "External" {
            tags "External"
        }
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Auth enforcement sidecar (TokenReview + SAR)" "External" {
            tags "External"
        }
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane" "External" {
            tags "External"
        }

        # External Services
        s3Storage = softwareSystem "S3-Compatible Storage" "Model artifacts and evaluation results" "External Service" {
            tags "ExternalService"
        }
        ociRegistry = softwareSystem "OCI Registry" "Container image and result storage" "External Service" {
            tags "ExternalService"
        }
        postgresql = softwareSystem "PostgreSQL" "Persistent storage for TAS and EvalHub" "External Service" {
            tags "ExternalService"
        }
        mlflow = softwareSystem "MLflow" "Experiment tracking for EvalHub" "External Service" {
            tags "ExternalService"
        }
        mcpGateway = softwareSystem "MCP Gateway (Kuadrant)" "Model Context Protocol gateway extension" "External" {
            tags "External"
        }

        # Relationships — Users
        dataScientist -> trustyaiOperator "Creates TrustyAIService, LMEvalJob, EvalHub, GuardrailsOrchestrator, NemoGuardrails CRs"
        platformAdmin -> rhodsOperator "Enables TrustyAI module via DSC"
        rhodsOperator -> trustyaiOperator "Creates TrustyAI CR (module registration)"

        # Relationships — Internal
        trustyaiOperator -> kserve "Patches InferenceServices (TAS logger), auto-discovers endpoints (GORCH)" "HTTPS/6443 (via k8s API)"
        trustyaiOperator -> prometheus "Creates ServiceMonitors for metrics scraping"
        trustyaiOperator -> kueue "Optional workload queuing for LMES jobs" "HTTPS/6443 (via k8s API)"
        trustyaiOperator -> k8sAPI "CR CRUD, leader election, pod exec, RBAC" "HTTPS/6443"
        trustyaiOperator -> istio "Creates DestinationRules, VirtualServices (TAS), EnvoyFilters (NemoGuardrails)"
        trustyaiOperator -> certManager "TLS certificate generation via service annotations"
        trustyaiOperator -> mcpGateway "Discovers MCPGatewayExtension resources (NemoGuardrails)" "HTTPS/6443 (via k8s API)"

        # Relationships — External Services
        trustyaiOperator -> s3Storage "LMES: download assets, upload results" "HTTPS/443"
        trustyaiOperator -> ociRegistry "LMES: upload results to OCI" "HTTPS/443"
        trustyaiOperator -> postgresql "TAS/EvalHub: persistent data storage" "TCP/5432"
        trustyaiOperator -> mlflow "EvalHub: experiment tracking" "HTTPS/443"

        # Relationships — Security
        trustyaiOperator -> kubeRbacProxy "Injects as sidecar in all user-facing deployments"
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
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Controller" {
                background #85bbf0
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "ExternalService" {
                background #f5a623
                color #ffffff
            }
        }
    }
}
