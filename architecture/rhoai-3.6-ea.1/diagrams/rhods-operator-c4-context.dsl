workspace {
    model {
        admin = person "Cluster Admin" "Configures RHOAI platform via DataScienceCluster and DSCInitialization CRs"

        rhodsOperator = softwareSystem "rhods-operator" "Central lifecycle operator for Red Hat OpenShift AI - manages deployment, configuration, and reconciliation of all AI/ML platform components" {
            manager = container "Manager" "Main operator binary - platform and component reconcilers, admission webhooks, metrics" "Go controller-runtime Operator" {
                dscInitReconciler = component "DSCInitialization Reconciler" "Drives cluster-wide platform initialization" "controller-runtime Reconciler"
                dscReconciler = component "DataScienceCluster Reconciler" "Manages component lifecycle based on DSC CR spec" "controller-runtime Reconciler"
                authController = component "Auth Service Controller" "Manages namespace-scoped RBAC, watches MaaS and Kuadrant namespaces" "controller-runtime Reconciler"
                gatewayController = component "Gateway Service Controller" "Manages GatewayClass, Gateway, HTTPRoute, conditional Istio resources, kube-auth-proxy" "controller-runtime Reconciler"
                monitoringController = component "Monitoring Service Controller" "Manages Prometheus observability resources" "controller-runtime Reconciler"
                webhookServer = component "Webhook Server" "10 admission webhooks (conversion, mutating, validating) on port 9443 TLS" "controller-runtime Webhook"
                componentControllers = component "Component Controllers" "Per-component reconcilers: DSP, Kueue, ModelRegistry, Ray, Spark, Trainer, TrainingOp, TrustyAI" "controller-runtime Reconcilers"
            }
            cloudmanager = container "Cloud Manager" "Multi-cloud Kubernetes engine management (AWS, Azure, CoreWeave)" "Go CLI"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for all resource operations" "External" {
            tags "External"
        }
        openshiftConfig = softwareSystem "OpenShift Platform" "Cluster configuration: APIServer TLS profile, service-ca, OAuth" "External" {
            tags "External"
        }
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for ingress routing (GatewayClass, Gateway, HTTPRoute)" "External" {
            tags "External"
        }
        istio = softwareSystem "Istio Service Mesh" "Optional service mesh for mTLS, traffic routing (EnvoyFilter, DestinationRule)" "External" {
            tags "External"
        }
        prometheusOperator = softwareSystem "prometheus-operator" "Manages Prometheus monitoring resources (PodMonitor, PrometheusRule, ServiceMonitor)" "External" {
            tags "External"
        }
        kuadrant = softwareSystem "Kuadrant" "API management and auth policy - triggers RBAC reconciliation when namespace exists" "Internal ODH" {
            tags "Internal ODH"
        }
        maas = softwareSystem "Models-as-a-Service" "MaaS controller - triggers RBAC reconciliation when namespace exists" "Internal ODH" {
            tags "Internal ODH"
        }

        # Relationships
        admin -> rhodsOperator "Creates DataScienceCluster and DSCInitialization CRs via kubectl/oc"
        rhodsOperator -> kubernetesAPI "Watch CRDs, CRUD all managed resources" "HTTPS/6443, TLS 1.2+, ServiceAccount"
        rhodsOperator -> openshiftConfig "Read TLS security profile, OAuth config" "Kubernetes API"
        rhodsOperator -> gatewayAPI "Create GatewayClass, Gateway, HTTPRoute" "Kubernetes API"
        rhodsOperator -> istio "Conditional: Create EnvoyFilter, DestinationRule" "Kubernetes API"
        rhodsOperator -> prometheusOperator "Create PodMonitor, PrometheusRule, ServiceMonitor" "Kubernetes API"
        rhodsOperator -> kuadrant "Watch kuadrant-system namespace" "Kubernetes API"
        rhodsOperator -> maas "Watch models-as-a-service namespace, use Go library" "Kubernetes API + Go import"

        kubernetesAPI -> rhodsOperator "Admission requests to webhook server" "HTTPS/9443, TLS"
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

        component manager "ManagerComponents" {
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
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #5ba3f5
                color #ffffff
            }
            element "Component" {
                background #85bbf7
                color #ffffff
            }
        }
    }
}
