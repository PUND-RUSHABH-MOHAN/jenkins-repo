
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
        // SCM checkout happens automatically
        // But we'll handle cloning ourselves for better control
        
        stage('Clone Repository') {
            steps {
                script {
                    echo "📥 Cloning from GitHub..."
                    
                    // Clean workspace first
                    deleteDir()
                    
                    // Use SSH key to clone (more reliable than token in dropdown)
                    withCredentials([sshUserPrivateKey(credentialsId: 'aws-ec2-ssh-key', keyFileVariable: 'SSH_KEY_FILE')]) {
                        sh '''
                        GIT_SSH_COMMAND="ssh -i $SSH_KEY_FILE -o StrictHostKeyChecking=no" \
                        git clone git@github.com:PUND-RUSHABH-MOHAN/jenkins-repo.git .
                        
                        git checkout main
                        
                        echo "✓ Repository cloned"
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
                    ls -la jenkins-ansible/ || echo "jenkins-ansible not found"
                    ls -la terraform/ || echo "terraform not found"
                    '''
                }
            }
        }
        
        stage('Verify Configuration') {
            steps {
                script {
                    echo "Checking inventory..."
                    
                    sh '''
                    if [ ! -f "jenkins-ansible/inventory/inventory.ini" ]; then
                        echo "❌ inventory.ini not found"
                        echo "Need to run: terraform apply && update_inventory.sh"
                        exit 1
                    fi
                    
                    echo "✓ Inventory found"
                    '''
                }
            }
        }
        
        stage('Test Connectivity') {
            steps {
                script {
                    echo "🔗 Testing SSH connectivity..."
                    
                    withCredentials([sshUserPrivateKey(credentialsId: 'aws-ec2-ssh-key', keyFileVariable: 'SSH_KEY_FILE')]) {
                        sh '''
                        cd jenkins-ansible
                        export ANSIBLE_PRIVATE_KEY_FILE=$SSH_KEY_FILE
                        
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
                    echo "🚀 Deploying..."
                    
                    withCredentials([sshUserPrivateKey(credentialsId: 'aws-ec2-ssh-key', keyFileVariable: 'SSH_KEY_FILE')]) {
                        sh '''
                        cd jenkins-ansible
                        export ANSIBLE_PRIVATE_KEY_FILE=$SSH_KEY_FILE
                        
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
                    echo "Verifying..."
                    
                    sh '''
                    cd jenkins-ansible
                    WEB=$(grep "web_server_1" inventory/inventory.ini | grep "ansible_host" | awk '{print $NF}' | cut -d'=' -f2)
                    
                    curl -s http://$WEB | grep -q "Web Server Running" && echo "✓ Success" || exit 1
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ BUILD SUCCESS"
        }
        failure {
            echo "❌ BUILD FAILED"
        }
    }
}


echo "✓ Created new Jenkinsfile"
