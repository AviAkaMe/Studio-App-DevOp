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
        DOCKER_REGISTRY = 'avit83'
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
                    // only run when Jenkinsfile, k8s/, or app/ changes
                    def diffCmd = """
               git rev-parse --verify HEAD^ >/dev/null 2>&1 \
               && git diff --name-only HEAD^ HEAD \
               || git show --pretty='' --name-only HEAD
            """
                    def changes = sh(script: diffCmd, returnStdout: true).trim()
                    def hasChanges = changes.readLines().any { line ->
                        line.startsWith('Jenkinsfile') ||
                        line.startsWith('k8s/')        ||
                        line.startsWith('app/')
                    }
                    if (!hasChanges) {
                        echo 'No relevant changes; skipping.'
                        currentBuild.result = 'NOT_BUILT'
                        error('No relevant changes')
                    }
                }
            }
        }

        stage('Lint & Test App') {
            agent any
            steps {
                dir('app') {
                    sh 'python3 -m venv venv'
                    sh '. venv/bin/activate && pip install --upgrade pip flake8 pytest'

                    // Lint
                    sh '. venv/bin/activate && flake8 . --exclude venv,node_modules'

                    // Only run npm/ESLint if package.json exists
                    script {
                        if (fileExists('package.json')) {
                            sh 'npm install'
                            sh 'npx eslint .'
        } else {
                            echo 'No package.json found; skipping npm install & ESLint'
                        }
                    }
                }
            }
        }

        stage('Build & Push Docker Images') {
            steps {
                dir('app') {
                    script {
                        docker.withRegistry('', DOCKER_CREDS) {
                            // build & push backend
                            def flaskImage = docker.build(
                      "${DOCKER_REGISTRY}/backend:${env.BUILD_NUMBER}",
                      'backend'
                    )
                            flaskImage.push()

                            // build & push frontend
                            def reactImage = docker.build(
                      "${DOCKER_REGISTRY}/frontend:${env.BUILD_NUMBER}",
                      'frontend'
                    )
                            reactImage.push()
                        }
                    }
                }
            }
        }

        stage('Deploy to Dev') {
            steps {
                // mount your secret kubeconfig file into $KUBECONFIG
                withCredentials([file(
      credentialsId: env.KUBECONFIG_CRED,
      variable: 'KUBECONFIG'
    )]) {
                    // wrap everything in a single shell block
                    sh '''
        echo ">>> Using kubeconfig at $KUBECONFIG"
        kubectl --kubeconfig="$KUBECONFIG" config view

        echo ">>> Checking namespace connectivity"
        kubectl --kubeconfig="$KUBECONFIG" get pods -n jenkins

        echo ">>> Applying deployment.yaml"
        kubectl --kubeconfig="$KUBECONFIG" apply -f k8s/deployment.yaml

        echo ">>> Waiting for rollout"
        kubectl --kubeconfig="$KUBECONFIG" rollout status deploy/test-backend
      '''
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
