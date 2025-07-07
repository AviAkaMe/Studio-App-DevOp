pipeline {
    agent any

    parameters {
        string(name: 'CODE_REPO_URL', defaultValue: 'https://github.com/myorg/app.git', description: 'Git URL of the application repository')
        string(name: 'CODE_REPO_BRANCH', defaultValue: 'main', description: 'Branch of the application repository')
        booleanParam(name: 'PROMOTE_TO_PROD', defaultValue: false, description: 'Deploy to production after dev')
    }

    environment {
        DOCKER_REGISTRY = 'docker.io/mycompany'
        DOCKER_CREDS = 'docker-hub-creds'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                dir('app') {
                    git url: params.CODE_REPO_URL, branch: params.CODE_REPO_BRANCH
                }
            }
        }

        stage('Lint') {
            steps {
                dir('app') {
                    sh 'flake8 .'
                    sh 'npm install'
                    sh 'npx eslint .'
                }
            }
        }

        stage('Test') {
            steps {
                dir('app') {
                    sh 'pytest'
                }
            }
        }

        stage('Build & Push Docker Images') {
            steps {
                dir('app') {
                    script {
                        def flaskImage = docker.build("${DOCKER_REGISTRY}/flask-app:${env.BUILD_NUMBER}", 'flask/Dockerfile')
                        def reactImage = docker.build("${DOCKER_REGISTRY}/react-app:${env.BUILD_NUMBER}", 'react/Dockerfile')
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
                sh 'kubectl apply -k manifests/overlays/dev'
                sh 'kubectl -n studio-app-dev rollout status deploy/flask'
                sh 'kubectl -n studio-app-dev rollout status deploy/react'
                dir('app') {
                    sh 'pytest -m smoke'
                }
            }
        }

        stage('Promote to Prod') {
            when {
                expression { return params.PROMOTE_TO_PROD }
            }
            steps {
                input message: 'Deploy to production?'
                sh 'kubectl apply -k manifests/overlays/prod'
                sh 'kubectl -n studio-app-prod rollout status deploy/flask'
                sh 'kubectl -n studio-app-prod rollout status deploy/react'
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}