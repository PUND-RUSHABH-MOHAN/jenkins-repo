
pipeline {
    agent any
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 20, unit: 'MINUTES')
    }
    
    environment {
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        ANSIBLE_LOG_PATH = 'ansible.log'
    }
    
    stages {
        stage('Clone Repository') {
            steps {
                script {
                    echo "📥 Cloning from GitHub..."
                    
                    // Clean workspace
                    deleteDir()
                    
                    // Use GitHub token to clone
                    withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                        sh '''
                        echo "Using GitHub token for authentication..."
                        
                        git clone \
                          https://${GITHUB_TOKEN}@github.com/PUND-RUSHABH-MOHAN/jenkins-repo.git .
                        
                        git checkout main
                        
                        echo "✓ Repository cloned successfully"
                        '''
                    }
                }
            }
        }
        
        stage('Verify Files') {
            steps {
                script {
                    echo "📋 Verifying files..."
                    
                    sh '''
                    if [ ! -d "jenkins-ansible" ]; then
                        echo "❌ jenkins-ansible directory not found"
                        exit 1
                    fi
                    
                    if [ ! -f "jenkins-ansible/inventory/inventory.ini" ]; then
                        echo "❌ inventory.ini not found"
                        echo "Need to run: terraform apply && update_inventory.sh"
                        exit 1
                    fi
                    
                    echo "✓ All files verified"
                    '''
                }
            }
        }
        
        stage('Test Connectivity') {
            steps {
                script {
                    echo "🔗 Testing SSH to EC2s..."
                    
                    withCredentials([sshUserPrivateKey(credentialsId: 'aws-ec2-ssh-key', keyFileVariable: 'SSH_KEY_FILE')]) {
                        sh '''
                        cd jenkins-ansible
                        export ANSIBLE_PRIVATE_KEY_FILE=$SSH_KEY_FILE
                        
                        echo "Pinging servers..."
                        ansible all -m ping
                        
                        echo "✓ All servers reachable"
                        '''
                    }
                }
            }
        }
        
        stage('Deploy Applications') {
            steps {
                script {
                    echo "🚀 Deploying with Ansible..."
                    
                    withCredentials([sshUserPrivateKey(credentialsId: 'aws-ec2-ssh-key', keyFileVariable: 'SSH_KEY_FILE')]) {
                        sh '''
                        cd jenkins-ansible
                        export ANSIBLE_PRIVATE_KEY_FILE=$SSH_KEY_FILE
                        
                        echo "Running Ansible playbooks..."
                        ansible-playbook playbooks/deploy_all.yml -v
                        
                        echo "✓ Deployment complete"
                        '''
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    echo "✅ Verifying deployment..."
                    
                    sh '''
                    cd jenkins-ansible
                    
                    WEB_SERVER=$(grep "web_server_1" inventory/inventory.ini | grep "ansible_host" | awk '{print $NF}' | cut -d'=' -f2)
                    
                    echo "Testing web server: http://$WEB_SERVER"
                    sleep 2
                    
                    if curl -s http://$WEB_SERVER | grep -q "Web Server Running"; then
                        echo "✓ Web server responding"
                    else
                        echo "✗ Verification failed"
                        exit 1
                    fi
                    '''
                }
            }
        }
    }
    
    post {
        always {
            sh 'echo "Build completed"'
        }
        success {
            echo "✅ BUILD SUCCESS"
        }
        failure {
            echo "❌ BUILD FAILED"
        }
    }
}


echo "✓ Updated Jenkinsfile to use GitHub token"
