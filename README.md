# DevOps Pipeline Setup

This repository contains the Jenkins pipeline and Kubernetes manifests for the Studio App.

## Jenkins Configuration

1. **Docker Hub Credentials**
   - Create a Jenkins credential of type *Username with password*.
   - ID: `docker-hub-creds`
   - The credential must have permission to push images to `docker.io/mycompany`.

2. **Kubeconfig Credential**
   - Create a Jenkins credential of type *Secret file*.
   - ID: `jenkins-kubeconfig`
   - The file should contain a kubeconfig for the `jenkins` service account with RBAC permissions defined in `manifests/rbac`.

3. **Multibranch Pipeline**
   - Create a Multibranch Pipeline or GitHub webhook-triggered job pointing to this repository.
   - Ensure the job uses the `Jenkinsfile` in the repository root.

Once configured, Jenkins will build, test and deploy the application using the provided credentials.