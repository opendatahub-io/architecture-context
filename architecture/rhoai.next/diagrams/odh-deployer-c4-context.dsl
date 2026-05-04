workspace {
    model {
        admin = person "Platform Admin / SRE" "Deploys and monitors RHODS platform"

        odhDeployer = softwareSystem "odh-deployer" "Containerized shell-script deployer that bootstraps RHODS/RHOAI platform components by creating namespaces, KfDef CRs, monitoring infrastructure, network policies, and dashboard configuration" {
            deployScript = container "deploy.sh" "Main deployment orchestrator — creates namespaces, applies KfDef CRs, configures monitoring, network policies, and dashboard resources" "Bash Script (UBI8-minimal + oc CLI)"
            prometheusStack = container "Prometheus Stack" "Complete Prometheus + Alertmanager deployment with SLO burn rate alerts, blackbox probing, and OAuth proxy frontends" "Prometheus + Alertmanager + Blackbox Exporter"
            kfdefManifests = container "KfDef Manifests" "KfDef custom resources that trigger ODH operator to install platform components" "YAML CRs"
            dashboardConfig = container "Dashboard Configuration" "CRDs (OdhApplication, OdhDocument, OdhQuickStart), OdhDashboardConfig, ISV tiles, ServingRuntime templates" "Kustomize YAML"
            networkPolicies = container "Network Policies" "Namespace-scoped network policies restricting ingress across applications, monitoring, and operator namespaces" "Kubernetes NetworkPolicy"
        }

        odhOperator = softwareSystem "ODH Operator" "KfDef controller that reconciles component installations from odh-manifests" "Internal RHOAI"
        rhodsDashboard = softwareSystem "RHODS Dashboard" "Web UI for data scientists to manage notebooks, models, and pipelines" "Internal RHOAI"
        notebookController = softwareSystem "ODH Notebook Controller" "Manages Jupyter notebook lifecycle" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh Serving" "Multi-model serving platform" "Internal RHOAI"
        dspo = softwareSystem "Data Science Pipelines Operator" "ML pipeline orchestration" "Internal RHOAI"
        modelController = softwareSystem "ODH Model Controller" "Model serving reconciler" "Internal RHOAI"

        clusterPrometheus = softwareSystem "OpenShift Cluster Prometheus" "Cluster-wide metrics collection in openshift-monitoring namespace" "External"
        openshiftAPI = softwareSystem "OpenShift API Server" "Kubernetes API server for cluster operations" "External"
        pagerduty = softwareSystem "PagerDuty" "Incident alerting for critical SLO violations (managed only)" "External"
        deadMansSnitch = softwareSystem "Dead Man's Snitch" "Monitoring pipeline liveness verification (managed only)" "External"
        smtpServer = softwareSystem "SMTP Server" "Email notifications for user-facing alerts (managed only)" "External"
        osdAddon = softwareSystem "OSD Addon Framework" "Provides addon parameters and environment detection" "External"

        # Relationships
        admin -> odhDeployer "Triggers deployment"
        deployScript -> openshiftAPI "Creates namespaces, applies CRs, configures RBAC" "HTTPS/443, SA Token"
        deployScript -> kfdefManifests "Applies KfDef CRs"
        deployScript -> prometheusStack "Deploys monitoring stack"
        deployScript -> dashboardConfig "Installs dashboard config and ISV tiles"
        deployScript -> networkPolicies "Applies network policies"

        kfdefManifests -> odhOperator "KfDef CRs trigger component installation" "Kubernetes API"
        odhOperator -> rhodsDashboard "Installs via KfDef"
        odhOperator -> notebookController "Installs via KfDef"
        odhOperator -> modelMesh "Installs via KfDef"
        odhOperator -> dspo "Installs via KfDef"

        prometheusStack -> clusterPrometheus "Federates metrics" "HTTPS/9091, Bearer Token"
        prometheusStack -> rhodsDashboard "Probes availability" "HTTPS/8443"
        prometheusStack -> notebookController "Scrapes metrics" "HTTP/8080"
        prometheusStack -> modelController "Scrapes metrics" "HTTP/8080"
        prometheusStack -> modelMesh "Scrapes metrics" "HTTP/8080"
        prometheusStack -> dspo "Scrapes metrics" "HTTP/8080"
        prometheusStack -> pagerduty "Sends critical alerts" "HTTPS/443, Service Key"
        prometheusStack -> deadMansSnitch "Sends heartbeat" "HTTPS/443, URL Token"
        prometheusStack -> smtpServer "Sends email alerts" "SMTP, STARTTLS"

        odhDeployer -> osdAddon "Reads addon parameters" "Kubernetes API"
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
