# CLAUDE.md

Contexto operativo para agentes de código que trabajen en este repositorio. La guía completa para humanos está en [CONTRIBUTING.md](CONTRIBUTING.md); este archivo resume lo indispensable.

## Qué es

Terraform para AWS (`us-east-1`): VPC + EC2/Nginx en tres ambientes aislados. Remote state en S3 con locking en DynamoDB.

```text
backend/               bootstrap de S3 + DynamoDB (state LOCAL, no versionado)
environments/<env>/    root modules dev | staging | prod (state remoto por ambiente)
modules/networking/    VPC, subnets, IGW, NAT opcional, default SG deny-all
modules/web_server/    EC2, SG, key pair, user_data en templates/
```

## Comandos

```bash
make ci                    # fmt-check + validate-all + lint + test + security-scan
make test                  # terraform test con mock_provider (sin credenciales AWS)
make validate-all          # init -backend=false + validate en los 4 root modules
make plan ENV=dev          # requiere credenciales AWS y backend inicializado
```

## Reglas

- **Nunca** ejecutes `apply`, `destroy`, `backend-init`, `backend-destroy`, `force-unlock` ni `state rm/mv` sin aprobación explícita del usuario.
- **Nunca** borres ni edites `*.tfstate` (en especial `backend/terraform.tfstate`, que es irrecuperable) ni `.terraform.lock.hcl` de root modules.
- **Nunca** leas ni muestres el contenido de `terraform.tfvars`; usa `terraform.tfvars.example`.
- Los módulos no declaran `provider`; los tags comunes van en `default_tags` del root module.
- Cambios estructurales en un ambiente (`main.tf`, `providers.tf`, `outputs.tf`) se replican en los tres.
- Toda variable restringida lleva `validation` y un test `expect_failures` en `modules/*/tests/`.
- Excepciones de Checkov: inline `# checkov:skip=<ID>:<justificación>`, no globales.
- Commits con Conventional Commits (`feat|fix|refactor|test|ci|build|docs|chore`), atómicos.
- `.terraform` es un symlink a `.terraform.nosync` (exclusión de iCloud); no lo conviertas en directorio.
