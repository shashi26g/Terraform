pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION    = 'ap-south-1' 
        AWS_ACCOUNT_ID        = '211856249928'
        ECR_REPO_NAME         = 'java-app-repo'
        EKS_CLUSTER_NAME      = 'production-eks-cluster'
        IMAGE_TAG             = "${BUILD_NUMBER}"
        
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
    }

    stages {
        stage('Checkout Source') {
            steps {
                echo 'Pulling application code configurations from Git...'
                checkout scm
            }
        }

        stage('Docker Build') {
            steps {
                echo 'Starting multi-stage Docker build packaging cycle...'
                sh "docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Push to ECR') {
            steps {
                echo 'Authenticating with AWS ECR...'
                sh "aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
                
                echo 'Pushing Docker image up to target container registry...'
                sh "docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}"
            }
        }

        stage('Deploy to EKS via Helm') {
            steps {
                echo 'Updating Kubeconfig context for EKS...'
                sh "aws eks update-kubeconfig --region ${AWS_DEFAULT_REGION} --name ${EKS_CLUSTER_NAME}"
                
                echo 'Executing Helm Upgrade/Install routines...'
                sh """
                helm upgrade --install java-application ./helm-charts/java-app \
                  --namespace default \
                  --set image.repository=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${ECR_REPO_NAME} \
                  --set image.tag=${IMAGE_TAG}
                """
            }
        }

        stage('App Health Check') {
            steps {
                echo 'Verifying deployment rollout availability status...'
                // Wait up to 120 seconds for pods to instantiate and transition successfully
                sh "kubectl rollout status deployment/java-application --namespace default --timeout=120s"
                
                echo 'Assessing absolute system pod health states...'
                sh """
                STATUS=\$(kubectl get pods -l app.kubernetes.io/name=java-app --namespace default -o jsonpath='{.items[0].status.phase}')
                echo "Current Active Pod State: \$STATUS"
                if [ "\$STATUS" != "Running" ]; then
                    echo "❌ Health check verification failed! Pod is not active."
                    exit 1
                fi
                echo "✅ Application instance health checks passed successfully!"
                """
            }
        }
    }

    post {
        success {
            echo '✅ Deployment lifecycle execution completed cleanly!'
            sh "docker rmi ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG} || true"
        }
        failure {
            echo '❌ Pipeline runtime error encountered. Inspect console logs.'
        }
    }
}
