pipeline {
    agent any
    
    stages {
        stage('Checkout Source') {
            steps {
                echo 'Pulling declarative infrastructure configuration from Git...'
            }
        }
        
        stage('Terraform Initialize') {
            steps {
                sh 'terraform init'
            }
        }
        
        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }
        
        stage('Terraform Evaluation Plan') {
            steps {
                sh 'terraform plan -out=tfplan'
            }
        }
        
        stage('Terraform Automated Apply') {
            steps {
                sh 'terraform apply -auto-approve tfplan'
            }
        }
    }
}
