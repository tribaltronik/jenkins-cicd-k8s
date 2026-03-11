# Jenkins on Kind - Troubleshooting Context

## Overview
This document captures the troubleshooting steps taken to get Jenkins running on a Kind (Kubernetes in Docker) cluster.

## Initial State
- Kind cluster `jenkins` already existed
- Jenkins pod was in `CrashLoopBackOff` state with 27+ restarts

## Root Causes Identified

### 1. JCasC Configuration Conflict
**Error:** `ConfiguratorConflictException` - conflicting configuration between default JCasC and custom config

**Cause:** The Jenkins Helm chart includes a default JCasC config (`jenkins-jenkins-jcasc-config` ConfigMap) that conflicted with the custom `numExecutors: 0` setting in `helm-values.yaml`.

**Fix:** Added `JCasC.defaultConfig: false` to disable the default configuration.

### 2. Incomplete JCasC Configuration
**Error:** `UnknownConfiguratorException: No configurator for the following root elements: clouds`

**Cause:** The custom JCasC config was missing required `securityRealm` and `authorizationStrategy` sections. The Kubernetes plugin wasn't initialized when JCasC tried to configure clouds.

**Fix:** Added complete security configuration:
```yaml
securityRealm:
  local:
    allowsSignup: false
    users:
      - id: "admin"
        password: "admin"
authorizationStrategy:
  loggedInUsersCanDoAnything:
    allowAnonymousRead: false
```

### 3. Plugin Version Conflicts
**Error:** Plugin dependency failures with messages like "Plugin is missing: commons-lang3-api"

**Cause:** Explicitly specifying plugin versions that don't exist or aren't compatible (e.g., `workflow-api:1296.v9e8337a_24d32` returned 404).

**Fix:** Removed explicit versions - let the Helm chart resolve compatible versions automatically.

## Final Working Configuration

### helm-values.yaml
```yaml
controller:
  servicePort: 8080
  serviceType: NodePort
  nodePort: 30080
  
  installPlugins:
    - kubernetes
    - workflow-aggregator
    - git
    - configuration-as-code
  
  installLatestSpecified: false
  
  admin:
    username: admin
    password: admin
  
  JCasC:
    defaultConfig: false
    configScripts:
      jenkins: |
        jenkins:
          systemMessage: "Jenkins on Kind - Platform PoC"
          numExecutors: 0
          mode: NORMAL
          securityRealm:
            local:
              allowsSignup: false
              users:
                - id: "admin"
                  password: "admin"
                  name: "Admin"
          authorizationStrategy:
            loggedInUsersCanDoAnything:
              allowAnonymousRead: false
          clouds:
            - kubernetes:
                name: "kubernetes"
                serverUrl: "https://kubernetes.default"
                namespace: "jenkins"
                jenkinsUrl: "http://jenkins:8080"
                jenkinsTunnel: "jenkins-agent:50000"
                templates:
                  - name: "default"
                    namespace: "jenkins"
                    label: "jenkins-agent"
                    containers:
                      - name: "jnlp"
                        image: "jenkins/inbound-agent:latest"
                        alwaysPullImage: false
                        workingDir: "/home/jenkins/agent"
                        ttyEnabled: true
                        resourceRequestCpu: "100m"
                        resourceRequestMemory: "256Mi"

persistence:
  enabled: true
  size: 8Gi

serviceAccount:
  create: true
  name: jenkins
```

## Key Takeaways

1. **Always disable default JCasC** when providing custom JCasC config: `JCasC.defaultConfig: false`

2. **Complete security config required**: JCasC requires full securityRealm and authorizationStrategy when using custom config

3. **Don't pin plugin versions**: Let the Helm chart resolve compatible versions to avoid 404s

4. **Plugin loading order matters**: kubernetes plugin must be loaded before JCasC tries to configure clouds

## Access
- URL: http://localhost:8080
- Username: admin
- Password: admin

## Commands Used
```bash
# Reinstall Jenkins after config changes
helm uninstall jenkins -n jenkins
helm install jenkins jenkins/jenkins -n jenkins -f jenkins/helm-values.yaml

# Check pod status
kubectl get pods -n jenkins

# Get logs
kubectl logs jenkins-0 -n jenkins -c jenkins
kubectl logs jenkins-0 -n jenkins -c jenkins --previous

# Get admin password
kubectl exec -n jenkins jenkins-0 -- cat /run/secrets/additional/chart-admin-password
```
