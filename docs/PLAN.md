# Phase 1: Kind Cluster + Jenkins Installation - Plan

## Completed Steps

- [x] Created `kind/cluster-config.yaml` - Kind cluster configuration
- [x] Created `jenkins/helm-values.yaml` - Jenkins Helm chart values with JCasC
- [x] Created `jenkins/jcasc.yaml` - JCasC configuration (reference)
- [x] Created `Makefile` - Main entry point with targets: install, cluster, jenkins, password, cleanup
- [x] Created `test-pipeline.groovy` - Test pipeline for K8s agents

## Goal
Automate single-node K8s cluster + Jenkins deployment (~3 hours)

## Repository Structure
```
jenkins-kind-poc/
├── Makefile                      # Main entry point (make install, make cleanup, etc.)
├── PLAN.md                      # This file
├── README.md                    # Project documentation
├── docs/PLAN.md
├── kind/
│   └── cluster-config.yaml      # Kind cluster configuration
├── jenkins/
│   ├── helm-values.yaml         # Jenkins Helm chart values
│   └── jcasc.yaml              # JCasC configuration (optional reference)
└── test-pipeline.groovy        # Test pipeline for K8s agents
```

## Implementation Steps

### Step 1: Kind Cluster Configuration
- **File**: `kind/cluster-config.yaml`
- Single-node cluster (control-plane + worker)
- Port mapping: containerPort 30080 → hostPort 8080
- Persistent volumes enabled via kubeadmConfigPatches

### Step 2: Jenkins Helm Values
- **File**: `jenkins/helm-values.yaml`
- NodePort service on port 30080
- Required plugins: kubernetes, workflow-aggregator, git, configuration-as-code
- JCasC configuration for K8s cloud connection
- 8Gi persistent storage
- ServiceAccount creation

### Step 3: JCasC Configuration (Reference)
- **File**: `jenkins/jcasc.yaml`
- Standalone JCasC YAML for reference
- Configures: systemMessage, numExecutors, Kubernetes cloud, agent templates

### Step 4: Makefile
- **File**: `Makefile`
- Orchestrates all deployment steps
- Targets: install, cluster, jenkins, password, cleanup

### Step 5: Test Pipeline
- **File**: `test-pipeline.groovy`
- Sample pipeline to verify K8s agents work

### Step 6: README
- **File**: `README.md`
- Documentation for the project
- Quick start guide and architecture overview

## Prerequisites
- Docker installed
- Kind installed
- Helm installed
- kubectl installed

## Usage

```bash
# Install everything (Kind cluster + Jenkins)
make install

# Or run steps separately
make cluster      # Create Kind cluster only
make jenkins     # Install Jenkins on existing cluster

# Get admin password
make password

# Open browser
http://localhost:8080

# Run test pipeline (copy contents from test-pipeline.groovy)

# Cleanup
make cleanup
```

## Validation Checklist
- [x] Kind cluster running (1 node)
- [x] Jenkins pod running
- [x] Access localhost:8080
- [x] Login works (admin password)
- [x] K8s cloud configured (via JCasC)
- [ ] Test pipeline runs successfully (manual: copy test-pipeline.groovy content to Jenkins UI)
- [ ] Agent pod spawns in jenkins namespace (manual: run test pipeline in Jenkins UI)

## What This Demonstrates
- **Automation**: Single script deploys everything
- **K8s knowledge**: Kind, services, StatefulSets
- **Jenkins expertise**: Helm, JCasC, K8s plugin
- **Production patterns**: Persistent storage, RBAC

## Timeline
- Scripts creation: 1.5h
- Testing: 1h
- Documentation: 0.5h
- **Total: ~3 hours**

## Next Phase Ideas
After this works, add:
- Basic CI/CD pipeline (build + deploy app)
- Security scanning (Trivy)
- Monitoring (Prometheus)
