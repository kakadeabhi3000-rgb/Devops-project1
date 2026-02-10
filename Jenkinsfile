
pipeline {
    agent any

    stages {

        stage("Install Python Tools") {
            steps {
                sh '''
                sudo apt update
                sudo apt install -y python3-venv python3-pip
                '''
            }
        }

        stage("Setup Environment") {
            steps {
                sh '''
                python3 -m venv venv
                . venv/bin/activate
                pip install -r requirements.txt
                '''
            }
        }

        stage("Run Attack Simulation") {
            steps {
                sh '''
                . venv/bin/activate
                python3 red_team.py | tee attack_output.log
                '''
                archiveArtifacts artifacts: 'attack_output.log'
            }
        }
    }
}
