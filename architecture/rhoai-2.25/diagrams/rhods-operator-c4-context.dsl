workspace {
    model {
        admin = person "Cluster Admin" "Configures and manages the RHOAI platform via CRDs"
        datascientist = person "Data Scientist" "Uses deployed data science components (notebooks, pipelines, model serving)"

        rhodsOperator = softwareSystem "rhods-operator" "Central platform operator for RHOAI - deploys, configures, and lifecycle-manages all data science components" {
            dsciController = container "DSCInitialization Controller" "Infrastructure initialization: namespaces, networking, monitoring, service mesh, auth, CA bundles" "Go (controller-runtime)"
            dscController = container "DataScienceCluster Controller" "Application-level component provisioning via registry-based component system" "Go (controller-runtime)"
            componentRegistry = container "Component Registry" "Plugin system for dynamic component discovery and management" "Go"
            componentControllers = container "Component Controllers (14)" "Per-component lifecycle management: Dashboard, Workbenches, KServe, ModelMesh, ModelController, DSP, Kueue, CodeFlare, Ray, TrustyAI, ModelRegistry, TrainingOperator, FeastOperator, LlamaStackOperator" "Go (controller-runtime)"
            serviceControllers = container "Service Controllers (6)" "Platform services: Auth, CertConfigMapGenerator, Monitoring, SecretGenerator, ServiceMesh, Setup" "Go (controller-runtime)"
            webhookServer = container "Admission Webhooks (10)" "Validation and mutation: singleton enforcement, HardwareProfile injection, platform connections, Kueue validation" "Go (9443/TCP HTTPS)"
            manifests = container "Prefetched Manifests" "Kustomize manifests from 16 downstream repos baked into container image" "Filesystem (/opt/manifests/)"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane for all resource management" "External"
        openshift = softwareSystem "OpenShift Platform" "OAuth, Routes, Console, service-ca, CNO, Ingress" "External"
        olm = softwareSystem "Operator Lifecycle Manager" "Manages operator installation and upgrades" "External"

        istioOperator = softwareSystem "Maistra/Istio Operator" "Service mesh control plane management" "Conditional"
        authorinoOperator = softwareSystem "Authorino Operator" "External authorization provider for service mesh" "Conditional"
        knativeOperator = softwareSystem "Knative Serving Operator" "Serverless autoscaling for KServe" "Conditional"
        cooOperator = softwareSystem "Cluster Observability Operator" "MonitoringStack and ThanosQuerier management" "Conditional"
        tempoOperator = softwareSystem "Tempo Operator" "Distributed tracing backend" "Conditional"
        otelOperator = softwareSystem "OpenTelemetry Operator" "Telemetry collection and export" "Conditional"
        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics scraping and alerting" "External"

        dashboard = softwareSystem "ODH Dashboard" "Web UI and application catalog" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Standardized ML model serving" "Internal RHOAI"
        modelmesh = softwareSystem "ModelMesh Serving" "Multi-model serving runtime" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration with Argo" "Internal RHOAI"
        notebooks = softwareSystem "Workbenches/Notebooks" "JupyterLab notebook environments" "Internal RHOAI"

        segmentio = softwareSystem "Segment.io" "Usage telemetry (Self-Managed only)" "External SaaS"
        deadmansnitch = softwareSystem "Deadmansnitch" "Health monitoring (Managed RHOAI only)" "External SaaS"
        pagerduty = softwareSystem "PagerDuty" "Incident management (Managed RHOAI only)" "External SaaS"

        # Relationships
        admin -> rhodsOperator "Creates DSCInitialization and DataScienceCluster CRs via kubectl"
        datascientist -> dashboard "Accesses notebooks, pipelines, model serving UI"
        datascientist -> notebooks "Runs data science workloads"
        datascientist -> kserve "Deploys and queries ML models"

        rhodsOperator -> k8sApi "Manages all cluster resources" "HTTPS/6443"
        rhodsOperator -> openshift "Registers OAuth clients, reads cluster config" "HTTPS/443"
        rhodsOperator -> olm "Detects installed operators" "Watch CRDs"

        rhodsOperator -> istioOperator "Creates ServiceMeshControlPlane" "CRD"
        rhodsOperator -> authorinoOperator "Deploys Authorino instance" "CRD"
        rhodsOperator -> knativeOperator "Creates KnativeServing" "CRD"
        rhodsOperator -> cooOperator "Creates MonitoringStack" "CRD"
        rhodsOperator -> tempoOperator "Creates TempoMonolithic" "CRD"
        rhodsOperator -> otelOperator "Creates OpenTelemetryCollector" "CRD"
        rhodsOperator -> prometheusOperator "Creates ServiceMonitors, PrometheusRules" "CRD"

        rhodsOperator -> dashboard "Deploys and manages lifecycle" "Kustomize manifests"
        rhodsOperator -> kserve "Deploys and configures with mesh integration" "Kustomize manifests"
        rhodsOperator -> modelmesh "Deploys and manages lifecycle" "Kustomize manifests"
        rhodsOperator -> dsp "Deploys and manages lifecycle" "Kustomize manifests"
        rhodsOperator -> notebooks "Deploys and manages lifecycle, webhook mutation" "Kustomize manifests"

        rhodsOperator -> segmentio "Sends usage telemetry" "HTTPS/443"
        rhodsOperator -> deadmansnitch "Sends health heartbeats" "HTTPS/443"
        rhodsOperator -> pagerduty "Sends alert notifications" "HTTPS/443"

        # Internal container relationships
        dsciController -> serviceControllers "Initializes platform services"
        dscController -> componentRegistry "Iterates registered components"
        componentRegistry -> componentControllers "Dispatches to component controllers"
        componentControllers -> manifests "Reads kustomize manifests"
        componentControllers -> k8sApi "Applies manifests via server-side apply" "HTTPS/6443"
        k8sApi -> webhookServer "Admission requests" "HTTPS/9443"
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
            element "External SaaS" {
                background #f5a623
                color #ffffff
            }
            element "Conditional" {
                background #9C27B0
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
                background #438DD5
                color #ffffff
            }
        }
    }
}
