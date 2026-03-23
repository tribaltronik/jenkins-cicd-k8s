pipeline {
    agent { docker { image 'ubuntu:22.04' } }
    stages {
        stage('Build') {
            steps {
                echo 'Building...'
                sh 'echo "Hello from Docker agent!"'
                sh 'hostname'
                sh 'cat /etc/os-release'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing...'
                sh 'uname -a'
            }
        }
    }
    post {
        always {
            echo 'Pipeline completed!'
        }
    }
}
