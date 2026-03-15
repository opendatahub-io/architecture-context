# Architecture Diagrams for RHOAI 3.2 Platform

Generated from: `architecture/rhoai-3.2/PLATFORM.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./platform-component.png) ([mmd](./platform-component.mmd)) - Complete platform architecture showing all 15 components organized by namespace
- [Data Flows](./platform-dataflow.png) ([mmd](./platform-dataflow.mmd)) - End-to-end ML workflow from development to production
- [Dependencies](./platform-dependencies.png) ([mmd](./platform-dependencies.mmd)) - Comprehensive dependency graph

### For Architects
- [C4 Context](./platform-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./platform-component.png) ([mmd](./platform-component.mmd)) - High-level platform architecture
- [Dependency Graph](./platform-dependencies.png) ([mmd](./platform-dependencies.mmd)) - Complete dependency mapping

### For Security Teams
- [Security Network Diagram (PNG)](./platform-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./platform-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./platform-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./platform-rbac.png) ([mmd](./platform-rbac.mmd)) - RBAC permissions and bindings

## Platform Overview

**Red Hat OpenShift AI (RHOAI) 3.2** is an enterprise-grade AI/ML platform built on OpenShift that provides end-to-end capabilities for the complete machine learning lifecycle.

### Platform Statistics
- **Total Components**: 15 operators/services
- **Namespaces**: 5 (control plane, applications, kubeflow, monitoring, user workspaces)
- **CRD API Groups**: 15+ 
- **External Dependencies**: 12+
- **Service Mesh**: Istio with mTLS STRICT for model serving
- **Authentication**: 7 patterns
- **GPU Support**: NVIDIA CUDA (12.6, 12.8), AMD ROCm (6.2-6.4), Intel Gaudi
- **FIPS Compliance**: All operators built with FIPS-enabled Go runtime and UBI9 base images

### Components

**Platform Control Plane:**
- RHODS Operator v1.6.0

**Application Services:**
- ODH Dashboard v1.21.0
- Model Registry b068597
- MLflow cd9ad05
- Feast 0.58.0
- TrustyAI a2e891d
- Llama Stack v0.5.0

**Kubeflow Components:**
- Notebook Controller 1.27.0
- Training Operator 1.9.0
- Trainer 2.1.0
- KubeRay 72c07895

**Model Serving:**
- KServe 27c1e99b7
- ODH Model Controller v1.27.0

**ML Pipelines:**
- Data Science Pipelines Operator 9d94973

**Monitoring:**
- Prometheus & Alertmanager

## Diagram Descriptions

See [PLATFORM.md](../PLATFORM.md) for complete architecture documentation.
