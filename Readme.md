### Terraform para Keycloak

Um stack separado (`terraform-keycloak/`) provisiona uma instância do Keycloak em ECS Fargate com:

- VPC dedicada, ALB e security groups.
- RDS PostgreSQL (armazenamento dos dados do Keycloak).
- Serviço ECS com a imagem oficial (`quay.io/keycloak/keycloak:<versão>`).

Os arquivos seguem a mesma estrutura (`providers.tf`, `variables.tf`, `main.tf`, `outputs.tf`). Para utilizar:

```bash
cd terraform-keycloak
terraform init \
  -backend-config="bucket=<bucket-state>" \
  -backend-config="key=<prefixo>/terraform-keycloak.tfstate" \
  -backend-config="region=<aws-region>" \
  -backend-config="dynamodb_table=<tabela-lock>"
terraform plan \
  -var admin_password=<senha-admin> \
  -var db_admin_password=<senha-db>
terraform apply \
  -var admin_password=<senha-admin> \
  -var db_admin_password=<senha-db>
```

> **Importante**: definições de senha (`admin_password`, `db_admin_password`) não têm valor padrão. Passe-as via CLI ou arquivo de variáveis seguro. O output `alb_dns` indica o endpoint público do Keycloak; use-o para apontar o `KEYCLOAK_ISSUER` da API.

### Deploy automatizado com GitHub Actions

O workflow `.github/workflows/terraform.yml` roda automaticamente:

- `terraform plan` em _pull requests_ para `main` (o plano é publicado como artifact).
- `terraform plan` + `terraform apply` em pushes para `main`.
- Execução manual (`workflow_dispatch`), onde é possível forçar o apply marcando o input `apply_on_dispatch=true`.

Configure os segredos/variáveis do repositório antes de habilitar o pipeline:

| Tipo       | Nome                         | Descrição                                                                 |
|------------|------------------------------|---------------------------------------------------------------------------|
| Secret     | `AWS_ACCESS_KEY_ID`          | Access key com permissão de aplicar o Terraform.                          |
| Secret     | `AWS_SECRET_ACCESS_KEY`      | Secret key correspondente.                                               |
| Secret     | `TF_BACKEND_BUCKET`          | Bucket S3 usado pelo backend remoto.                                     |
| Secret     | `TF_BACKEND_REGION`          | Região do bucket (ex: `us-east-1`).                                      |
| Secret     | `TF_BACKEND_DYNAMO_TABLE`    | (Opcional) tabela DynamoDB para lock do estado.                          |
| Secret     | `TF_STATE_KEY`               | Caminho/objeto do estado (`postech-car-keycloak/terraform.tfstate`).     |
| Secret     | `KEYCLOAK_ADMIN_PASSWORD`    | Valor de `admin_password`.                                               |
| Secret     | `KEYCLOAK_DB_PASSWORD`       | Valor de `db_admin_password`.                                            |
| Variable   | `AWS_REGION`                 | (Opcional) Região default usada pelo provider e pelo workflow.           |

> Caso `TF_BACKEND_REGION` não seja informado, o workflow usa `AWS_REGION` (ou `us-east-1`). Sem `TF_BACKEND_DYNAMO_TABLE`, a etapa de lock remoto simplesmente é ignorada.
