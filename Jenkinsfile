pipeline {
    agent any

    environment {
        QA_HOST        = '98.94.68.254'
        QA_USER        = 'ubuntu'

        // Updated Project Path
        QA_PROJECT_DIR = '/home/ubuntu/QA/api/eva-services-java-monolith'

        SSH_CRED_ID    = 'qa-server-ssh-key'

        // PM2 App Name
        PM2_APP_NAME   = 'qa-environment'

        PORT           = '8080'

        // Updated Repo URL
        REPO_URL       = 'https://github.com/eva-equity-partners-testing-01/eva-saas-core-service.git'

        TEAMS_URL      = 'https://defaulte3ce5830f7d140c0ab827ce4f99738.f0.environment.api.powerplatform.com:443/powerautomate/automations/direct/workflows/5c488acdd9b94415a86cd66bd3f10c87/triggers/manual/paths/invoke?api-version=1&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=5PyZaC5FoW98hJSDKFlCsOavaLkDMeWA8EED2GXQvfo'
    }

    stages {

        stage('Prepare Metadata') {
            steps {
                script {

                    env.MERGED_BY = sh(
                        script: 'git log -1 --pretty=format:"%an"',
                        returnStdout: true
                    ).trim()

                    env.COMMITTED_BY = sh(
                        script: 'git log -1 --pretty=format:"%an" HEAD^2 2>/dev/null || git log -2 --pretty=format:"%an" | tail -1',
                        returnStdout: true
                    ).trim()

                    env.COMMIT_MSG = sh(
                        script: 'git log -1 --pretty=format:"%s"',
                        returnStdout: true
                    ).trim()

                    env.SOURCE_BRANCH = sh(
                        script: 'git log -1 --merges --pretty=format:"%s" | grep -oP "Merge pull request #\\d+ from \\K\\S+" || echo "${BRANCH_NAME}"',
                        returnStdout: true
                    ).trim()

                    env.JOB_SHORT = env.JOB_NAME.tokenize('/').size() > 1 ?
                        env.JOB_NAME.tokenize('/')[1] :
                        env.JOB_NAME

                    env.PR_URL = env.CHANGE_URL ?: "${env.REPO_URL}/tree/${env.BRANCH_NAME}"

                    echo "=============================================="
                    echo "COMMITTED_BY : ${env.COMMITTED_BY}"
                    echo "SOURCE_BRANCH: ${env.SOURCE_BRANCH}"
                    echo "COMMIT_MSG   : ${env.COMMIT_MSG}"
                    echo "=============================================="
                }
            }
        }

        stage('Deployment Notification') {
            when {
                allOf {
                    not { changeRequest() }
                    branch 'qa'
                }
            }

            steps {

                echo "DEPLOYMENT STARTED"
                echo "COMMITTED BY : ${env.COMMITTED_BY}"

                sh """
                    curl -s -X POST "${TEAMS_URL}" \\
                    -H "Content-Type: application/json" \\
                    -d '{
                        "status": "started",
                        "job": "${env.JOB_SHORT}",
                        "environment": "QA",
                        "branch": "${env.SOURCE_BRANCH}",
                        "committed_by": "${env.COMMITTED_BY}",
                        "commit_message": "${env.COMMIT_MSG}",
                        "pr_url": "${env.PR_URL}"
                    }'
                """
            }
        }

        stage('Git Checkout & Pull') {
            steps {
                sshagent(credentials: [SSH_CRED_ID]) {

                    sh """
                        ssh -o StrictHostKeyChecking=no ${QA_USER}@${QA_HOST} '
                            set -e

                            cd ${QA_PROJECT_DIR}

                            git stash || true
                            git fetch --all
                            git checkout qa
                            git pull origin qa
                        '
                    """
                }
            }
        }

        stage('Build Maven Project') {
            steps {

                sshagent(credentials: [SSH_CRED_ID]) {

                    sh """
                        ssh -o StrictHostKeyChecking=no ${QA_USER}@${QA_HOST} '
                            set -e

                            cd ${QA_PROJECT_DIR}

                            echo "Loading Environment Variables..."
                            source .env

                            echo "Building Maven Project..."
                            /opt/apache-maven-3.5.2/bin/mvn clean install -DskipTests
                        '
                    """
                }
            }
        }

        stage('Deploy with PM2') {

            when {
                allOf {
                    not { changeRequest() }
                    branch 'qa'
                }
            }

            steps {

                sshagent(credentials: [SSH_CRED_ID]) {

                    sh """
                        ssh -o StrictHostKeyChecking=no ${QA_USER}@${QA_HOST} '
                            set -e

                            cd ${QA_PROJECT_DIR}/target

                            echo "Stopping Existing PM2 Process..."
                            pm2 delete ${PM2_APP_NAME} || true

                            echo "Starting Spring Boot Application with PM2..."

                            pm2 start "java -jar spring-boot-jpa-postgresql-0.0.1-SNAPSHOT.jar" \\
                                --name ${PM2_APP_NAME}

                            echo "Saving PM2 Process List..."
                            pm2 save

                            echo "PM2 Process Status..."
                            pm2 list
                        '
                    """
                }
            }
        }
    }

    post {

        success {

            script {

                if (env.BRANCH_NAME == 'qa' && !env.CHANGE_ID) {

                    sh """
                        curl -s -X POST "${TEAMS_URL}" \\
                        -H "Content-Type: application/json" \\
                        -d '{
                            "status": "ended",
                            "job": "${env.JOB_SHORT}",
                            "environment": "QA",
                            "branch": "${env.SOURCE_BRANCH}",
                            "committed_by": "${env.COMMITTED_BY}",
                            "commit_message": "${env.COMMIT_MSG}",
                            "pr_url": "${env.PR_URL}",
                            "result": "SUCCESS"
                        }'
                    """
                }
            }

            echo "PIPELINE SUCCESS"
        }

        failure {

            script {

                if (env.BRANCH_NAME == 'qa' && !env.CHANGE_ID) {

                    sh """
                        curl -s -X POST "${TEAMS_URL}" \\
                        -H "Content-Type: application/json" \\
                        -d '{
                            "status": "ended",
                            "job": "${env.JOB_SHORT}",
                            "environment": "QA",
                            "branch": "${env.SOURCE_BRANCH}",
                            "committed_by": "${env.COMMITTED_BY}",
                            "commit_message": "${env.COMMIT_MSG}",
                            "pr_url": "${env.PR_URL}",
                            "result": "FAILED"
                        }'
                    """
                }
            }

            echo "PIPELINE FAILED"
        }
    }
}
