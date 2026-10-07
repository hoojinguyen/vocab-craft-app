.PHONY: deploy-db

deploy-db:
	@./scripts/deploy_db.sh "$(DB_FILE)"

.PHONY: run-device build-iphone

run-device: build-iphone

build-iphone:
	@./scripts/run_device.sh
