.PHONY: help install cluster jenkins password cleanup dc-up dc-down dc-logs dc-password dc-remove

help:
	@echo "Jenkins on Kind - Makefile targets:"
	@echo "  make install     - Create Kind cluster and install Jenkins"
	@echo "  make cluster     - Create Kind cluster only"
	@echo "  make jenkins     - Install Jenkins on existing cluster"
	@echo "  make password    - Get Jenkins admin password (Kind)"
	@echo "  make cleanup     - Delete Kind cluster"
	@echo ""
	@echo "Docker Compose targets:"
	@echo "  make dc-up       - Start Jenkins with Docker Compose"
	@echo "  make dc-down     - Stop Jenkins (Docker Compose)"
	@echo "  make dc-logs     - View Jenkins logs (Docker Compose)"
	@echo "  make dc-password - Get Jenkins admin password (Docker)"
	@echo "  make dc-remove   - Remove Jenkins container and volume"

install: cluster jenkins

cluster:
	@echo "Creating Kind cluster..."
	kind create cluster --name jenkins --config kind/cluster-config.yaml
	@echo "Cluster created:"
	kubectl get nodes

jenkins:
	@echo "Installing Jenkins..."
	kubectl create namespace jenkins || true
	helm repo add jenkins https://charts.jenkins.io || true
	helm repo update
	helm install jenkins jenkins/jenkins \
		-n jenkins \
		-f jenkins/helm-values.yaml
	@echo "Waiting for Jenkins..."
	kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=jenkins -n jenkins --timeout=300s
	@echo "Jenkins installed!"
	@echo "Access: http://localhost:8080"

password:
	@kubectl exec -n jenkins jenkins-0 -- cat /run/secrets/additional/chart-admin-password

cleanup:
	kind delete cluster --name jenkins

dc-up:
	docker-compose up -d
	@echo "Waiting for Jenkins to be ready..."
	@sleep 10
	@echo "Jenkins is starting. Access: http://localhost:8080"
	@echo "Admin password: docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"

dc-down:
	docker-compose down

dc-logs:
	docker-compose logs -f

dc-password:
	@docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

dc-remove:
	docker-compose down -v
	@echo "Jenkins container and volume removed"
