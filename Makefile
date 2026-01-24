# Makefile for longway.nvim

.PHONY: test test-deps compile clean help

help:
	@echo "longway.nvim development commands:"
	@echo ""
	@echo "  make test-deps  - Install test dependencies (plenary, nfnl)"
	@echo "  make compile    - Compile all Fennel files to Lua"
	@echo "  make test       - Run the test suite"
	@echo "  make clean      - Remove test artifacts"
	@echo ""

test-deps:
	@./scripts/setup-test-deps

compile: test-deps
	@./scripts/compile

test: test-deps
	@./scripts/test

clean:
	@rm -rf .test/nvim/pack
	@echo "Cleaned test dependencies"
