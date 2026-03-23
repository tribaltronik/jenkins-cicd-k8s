#!/bin/bash
set -e

AGENT_SECRET=$(cat /var/jenkins_home/agent-secret.txt)
exec /usr/local/bin/jenkins-agent -url http://jenkins:8080 -secret "$AGENT_SECRET" -name docker-agent -workDir /home/jenkins/agent
