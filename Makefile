.PHONY: help start clean logs password

help:
	@echo "Jenkins Docker Compose - Makefile targets:"
	@echo "  make start    - Start Jenkins containers"
	@echo "  make clean   - Stop and remove containers"
	@echo "  make logs    - View logs"
	@echo "  make password - Get Jenkins admin password"

start:
	docker compose up -d
	@echo "Jenkins starting at http://localhost:8080"

clean:
	docker compose down

logs:
	docker compose logs -f

password:
	@docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword