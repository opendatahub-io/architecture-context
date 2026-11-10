workspace "MCP Lifecycle Module Operator" "RHOAI 3.7-ea.1" {
    model {
        admin = person "Cluster Admin" "Configures cluster TLS security profile"
        tenant = person "Namespace User" "Creates MCPServer resources in their namespace"

        mlmo = softwareSystem "MCP Lifecycle Module Operator" "ODH module operator that deploys, reconciles and garbage-collects the MCP Lifecycle Operator" {
            manager = container "Module Manager (/manager)" "controller-runtime manager; probes :8081, secure metrics :8443" "Go Operator"
            reconciler = container "MCPLifecycleOperatorReconciler" "render → SSA apply → GC → readiness → conversion gate → storage migration" "Go Reconciler"
            renderer = container "KustomizeProvider" "Embedded operand manifests with namespace/image/TLS/posture transforms" "manifestival"
            tls = container "TLS resolver + SecurityProfileWatcher" "Projects cluster TLS profile; restarts on change" "Go"
            gwdisc = container "Gateway discovery" "Discovers Kuadrant MCPGatewayExtensions and Gateway listeners" "Dynamic client"
            svm = container "Storage migration driver" "StorageVersionMigration mcpservers-v1beta1" "Go"
        }

        platform = softwareSystem "opendatahub-operator / rhods-operator" "Platform operator; creates MCPLifecycleOperator/default" "Internal ODH"
        operand = softwareSystem "MCP Lifecycle Operator (operand)" "Manages MCPServer / MCPGatewayBinding; serves conversion + validating webhooks" "Internal ODH"
        k8s = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        ocpConfig = softwareSystem "OpenShift APIServer config" "Cluster TLS security profile" "Internal ODH"
        certManager = softwareSystem "cert-manager" "Self-signed Issuer + Certificates for operand TLS" "External"
        prometheus = softwareSystem "Prometheus / Prometheus Operator" "Scrapes operand metrics via ServiceMonitor" "External"
        kuadrant = softwareSystem "Kuadrant MCP Gateway + Gateway API" "MCPGatewayExtension and Gateway listeners (optional)" "External"
        migrator = softwareSystem "kube-storage-version-migrator" "Serves StorageVersionMigration (optional)" "External"

        platform -> mlmo "Creates MCPLifecycleOperator CR, ConfigMap, injects env; reads status.distribution" "Kubernetes API HTTPS/6443"
        mlmo -> k8s "Watch, SSA apply, GC, status patch" "HTTPS/6443 SA token"
        mlmo -> operand "Deploys, upgrades and GCs operand resources" "SSA via Kubernetes API"
        mlmo -> ocpConfig "Watches TLS profile" "HTTPS/6443"
        mlmo -> kuadrant "Discovers gateways for status" "HTTPS/6443 dynamic informers"
        mlmo -> migrator "Creates StorageVersionMigration" "HTTPS/6443"
        mlmo -> certManager "Creates Issuer/Certificates for operand" "HTTPS/6443"
        mlmo -> prometheus "Creates ServiceMonitor for operand" "HTTPS/6443"
        k8s -> operand "Calls /convert and /validate webhooks" "HTTPS/443→9443"
        prometheus -> operand "Scrapes /metrics" "HTTPS/8443 Bearer"
        admin -> ocpConfig "Updates tlsSecurityProfile" "HTTPS/6443"
        tenant -> operand "Creates MCPServer CRs" "Kubernetes API"

        manager -> reconciler "Runs"
        reconciler -> renderer "Renders operand manifests"
        reconciler -> tls "Resolves TLS env"
        reconciler -> gwdisc "Discovers gateways"
        reconciler -> svm "Drives storage migration"
        reconciler -> k8s "SSA apply / GC / status" "HTTPS/6443"
    }

    views {
        systemContext mlmo "SystemContext" {
            include *
            autoLayout
        }

        container mlmo "Containers" {
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
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
            }
        }
    }
}
