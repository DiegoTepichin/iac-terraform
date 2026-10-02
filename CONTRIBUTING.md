# Contributing

## Setup

```bash
brew install terraform tflint checkov pre-commit   # or your platform's equivalent
pre-commit install
make help
```

`make ci` must pass before opening a pull request. It runs the same checks as GitHub Actions and needs no AWS credentials.

## Conventions

- **Modules** (`modules/*`) declare `required_providers` in `versions.tf` but no `provider` block. Region and common tags come from the root module's `default_tags`.
- **Environments** (`environments/*`) share the same structure. A change to `main.tf`, `providers.tf` or `outputs.tf` in one environment is applied to all three; differences belong in `variables.tf` defaults.
- **Variables and outputs** use `snake_case` and always have a `description`. Constrained inputs get a `validation` block; rules that span several inputs use a `precondition`.
- **Tests:** every new validation or precondition gets a `run` block with `expect_failures`, and every behavior change gets an `assert`. Tests use `mock_provider`, so they never touch AWS.
- **Security exceptions** are written inline next to the resource as `# checkov:skip=<ID>:<reason>`.
- **Never commit** `*.tfstate`, `*.tfvars`, `backend.hcl` or saved plans. Root module lock files (`.terraform.lock.hcl`) are committed.

## Commits and pull requests

- [Conventional Commits](https://www.conventionalcommits.org/): `feat`, `fix`, `refactor`, `test`, `ci`, `build`, `docs`, `chore`, with a scope where useful (`feat(web_app): ...`).
- One logical change per commit. If a commit changes deployed resources, the body says what gets replaced or modified.
- Attach the `make plan` summary for each affected environment to the pull request, and call out any resource that would be replaced (`-/+`).
