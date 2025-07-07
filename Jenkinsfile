// Jenkins pipeline that builds, tests and deploys the Studio application.
pipeline {
    // Run on any available Jenkins agent
    agent any

    // Automatically start a build when changes are pushed to this repo
    triggers {
        // GitHub webhooks invoke this when a push occurs
        githubPush()
    }

    // Parameters allow the job to be reused for different repos/branches
    parameters {
        // URL of the application source repository
        string(name: 'CODE_REPO_URL', defaultValue: 'https://github.com/myorg/app.git', description: 'Git URL of the application repository')
        // Branch name to build from
        string(name: 'CODE_REPO_BRANCH', defaultValue: 'main', description: 'Branch of the application repository')
        // If true, we will also deploy to production
        booleanParam(name: 'PROMOTE_TO_PROD', defaultValue: false, description: 'Deploy to production after dev')
    }

    // Global environment variables used in the pipeline
    environment {
        // Where Docker images will be stored
        DOCKER_REGISTRY = 'docker.io/mycompany'
        // Jenkins credential ID for Docker Hub
        DOCKER_CREDS = 'docker-hub-creds'
        // Jenkins credential ID that stores the kubeconfig file
        KUBECONFIG_CRED = 'jenkins-kubeconfig'
    }

    stages {
        stage('Checkout') {
            steps {
                // Checkout this DevOps repository
                checkout scm
                // Also fetch the application source into the 'app' directory
                dir('app') {
                    git url: params.CODE_REPO_URL, branch: params.CODE_REPO_BRANCH
                }
            }
        }

        stage('Detect DevOps Changes') {
            steps {
                script {
                    // Check if the commit touched the Jenkinsfile or manifests directory
                    def diffCmd = "git rev-parse --verify HEAD^ >/dev/null 2>&1 && git diff --name-only HEAD^ HEAD || git show --pretty='' --name-only HEAD"
                    def changes = sh(script: diffCmd, returnStdout: true).trim()
                    if (!changes.matches('(Jenkinsfile|manifests/).*')) {
                        echo 'No changes to manifests or Jenkinsfile detected. Skipping build.'
                        currentBuild.result = 'NOT_BUILT'
                        // Abort the job early when no relevant files changed
                        error('No relevant changes')
                    }
                }
            }
        }

        stage('Lint') {
            steps {
                // Run code quality checks for both Python and JavaScript
                dir('app') {
                    sh 'flake8 .'
                    sh 'npm install'
                    sh 'npx eslint .'
                }
            }
        }

        stage('Test') {
            steps {
                // Execute the application's unit tests
                dir('app') {
                    sh 'pytest'
                }
            }
        }

        stage('Build & Push Docker Images') {
            steps {
                dir('app') {
                    script {
                        // Build container images for the backend and frontend
                        def flaskImage = docker.build("${DOCKER_REGISTRY}/flask-app:${env.BUILD_NUMBER}", 'flask/Dockerfile')
                        def reactImage = docker.build("${DOCKER_REGISTRY}/react-app:${env.BUILD_NUMBER}", 'react/Dockerfile')
                        // Authenticate to the registry and push the images
                        docker.withRegistry('', DOCKER_CREDS) {
                            flaskImage.push()
                            reactImage.push()
                        }
                    }
                }
            }
        }

        stage('Deploy to Dev') {
            steps {
                // Use the Kubernetes credentials to deploy the app to the development namespace
                withCredentials([file(credentialsId: env.KUBECONFIG_CRED, variable: 'KUBECONFIG')]) {
                    sh 'kubectl apply -k manifests/overlays/dev'
                    // Wait for the deployments to finish rolling out
                    sh 'kubectl -n studio-app-dev rollout status deploy/flask'
                    sh 'kubectl -n studio-app-dev rollout status deploy/react'
                }
                // Run a small set of smoke tests against the dev environment
                dir('app') {
                    sh 'pytest -m smoke'
                }
            }
        }

        stage('Promote to Prod') {
            // Only run when the parameter is enabled
            when {
                expression { return params.PROMOTE_TO_PROD }
            }
            steps {
                // Require manual confirmation before impacting production
                input message: 'Deploy to production?'
                withCredentials([file(credentialsId: env.KUBECONFIG_CRED, variable: 'KUBECONFIG')]) {
                    // Apply the production overlay and wait for rollouts
                    sh 'kubectl apply -k manifests/overlays/prod'
                    sh 'kubectl -n studio-app-prod rollout status deploy/flask'
                    sh 'kubectl -n studio-app-prod rollout status deploy/react'
                }
            }
        }
    }

    post {
        // Always clean the workspace so future builds start fresh
        always {
            cleanWs()
        }
    }
}