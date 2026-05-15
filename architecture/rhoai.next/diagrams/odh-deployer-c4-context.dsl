workspace {
    model {
        platformAdmin = person "Platform Administrator" "Installs and manages the RHODS platform on OpenShift"
        dataScientist = person "Data Scientist" "Uses RHODS dashboard, notebooks, and model serving"
        sreEngineer = person "SRE Engineer" "Monitors platform health and responds to alerts (managed service)"

        odhDeployer = softwareSystem "odh-deployer" "Bootstraps RHODS platform components by creating KfDef CRs, configuring monitoring, networking, dashboard ISVs, and partner integrations" {
            deployScript = container "deploy.sh" "Main deployment script — orchestrates namespace creation, CRD application, KfDef creation, monitoring config, ISV deployment, network policies" "Bash Script (Init Container)"
            kfdefManifests = container "KfDef Manifests" "KfDef YAML resources that trigger operator to deploy dashboard, notebooks, model-mesh, DSPO, monitoring, anaconda" "Kubernetes CRs"
            dashboardCRDs = container "Dashboard CRDs" "OdhApplication, OdhDocument, OdhQuickStart, OdhDashboardConfig custom resources for ISV tiles and dashboard config" "Kustomize Overlays"
            monitoringManifests = container "Monitoring Stack" "Prometheus, Alertmanager, Blackbox Exporter deployments with SLO-based alerting, PagerDuty/SMTP/DMS integrations" "Kubernetes Manifests"
            networkPolicies = container "Network Policies" "NetworkPolicy resources controlling ingress to applications, monitoring, and operator namespaces" "Kubernetes Manifests"
        }

        rhodsOperator = softwareSystem "rhods-operator (opendatahub operator)" "Reconciles KfDef CRs to deploy and manage RHODS platform components" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science projects, notebooks, model serving, and ISV integrations" "Internal RHOAI"
        notebookController = softwareSystem "ODH Notebook Controller" "Manages Jupyter notebook server lifecycle on OpenShift" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh" "Multi-model serving platform for deploying and managing ML models at scale" "Internal RHOAI"
        dspo = softwareSystem "Data Science Pipelines Operator" "Manages Data Science Pipelines (based on Kubeflow Pipelines)" "Internal RHOAI"

        ocpPrometheus = softwareSystem "OpenShift Prometheus" "Platform monitoring stack in openshift-monitoring namespace" "External (OpenShift)"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for managing all Kubernetes resources" "External (OpenShift)"
        ocpConsole = softwareSystem "OpenShift Console" "Web console for managing OpenShift clusters" "External (OpenShift)"

        pagerduty = softwareSystem "PagerDuty" "Incident management and alerting platform" "External SaaS"
        smtpServer = softwareSystem "SMTP Server" "Email delivery service for user notifications" "External"
        deadMansSnitch = softwareSystem "Dead Man's Snitch" "Heartbeat monitoring service" "External SaaS"
        segmentIO = softwareSystem "Segment.io" "Analytics and telemetry tracking" "External SaaS"
        anaconda = softwareSystem "Anaconda CE" "Anaconda Community Edition for data science packages" "External Partner"

        # Relationships
        platformAdmin -> odhDeployer "Triggers platform bootstrap by installing RHODS operator"
        dataScientist -> odhDashboard "Uses dashboard for notebooks, model serving, ISV tools"
        sreEngineer -> ocpPrometheus "Monitors platform health via federated metrics and alerts"

        deployScript -> k8sAPI "Creates namespaces, applies CRDs, creates KfDef CRs, deploys monitoring, applies network policies" "HTTPS/443 TLS 1.2+ SA Token"
        deployScript -> kfdefManifests "Reads and applies KfDef manifests"
        deployScript -> dashboardCRDs "Reads and applies dashboard CRDs and ISV tiles"
        deployScript -> monitoringManifests "Deploys Prometheus, Alertmanager, Blackbox Exporter"
        deployScript -> networkPolicies "Applies NetworkPolicies across namespaces"

        kfdefManifests -> rhodsOperator "KfDef CRs trigger operator reconciliation"
        rhodsOperator -> odhDashboard "Deploys dashboard components"
        rhodsOperator -> notebookController "Deploys notebook controller"
        rhodsOperator -> modelMesh "Deploys ModelMesh serving"
        rhodsOperator -> dspo "Deploys Data Science Pipelines Operator"

        monitoringManifests -> ocpPrometheus "Federates haproxy, controller_runtime, resource metrics" "HTTPS/9091 TLS Bearer Token"
        monitoringManifests -> notebookController "Scrapes metrics" "HTTP/8080 plaintext"
        monitoringManifests -> modelMesh "Scrapes metrics" "HTTP/8080 plaintext"
        monitoringManifests -> dspo "Scrapes metrics" "HTTP/8080 plaintext"
        monitoringManifests -> rhodsOperator "Scrapes metrics" "HTTP/8383 plaintext"
        monitoringManifests -> odhDashboard "Blackbox probes dashboard availability" "HTTPS/8443 TLS"

        monitoringManifests -> pagerduty "Routes critical alerts" "HTTPS/443 TLS 1.2+ Service Key"
        monitoringManifests -> smtpServer "Sends user notifications" "SMTP TLS STARTTLS"
        monitoringManifests -> deadMansSnitch "Heartbeat every 5 min" "HTTPS/443 TLS 1.2+ URL secret"

        dashboardCRDs -> odhDashboard "Configures ISV tiles, quickstarts, documentation, feature flags"
        deployScript -> ocpConsole "Creates ConsoleLink for Application Launcher"
        deployScript -> anaconda "Creates anaconda-ce-access secret placeholder"
        odhDashboard -> segmentIO "Sends analytics telemetry via segment key"
    }

    views {
        systemContext odhDeployer "SystemContext" {
            include *
            autoLayout
        }

        container odhDeployer "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External (OpenShift)" {
                background #999999
                color #ffffff
            }
            element "External SaaS" {
                background #f5a623
                color #333333
            }
            element "External" {
                background #cccccc
                color #333333
            }
            element "External Partner" {
                background #e6522c
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #333333
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
