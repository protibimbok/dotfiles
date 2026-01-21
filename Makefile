.PHONY: help test-ubuntu test-ubuntu-clean clean

SANDBOX_DIR := .sandbox
CONTAINER_NAME := ubuntu-setup-test
UBUNTU_IMAGE := ubuntu:24.04
ABS_PATH := $(shell pwd)

help:
	@echo "Dotfiles Setup Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  test-ubuntu        - Test Ubuntu setup in a Docker container"
	@echo "  test-ubuntu-clean  - Clean test container and rebuild"
	@echo "  clean              - Remove sandbox directory and test containers"
	@echo ""
	@echo "Usage:"
	@echo "  make test-ubuntu   # Run Ubuntu setup in a fresh container"

$(SANDBOX_DIR):
	@mkdir -p $(SANDBOX_DIR)

test-ubuntu: $(SANDBOX_DIR)
	@echo "==> Testing Ubuntu setup in container..."
	@echo "==> Using path: $(ABS_PATH)/os-setup"
	@echo "==> Creating test output directory..."
	@mkdir -p $(SANDBOX_DIR)/test-ubuntu
	@echo "==> Creating fresh Ubuntu container..."
	docker run --rm \
		--name $(CONTAINER_NAME) \
		-v "$(ABS_PATH)/os-setup:/mnt/os-setup:ro" \
		-v "$(ABS_PATH)/$(SANDBOX_DIR)/test-ubuntu:/mnt/output" \
		-e DEBIAN_FRONTEND=noninteractive \
		-e TZ=UTC \
		-e OS_SETUP_MODULES="01-basic-tools,02-nginx,03-php" \
		-e CI=true \
		$(UBUNTU_IMAGE) \
		/bin/bash -c '\
			set -e; \
			echo "==> Installing initial packages..." && \
			apt-get update -qq && \
			apt-get install -y -qq sudo ca-certificates && \
			echo "==> Creating test user..." && \
			useradd -m -s /bin/bash testuser && \
			usermod -aG sudo testuser && \
			echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
			echo "==> Checking mounted directory..." && \
			ls -la /mnt/os-setup/ && \
			echo "==> Copying os-setup to testuser home..." && \
			mkdir -p /home/testuser/os-setup && \
			cp -rv /mnt/os-setup/* /home/testuser/os-setup/ && \
			chown -R testuser:testuser /home/testuser/os-setup && \
			echo "==> Making scripts executable..." && \
			find /home/testuser/os-setup -type f -name "*.sh" -exec chmod +x {} \; && \
			find /home/testuser/os-setup -type f -name "git-*" ! -name "*.sh" -exec chmod +x {} \; && \
			echo "==> Verifying directory structure:" && \
			ls -la /home/testuser/os-setup/ && \
			ls -la /home/testuser/os-setup/ubuntu/ && \
			echo "==> Starting Ubuntu setup as testuser..." && \
			su - testuser -c "cd /home/testuser && echo \"\" | ./os-setup/ubuntu/setup.sh" && \
			echo "==> Capturing modified files..." && \
			mkdir -p /mnt/output/home/testuser && \
			cp -r /home/testuser/.bashrc /mnt/output/home/testuser/ 2>/dev/null || true && \
			cp -r /home/testuser/.local /mnt/output/home/testuser/ 2>/dev/null || true && \
			cp -r /home/testuser/.ssh /mnt/output/home/testuser/ 2>/dev/null || true && \
			cp -r /home/testuser/.config /mnt/output/home/testuser/ 2>/dev/null || true && \
			mkdir -p /mnt/output/etc && \
			cp -r /etc/nginx /mnt/output/etc/ 2>/dev/null || true && \
			cp -r /etc/php /mnt/output/etc/ 2>/dev/null || true && \
			echo "==> Captured files:" && \
			find /mnt/output -type f 2>/dev/null | head -20 \
		' 2>&1 | tee $(SANDBOX_DIR)/test-ubuntu.log
	@echo ""
	@echo "==> Test completed. Log saved to: $(SANDBOX_DIR)/test-ubuntu.log"
	@echo "==> Modified files saved to: $(SANDBOX_DIR)/test-ubuntu/"
	@echo ""

test-ubuntu-clean:
	@echo "==> Cleaning up old test containers..."
	-docker rm -f $(CONTAINER_NAME) 2>/dev/null || true
	@echo "==> Running fresh test..."
	@$(MAKE) test-ubuntu

clean:
	@echo "==> Cleaning sandbox directory..."
	rm -rf $(SANDBOX_DIR)
	@echo "==> Removing test containers..."
	-docker rm -f $(CONTAINER_NAME) 2>/dev/null || true
	@echo "==> Clean complete"
	@echo ""
	@echo "Note: This removes:"
	@echo "  - $(SANDBOX_DIR)/test-ubuntu.log"
	@echo "  - $(SANDBOX_DIR)/test-ubuntu/ (captured files)"
