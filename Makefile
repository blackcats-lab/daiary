# dAIary monorepo task runner
# Usage: make <target>

.PHONY: help setup \
        mobile-pub-get mobile-test mobile-lint mobile-build mobile-format mobile-codegen \
        supabase-start supabase-stop supabase-status supabase-db-reset \
        functions-serve functions-deploy functions-lint functions-fmt functions-test \
        db-push db-diff \
        lint test clean

help:
	@echo "dAIary monorepo tasks:"
	@echo ""
	@echo "  setup              - Install dependencies for mobile and supabase"
	@echo ""
	@echo "  Mobile (Flutter):"
	@echo "  mobile-pub-get     - flutter pub get"
	@echo "  mobile-test        - flutter test"
	@echo "  mobile-lint        - flutter analyze"
	@echo "  mobile-format      - dart format"
	@echo "  mobile-codegen     - build_runner build"
	@echo "  mobile-build       - flutter build apk / ipa"
	@echo ""
	@echo "  Supabase:"
	@echo "  supabase-start     - Start local Supabase stack"
	@echo "  supabase-stop      - Stop local Supabase stack"
	@echo "  supabase-status    - Show local stack status"
	@echo "  supabase-db-reset  - Drop local DB and re-run migrations + seed"
	@echo "  db-push            - Push local migrations to linked remote project"
	@echo "  db-diff            - Generate a new migration from local schema diff"
	@echo ""
	@echo "  Edge Functions (Deno):"
	@echo "  functions-serve    - Serve all functions locally"
	@echo "  functions-deploy   - Deploy all functions to remote project"
	@echo "  functions-lint     - deno lint"
	@echo "  functions-fmt      - deno fmt --check"
	@echo "  functions-test     - deno test"
	@echo ""
	@echo "  Aggregate:"
	@echo "  lint               - Run mobile-lint and functions-lint"
	@echo "  test               - Run mobile-test and functions-test"
	@echo "  clean              - Remove build artifacts"

setup: mobile-pub-get
	@echo "Setup complete. Remember to copy .env.example files to .env."

# ===== Mobile =====
mobile-pub-get:
	cd mobile && flutter pub get

mobile-test:
	cd mobile && flutter test

mobile-lint:
	cd mobile && flutter analyze

mobile-format:
	cd mobile && dart format lib test

mobile-codegen:
	cd mobile && dart run build_runner build --delete-conflicting-outputs

mobile-build:
	cd mobile && flutter build apk --release

# ===== Supabase =====
supabase-start:
	supabase start

supabase-stop:
	supabase stop

supabase-status:
	supabase status

supabase-db-reset:
	supabase db reset

db-push:
	supabase db push

db-diff:
	supabase db diff -f new_migration

# ===== Edge Functions =====
functions-serve:
	supabase functions serve --env-file supabase/.env.local

functions-deploy:
	supabase functions deploy

functions-lint:
	cd supabase/functions && deno lint

functions-fmt:
	cd supabase/functions && deno fmt --check

functions-test:
	cd supabase/functions && deno test --allow-all

# ===== Aggregate =====
lint: mobile-lint functions-lint

test: mobile-test functions-test

clean:
	cd mobile && flutter clean
	rm -rf supabase/.temp
