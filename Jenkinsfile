pipeline {
    agent any

    // trigger on pushes to this Config repo
    triggers {
        githubPush()
    }

    parameters {
        // app-code Git URL:
        string(
          name: 'CODE_REPO_URL',
          defaultValue: 'https://github.com/AviAkaMe/Studio-App-Code.git',
          description: 'Git URL of the application repository'
        )
        string(
          name: 'CODE_REPO_BRANCH',
          defaultValue: 'main',
          description: 'Branch of the application repository'
        )
        booleanParam(
          name: 'PROMOTE_TO_PROD',
          defaultValue: false,
          description: 'Deploy to production after dev'
        )
    }

    environment {
        DOCKER_REGISTRY = 'docker.io/avit83'
        DOCKER_CREDS    = 'docker-hub-creds'
        KUBECONFIG_CRED = 'jenkins-kubeconfig'
    }

    stages {
        stage('Checkout DevOps & App Code') {
            steps {
                // grab this Config repo
                checkout scm

                // grab actual app source
                dir('app') {
                    git url: params.CODE_REPO_URL,
                        branch: params.CODE_REPO_BRANCH
                }
            }
        }

        stage('Detect DevOps Changes') {
            steps {
                script {
                    // only run on Jenkinsfile or k8s/ changes
                    def diffCmd = """
                       git rev-parse --verify HEAD^ >/dev/null 2>&1 \
                       && git diff --name-only HEAD^ HEAD \
                       || git show --pretty='' --name-only HEAD
                    """
                    def changes = sh(script: diffCmd, returnStdout: true).trim()
                    if (!changes.matches('(Jenkinsfile|k8s/).*')) {
                        echo 'No DevOps changes; skipping.'
                        currentBuild.result = 'NOT_BUILT'
                        error('No relevant changes')
                    }
                }
            }
        }

        stage('Lint & Test App') {
            steps {
                dir('app') {
                    sh 'flake8 .'
                    sh 'npm install'
                    sh 'npx eslint .'
                    sh 'pytest'
                }
            }
        }

        stage('Build & Push Docker Images') {
            steps {
                dir('app') {
                    script {
                        // build with BUILD_NUMBER for immutability
                        def flaskImage = docker.build(
                          "${DOCKER_REGISTRY}/backend:${env.BUILD_NUMBER}",
                          'backend'
                        )
                        def reactImage = docker.build(
                          "${DOCKER_REGISTRY}/frontend:${env.BUILD_NUMBER}",
                          'frontend'
                        )

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
                withCredentials([file(
                  credentialsId: env.KUBECONFIG_CRED,
                  variable: 'KUBECONFIG'
                )]) {
                    // apply your k8s YAML from Config repo
                    sh 'kubectl apply -f k8s/deployment.yaml'
                    sh 'kubectl rollout status deploy/test-backend'
                }
                // optional smoke tests against dev
                dir('app') {
                    sh 'pytest -m smoke'
                }
            }
        }

        stage('Promote to Prod') {
            when { expression { params.PROMOTE_TO_PROD } }
            steps {
                input 'Deploy to production?'
                withCredentials([file(
                  credentialsId: env.KUBECONFIG_CRED,
                  variable: 'KUBECONFIG'
                )]) {
                    sh 'kubectl apply -f k8s/deployment-prod.yaml'
                    sh 'kubectl rollout status deploy/test-backend -n production' 
                }
            }
        }
    }

    post {
        always { cleanWs() }
    }
}