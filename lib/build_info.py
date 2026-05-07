"""Build and deployment metadata extraction from RHOAI-Build-Config."""

import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional

import yaml


@dataclass
class BuildInfo:
    """Build and deployment metadata extracted from RHOAI-Build-Config."""

    ocp_versions: List[str]  # Supported OCP release versions (e.g. ["v4.19", "v4.20"])
    product_version: str  # Product version from bundle patch (e.g. "3.4.0-ea.1")
    related_images: List[str]  # RELATED_IMAGE env var names from bundle patch
    image_count: int  # Total number of container images shipped
    supported_architectures: List[str]  # CPU architectures (e.g. ["amd64", "arm64"])
    min_kube_version: str  # Minimum Kubernetes version (e.g. "1.25.0")
    # OLM feature annotations (e.g. {"fips-compliant": "true"})
    operator_features: Dict[str, str]
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
                if (
                    label.startswith("operatorframework.io/arch.")
                    and value == "supported"
                ):
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
                        image_name = (
                            image.split("@")[0].split(":")[-1]
                            if "@" in image
                            else image
                        )
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
        archs = ", ".join(build_info.supported_architectures)
        lines.append(
            f"Supported CPU architectures: {archs}"
        )
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
        num_repos = len(repo_counts)
        num_images = len(build_info.image_to_repo)
        lines.append(
            f"Source repositories producing container images"
            f" ({num_repos} repos -> {num_images} images):"
        )
        for repo, count in sorted(repo_counts.items()):
            lines.append(f"  {repo}: {count} image(s)")
    return "\n".join(lines)


def get_full_build_info(checkouts_dir: Path) -> Optional[dict]:
    """
    Extract complete build and image inventory from RHOAI-Build-Config.

    Parses all bundle source files, correlates image data across them,
    and returns a JSON-serializable dict with the full image inventory.

    Returns None when the bundle/ directory doesn't exist (e.g. next branch).
    """
    build_config_dir = checkouts_dir / "RHOAI-Build-Config"
    if not build_config_dir.exists():
        return None

    bundle_dir = build_config_dir / "bundle"
    if not bundle_dir.exists():
        return None

    csv_path = bundle_dir / "manifests" / "rhods-operator.clusterserviceversion.yaml"
    if not csv_path.exists():
        return None

    # --- Reuse existing parsers for metadata ---
    basic = get_build_info(checkouts_dir)
    ocp_versions = get_supported_ocp_versions(checkouts_dir)

    product_version = basic.product_version if basic else ""
    supported_architectures = basic.supported_architectures if basic else []
    min_kube_version = basic.min_kube_version if basic else ""
    operator_features = basic.operator_features if basic else {}

    # --- Parse bundle_build_args.map for source repos + commits ---
    build_args: Dict[str, str] = {}
    args_path = bundle_dir / "bundle_build_args.map"
    if args_path.exists():
        for line in args_path.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            build_args[key.strip()] = value.strip()

    # --- Parse bundle-patch.yaml for staging (quay.io) refs ---
    staging_refs: Dict[str, str] = {}
    bundle_patch_path = bundle_dir / "bundle-patch.yaml"
    if bundle_patch_path.exists():
        try:
            data = yaml.safe_load(bundle_patch_path.read_text())
            for img in data.get("patch", {}).get("relatedImages", []):
                name = img.get("name", "")
                value = img.get("value", "")
                if name and value:
                    staging_refs[name] = value
        except Exception:
            pass

    # --- Parse additional-images-patch.yaml to identify infrastructure images ---
    infrastructure_names: set = set()
    additional_path = bundle_dir / "additional-images-patch.yaml"
    if additional_path.exists():
        try:
            data = yaml.safe_load(additional_path.read_text())
            for img in data.get("additionalImages", []):
                name = img.get("name", "")
                if name:
                    infrastructure_names.add(name)
        except Exception:
            pass

    # --- Parse CSV for production (registry.redhat.io) RELATED_IMAGE refs ---
    csv_images: List[dict] = []
    try:
        csv_data = yaml.safe_load(csv_path.read_text())
        containers = (
            csv_data.get("spec", {})
            .get("install", {})
            .get("spec", {})
            .get("deployments", [])
        )
        for deployment in containers:
            for container in (
                deployment.get("spec", {})
                .get("template", {})
                .get("spec", {})
                .get("containers", [])
            ):
                for env in container.get("env", []):
                    name = env.get("name", "")
                    value = env.get("value", "")
                    if name.startswith("RELATED_IMAGE_") and value:
                        csv_images.append({"name": name, "production_ref": value})
    except Exception:
        pass

    # --- Correlate across files ---
    images = []
    seen_names: set = set()

    for entry in csv_images:
        name = entry["name"]
        if name in seen_names:
            continue
        seen_names.add(name)

        production_ref = entry["production_ref"]

        # Extract repository from production ref
        # e.g. "registry.redhat.io/rhoai/img@sha256:..."
        repository = ""
        ref_match = re.match(r'^[^/]+/(.+?)[@:]', production_ref)
        if ref_match:
            repository = ref_match.group(1)

        # Match staging ref by RELATED_IMAGE name
        staging_ref = staging_refs.get(name, "")

        # Derive build-args key stem: RELATED_IMAGE_ODH_DASHBOARD_IMAGE -> ODH_DASHBOARD
        stem = name
        if stem.startswith("RELATED_IMAGE_"):
            stem = stem[len("RELATED_IMAGE_"):]
        if stem.endswith("_IMAGE"):
            stem = stem[:-len("_IMAGE")]

        source_repo = build_args.get(f"{stem}_GIT_URL", "")
        source_commit = build_args.get(f"{stem}_GIT_COMMIT", "")

        category = "infrastructure" if name in infrastructure_names else "component"

        image_entry = {
            "name": name,
            "repository": repository,
            "production_ref": production_ref,
            "category": category,
        }
        if staging_ref:
            image_entry["staging_ref"] = staging_ref
        if source_repo:
            image_entry["source_repo"] = source_repo
        if source_commit:
            image_entry["source_commit"] = source_commit

        images.append(image_entry)

    return {
        "product_version": product_version,
        "supported_ocp_versions": ocp_versions,
        "supported_architectures": supported_architectures,
        "min_kube_version": min_kube_version,
        "operator_features": operator_features,
        "images": images,
    }


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
    build_config_path = (
        checkouts_dir
        / "RHOAI-Build-Config"
        / "config"
        / "build-config.yaml"
    )
    if not build_config_path.exists():
        return []

    try:
        data = yaml.safe_load(build_config_path.read_text())
        versions = (
            data.get("config", {})
            .get("supported-ocp-versions", {})
            .get("release", [])
        )
        return [str(v) for v in versions]
    except Exception:
        return []
