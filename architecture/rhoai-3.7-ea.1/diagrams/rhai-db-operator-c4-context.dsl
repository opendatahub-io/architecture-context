workspace "rhai-db-operator" "RHOAI shared database infrastructure service (downstream of opendatahub-db-operator)" {
    model {
        admin = person "Cluster Administrator" "Registers External PostgreSQL providers and admin Secrets"
        consumerTeam = person "Component / User" "Creates DatabaseClaim or SchemaClaim in a namespace"

        dbOperator = softwareSystem "rhai-db-operator" "Declarative PostgreSQL access for RHOAI components: providers (supply) and claims (demand) with per-claim connection Secrets" {
            manager = container "odh-db-operator-operator" "controller-runtime manager: leader election, health :8081, HTTPS metrics :8443, webhook :9443 (no handlers)" "Go Operator"
            dsReconciler = container "DatabaseService reconciler" "Reconciles default-db-operator singleton, installs infrastructure CRDs, manages rhai-db default provider" "Go Controller"
            dpReconciler = container "DatabaseProvider reconciler" "Renders Internal PostgreSQL backend or validates External connectivity" "Go Controller"
            dcReconciler = container "DatabaseClaim reconciler" "Provisions database-scoped role, optional database, extensions; writes connection Secret" "Go Controller"
            scReconciler = container "SchemaClaim reconciler" "Provisions dedicated schema and login role; writes connection Secret" "Go Controller"
            pgLib = container "pkg/postgres" "pgx client, TLS config, safe DDL, password generation, log redaction" "Go Library"
            internalPg = container "Internal PostgreSQL" "Single-instance StatefulSet (rhel9/postgresql-16), 5432/TCP, cert-manager TLS, RWO PVC" "PostgreSQL 16" "Database"
        }

        rhods = softwareSystem "rhods-operator" "RHOAI platform operator; enables the databaseservice module" "Internal RHOAI"
        consumers = softwareSystem "Consuming platform components" "Model registry, feature store and other services that mount the connection Secret" "Internal RHOAI"
        monitoring = softwareSystem "OpenShift monitoring / data-science-collector" "Scrapes operator metrics" "Internal RHOAI"
        serviceCa = softwareSystem "OpenShift Service CA" "Issues metrics-server-cert and CA bundle" "Internal RHOAI"
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        certManager = softwareSystem "cert-manager" "Issues Internal PostgreSQL server certs and webhook cert" "External"
        externalPg = softwareSystem "External PostgreSQL" "Administrator-managed PostgreSQL" "External"

        rhods -> dbOperator "Creates DatabaseService/default-db-operator, installs Helm chart, sets platformType/Version" "HTTPS/6443"
        admin -> dbOperator "Creates DatabaseProvider (External/Internal)" "kubectl, HTTPS/6443"
        consumerTeam -> dbOperator "Creates DatabaseClaim / SchemaClaim" "kubectl, HTTPS/6443"
        dbOperator -> k8sApi "Watches CRs, manages operands and Secrets" "HTTPS/6443, SA token"
        dbOperator -> certManager "Creates Issuer/Certificate CRs" "HTTPS/6443"
        dbOperator -> externalPg "Validates connectivity, provisions roles/schemas" "PostgreSQL, sslmode require (verify-ca with CA)"
        serviceCa -> dbOperator "Injects metrics serving cert"
        monitoring -> dbOperator "Scrapes /metrics" "HTTPS/8443, Bearer token"
        consumers -> internalPg "Connects with per-claim credentials" "PostgreSQL/5432, per sslmode"
        consumers -> externalPg "Connects with per-claim credentials" "PostgreSQL, per sslmode"

        dsReconciler -> dpReconciler "Creates rhai-db DatabaseProvider (via API)"
        dpReconciler -> internalPg "Renders StatefulSet, Service, PVC, NetworkPolicy, TLS"
        dpReconciler -> pgLib "Reachability and version checks"
        dcReconciler -> pgLib "Database/role provisioning"
        scReconciler -> pgLib "Schema/role provisioning"
        pgLib -> internalPg "DDL, roles, grants, extensions" "PostgreSQL/5432, TLS verify-full"
        pgLib -> externalPg "DDL, roles, grants, extensions" "PostgreSQL, require/verify-ca"
        manager -> dsReconciler "Runs"
        manager -> dpReconciler "Registers lazily once CRD exists"
        manager -> dcReconciler "Registers lazily once CRD exists"
        manager -> scReconciler "Registers lazily once CRD exists"
        manager -> k8sApi "Leader election, watches, writes" "HTTPS/6443"
        monitoring -> manager "Scrapes /metrics" "HTTPS/8443"
        consumers -> manager "Creates claims (via API)"
    }

    views {
        systemContext dbOperator "SystemContext" {
            include *
            autoLayout
        }

        container dbOperator "Containers" {
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
            }
            element "Database" {
                shape Cylinder
                background #9fc5e8
            }
            element "Person" {
                shape Person
            }
        }
    }
}
