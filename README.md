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

## CI/CD Triggers

### Code Repository Webhook

Create a GitHub webhook in the application repository so pushes to `main` trigger this pipeline. The helper script `scripts/setup_code_repo_webhook.sh` can be used:

```bash
./scripts/setup_code_repo_webhook.sh <github-token> <owner> <repo> https://jenkins.example.com/github-webhook/
```

### DevOps Repository Builds

This repository contains the deployment manifests and pipeline definition. Jenkins is configured to rebuild when files under `manifests/` or the `Jenkinsfile` change. The `Detect DevOps Changes` stage in the pipeline exits early when no such changes are detected.