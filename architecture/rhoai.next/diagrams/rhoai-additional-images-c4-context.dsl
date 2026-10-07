workspace {
    model {
        rhoaiAdditionalImages = softwareSystem "rhoai-additional-images" "Placeholder repository for tracking additional RHOAI container images not referenced in component manifests. Contains only README.md — no source code, no Dockerfiles, no deployment manifests." "Placeholder"

        rhoaiBuildSystem = softwareSystem "RHOAI Product Build System" "Builds and publishes container images for the RHOAI platform" "External"
        containerRegistry = softwareSystem "Container Image Registry" "Hosts built container images" "External"
        rhoaiPlatform = softwareSystem "RHOAI Platform" "Red Hat OpenShift AI platform distribution" "Internal"

        rhoaiBuildSystem -> containerRegistry "Builds & publishes additional images" "CI/CD"
        rhoaiPlatform -> containerRegistry "Pulls images for deployment" "HTTPS/443"
    }

    views {
        systemContext rhoaiAdditionalImages "SystemContext" {
            include *
            autoLayout
            description "rhoai-additional-images is an architecturally inert placeholder repository. It contains no deployable components — it exists solely for organizational image tracking."
        }

        styles {
            element "Placeholder" {
                background #f9f9f9
                color #999999
                shape RoundedBox
            }
            element "External" {
                background #999999
            }
            element "Internal" {
                background #7ed321
            }
        }
    }
}
