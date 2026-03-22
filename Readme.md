### Terraform para App + Cognito

O diretório `terraform/` provisiona toda a infra necessária para rodar a aplicação e autenticar usuários via Amazon Cognito:

- VPC dedicada com sub-redes públicas, IGW, rotas e security groups.
- Repositório ECR, ECS Fargate (task definition + service) e um Application Load Balancer para a aplicação principal.
- Cognito User Pool + App Client + domínio público para usar o Hosted UI/fluxo OAuth.

Para usar localmente:

```bash
cd terraform
terraform init \
  -backend-config="bucket=<bucket-state>" \
  -backend-config="key=<prefixo>/terraform.tfstate" \
  -backend-config="region=<aws-region>" \
  -backend-config="dynamodb_table=<tabela-lock>"
terraform plan \
  -var-file=<opcional>.tfvars
terraform apply \
  -var-file=<opcional>.tfvars
```

Variáveis úteis:

- `app_container_image`: informe o URI completo caso queira usar uma imagem já existente (por padrão, usa o ECR criado aqui com a tag `latest`).
- `cognito_callback_urls` / `cognito_logout_urls`: listas com as URLs autorizadas no User Pool Client.

> Os outputs incluem o DNS do ALB da aplicação e os identificadores do User Pool, App Client e domínio Cognito para integrar o front-end.

### Deploy automatizado com GitHub Actions

O workflow `.github/workflows/terraform.yml` executa:

- `terraform plan` em _pull requests_ para `main` (publicando o plano como artifact).
- `terraform plan` + `terraform apply` em pushes para `main`.
- Execução manual (`workflow_dispatch`), onde é possível forçar o apply marcando o input `apply_on_dispatch=true` ou destruir tudo (input `destroy=true`).

Configure os segredos/variáveis antes de habilitar o pipeline:

| Tipo     | Nome                      | Descrição                                                             |
|----------|---------------------------|------------------------------------------------------------------------|
| Secret   | `AWS_ACCESS_KEY_ID`       | Access key com permissão de aplicar o Terraform.                       |
| Secret   | `AWS_SECRET_ACCESS_KEY`   | Secret key correspondente.                                            |
| Secret   | `TF_BACKEND_BUCKET`       | Bucket S3 usado pelo backend remoto.                                  |
| Secret   | `TF_BACKEND_REGION`       | Região do bucket (ex.: `us-east-1`).                                   |
| Secret   | `TF_BACKEND_DYNAMO_TABLE` | (Opcional) tabela DynamoDB para lock do estado.                       |
| Secret   | `TF_STATE_KEY`            | Caminho/objeto do estado (`postech-car/terraform.tfstate`, por ex.).  |
| Variable | `AWS_REGION`              | (Opcional) Região default usada pelo provider e pelo workflow.        |

> Caso `TF_BACKEND_REGION` não seja informado, o workflow usa `AWS_REGION` (ou `us-east-1`). Sem `TF_BACKEND_DYNAMO_TABLE`, a etapa de lock remoto é ignorada.
