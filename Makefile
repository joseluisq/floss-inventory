run:
	@dart --version
	@dart run src/projects.dart
.PHONY: run

lint:
	@dart --version
	@dart analyze .
.PHONY: lint

jit:
	@dart --version
	@dart compile jit-snapshot src/projects.dart
.PHONY: jit

dep:
	@dart --version
	@dart pub get
.PHONY: dep

fmt_lint:
	@dart --version
	@dart fix --dry-run
.PHONY: fmt_lint

fmt:
	@dart --version
	@dart format --fix .
.PHONY: fmt

fix:
	@dart --version
	@dart fix --apply .
.PHONY: fix
