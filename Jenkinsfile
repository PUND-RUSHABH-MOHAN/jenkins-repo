pipeline {
    agent any
    
    // WHY: Only Jenkins does Ansible, not Terraform
    triggers {
        // GitHub webhook will trigger build
        githubPush()
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 20, unit: 'MINUTES')
    }
    
    environment {
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        ANSIBLE_LOG_PATH = 'ansible.log'
        // WHY: Ansible settings for secure deployment
    }
    
    stages {
        // ========================================
        // STAGE 1: Clone from GitHub
        // ========================================
        stage('Clone Repository') {
            steps {
                script {
                    echo "📥 Cloning Ansible files from GitHub..."
                    
                    // WHY: Use GitHub token to authenticate
                    // WHAT HAPPENS: Jenkins clones private repo
                    withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                        sh '''
                        echo "GitHub token loaded ✓"
                        
                        git clone \
                          https://${GITHUB_TOKEN}@github.com/YOUR_USERNAME/terraform-aws-project.git \
                          .
                        
                        git checkout main
                        
                        echo "✓ Repository cloned successfully"
                        echo "Files available:"
                        ls -la jenkins-ansible/playbooks/
                        '''
                    }
                    
                    // WHY: Token not exposed in logs
                    // WHAT HAPPENS: Credentials hidden from console output
                }
            }
        }
        
        // ========================================
        // STAGE 2: Verify Inventory Exists
        // ========================================
        stage('Verify Configuration') {
            steps {
                script {
                    echo "📋 Checking Ansible inventory..."
                    
                    dir('jenkins-ansible') {
                        sh '''
                        if [ ! -f "inventory/inventory.ini" ]; then
                            echo "❌ ERROR: inventory.ini not found"
                            echo ""
                            echo "SOLUTION:"
                            echo "1. SSH to INFRA-SERVER: ssh -i ~/.ssh/aws-ec2-key ubuntu@15.206.124.45"
                            echo "2. Run Terraform: cd ~/terraform-aws-project/terraform && terraform apply"
                            echo "3. Update inventory: bash ../jenkins-ansible/inventory/update_inventory.sh"
                            echo ""
                            exit 1
                        fi
                        
                        echo "✓ Inventory file found"
                        echo ""
                        echo "Servers in inventory:"
                        grep -E "^web_server|^rds_mysql" inventory/inventory.ini
                        '''
                    }
                }
            }
        }
        
        // ========================================
        // STAGE 3: Test SSH Connection
        // ========================================
        stage('Test Connectivity') {
            steps {
                script {
                    echo "🔗 Testing Ansible SSH connectivity..."
                    
                    // WHY: Use SSH key credential for authentication
                    // WHAT HAPPENS: Jenkins SSH to EC2s and runs ansible ping
                    withCredentials([sshUserPrivateKey(credentialsId: 'aws-ec2-ssh-key', keyFileVariable: 'SSH_KEY_FILE')]) {
                        dir('jenkins-ansible') {
                            sh '''
                            export ANSIBLE_PRIVATE_KEY_FILE=$SSH_KEY_FILE
                            
                            echo "SSH key loaded ✓"
                            echo "Testing connectivity to all servers..."
                            echo ""
                            
                            # Ping all servers
                            ansible all -m ping
                            
                            echo ""
                            echo "✓ All servers reachable"
                            '''
                        }
                    }
                    
                    // WHY: SSH key not exposed
                    // WHAT HAPPENS: Secure authentication to EC2s
                }
            }
        }
        
        // ========================================
        // STAGE 4: Deploy Applications
        // ========================================
        stage('Deploy Applications') {
            steps {
                script {
                    echo "🚀 Deploying applications with Ansible..."
                    
                    // WHY: Run Ansible playbooks on EC2s
                    // WHAT HAPPENS: Applications deployed to all servers
                    withCredentials([sshUserPrivateKey(credentialsId: 'aws-ec2-ssh-key', keyFileVariable: 'SSH_KEY_FILE')]) {
                        dir('jenkins-ansible') {
                            sh '''
                            export ANSIBLE_PRIVATE_KEY_FILE=$SSH_KEY_FILE
                            
                            echo "Running deployment playbooks..."
                            echo ""
                            
                            # Deploy to all web servers
                            ansible-playbook playbooks/deploy_all.yml -v
                            
                            echo ""
                            echo "✓ Deployment playbooks completed"
                            '''
                        }
                    }
                }
            }
        }
        
        // ========================================
        // STAGE 5: Verify Deployment
        // ========================================
        stage('Verify Deployment') {
            steps {
                script {
                    echo "✅ Verifying deployment success..."
                    
                    dir('jenkins-ansible') {
                        sh '''
                        echo "Testing web servers..."
                        
                        # Get web server IP from inventory
                        WEB_SERVER=$(grep "web_server_1" inventory/inventory.ini | grep "ansible_host" | awk '{print $NF}' | cut -d'=' -f2)
                        
                        echo "Testing: http://$WEB_SERVER"
                        sleep 2
                        
                        # Test HTTP response
                        RESPONSE=$(curl -s http://$WEB_SERVER)
                        
                        if echo "$RESPONSE" | grep -q "Web Server Running"; then
                            echo ""
                            echo "✓ Web server responding correctly"
                            echo ""
                            echo "Response:"
                            echo "$RESPONSE" | grep -E "Version|Hostname|Time" | head -5
                        else
                            echo "✗ Web server verification failed"
                            exit 1
                        fi
                        '''
                    }
                }
            }
        }
    }
    
    // ========================================
    // POST BUILD ACTIONS
    // ========================================
    post {
        always {
            sh '''
            echo ""
            echo "════════════════════════════════════════════"
            echo "BUILD COMPLETE"
            echo "════════════════════════════════════════════"
            echo "Jenkins uses credentials:"
            echo "  ✓ GitHub Token: To clone repository"
            echo "  ✓ SSH Key: To connect to EC2s"
            echo "════════════════════════════════════════════"
            '''
        }
        success {
            echo "✅ Application deployed successfully!"
        }
        failure {
            echo "❌ Deployment failed! Check logs above."
        }
    }
}
