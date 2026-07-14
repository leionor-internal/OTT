pipeline {

    agent any

    environment {
        DOCKER_IMAGE = "akashms54/ott-platform"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build \
                        -t ${DOCKER_IMAGE}:${IMAGE_TAG} \
                        -t ${DOCKER_IMAGE}:latest .
                '''
            }
        }

        stage('Push Docker Image') {
            steps {

                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {

                    sh '''
                        echo "$DOCKER_PASS" | docker login \
                            -u "$DOCKER_USER" \
                            --password-stdin

                        docker push ${DOCKER_IMAGE}:${IMAGE_TAG}
                        docker push ${DOCKER_IMAGE}:latest

                        docker logout
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    docker compose down || true
                    docker compose pull
                    docker compose up -d
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    echo "Waiting for application..."
                    sleep 30

                    curl -f http://localhost:8085/api/ping
                '''
            }
        }
    }

    post {

        success {
            echo "Pipeline completed successfully."
        }

        failure {
            echo "Pipeline failed."
        }

        always {
            cleanWs()
        }
    }
}
