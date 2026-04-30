workspace {
    model {
        sre = person "SRE / Platform Admin" "Manages RHODS platform installation and monitoring"
        datascientist = person "Data Scientist" "Uses RHODS platform for ML workloads"

        odhDeployer = softwareSystem "odh-deployer" "Init container that bootstraps RHODS platform by creating KfDef CRs, CRDs, monitoring stack, network policies, and dashboard configuration" {
            deploySh = container "deploy.sh" "Main deployment entrypoint orchestrating entire RHODS setup via oc CLI commands" "Shell Script (Bash)"
            kfdefManifests = container "KfDef Manifests" "KfDef custom resource definitions triggering operator to deploy individual RHODS components" "YAML Manifests"
            monitoringStack = container "Monitoring Stack" "Prometheus, Alertmanager, Blackbox Exporter deployment manifests with SLO recording rules" "YAML Manifests"
            dashboardConfig = container "Dashboard Config" "CRDs, ISV application tiles, OdhDashboardConfig, serving runtime templates" "YAML + Kustomize"
            networkPolicies = container "Network Policies" "Network policies for redhat-ods-applications, monitoring, and operator namespaces" "YAML Manifests"
        }

        rhodsOperator = softwareSystem "rhods-operator" "OpenDataHub operator that watches KfDef CRs and reconciles component deployments" "Internal RHOAI"
        odhManifests = softwareSystem "odh-manifests" "Bundled component manifests tarball extracted by operator" "Internal RHOAI"
        rhodsDashboard = softwareSystem "rhods-dashboard" "RHODS Dashboard web UI" "Internal RHOAI"
        notebookController = softwareSystem "odh-notebook-controller" "Manages notebook pod lifecycle" "Internal RHOAI"
        modelController = softwareSystem "odh-model-controller" "Manages model serving lifecycle" "Internal RHOAI"
        modelmeshController = softwareSystem "modelmesh-controller" "ModelMesh serving controller" "Internal RHOAI"
        dspo = softwareSystem "data-science-pipelines-operator" "Data Science Pipelines operator" "Internal RHOAI"
        clusterPrometheus = softwareSystem "prometheus-k8s (openshift-monitoring)" "Cluster built-in Prometheus for metric federation" "External"
        openshiftAPI = softwareSystem "OpenShift API Server" "Kubernetes/OpenShift API server" "External"
        openshiftConsole = softwareSystem "OpenShift Console" "OpenShift web console with Application Launcher" "External"
        pagerduty = softwareSystem "PagerDuty" "Incident alerting service (managed service only)" "External"
        deadMansSnitch = softwareSystem "Dead Man's Snitch" "Monitoring liveness heartbeat service (managed service only)" "External"
        smtpServer = softwareSystem "SMTP Server" "Email notification service (managed service only)" "External"
        osdAddon = softwareSystem "OSD Addon Framework" "OpenShift Dedicated addon parameter injection" "External"

        sre -> odhDeployer "Triggers deployment via operator"
        datascientist -> rhodsDashboard "Uses RHODS dashboard"

        deploySh -> openshiftAPI "Creates namespaces, CRDs, KfDefs, ConfigMaps, Secrets, NetworkPolicies via oc CLI" "HTTPS/443"
        deploySh -> kfdefManifests "Applies KfDef CRs"
        deploySh -> monitoringStack "Deploys Prometheus, Alertmanager, Blackbox Exporter"
        deploySh -> dashboardConfig "Applies CRDs, ISV tiles, OdhDashboardConfig"
        deploySh -> networkPolicies "Applies network policies"

        odhDeployer -> rhodsOperator "Creates KfDef CRs that operator watches and reconciles" "Kubernetes API"
        rhodsOperator -> odhManifests "Extracts and applies component manifests" "file:///opt/manifests"
        odhDeployer -> openshiftConsole "Creates ConsoleLink CR for dashboard in Application Launcher" "Kubernetes API"
        odhDeployer -> osdAddon "Reads addon-managed-odh-parameters, pagerduty, smtp, deadmanssnitch secrets" "Kubernetes API"

        monitoringStack -> clusterPrometheus "Federates haproxy, controller_runtime, container, kubelet metrics" "HTTPS/9091"
        monitoringStack -> notebookController "Scrapes metrics" "HTTP/8080"
        monitoringStack -> modelController "Scrapes metrics" "HTTP/8080"
        monitoringStack -> modelmeshController "Scrapes metrics" "HTTP/8080"
        monitoringStack -> dspo "Scrapes metrics" "HTTP/8080"
        monitoringStack -> rhodsDashboard "Blackbox probe for SLO monitoring" "HTTPS/8443"
        monitoringStack -> pagerduty "Sends critical alerts (managed service only)" "HTTPS/443"
        monitoringStack -> deadMansSnitch "Sends heartbeat (managed service only)" "HTTPS/443"
        monitoringStack -> smtpServer "Sends user notification emails (managed service only)" "SMTP/TLS"
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
