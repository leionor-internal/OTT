pipeline {
    agent any

    tools {
        maven 'Maven3'
    }

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds')
        DOCKER_IMAGE = "akashms54/ott-platform"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo 'Building with Maven...'
                sh 'mvn -B clean compile'
            }
        }

        stage('Test') {
            steps {
                echo 'Running unit tests...'
                sh 'mvn -B test'
            }

            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Package') {
            steps {
                echo 'Packaging application as JAR...'
                sh 'mvn -B package -DskipTests'
            }

            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar',
                                     fingerprint: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                echo 'Building Docker image...'

                sh """
                docker build \
                -t ${DOCKER_IMAGE}:${IMAGE_TAG} \
                -t ${DOCKER_IMAGE}:latest .
                """
            }
        }

        stage('Docker Push') {
            steps {
                echo 'Pushing Docker image to registry...'

                sh '''
                echo $DOCKERHUB_CREDENTIALS_PSW | \
                docker login \
                -u $DOCKERHUB_CREDENTIALS_USR \
                --password-stdin
                '''

                sh "docker push ${DOCKER_IMAGE}:${IMAGE_TAG}"

                sh "docker push ${DOCKER_IMAGE}:latest"
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying with docker-compose...'

                sh 'docker compose down || true'

                sh 'docker compose up -d --no-build'
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }

        failure {
            echo 'Pipeline failed. Check the logs above.'
        }

        always {
            echo 'Pipeline finished.'
       }
    }
}
