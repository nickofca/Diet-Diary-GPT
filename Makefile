.PHONY: deploy destroy clean help

# Default namespace is "default" unless overridden
NAMESPACE ?= default

# Deploy target: This calls the deploy.sh script with the namespace parameter.
deploy:
	@echo "Deploying Terraform resources with namespace: $(NAMESPACE)"
	./deploy.sh $(NAMESPACE)

# Destroy target: Changes into the tf directory and destroys the resources.
destroy:
	@echo "Tearing down Terraform resources with namespace: $(NAMESPACE)"
	cd tf && terraform destroy -var="namespace=$(NAMESPACE)" -auto-approve

# Clean target: Optionally remove temporary files, e.g. the lambda.zip in the tf directory.
clean:
	@echo "Cleaning up temporary files..."
	rm -f tf/lambda.zip

# Help target: Displays usage information.
help:
	@echo "Usage:"
	@echo "  make deploy [NAMESPACE=your_namespace]   - Deploy resources with an optional namespace."
	@echo "  make destroy [NAMESPACE=your_namespace]  - Tear down resources with an optional namespace."
	@echo "  make clean                               - Remove temporary files."
	@echo "  make help                                - Show this help message."