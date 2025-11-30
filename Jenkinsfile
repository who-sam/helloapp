pipeline {
    agent any

    parameters {
        choice(
            choices: ['apply', 'destroy'],
            description: 'Choose to create or destroy infrastructure',
            name: 'ACTION'
        )
    }

    triggers {
        githubPush()
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo "🔹 Checking out repository..."
                git branch: 'main', url: 'https://github.com/who-sam/mind-infra-pipeline.git'
            }
        }

        stage('Terraform Init') {
            steps {
                echo "🔹 Initializing Terraform..."
                sh 'terraform init -reconfigure'
            }
        }

        stage('Terraform Plan') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                echo "🔹 Creating Terraform plan..."
                sh 'terraform plan -out=tfplan'
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                echo "🔹 Applying Terraform..."
                sh 'terraform apply -auto-approve tfplan'
                echo "✅ Infrastructure deployed successfully!"
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                echo "🗑️ Destroying Terraform infrastructure..."
                sh 'terraform destroy -auto-approve'
                echo "🔥 Infrastructure destroyed successfully!"
            }
        }
    }

    post {
        success {
            echo "🎉 Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
