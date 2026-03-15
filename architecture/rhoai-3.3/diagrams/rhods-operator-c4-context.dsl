workspace {
    model {
        platformAdmin = person "Platform Administrator" "Manages RHOAI/ODH platform deployment and configuration"

        rhodsOperator = softwareSystem "RHODS Operator" "Central control plane for Red Hat OpenShift AI that manages data science component lifecycle" {
            controllerManager = container "Controller Manager" "Reconciles DataScienceCluster and DSCInitialization resources" "Go Operator (Kubebuilder v4)" {
                dscController = component "DataScienceCluster Controller" "Manages component lifecycle" "Go Controller"
                dsciController = component "DSCInitialization Controller" "Manages platform initialization" "Go Controller"
                componentControllers = component "Component Controllers" "15+ component-specific reconcilers" "Go Controllers"
                serviceControllers = component "Service Controllers" "Infrastructure service reconcilers" "Go Controllers"
            }

            webhookServer = container "Webhook Server" "Validates and defaults DSC/DSCI resources" "Go Admission Controller" {
                validators = component "Validators" "ValidatingWebhooks for DSC/DSCI/Auth/Monitoring"
                mutators = component "Mutators" "MutatingWebhooks for defaulting"
            }

            metricsService = container "Metrics Service" "Exposes Prometheus metrics with auth proxy" "HTTP Service"
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform (1.24+)" "External"
        openshift = softwareSystem "OpenShift" "Enterprise Kubernetes distribution (4.12+)" "External"
        certManager = softwareSystem "Cert Manager / Service CA" "TLS certificate provisioning for webhooks" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring infrastructure" "External"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for model serving (2.4+)" "External"
        serverless = softwareSystem "OpenShift Serverless" "Knative for KServe serverless mode (1.30+)" "External"

        # Internal ODH/RHOAI Components (managed by operator)
        dashboard = softwareSystem "ODH Dashboard" "Web UI for data science workflows" "Internal ODH"
        kserve = softwareSystem "KServe Operator" "Model serving infrastructure" "Internal ODH"
        pipelines = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry Operator" "Model versioning and metadata" "Internal ODH"
        notebookController = softwareSystem "Notebook Controller" "Jupyter notebook lifecycle management" "Internal ODH"
        rayOperator = softwareSystem "Ray Operator" "Distributed computing" "Internal ODH"
        trainingOperator = softwareSystem "Training Operator" "Distributed training jobs (Kubeflow Training)" "Internal ODH"
        monitoringStack = softwareSystem "Monitoring Stack" "Prometheus, AlertManager, Grafana" "Internal ODH"

        # External Services
        containerRegistry = softwareSystem "Container Registries" "Component image storage" "External Service"

        # Relationships - User interactions
        platformAdmin -> rhodsOperator "Creates/manages DataScienceCluster and DSCInitialization via kubectl/oc"

        # Relationships - RHODS Operator to Kubernetes
        rhodsOperator -> kubernetes "Manages CRDs, watches resources, creates/updates deployments via REST API" "HTTPS/6443, TLS 1.2+, ServiceAccount token"
        rhodsOperator -> openshift "Authenticates users, creates Routes, manages OAuth clients" "HTTPS/6443, OAuth API"
        kubernetes -> webhookServer "Validates and mutates DSC/DSCI resources" "HTTPS/9443, mTLS"

        # Relationships - Certificate management
        webhookServer -> certManager "Obtains TLS certificates for webhook endpoints" "Certificate request"

        # Relationships - Component deployment
        rhodsOperator -> dashboard "Deploys and manages via Dashboard CR" "Kubernetes API"
        rhodsOperator -> kserve "Deploys and manages via KServe CR" "Kubernetes API"
        rhodsOperator -> pipelines "Deploys and manages via DataSciencePipelines CR" "Kubernetes API"
        rhodsOperator -> modelRegistry "Deploys and manages via ModelRegistry CR" "Kubernetes API"
        rhodsOperator -> notebookController "Deploys and manages Workbenches via CR" "Kubernetes API"
        rhodsOperator -> rayOperator "Deploys and manages via Ray CR" "Kubernetes API"
        rhodsOperator -> trainingOperator "Deploys and manages via TrainingOperator CR" "Kubernetes API"
        rhodsOperator -> monitoringStack "Configures via Monitoring CR and ServiceMonitors" "Kubernetes API"

        # Relationships - Infrastructure dependencies
        rhodsOperator -> istio "Configures service mesh for model serving (optional)" "Kubernetes API, CRD creation"
        rhodsOperator -> serverless "Configures Knative for serverless model serving (optional)" "Kubernetes API, CRD creation"
        rhodsOperator -> prometheusOperator "Creates ServiceMonitors and PrometheusRules" "Kubernetes API"

        # Relationships - Monitoring
        prometheusOperator -> metricsService "Scrapes operator metrics" "HTTP/8443, Bearer token"

        # Relationships - Image pulling
        rhodsOperator -> containerRegistry "Pulls component container images" "HTTPS/443, TLS 1.2+, Pull secrets"

        # Internal component relationships
        dscController -> componentControllers "Triggers component reconciliation"
        dsciController -> serviceControllers "Triggers service reconciliation"
        controllerManager -> webhookServer "Runs webhook server"
        controllerManager -> metricsService "Exposes metrics"
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

        component controllerManager "ControllerManagerComponents" {
            include *
            autoLayout
        }

        component webhookServer "WebhookServerComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "External Service" {
                background #f5a623
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
