workspace {
    model {
        sre = person "SRE / Platform Admin" "Deploys and manages the RHODS/RHOAI platform on OpenShift"
        dataScientist = person "Data Scientist" "Consumes RHODS Dashboard, notebooks, and model serving"

        odhDeployer = softwareSystem "odh-deployer" "Containerized Bash deployer that bootstraps RHODS platform components via KfDef CRs, monitoring, network policies, and dashboard configuration" {
            deployScript = container "deploy.sh" "Main orchestration script that creates namespaces, applies KfDef CRs, configures monitoring, network policies, and dashboard resources" "Bash Script"
            kfdefManifests = container "KfDef Manifests" "Kubernetes custom resources that trigger the ODH operator to install platform components" "YAML"
            monitoringConfigs = container "Monitoring Configs" "Prometheus, Alertmanager, and Blackbox Exporter deployment manifests with SLO burn rate alerting" "YAML"
            dashboardISVs = container "Dashboard ISVs" "Kustomize-based ISV application tiles, CRDs, and OdhDashboardConfig for the RHODS Dashboard" "Kustomize Overlays"
            networkPolicies = container "Network Policies" "Namespace-scoped network policies restricting ingress across applications, monitoring, and operator namespaces" "YAML"
        }

        odhOperator = softwareSystem "ODH Operator (KfDef Controller)" "Watches KfDef CRs and installs platform components from odh-manifests tarball" "Internal ODH"
        rhodsDashboard = softwareSystem "RHODS Dashboard" "Web UI for data scientists to manage notebooks, model serving, and ISV integrations" "Internal ODH"
        notebookController = softwareSystem "ODH Notebook Controller" "Manages Jupyter notebook lifecycle and spawning" "Internal ODH"
        modelMesh = softwareSystem "ModelMesh Serving" "Multi-model serving platform for ML inference" "Internal ODH"
        dspo = softwareSystem "Data Science Pipelines Operator" "Manages ML pipeline deployments" "Internal ODH"

        prometheus = softwareSystem "Prometheus" "Metrics collection, SLO burn rate alerting, federation from cluster Prometheus" "External"
        alertmanager = softwareSystem "Alertmanager" "Alert routing to PagerDuty, SMTP, and Dead Man's Snitch" "External"
        openshiftAPI = softwareSystem "OpenShift API Server" "Kubernetes API for all resource management" "External"
        clusterPrometheus = softwareSystem "OpenShift Cluster Prometheus" "Platform-level metrics provider in openshift-monitoring namespace" "External"
        pagerDuty = softwareSystem "PagerDuty" "Incident alerting for critical SLO violations (managed service only)" "External"
        deadMansSnitch = softwareSystem "Dead Man's Snitch" "Monitoring pipeline liveness verification (managed service only)" "External"
        smtpServer = softwareSystem "SMTP Server" "Email notifications for user-facing alerts (managed service only)" "External"
        osdAddonFramework = softwareSystem "OSD Addon Framework" "Provides addon parameters and manages addon lifecycle on OSD" "External"

        # Relationships
        sre -> odhDeployer "Triggers deployment job"
        odhDeployer -> openshiftAPI "Creates namespaces, applies CRs, RBAC, network policies" "HTTPS/443 TLS 1.2+ ServiceAccount Token"
        odhDeployer -> odhOperator "Creates KfDef CRs to trigger component installation" "Kubernetes API"
        odhOperator -> rhodsDashboard "Installs via KfDef" "Kubernetes API"
        odhOperator -> notebookController "Installs via KfDef" "Kubernetes API"
        odhOperator -> modelMesh "Installs via KfDef" "Kubernetes API"
        odhOperator -> dspo "Installs via KfDef" "Kubernetes API"

        odhDeployer -> prometheus "Deploys monitoring stack" "oc apply YAML"
        odhDeployer -> alertmanager "Deploys alerting stack" "oc apply YAML"
        prometheus -> clusterPrometheus "Federates HAProxy, pod, cluster metrics" "HTTPS/9091 TLS Bearer Token"
        prometheus -> rhodsDashboard "Scrapes metrics + blackbox probe" "HTTP/8080, HTTPS/8443"
        prometheus -> notebookController "Scrapes controller metrics" "HTTP/8080"
        prometheus -> modelMesh "Scrapes controller metrics" "HTTP/8080"
        prometheus -> dspo "Scrapes operator metrics" "HTTP/8080"
        prometheus -> alertmanager "Sends alerts" "HTTP/9093"
        alertmanager -> pagerDuty "Critical SLO alerts" "HTTPS/443 TLS 1.2+"
        alertmanager -> deadMansSnitch "Watchdog heartbeat" "HTTPS/443 TLS 1.2+"
        alertmanager -> smtpServer "User notification emails" "SMTP STARTTLS"

        odhDeployer -> osdAddonFramework "Reads addon parameters" "Kubernetes API Secret"
        dataScientist -> rhodsDashboard "Accesses RHODS Dashboard" "HTTPS/443"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
