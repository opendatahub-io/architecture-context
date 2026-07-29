workspace {
    model {
        clusterAdmin = person "Cluster Administrator" "Executes deploy.sh to install/upgrade RHOAI"

        odhDeployer = softwareSystem "odh-deployer" "Shell-based deployment orchestrator that provisions RHOAI platform components via KfDef CRs and direct Kubernetes manifests" {
            deployScript = container "deploy.sh" "Bash script orchestrating RHOAI installation" "Bash"
            prometheusStack = container "Prometheus" "Metrics collection with init container health gates" "Prometheus"
            alertmanagerStack = container "Alertmanager" "Alert routing to PagerDuty, DMS, SMTP" "Alertmanager"
            oauthProxy = container "OAuth Proxy" "Authentication sidecar for monitoring endpoints" "oauth-proxy"
        }

        openShiftAPI = softwareSystem "OpenShift API Server" "Kubernetes API for resource management" "Infrastructure"
        kubeflowOperator = softwareSystem "KubeFlow Operator" "Reconciles KfDef custom resources into platform workloads" "Internal RHOAI"

        dashboard = softwareSystem "RHOAI Dashboard" "Web UI for RHOAI management" "Internal RHOAI"
        notebookController = softwareSystem "Notebook Controller" "Manages Jupyter notebook lifecycle" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh" "Model serving infrastructure" "Internal RHOAI"
        dspo = softwareSystem "Data Science Pipelines Operator" "ML pipeline orchestration" "Internal RHOAI"
        modelController = softwareSystem "Model Controller" "Model lifecycle management" "Internal RHOAI"

        pagerDuty = softwareSystem "PagerDuty" "Critical alert routing (OSD only)" "External"
        deadMansSnitch = softwareSystem "Dead Man's Snitch" "Watchdog/heartbeat monitoring (OSD only)" "External"
        smtpServer = softwareSystem "SMTP Server" "Email alert notifications (OSD only)" "External"

        # Relationships
        clusterAdmin -> odhDeployer "Executes deploy.sh"
        odhDeployer -> openShiftAPI "Creates namespaces, applies manifests, deploys monitoring" "oc CLI / HTTPS 6443"
        openShiftAPI -> kubeflowOperator "Delivers KfDef CR events"
        kubeflowOperator -> dashboard "Deploys via KfDef"
        kubeflowOperator -> notebookController "Deploys via KfDef"
        kubeflowOperator -> modelMesh "Deploys via KfDef"
        kubeflowOperator -> dspo "Deploys via KfDef"

        odhDeployer -> dashboard "Scrapes metrics" "HTTPS 8443"
        odhDeployer -> notebookController "Scrapes metrics" "HTTP 8080"
        odhDeployer -> modelController "Scrapes metrics" "HTTP 8080"
        odhDeployer -> modelMesh "Scrapes metrics" "HTTP 8080"
        odhDeployer -> dspo "Scrapes metrics" "HTTP 8080"

        odhDeployer -> pagerDuty "Sends critical alerts (OSD)" "HTTPS 443"
        odhDeployer -> deadMansSnitch "Sends heartbeat (OSD)" "HTTPS 443"
        odhDeployer -> smtpServer "Sends email alerts (OSD)" "SMTP/TLS"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
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
        }
    }
}
