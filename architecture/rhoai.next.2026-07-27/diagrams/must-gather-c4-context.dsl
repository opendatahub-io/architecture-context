workspace {
    model {
        user = person "SRE / Support Engineer" "Collects diagnostic data from RHOAI clusters for troubleshooting"

        mustGather = softwareSystem "must-gather" "Shell-script diagnostic collection tool invoked via oc adm must-gather. Runs as ephemeral pod, collects logs, CRs, and cluster state from all RHOAI components." {
            orchestrator = container "gather.sh" "Main orchestrator script. Detects distribution, dispatches collectors, aggregates output." "Bash Script"
            commonLib = container "common.sh" "Shared library providing run_mustgather() and utility functions." "Bash Script"
            xksUtil = container "xks_util.sh" "Distribution detection for OpenShift, AKS, CKS, EKS." "Bash Script"
            servingCollector = container "gather_serving.sh" "Collects KServe, Authorino, NIM, llm-d, Kuadrant resources." "Bash Script"
            dspCollector = container "gather_data_science_pipelines.sh" "Collects DSP, Kubeflow, Argo pipeline resources." "Bash Script"
            dashboardCollector = container "gather_dashboard.sh" "Collects Dashboard, AcceleratorProfiles, HardwareProfiles." "Bash Script"
            mrCollector = container "gather_mr.sh" "Collects Model Registry resources." "Bash Script"
            aigatewayCollector = container "gather_aigateway.sh" "Collects MaaS, inference, batch gateway resources." "Bash Script"
            mcpCollector = container "gather_mcp_lifecycle_operator.sh" "Collects MCP Lifecycle Operator resources." "Bash Script"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server providing access to all resources, logs, and CRDs" "External"
        openShiftCLI = softwareSystem "OpenShift CLI (oc)" "Command-line tool that creates the must-gather pod and retrieves results" "External"

        # RHOAI Components (targets of collection)
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "RHOAI Component"
        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "RHOAI Component"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for RHOAI" "RHOAI Component"
        modelRegistry = softwareSystem "Model Registry" "Model metadata store" "RHOAI Component"
        notebooks = softwareSystem "Notebooks" "Jupyter notebook workspaces" "RHOAI Component"
        monitoring = softwareSystem "Monitoring" "Cluster monitoring stack" "RHOAI Component"

        # Relationships
        user -> openShiftCLI "Invokes oc adm must-gather"
        openShiftCLI -> k8sAPI "Creates ephemeral must-gather pod"
        k8sAPI -> mustGather "Schedules pod with SA token"
        mustGather -> k8sAPI "Reads resources, logs, CRDs via oc/kubectl" "HTTPS/6443"

        # Internal container relationships
        orchestrator -> commonLib "Sources shared functions"
        orchestrator -> xksUtil "Detects distribution"
        orchestrator -> servingCollector "Dispatches (parallel)"
        orchestrator -> dspCollector "Dispatches (parallel)"
        orchestrator -> dashboardCollector "Dispatches (parallel)"
        orchestrator -> mrCollector "Dispatches (parallel)"
        orchestrator -> aigatewayCollector "Dispatches (parallel)"
        orchestrator -> mcpCollector "Dispatches (parallel)"

        # Collection targets via API
        servingCollector -> k8sAPI "Reads KServe/Authorino/NIM/llm-d CRs"
        dspCollector -> k8sAPI "Reads DSP/Kubeflow/Argo CRs"
        dashboardCollector -> k8sAPI "Reads Dashboard CRs"
        mrCollector -> k8sAPI "Reads Model Registry CRs"
        aigatewayCollector -> k8sAPI "Reads AI Gateway CRs"
        mcpCollector -> k8sAPI "Reads MCP Lifecycle Operator CRs"
    }

    views {
        systemContext mustGather "SystemContext" {
            include *
            autoLayout
        }

        container mustGather "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "RHOAI Component" {
                background #7ed321
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
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
