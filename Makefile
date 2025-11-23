.PHONY: help setup start test format lint docker-build docker-up docker-down clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Install dependencies and set up database
	mix deps.get
	mix ecto.setup
	cd assets && npm install

start: ## Start the Phoenix server
	mix phx.server

test: ## Run tests
	mix test

test-watch: ## Run tests in watch mode
	mix test.watch

test-coverage: ## Run tests with coverage report
	mix coveralls.html
	@echo "Coverage report generated in cover/excoveralls.html"

format: ## Format code
	mix format

lint: ## Run code linting
	mix credo --strict

dialyzer: ## Run static analysis
	mix dialyzer

quality: format lint dialyzer ## Run all quality checks

db-reset: ## Reset database
	mix ecto.reset

db-migrate: ## Run database migrations
	mix ecto.migrate

db-rollback: ## Rollback last migration
	mix ecto.rollback

db-seed: ## Seed database
	mix run priv/repo/seeds.exs

docker-build: ## Build Docker image
	docker-compose build

docker-up: ## Start Docker containers
	docker-compose up

docker-down: ## Stop Docker containers
	docker-compose down

docker-clean: ## Remove Docker containers and volumes
	docker-compose down -v

prod-build: ## Build production Docker image
	docker-compose -f docker-compose.prod.yml build

prod-up: ## Start production Docker containers
	docker-compose -f docker-compose.prod.yml up -d

prod-down: ## Stop production Docker containers
	docker-compose -f docker-compose.prod.yml down

logs: ## Show application logs
	docker-compose logs -f app

shell: ## Open IEx shell
	iex -S mix phx.server

clean: ## Clean build artifacts
	mix clean
	rm -rf _build deps

release: ## Create production release
	mix release

deploy: quality test release ## Run full deployment pipeline
	@echo "Deployment complete!"

ci: ## Run CI pipeline locally
	mix format --check-formatted
	mix credo --strict
	mix test
