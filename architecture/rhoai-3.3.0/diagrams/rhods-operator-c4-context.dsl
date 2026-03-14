workspace {
    model {
        user = person "Data Scientist / Platform Admin" "Creates and manages data science platform and workloads"

        rhodsOperator = softwareSystem "RHODS Operator" "Primary operator for Red Hat OpenShift AI that manages and deploys data science platform components" {
            manager = container "Operator Manager" "Reconciles DSC/DSCI resources and manages component lifecycle" "Go Operator (3 replicas, leader elected)" {
                dsciController = component "DSCInitialization Controller" "Manages platform initialization, monitoring, auth, service mesh"
                dscController = component "DataScienceCluster Controller" "Manages component lifecycle (dashboard, kserve, workbenches, etc.)"
                componentControllers = component "Component Controllers" "Per-component reconcilers (15+ components)"
                serviceControllers = component "Service Controllers" "Infrastructure service reconcilers (auth, monitoring, gateway)"
            }
            webhook = container "Webhook Server" "Validates and defaults DSC/DSCI resources" "HTTPS/9443, TLS cert from Service CA"
            metrics = container "Metrics Service" "Prometheus metrics with auth proxy" "HTTP/8080, kube-rbac-proxy/8443"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster orchestration and resource management" "External - K8s 1.24+"
        certManager = softwareSystem "Cert Manager / OpenShift Service CA" "TLS certificate provisioning for webhooks" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "Monitoring infrastructure management" "External - Optional"
        istio = softwareSystem "Istio / OpenShift Service Mesh" "Service mesh for traffic management and mTLS" "External - Optional v2.4+"
        knative = softwareSystem "Knative Serving / OpenShift Serverless" "Serverless autoscaling platform" "External - Optional v1.30+"
        oauth = softwareSystem "OpenShift OAuth Server" "User authentication service" "External - RHOAI only"

        dashboard = softwareSystem "ODH Dashboard" "Web UI for data science workflows" "Internal ODH Component"
        kserve = softwareSystem "KServe Operator" "Model serving infrastructure" "Internal ODH Component"
        pipelines = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration" "Internal ODH Component"
        modelRegistry = softwareSystem "Model Registry Operator" "Model versioning and metadata" "Internal ODH Component"
        notebookController = softwareSystem "Notebook Controller" "Jupyter notebook lifecycle management" "Internal ODH Component"
        rayOperator = softwareSystem "Ray Operator" "Distributed computing framework" "Internal ODH Component"
        trainingOp = softwareSystem "Training Operator" "Distributed training jobs" "Internal ODH Component"
        monitoringStack = softwareSystem "Monitoring Stack" "Prometheus, AlertManager, Grafana" "Internal ODH Component"

        gitRepos = softwareSystem "Component Git Repositories" "Source of component manifests" "External"
        containerRegistry = softwareSystem "Container Registries" "Component container images" "External"

        # User interactions
        user -> rhodsOperator "Creates DataScienceCluster and DSCInitialization via kubectl/oc"
        user -> dashboard "Accesses data science workbench UI"

        # Operator core interactions
        rhodsOperator -> k8sAPI "Manages CRDs, resources, and component deployments" "HTTPS/6443, ServiceAccount token"
        k8sAPI -> webhook "Validates/mutates DSC and DSCI resources" "HTTPS/9443, mTLS"
        prometheusOp -> metrics "Scrapes operator metrics" "HTTP/8443, Bearer token"
        rhodsOperator -> certManager "Obtains webhook TLS certificates" "Auto-provisioned via Service CA"

        # Component deployment
        rhodsOperator -> dashboard "Deploys and manages"
        rhodsOperator -> kserve "Deploys and manages"
        rhodsOperator -> pipelines "Deploys and manages"
        rhodsOperator -> modelRegistry "Deploys and manages"
        rhodsOperator -> notebookController "Deploys and manages"
        rhodsOperator -> rayOperator "Deploys and manages"
        rhodsOperator -> trainingOp "Deploys and manages"
        rhodsOperator -> monitoringStack "Configures and deploys"

        # Infrastructure dependencies
        rhodsOperator -> istio "Configures service mesh for model serving" "CRD creation"
        rhodsOperator -> knative "Configures serverless infrastructure for KServe" "CRD creation"
        rhodsOperator -> oauth "Integrates user authentication (RHOAI)" "OAuth API/6443"

        # External resource fetching
        rhodsOperator -> gitRepos "Fetches component manifests" "HTTPS/443"
        rhodsOperator -> containerRegistry "Pulls component images" "HTTPS/443, Pull secrets"

        # Component interactions
        kserve -> istio "Uses for traffic routing and mTLS"
        kserve -> knative "Uses for autoscaling"
        dashboard -> k8sAPI "Manages user workloads"
        notebookController -> k8sAPI "Manages Jupyter notebook pods"
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

        component manager "Components" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH Component" {
                background #7ed321
                color #000000
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
