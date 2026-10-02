# Guía de contribución

Esta guía describe cómo está organizado el repositorio, las convenciones de código y el flujo de trabajo para proponer cambios de infraestructura de forma segura.

## Índice

- [Configuración del entorno](#configuración-del-entorno)
- [Arquitectura del código](#arquitectura-del-código)
- [Convenciones de código](#convenciones-de-código)
- [Comandos](#comandos)
- [Flujo de trabajo de Git](#flujo-de-trabajo-de-git)
- [Checklist de Pull Request](#checklist-de-pull-request)
- [Operaciones sensibles](#operaciones-sensibles)

---

## Configuración del entorno

```bash
brew install terraform tflint checkov pre-commit awscli   # macOS
pre-commit install                                        # activa los hooks locales
make help                                                 # lista todos los comandos
```

Antes de abrir un PR, `make ci` debe pasar: ejecuta los mismos checks que GitHub Actions.

---

## Arquitectura del código

| Directorio | Rol | ¿Tiene state? |
|---|---|---|
| `backend/` | Bootstrap de S3 + DynamoDB para el remote state. Se aplica una sola vez por cuenta. | Sí, **local** (no versionado) |
| `environments/<env>/` | Root modules. Componen módulos y definen valores por ambiente. | Sí, remoto en `s3://…/env/<env>/terraform.tfstate` |
| `modules/<nombre>/` | Módulos reutilizables, sin provider ni backend propios. | No |

### Reglas de diseño

1. **Los módulos no declaran `provider`.** Solo `required_providers` en `versions.tf`; la región y los tags los define el root module.
2. **Los tags comunes viven en `default_tags`** del provider (`Project`, `Environment`, `ManagedBy`). En los recursos solo se agregan tags propios (`Name`, `Tier`).
3. **Validar en el borde.** Toda variable con un dominio restringido (CIDR, ambiente, tamaños) lleva un bloque `validation`. Las reglas que cruzan variables se expresan como `precondition`.
4. **Los tres ambientes comparten estructura.** Un cambio en `main.tf`, `providers.tf` o `outputs.tf` de un ambiente se replica en los otros dos; las diferencias legítimas van en `variables.tf` / `terraform.tfvars`.
5. **Scripts fuera del HCL.** Contenido de `user_data` y similares va en `templates/*.tftpl` y se renderiza con `templatefile()`.

### Estructura de un módulo

```text
modules/<nombre>/
├── main.tf          # recursos y data sources
├── variables.tf     # entradas (todas con description y type)
├── outputs.tf       # salidas (todas con description)
├── versions.tf      # required_version + required_providers
├── templates/       # (opcional) plantillas .tftpl
└── tests/           # *.tftest.hcl con mock_provider
```

---

## Convenciones de código

| Elemento | Convención | Ejemplo |
|---|---|---|
| Recursos / variables / outputs | `snake_case` | `enable_nat_gateway` |
| Nombre lógico de recurso único | `main` o nombre de su función | `aws_vpc.main`, `aws_instance.web` |
| Nombre en AWS | `iac-<env>-<recurso>` o `<recurso>-<env>` | `iac-prod-vpc` |
| Booleanos | prefijo `enable_` | `enable_detailed_monitoring` |
| Recursos opcionales | `count = var.enable_x ? 1 : 0` | NAT Gateway |
| Formato | `terraform fmt` (lo aplica el hook) | — |

- Toda variable y output lleva `description` (TFLint lo exige).
- Las excepciones de seguridad se documentan **inline** con `# checkov:skip=<ID>:<justificación>` en el recurso afectado. Una excepción global en `.checkov.yaml` solo se admite para políticas que dependen de una variable (p. ej. `CKV_AWS_126`).
- Los lock files (`.terraform.lock.hcl`) se versionan en `backend/` y `environments/*`; no en `modules/`.
- Nunca se versionan `*.tfstate`, `*.tfvars` ni planes (`tfplan`). Usa `terraform.tfvars.example` para documentar variables nuevas.

### Tests

Los tests usan `terraform test` con `mock_provider "aws" {}`: no requieren credenciales ni generan costos.

- Cada `validation` y `precondition` nueva debe tener un `run` con `expect_failures`.
- Cada cambio de comportamiento en un módulo debe tener un `run` con `assert`.

```bash
make test
```

---

## Comandos

| Comando | Descripción |
|---|---|
| `make init ENV=<env>` | `terraform init` con backend remoto |
| `make plan ENV=<env>` | Genera `environments/<env>/tfplan` |
| `make apply ENV=<env>` | Aplica exactamente el plan guardado |
| `make destroy ENV=<env>` | Destruye el ambiente |
| `make output ENV=<env>` | Muestra los outputs |
| `make fmt` / `make fmt-check` | Formatea / verifica formato |
| `make validate ENV=<env>` / `make validate-all` | Valida sin tocar el backend remoto |
| `make lint` | TFLint en todo el repo |
| `make test` | Tests de módulos |
| `make security-scan` | Checkov |
| `make ci` | Todos los checks de CI en local |
| `make clean` | Borra caches de providers y planes (nunca state ni lock files) |

`ENV` acepta solo `dev`, `staging` o `prod`.

---

## Flujo de trabajo de Git

### Ramas

- `main` está protegida y siempre es desplegable.
- Trabajo en ramas cortas: `<tipo>/<descripcion-corta>` → `feat/alb-module`, `fix/nat-routing`.

### Commits: [Conventional Commits](https://www.conventionalcommits.org/)

```text
<tipo>(<scope opcional>): <resumen en imperativo, minúsculas, sin punto>

<cuerpo opcional: qué y por qué, no cómo>
```

| Tipo | Uso |
|---|---|
| `feat` | Nuevo recurso, módulo o capacidad |
| `fix` | Corrección de un comportamiento incorrecto |
| `refactor` | Cambio interno sin efecto en la infraestructura desplegada |
| `test` | Tests nuevos o modificados |
| `ci` | Pipelines de GitHub Actions |
| `build` | Versiones de providers, lock files, tooling |
| `docs` | Documentación |
| `chore` | Mantenimiento que no encaja en lo anterior |

Scopes habituales: `networking`, `web_server`, `backend`, `envs`, `make`.

Un commit = un cambio lógico. Si un commit cambia recursos en AWS, el cuerpo debe decir **qué se reemplaza o modifica** al aplicarlo.

---

## Checklist de Pull Request

- [ ] `make ci` pasa en local.
- [ ] Se adjunta la salida de `make plan` para cada ambiente afectado (resumen `Plan: X to add, Y to change, Z to destroy`).
- [ ] Ningún recurso se **reemplaza** inesperadamente (`-/+` en el plan).
- [ ] Variables nuevas: `description`, `type`, `validation` cuando aplique y entrada en `terraform.tfvars.example`.
- [ ] Cambios de comportamiento cubiertos por tests.
- [ ] README actualizado si cambia la arquitectura, los costos o la interfaz.

---

## Operaciones sensibles

| Operación | Precaución |
|---|---|
| Cambiar `backend.tf` | Requiere `terraform init -migrate-state`. Nunca editar el state a mano. |
| `make destroy ENV=prod` | Solo con aprobación explícita. Verificar `AWS_PROFILE` y el ambiente antes de confirmar. |
| `backend/` | Su state es local e irrecuperable si se pierde. Bucket y tabla tienen `prevent_destroy`. |
| Cambios en `user_data` | `user_data_replace_on_change = true`: **reemplaza** la instancia. |
| Cambios en `root_block_device` | Pueden forzar el reemplazo de la instancia. |
| Checkov local vs CI | CI usa la última versión de Checkov (con checks de grafo `CKV2_*`). Mantén la local al día: `pip install -U checkov`. |
| State bloqueado | Confirmar que nadie está ejecutando `apply` antes de `terraform force-unlock <LOCK_ID>`. |
