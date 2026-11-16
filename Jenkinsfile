pipeline {
    agent any

    environment {
        // Docker Hub credentials (configure in Jenkins Credentials)
        DOCKERHUB_CREDS = credentials('dockerhub-creds')
        // Kubernetes config (configure in Jenkins Credentials as secret file)
        KUBECONFIG_CREDS = credentials('kubeconfig')
        // App details
        APP_NAME = "flask-app"
        DOCKER_IMAGE = "your-dockerhub-username/${APP_NAME}"
        // Kubernetes namespace
        K8S_NAMESPACE = "default"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh '''
                    echo "Building Flask app..."
                    # No build step needed for Python, but you could add linting here
                    # python -m py_compile app.py
                '''
            }
        }

        stage('Unit Tests') {
            steps {
                sh '''
                    echo "Running tests..."
                    # Add your test commands here
                    # python -m pytest tests/ -v
                '''
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    // Get git commit short hash for tagging
                    def commitHash = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    def imageTag = "${commitHash}-${BUILD_NUMBER}"
                    env.IMAGE_TAG = imageTag
                    
                    // Build Docker image
                    sh """
                        docker build -t ${DOCKER_IMAGE}:${imageTag} .
                        docker tag ${DOCKER_IMAGE}:${imageTag} ${DOCKER_IMAGE}:latest
                    """
                    
                    // Login and push
                    sh """
                        echo ${DOCKERHUB_CREDS_PSW} | docker login -u ${DOCKERHUB_CREDS_USR} --password-stdin
                        docker push ${DOCKER_IMAGE}:${imageTag}
                        docker push ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Write kubeconfig from credentials
                    sh """
                        mkdir -p ~/.kube
                        cp ${KUBECONFIG_CREDS} ~/.kube/config
                        chmod 600 ~/.kube/config
                    """
                    
                    // Update deployment with new image
                    sh """
                        kubectl set image deployment/${APP_NAME} ${APP_NAME}=${DOCKER_IMAGE}:${IMAGE_TAG} -n ${K8S_NAMESPACE} --record
                        kubectl rollout status deployment/${APP_NAME} -n ${K8S_NAMESPACE} --timeout=300s
                    """
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sh """
                    kubectl get pods -n ${K8S_NAMESPACE} -l app=${APP_NAME}
                    kubectl get svc -n ${K8S_NAMESPACE} -l app=${APP_NAME}
                """
            }
        }
    }

    post {
        always {
            cleanWs()
            sh 'docker system prune -f || true'
        }
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed!"
            sh """
                kubectl rollout undo deployment/${APP_NAME} -n ${K8S_NAMESPACE} || true
            """
        }
    }
}