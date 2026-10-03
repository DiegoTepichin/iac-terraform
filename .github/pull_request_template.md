## What and why

<!-- What does this change and why is it needed? -->

## Plan summary

<!-- Paste the "Plan: X to add, Y to change, Z to destroy" line from `make plan ENV=<env>` for each affected environment. -->

| Environment | Plan |
|---|---|
| dev | |
| staging | |
| prod | |

**Resources replaced (`-/+`):**

<!-- List any resource that will be destroyed and recreated, or write "none". -->

## Checklist

- [ ] `make ci` passes locally
- [ ] Structural changes are applied to all three environments
- [ ] New validations or preconditions have an `expect_failures` test
- [ ] Module READMEs regenerated with `make docs` if inputs or outputs changed
- [ ] Commits follow Conventional Commits
