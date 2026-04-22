pipeline {
    agent { label 'docker-agent' }

    stages {
        stage('Build') {
            steps {
                echo 'Building application...'
                sh 'echo "Build step"'
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'echo "Test step"'
            }
        }

        stage('Docker Info') {
            steps {
                echo 'Docker environment:'
                sh 'docker version'
            }
        }
    }

    post {
        always {
            echo 'Pipeline completed'
        }
    }
}