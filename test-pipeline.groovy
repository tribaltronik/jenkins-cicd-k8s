pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: ubuntu
    image: ubuntu:22.04
    command:
    - sleep
    args:
    - infinity
'''
        }
    }
    stages {
        stage('Test') {
            steps {
                container('ubuntu') {
                    sh 'echo "Running on K8s pod!"'
                    sh 'hostname'
                    sh 'cat /etc/os-release'
                }
            }
        }
    }
}
