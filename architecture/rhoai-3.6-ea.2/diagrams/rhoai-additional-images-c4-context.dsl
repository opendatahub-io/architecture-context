workspace {
    model {
        releaseEngineer = person "Release Engineer" "Maintains digest-pinned image references for RHOAI disconnected deployments"

        rhoaiAdditionalImages = softwareSystem "rhoai-additional-images" "Declarative YAML catalog of 47 digest-pinned container images for disconnected RHOAI mirroring" {
            manifest = container "rhoai-disconnected-images.yaml" "YAML list of digest-pinned image references across 5 categories" "YAML Data File"
        }

        quayModh = softwareSystem "quay.io/modh" "Community container registry hosting FMS HF Tuning and Ray images" "External Registry"
        registryRedHat = softwareSystem "registry.redhat.io/rhoai" "Red Hat product container registry hosting notebook, pipeline, and training images" "External Registry"
        mirroringTooling = softwareSystem "Mirroring Tooling" "oc mirror or Quay mirror registry for disconnected image synchronization" "Tooling"
        disconnectedRegistry = softwareSystem "Disconnected Mirror Registry" "Air-gapped registry serving RHOAI installations" "Internal"

        notebooks = softwareSystem "Notebooks" "RHOAI notebook workbench images (Jupyter, Code Server, TrustYAI, LLM Compressor)" "Internal RHOAI"
        pipelines = softwareSystem "Data Science Pipelines" "RHOAI pipeline runtime images (Minimal, Data Science, PyTorch, TensorFlow)" "Internal RHOAI"
        training = softwareSystem "Training Runtimes" "RHOAI training runtime images (CUDA, ROCm, CPU)" "Internal RHOAI"
        ray = softwareSystem "Distributed Workloads" "Ray distributed compute images with CUDA and ROCm accelerator variants" "Internal RHOAI"
        fmsTuning = softwareSystem "FMS HF Tuning" "Fine-tuning runtime image" "Internal RHOAI"

        releaseEngineer -> rhoaiAdditionalImages "Updates digest-pinned image references"
        mirroringTooling -> rhoaiAdditionalImages "Reads image manifest" "File read"
        mirroringTooling -> quayModh "Pulls community images" "HTTPS/443"
        mirroringTooling -> registryRedHat "Pulls productized images" "HTTPS/443"
        mirroringTooling -> disconnectedRegistry "Pushes mirrored images" "HTTPS/443"

        rhoaiAdditionalImages -> notebooks "References workbench images" "Image digest"
        rhoaiAdditionalImages -> pipelines "References pipeline runtime images" "Image digest"
        rhoaiAdditionalImages -> training "References training runtime images" "Image digest"
        rhoaiAdditionalImages -> ray "References Ray compute images" "Image digest"
        rhoaiAdditionalImages -> fmsTuning "References fine-tuning image" "Image digest"
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
            element "External Registry" {
                background #f5a623
                shape Cylinder
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Tooling" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #dae8fc
            }
        }
    }
}
