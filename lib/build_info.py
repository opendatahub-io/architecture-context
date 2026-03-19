"""Build and deployment metadata extraction from RHOAI-Build-Config."""

import yaml
from pathlib import Path
from typing import Dict, List, Optional
from dataclasses import dataclass


@dataclass
class BuildInfo:
    """Build and deployment metadata extracted from RHOAI-Build-Config."""

    ocp_versions: List[str]  # Supported OCP release versions (e.g. ["v4.19", "v4.20"])
    product_version: str  # Product version from bundle patch (e.g. "3.4.0-ea.1")
    related_images: List[str]  # RELATED_IMAGE env var names from bundle patch
    image_count: int  # Total number of container images shipped
    supported_architectures: List[str]  # CPU architectures (e.g. ["amd64", "arm64"])
    min_kube_version: str  # Minimum Kubernetes version (e.g. "1.25.0")
    operator_features: Dict[str, str]  # OLM feature annotations (e.g. {"fips-compliant": "true"})
    image_to_repo: Dict[str, str]  # Container image name -> source git repo URL


def get_build_info(checkouts_dir: Path) -> Optional[BuildInfo]:
    """
    Extract build and deployment metadata from RHOAI-Build-Config.

    Reads:
    - config/build-config.yaml (OCP versions)
    - bundle/bundle-patch.yaml (product version, shipped images)
    - bundle/csv-patch.yaml (architectures, features, min kube version)

    Args:
        checkouts_dir: Path to the org checkout directory
                       (e.g. checkouts/red-hat-data-services.rhoai-3.4-ea.1)

    Returns:
        BuildInfo with extracted metadata, or None if RHOAI-Build-Config is not present.
    """
    build_config_dir = checkouts_dir / "RHOAI-Build-Config"
    if not build_config_dir.exists():
        return None

    ocp_versions = get_supported_ocp_versions(checkouts_dir)

    # Parse bundle-patch.yaml for product version and related images
    product_version = ""
    related_images = []
    bundle_patch_path = build_config_dir / "bundle" / "bundle-patch.yaml"
    if bundle_patch_path.exists():
        try:
            data = yaml.safe_load(bundle_patch_path.read_text())
            patch = data.get("patch", {})
            product_version = str(patch.get("version", ""))
            for img in patch.get("relatedImages", []):
                name = img.get("name", "")
                if name:
                    related_images.append(name)
        except Exception:
            pass

    # Parse csv-patch.yaml for architectures, features, min kube version
    supported_architectures = []
    min_kube_version = ""
    operator_features = {}
    csv_patch_path = build_config_dir / "bundle" / "csv-patch.yaml"
    if csv_patch_path.exists():
        try:
            data = yaml.safe_load(csv_patch_path.read_text())
            metadata = data.get("metadata", {})

            # Extract supported architectures from labels
            # e.g. "operatorframework.io/arch.amd64: supported"
            for label, value in metadata.get("labels", {}).items():
                if label.startswith("operatorframework.io/arch.") and value == "supported":
                    arch = label.split(".")[-1]
                    supported_architectures.append(arch)

            # Extract operator feature annotations
            # e.g. "features.operators.openshift.io/fips-compliant: true"
            for annotation, value in metadata.get("annotations", {}).items():
                if annotation.startswith("features.operators.openshift.io/"):
                    feature = annotation.split("/")[-1]
                    operator_features[feature] = str(value)

            # Extract min kube version from spec
            min_kube_version = str(data.get("spec", {}).get("minKubeVersion", ""))
        except Exception:
            pass

    # Find and parse snapshot-components YAML for image->repo mapping
    # Path pattern: release/*/stage/*/stage-release-*/snapshot-components/*.yaml
    image_to_repo = {}
    release_dir = build_config_dir / "release"
    if release_dir.exists():
        snapshot_files = sorted(release_dir.glob(
            "*/stage/*/stage-release-*/snapshot-components/snapshot-components-*.yaml"
        ))
        if snapshot_files:
            # Use the last (most recent) snapshot file
            try:
                data = yaml.safe_load(snapshot_files[-1].read_text())
                for comp in data.get("spec", {}).get("components", []):
                    image = comp.get("containerImage", "")
                    repo_url = comp.get("source", {}).get("git", {}).get("url", "")
                    if image and repo_url:
                        # Use image name without tag/digest as key
                        image_name = image.split("@")[0].split(":")[-1] if "@" in image else image
                        # Extract repo name from URL
                        repo_name = repo_url.rstrip("/").split("/")[-1]
                        image_to_repo[image_name] = repo_name
            except Exception:
                pass

    return BuildInfo(
        ocp_versions=ocp_versions,
        product_version=product_version,
        related_images=related_images,
        image_count=len(related_images),
        supported_architectures=sorted(supported_architectures),
        min_kube_version=min_kube_version,
        operator_features=operator_features,
        image_to_repo=image_to_repo,
    )


def format_build_info_context(build_info: BuildInfo) -> str:
    """
    Format BuildInfo into a string suitable for injection into agent prompts.

    Args:
        build_info: Extracted build metadata

    Returns:
        Multi-line string with build context for prompts
    """
    lines = []
    if build_info.product_version:
        lines.append(f"Product version: {build_info.product_version}")
    if build_info.ocp_versions:
        lines.append(f"Supported OCP versions: {', '.join(build_info.ocp_versions)}")
    if build_info.supported_architectures:
        lines.append(f"Supported CPU architectures: {', '.join(build_info.supported_architectures)}")
    if build_info.min_kube_version:
        lines.append(f"Minimum Kubernetes version: {build_info.min_kube_version}")
    if build_info.image_count:
        lines.append(f"Total shipped container images: {build_info.image_count}")
    if build_info.operator_features:
        enabled = [f for f, v in build_info.operator_features.items() if v == "true"]
        disabled = [f for f, v in build_info.operator_features.items() if v == "false"]
        if enabled:
            lines.append(f"Enabled operator features: {', '.join(sorted(enabled))}")
        if disabled:
            lines.append(f"Disabled operator features: {', '.join(sorted(disabled))}")
    if build_info.image_to_repo:
        # Summarize: group by repo, show count of images per repo
        from collections import Counter
        repo_counts = Counter(build_info.image_to_repo.values())
        lines.append(f"Source repositories producing container images ({len(repo_counts)} repos -> {len(build_info.image_to_repo)} images):")
        for repo, count in sorted(repo_counts.items()):
            lines.append(f"  {repo}: {count} image(s)")
    return "\n".join(lines)


def get_supported_ocp_versions(checkouts_dir: Path) -> List[str]:
    """
    Extract supported OCP versions from RHOAI-Build-Config/config/build-config.yaml.

    Args:
        checkouts_dir: Path to the org checkout directory
                       (e.g. checkouts/red-hat-data-services.rhoai-3.4-ea.1)

    Returns:
        List of OCP version strings (e.g. ["v4.19", "v4.20", "v4.21"]),
        or empty list if the file is not found or cannot be parsed.
    """
    build_config_path = checkouts_dir / "RHOAI-Build-Config" / "config" / "build-config.yaml"
    if not build_config_path.exists():
        return []

    try:
        data = yaml.safe_load(build_config_path.read_text())
        versions = data.get("config", {}).get("supported-ocp-versions", {}).get("release", [])
        return [str(v) for v in versions]
    except Exception:
        return []
