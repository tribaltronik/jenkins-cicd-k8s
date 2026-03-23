import hudson.model.*
import hudson.slaves.*
import jenkins.model.*

def agentName = 'docker-agent'

def node = Jenkins.instance.getNode(agentName)
if (node != null) {
    println "Agent '$agentName' already exists"
    def computer = node.getComputer()
    if (computer != null) {
        def secret = computer.getJnlpMac()
        new File('/var/jenkins_home/agent-secret.txt').text = secret
        println "Secret updated: $secret"
    }
    return
}

def launcher = new hudson.slaves.JNLPLauncher(true)
def newNode = new DumbSlave(
    agentName,
    'Docker Agent',
    '/home/jenkins/agent',
    '2',
    Node.Mode.NORMAL,
    'docker-agent',
    launcher,
    new hudson.slaves.RetentionStrategy.Demand(5, 5)
)

Jenkins.instance.addNode(newNode)
println "Agent '$agentName' created successfully"
