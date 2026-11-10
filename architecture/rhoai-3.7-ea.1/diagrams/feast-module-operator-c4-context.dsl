workspace "feast-module-operator" "RHOAI 3.7-ea.1 - Feast module operator" {
    model {
        admin = person "Platform Administrator" "Enables Feast through the DataScienceCluster"
        dataScientist = person "Data Scientist" "Creates FeatureStore CRs in project namespaces"

        feastModule = softwareSystem "feast-module-operator" "ODH module operator that deploys and configures the upstream Feast operator" {
            manager = container "Manager (operator subcommand)" "Reconciles the singleton FeastOperator CR; renders and applies bundled Feast kustomize manifests; manages capabilities ConfigMap, Data Registry namespace, finalizer handshake" "Go, controller-runtime, opendatahub-operator reconciler framework"
            tlsWatcher = container "TLS Profile Loader/Watcher" "Applies OpenShift APIServer TLS profile to metrics server; restarts manager on change" "Go runnable"
            manifests = container "Bundled Feast Manifests" "Upstream Feast operator 0.67.0 kustomize payload copied to /opt/manifests" "Kustomize"
            chartgen = container "chartgen" "Generates the Helm chart used by the platform operator" "Go build tool"

            manager -> manifests "Renders" "file"
            tlsWatcher -> manager "Configures metrics TLS / triggers restart"
        }

        platformOp = softwareSystem "ODH/RHOAI Platform Operator" "rhods-operator; installs module via Helm, creates FeastOperator CR, provides odh-data-config" "Internal ODH"
        feastOp = softwareSystem "Feast Operator" "Upstream feast-operator-controller-manager; reconciles FeatureStore CRs and Data Registry" "Internal ODH"
        dataRegistry = softwareSystem "Data Registry" "rhoai-data-registry namespace and workloads (Feast + odh-dashboard)" "Internal ODH"
        k8s = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        ocpConfig = softwareSystem "OpenShift APIServer Config" "config.openshift.io/v1 APIServer cluster - TLS security profile" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Scrapes metrics" "External"

        admin -> platformOp "Enables Feast component"
        dataScientist -> feastOp "Creates FeatureStore CRs" "kubectl / Dashboard"
        platformOp -> feastModule "Helm install; creates FeastOperator default-feastoperator" "HTTPS/6443"
        feastModule -> k8s "Watches CRs, applies manifests, updates status" "HTTPS/6443 TLS 1.2+, SA token"
        feastModule -> feastOp "Deploys; configures via feast-capabilities-config; capabilities-hash rollout; finalizer handshake" "via Kubernetes API"
        feastModule -> dataRegistry "Creates/labels rhoai-data-registry namespace" "via Kubernetes API"
        feastModule -> ocpConfig "Reads/watches TLS profile" "HTTPS/6443"
        prometheus -> feastModule "Scrapes /metrics" "HTTPS/8443 Bearer TokenReview+SAR"
        prometheus -> feastOp "Scrapes /metrics" "HTTPS/8443 service-CA TLS"
        feastOp -> dataRegistry "Manages Data Registry workloads"

        manager -> k8s "Reconciles" "HTTPS/6443"
        tlsWatcher -> ocpConfig "Get + watch" "HTTPS/6443"
        platformOp -> manager "Creates FeastOperator CR"
        prometheus -> manager "Scrapes /metrics" "HTTPS/8443"
    }

    views {
        systemContext feastModule "SystemContext" {
            include *
            autoLayout
        }

        container feastModule "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
            }
            element "Internal ODH" {
                background #7ed321
            }
        }
    }
}
