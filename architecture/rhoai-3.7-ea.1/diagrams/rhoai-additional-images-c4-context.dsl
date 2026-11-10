workspace {
    model {
        relEng = person "RHOAI Release Engineering" "Maintains release metadata for RHOAI"

        additionalImages = softwareSystem "rhoai-additional-images" "Placeholder repository meant to list additional RHOAI images that component manifests don't reference. Contains only README.md on rhoai-3.7-ea.1." {
            readme = container "README.md" "States the repository's intent; only file in the repository" "Markdown"
        }

        konflux = softwareSystem "RHOAI Build / Release Tooling (Konflux)" "Builds the product bundle, related-images list and disconnected mirror set" "Internal RHOAI"
        github = softwareSystem "GitHub" "Hosts the repository" "External"

        relEng -> additionalImages "Would commit additional image list (intended; none present)" "HTTPS/443 git, TLS 1.2+"
        konflux -> additionalImages "Would read additional image references (intended; no consumer found)" "HTTPS/443 git, TLS 1.2+"
        additionalImages -> github "Hosted on"
    }

    views {
        systemContext additionalImages "SystemContext" {
            include *
            autoLayout
        }

        container additionalImages "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
        }
    }
}
