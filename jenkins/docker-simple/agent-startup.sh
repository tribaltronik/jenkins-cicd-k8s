#!/bin/bash
set -e

JENKINS_URL=${JENKINS_URL:-http://jenkins:8080}
AGENT_NAME=${AGENT_NAME:-docker-agent}
AGENT_HOME=${AGENT_HOME:-/home/jenkins/agent}
AGENT_PORT=${AGENT_PORT:-50000}

echo "Waiting for Jenkins to be ready..."
until curl -s -f "$JENKINS_URL/api/json" -u admin:admin > /dev/null 2>&1; do
    echo "Jenkins not ready, waiting..."
    sleep 5
done
echo "Jenkins is ready!"

echo "Creating agent node: $AGENT_NAME"

NODE_CONFIG="<slave>
  <name>$AGENT_NAME</name>
  <description>Docker Agent</description>
  <remoteFS>$AGENT_HOME</remoteFS>
  <numExecutors>2</numExecutors>
  <mode>NORMAL</mode>
  <retentionStrategy class=\"hudson.slaves.RetentionStrategy$Demand\">
    <inActivityDelay>5</inActivityDelay>
    <idleDelay>5</idleDelay>
  </retentionStrategy>
  <launcher class=\"hudson.slaves.JNLPLauncher\">
    <webSocket>false</webSocket>
  </launcher>
  <label>docker-agent</label>
</slave>"

curl -s -X POST "$JENKINS_URL/computer/doCreateItem" \
    -u admin:admin \
    --data-urlencode "name=$AGENT_NAME" \
    --data-urlencode "type=hudson.slaves.DumbSlave\$DescriptorImpl" \
    --data-urlencode "json={\"name\":\"$AGENT_NAME\",\"nodeDescription\":\"Docker Agent\",\"numExecutors\":\"2\",\"remoteFS\":\"/home/jenkins/agent\",\"labelString\":\"docker-agent\",\"mode\":\"NORMAL\",\"type\":\"hudson.slaves.DumbSlave\$DescriptorImpl\",\"retentionStrategy\":{\"stapler-class\":\"hudson.slaves.RetentionStrategy\$Demand\",\"inactivityDelay\":\"5\",\"idleDelay\":\"5\"},\"launcher\":{\"stapler-class\":\"hudson.slaves.JNLPLauncher\"}}" 2>/dev/null || true

sleep 2

echo "Getting agent secret..."
SECRET_FILE="$JENKINS_URL/computer/$AGENT_NAME/config.xml"
AGENT_SECRET=$(curl -s -u admin:admin "$SECRET_FILE" | grep -oP '(?<=<secret><!\[CDATA\[)[^]]+(?=\]\]></secret>)' || echo "")

if [ -z "$AGENT_SECRET" ]; then
    echo "Could not get secret, trying alternative method..."
    SECRET=$(curl -s -u admin:admin "$JENKINS_URL/computer/$AGENT_NAME/agent-secret" || echo "")
    AGENT_SECRET=$(echo "$SECRET" | grep -v "^$" | head -1)
fi

echo "Agent secret obtained, starting agent..."
exec java -jar /agent.jar -url "$JENKINS_URL" -secret "${AGENT_SECRET}" -name "$AGENT_NAME" -workDir "$AGENT_HOME" -headless
