.PHONY: deploy destroy clean help

# Default namespace is "default" unless overridden via command line, e.g. make deploy NAMESPACE=myproject
NAMESPACE ?= default

deploy:
	@echo "Deploying Terraform resources with namespace: $(NAMESPACE)"
	@echo "Compressing lambda_function.py into lambda.zip..."
	zip -j lambda.zip lambda_function.py
	@echo "Moving lambda.zip into the 'tf' directory..."
	mv lambda.zip tf/lambda.zip
	@echo "Changing directory to 'tf' and initializing Terraform..."
	@cd tf && terraform init
	@echo "Creating Terraform plan..."
	@cd tf && terraform plan -var="namespace=$(NAMESPACE)" -out=tfplan
	@echo "Ready to apply Terraform plan."
	@cd tf && \
		read -p "Apply the Terraform plan? (yes/no): " CONFIRM && \
		if [ "$$CONFIRM" = "yes" ]; then \
			terraform apply tfplan; \
		else \
			echo "Deployment canceled."; \
			exit 0; \
		fi

destroy:
	@echo "Tearing down Terraform resources with namespace: $(NAMESPACE)"
	@cd tf && terraform destroy -var="namespace=$(NAMESPACE)" -auto-approve

clean:
	@echo "Cleaning up temporary files..."
	@rm -f tf/lambda.zip

help:
	@echo "Usage:"
	@echo "  make deploy [NAMESPACE=your_namespace]   - Deploy resources with an optional namespace."
	@echo "  make destroy [NAMESPACE=your_namespace]  - Tear down resources with an optional namespace."
	@echo "  make clean                               - Remove temporary files."
	@echo "  make help                                - Show this help message."