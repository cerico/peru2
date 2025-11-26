VM_NAME := $(shell basename $(CURDIR))
VM_USER := $(shell whoami)

.PHONY: info start stop ssh setup destroy limas

.DEFAULT_GOAL := _tldr

%:
	@$(MAKE) _commands

info:
	@echo ""
	@if limactl list 2>/dev/null | grep -q $(VM_NAME); then \
		echo "VM Status:"; \
		echo ------------------; \
		limactl list $(VM_NAME); \
	else \
		echo "Status: VM not created yet"; \
	fi
	@echo ""

limas:
	@limactl list
	@echo ""
	@echo "Commands:"
	@echo "  limactl stop <name>     Stop a machine"
	@echo "  limactl start <name>    Start a machine"
	@echo "  limactl shell <name>    SSH into a machine"
	@echo "  limactl delete <name>   Delete a machine"

start:
	@echo "Starting VM..."
	@limactl start $(VM_NAME)
	@echo "✓ VM started"

stop:
	@echo "Stopping VM..."
	@limactl stop $(VM_NAME)
	@echo "✓ VM stopped"

ssh:
	@echo "Connecting to VM..."
	@limactl shell $(VM_NAME)

setup:
	@echo "Checking prerequisites..."
	@if command -v limactl >/dev/null 2>&1; then \
		echo "✓ Lima already installed"; \
	else \
		echo "Installing Lima via Homebrew..."; \
		brew install lima; \
		echo "✓ Lima installed"; \
	fi
	@if [ -f ~/.ssh/id_ed25519 ]; then \
		echo "✓ Found SSH key at ~/.ssh/id_ed25519"; \
	elif [ -f ~/.ssh/id_rsa ]; then \
		echo "✓ Found SSH key at ~/.ssh/id_rsa"; \
	else \
		echo "✗ No SSH key found"; \
		echo ""; \
		echo "Please generate a GitHub SSH key first:"; \
		echo "  ssh-keygen -t ed25519 -C \"your_email@example.com\""; \
		echo "  ssh-add ~/.ssh/id_ed25519"; \
		echo "  Then add it to GitHub: https://github.com/settings/keys"; \
		exit 1; \
	fi
	@if ! limactl list 2>/dev/null | grep -q $(VM_NAME); then \
		echo "VM not found. Creating VM first..."; \
		echo ""; \
		$(MAKE) _create; \
		exit 0; \
	fi
	@echo "Setting up SSH keys for private repo access..."
	@echo "Adding SSH keys to agent..."
	@ssh-add ~/.ssh/id_ed25519 2>/dev/null || ssh-add ~/.ssh/id_rsa 2>/dev/null || echo "Note: Could not find SSH key"
	@echo "Verifying SSH keys..."
	@ssh-add -l
	@echo ""
	@echo "Setting up VM dependencies..."
	@limactl shell $(VM_NAME) sudo apt update
	@limactl shell $(VM_NAME) sudo apt install -y git curl postgresql postgresql-contrib openssl make ca-certificates gnupg
	@echo "Installing Node.js 22..."
	@limactl shell $(VM_NAME) bash -c 'curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -'
	@limactl shell $(VM_NAME) sudo apt install -y nodejs
	@echo "Installing pnpm..."
	@limactl shell $(VM_NAME) sudo npm install -g pnpm
	@echo "Setting up PostgreSQL..."
	@limactl shell $(VM_NAME) sudo systemctl start postgresql
	@limactl shell $(VM_NAME) sudo systemctl enable postgresql
	@limactl shell $(VM_NAME) sudo pg_ctlcluster 16 main start
	@echo "Configuring PostgreSQL authentication..."
	@limactl shell $(VM_NAME) bash -c 'sudo sed -i "s/scram-sha-256/trust/g" /etc/postgresql/*/main/pg_hba.conf'
	@limactl shell $(VM_NAME) sudo systemctl reload postgresql
	@echo "Creating PostgreSQL superuser for current user..."
	@limactl shell $(VM_NAME) bash -c 'sudo -u postgres createuser -s $$(whoami) 2>/dev/null || echo "  ✓ User already exists"'
	@echo "Granting schema permissions..."
	@limactl shell $(VM_NAME) bash -c 'for db in $$(psql -lqt | cut -d "|" -f 1 | grep -v template | grep -v postgres | sed "s/ //g" | grep -v "^$$"); do psql $$db -c "GRANT ALL ON SCHEMA public TO $$(whoami);" 2>/dev/null || true; done'
	@echo ""
	@echo "✓ VM setup complete!"
	@echo ""
	@echo "Installed versions:"
	@limactl shell $(VM_NAME) node --version
	@limactl shell $(VM_NAME) pnpm --version
	@$(MAKE) ssh

destroy:
	@echo "Destroying VM..."
	@limactl delete --force $(VM_NAME)
	@echo "✓ VM destroyed"

include makefiles/*.mk
