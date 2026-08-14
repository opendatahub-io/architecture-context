workspace {
    model {
        platformAdmin = person "Platform Admin" "Configures and manages the RHOAI platform via DataScienceCluster and DSCInitialization CRs"
        dataScientist = person "Data Scientist" "Uses AI/ML components deployed and managed by the operator"

        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that orchestrates lifecycle of all OpenShift AI components" {
            dscController = container "DataScienceCluster Controller" "Manages top-level platform lifecycle, triggers component reconciliation" "Go controller-runtime"
            dsciController = container "DSCInitialization Controller" "Handles platform initialization and service controller setup" "Go controller-runtime"
            webhookServer = container "Webhook Server" "Validates and defaults DataScienceCluster, DSCInitialization, and HardwareProfile resources" "Go controller-runtime, port 9443"
            authController = container "Auth Service Controller" "Manages RBAC group policies, watches MaaS and Kuadrant namespaces" "Go controller-runtime"
            gatewayController = container "Gateway Service Controller" "Provisions Gateway API chain, kube-auth-proxy, Routes, conditional Istio integration" "Go controller-runtime"
            monitoringController = container "Monitoring Service Controller" "Deploys Prometheus proxies, collectors, and monitoring Routes" "Go controller-runtime"
            componentControllers = container "Component Controllers" "Per-component controllers for DSP, Kueue, ModelRegistry, Ray, Spark, Trainer, TrainingOperator, TrustyAI" "Go controller-runtime"
            cloudmanager = container "Cloud Manager" "Manages cloud-provider Kubernetes engine resources (AWS, Azure, CoreWeave)" "Go binary"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource operations and admission" "External"
        openshiftPlatform = softwareSystem "OpenShift Platform" "Provides Routes, OAuth, service-ca, image streams" "External"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management and mTLS (conditional)" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for ingress routing" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Manages Prometheus monitoring stack" "External"
        modelsAsAService = softwareSystem "Models-as-a-Service" "MaaS subsystem for model serving" "Internal RHOAI"
        kuadrant = softwareSystem "Kuadrant" "API management and rate limiting" "Internal RHOAI"
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving infrastructure" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model metadata and artifact registry" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queueing and quota management" "Internal RHOAI"
        ray = softwareSystem "Ray" "Distributed computing framework" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI explainability and fairness" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for OpenShift AI" "Internal RHOAI"

        platformAdmin -> rhodsOperator "Creates DataScienceCluster and DSCInitialization CRs" "kubectl / HTTPS"
        rhodsOperator -> kubernetesAPI "Manages cluster resources" "HTTPS/6443, ServiceAccount"
        kubernetesAPI -> rhodsOperator "Sends admission webhook requests" "HTTPS/9443, TLS service-ca"
        rhodsOperator -> openshiftPlatform "Creates Routes, reads APIServer TLS profile, manages OAuth" "HTTPS"
        rhodsOperator -> istio "Conditionally creates EnvoyFilter, DestinationRule" "Kubernetes API"
        rhodsOperator -> gatewayAPI "Provisions GatewayClass, Gateway, HTTPRoutes" "Kubernetes API"
        rhodsOperator -> prometheusOperator "Creates ServiceMonitors, PodMonitors, PrometheusRules" "Kubernetes API"
        rhodsOperator -> modelsAsAService "Watches namespace for reconciliation triggers" "Kubernetes Watch"
        rhodsOperator -> kuadrant "Watches namespace for reconciliation triggers" "Kubernetes Watch"
        rhodsOperator -> dataSciencePipelines "Deploys and manages component" "kustomize manifests"
        rhodsOperator -> kserve "Deploys and manages component" "kustomize manifests"
        rhodsOperator -> modelRegistry "Deploys and manages component" "kustomize manifests"
        rhodsOperator -> kueue "Deploys and manages component" "kustomize manifests"
        rhodsOperator -> ray "Deploys and manages component" "kustomize manifests"
        rhodsOperator -> trustyai "Deploys and manages component" "kustomize manifests"
        dashboard -> rhodsOperator "Reads platform state via CRs" "Kubernetes API"
        dataScientist -> dashboard "Accesses AI/ML platform" "HTTPS via Gateway"
    }

    views {
        systemContext rhodsOperator "SystemContext" {
            include *
            autoLayout
        }

        container rhodsOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
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
                background #438dd5
                color #ffffff
            }
        }
    }
}
