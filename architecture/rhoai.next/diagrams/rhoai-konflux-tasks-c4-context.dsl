workspace {
    model {
        developer = person "RHOAI Developer" "Develops RHOAI components and triggers CI/CD builds"
        releaseEngineer = person "Release Engineer" "Manages RHOAI release pipelines and monitors build status"

        konfluxTasks = softwareSystem "rhoai-konflux-tasks" "Reusable Tekton tasks, step actions, and pipelines for RHOAI CI/CD on Konflux" {
            initTask = container "rhoai-init" "CPE ID computation, image metadata parsing, Slack setup, RHEL targeting" "Tekton Task (Shell)"
            prefetchTask = container "prefetch-operand-manifests-oci-ta" "Fetches operand deployment manifests via operator-processor" "Tekton Task (Shell/Python)"
            evalScanTask = container "evaluate-scan-results" "Aggregates scan results; report-only mode with planned enforcement" "Tekton Task (Shell)"
            triggerOpTask = container "trigger-operator-build" "Triggers operator builds via commit comments" "Tekton Task (Shell)"
            triggerBundleTask = container "trigger-bundle-build" "Dispatches bundle build workflows" "Tekton Task (Shell)"
            triggerGroupTask = container "trigger-group-testing" "Monitors check runs; triggers group testing" "Tekton Task (Shell)"
            genSnapshotTask = container "generate-snapshot-for-group-testing" "Resolves image digests and git provenance from Quay" "Tekton Task (Shell)"
            sealightsTask = container "rhoai-inject-sealights-oci-ta" "Injects Sealights-instrumented images into bundles" "Tekton Task (Shell)"
            secureGitPush = container "secure-git-push" "leaktk pre-scan + git push" "Tekton StepAction (Shell)"
            securePushOCI = container "secure-push-oci" "leaktk pre-scan + OCI push with retry" "Tekton StepAction (Shell)"
            containerBuild = container "container-build Pipeline" "Single-arch build: 17 tasks with security scans, SBOM, Slack" "Tekton Pipeline"
            containerBuildRemote = container "container-build-remote Pipeline" "Multi-arch build with matrix-based platform builds" "Tekton Pipeline"
        }

        tekton = softwareSystem "Tekton Pipelines" "Cloud-native CI/CD pipeline engine" "External"
        konfluxCI = softwareSystem "Konflux CI" "Red Hat's managed CI/CD platform with task catalog" "External"
        github = softwareSystem "GitHub" "Source code hosting, API for PR comments, workflow dispatch" "External"
        quayio = softwareSystem "Quay.io" "Container image registry for RHOAI images" "External"
        slack = softwareSystem "Slack" "Team notification service for build failures" "External"

        rhoaiAutomation = softwareSystem "RHOAI-Konflux-Automation" "Provides operator-processor Python tool" "Internal RHOAI"
        odhBuildConfig = softwareSystem "ODH-Build-Config" "Bundle patch configuration and build triggering" "Internal RHOAI"
        odhOperator = softwareSystem "opendatahub-operator" "RHOAI/ODH operator repository" "Internal RHOAI"
        trustedArtifacts = softwareSystem "Trusted Artifacts" "OCI-based artifact storage for build provenance" "External"

        developer -> konfluxTasks "Triggers builds via PR/push"
        releaseEngineer -> konfluxTasks "Monitors pipeline status and scan results"

        konfluxTasks -> tekton "Uses Tekton API for task/pipeline definitions" "Tekton v1"
        konfluxTasks -> konfluxCI "Resolves upstream tasks via OCI bundle digests" "HTTPS/443"
        konfluxTasks -> github "PR comments, workflow dispatch, commit comments, check runs" "HTTPS/443 Bearer token"
        konfluxTasks -> quayio "Image push/pull, tag resolution, manifest inspection, attestations" "HTTPS/443"
        konfluxTasks -> slack "Build failure notifications" "HTTPS/443 Webhook"
        konfluxTasks -> rhoaiAutomation "Clones operator-processor tool" "HTTPS/443 Git"
        konfluxTasks -> odhBuildConfig "Clones config; dispatches bundle build workflows" "HTTPS/443 Git + API"
        konfluxTasks -> odhOperator "Triggers operator builds via commit comments" "HTTPS/443 API"
        konfluxTasks -> trustedArtifacts "Creates and consumes trusted artifacts" "HTTPS/443 OCI"
    }

    views {
        systemContext konfluxTasks "SystemContext" {
            include *
            autoLayout
        }

        container konfluxTasks "Containers" {
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
        }
    }
}
