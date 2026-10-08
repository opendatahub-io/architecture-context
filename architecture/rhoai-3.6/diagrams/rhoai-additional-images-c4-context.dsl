workspace {
    model {
        operator = person "RHOAI Administrator" "Prepares disconnected/air-gapped deployments"

        rhoaiAdditionalImages = softwareSystem "rhoai-additional-images" "Metadata repository maintaining a registry of additional RHOAI container images not referenced in component manifests, ensuring completeness for disconnected deployment image mirroring" {
            manifest = container "rhoai-disconnected-images.yaml" "Lists 68 digest-pinned container image references organized by category" "YAML Manifest"
        }

        mirroringTooling = softwareSystem "Disconnected Deployment Tooling" "oc-mirror / skopeo for image mirroring" "External"

        quayModh = softwareSystem "quay.io/modh" "Upstream/community container registry hosting Ray and fms-hf-tuning images" "External"
        registryRHOAI = softwareSystem "registry.redhat.io/rhoai" "Red Hat productized container registry for RHOAI images" "External"
        mirrorRegistry = softwareSystem "Disconnected Mirror Registry" "Local container registry in air-gapped environment" "External"

        notebooks = softwareSystem "Notebooks" "Jupyter notebook workbench images (N-1 and deprecated)" "Internal RHOAI"
        distributedWorkloads = softwareSystem "Distributed Workloads" "Ray cluster images used by CodeFlare/KubeRay" "Internal RHOAI"
        trainer = softwareSystem "Trainer" "Training runtime images for distributed training" "Internal RHOAI"
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "Pipeline runtime images" "Internal RHOAI"

        operator -> rhoaiAdditionalImages "Reviews image list for disconnected deployment"
        mirroringTooling -> rhoaiAdditionalImages "Reads image manifest" "File read"
        mirroringTooling -> quayModh "Pulls upstream images" "HTTPS/443"
        mirroringTooling -> registryRHOAI "Pulls productized images" "HTTPS/443"
        mirroringTooling -> mirrorRegistry "Pushes mirrored images" "HTTPS/443"

        rhoaiAdditionalImages -> notebooks "References N-1 and deprecated workbench images"
        rhoaiAdditionalImages -> distributedWorkloads "References Ray cluster images"
        rhoaiAdditionalImages -> trainer "References training runtime images"
        rhoaiAdditionalImages -> dataSciencePipelines "References pipeline runtime images"
    }

    views {
        systemContext rhoaiAdditionalImages "SystemContext" {
            include *
            autoLayout
        }

        container rhoaiAdditionalImages "Containers" {
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
