# Prova do Primeiro Bimestre — DevOps

**Aluno:** Emar Cristian
**RA:** 6325192
**E-mail:** emar2nd@gmail.com
**GitHub:** iHawlKz7
**Disciplina:** DevOps
**Curso:** Análise e Desenvolvimento de Sistemas

---

## API de Reservas — TechNova

Projeto desenvolvido para a Prova do Primeiro Bimestre da disciplina de DevOps.

O objetivo foi construir uma solução completa e reproduzível para uma API de Reservas, aplicando os conteúdos estudados nas Aulas 01 a 07:

- Git e Conventional Commits
- Docker
- Docker Compose
- Terraform
- AWS
- VPC
- EC2
- RDS PostgreSQL
- Security Groups
- Remote State
- S3
- DynamoDB
- Terraform Modules
- IA como copiloto

---

## Arquitetura

### Ambiente local

    Cliente
       |
       v
    API Node.js / Express
       |
       v
    PostgreSQL

O ambiente local utiliza Docker Compose e possui:

- container da API;
- container PostgreSQL;
- volume nomeado para persistência;
- rede bridge própria;
- healthcheck do PostgreSQL;
- healthcheck da API através de `/health`;
- `depends_on` aguardando o banco ficar saudável;
- política de restart para os serviços.

Todo o ambiente local pode ser iniciado com:

    docker compose up -d --build

---

## Arquitetura AWS

    Internet
       |
       v
    Internet Gateway
       |
       v
    Subnet Pública
       |
       v
    EC2 - Docker - API :3000
       |
       | PostgreSQL :5432
       v
    Security Group
       |
       v
    RDS PostgreSQL
    Subnets Privadas

A infraestrutura AWS é provisionada com Terraform e contém:

- VPC;
- 2 subnets públicas em AZs diferentes;
- 2 subnets privadas em AZs diferentes;
- Internet Gateway;
- Route Table pública;
- Security Group da EC2;
- Security Group do RDS;
- EC2 t2.micro;
- RDS PostgreSQL db.t3.micro;
- S3 para Remote State;
- DynamoDB para locking.

O RDS possui:

- `publicly_accessible = false`;
- `storage_encrypted = true`;
- acesso à porta 5432 somente pelo Security Group da EC2.

A EC2 utiliza o instance profile fornecido pelo AWS Academy:

    LabInstanceProfile

Nenhum usuário, grupo ou role IAM próprio é criado.

---

## Estrutura do projeto

    prova-primeiro-bimestre-devops/
    ├── README.md
    ├── .gitignore
    ├── .env.example
    ├── docker-compose.yml
    ├── relatorio.md
    ├── app/
    │   ├── src/
    │   │   └── index.js
    │   ├── package.json
    │   ├── package-lock.json
    │   ├── Dockerfile
    │   └── .dockerignore
    ├── infra/
    │   ├── backend/
    │   ├── modules/
    │   │   ├── vpc/
    │   │   ├── security-group/
    │   │   ├── ec2/
    │   │   └── rds/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── providers.tf
    ├── scripts/
    │   ├── deploy-aws.sh
    │   └── destroy-aws.sh
    └── evidencias/

---

## API

### Health Check

    GET /health

### Criar reserva

    POST /reservas

Exemplo de corpo:

    {
      "cliente": "Teste AWS",
      "data": "2026-09-27",
      "status": "confirmada"
    }

### Listar reservas

    GET /reservas

### Buscar por ID

    GET /reservas/:id

### Atualizar reserva

    PUT /reservas/:id

### Excluir reserva

    DELETE /reservas/:id

Os dados são armazenados no PostgreSQL, tanto no ambiente local quanto na AWS.

---

## Execução local

Crie o arquivo `.env`:

    cp .env.example .env

Suba o ambiente:

    docker compose up -d --build

Verifique:

    docker compose ps

Os serviços `reservas-db` e `reservas-api` devem ficar com status `healthy`.

Teste:

    curl http://localhost:3000/health

Resultado esperado:

    {
      "status": "ok",
      "database": "connected"
    }

Para remover os containers:

    docker compose down

Para remover também o volume persistente:

    docker compose down -v

---

## AWS Academy

A solução foi desenvolvida utilizando o AWS Academy Learner Lab.

Região:

    us-east-1

Antes do deploy é necessário configurar as credenciais temporárias fornecidas pelo Learner Lab.

Validação:

    aws sts get-caller-identity

As credenciais do Learner Lab nunca são armazenadas no repositório.

---

## Deploy AWS

A senha do RDS deve ser fornecida por variável de ambiente e não é versionada.

O script valida a senha antes de criar recursos. Ela deve possuir entre 8 e 128 caracteres e obedecer às restrições utilizadas pelo Amazon RDS.

Exemplo:

    export DB_PASSWORD='SUA_SENHA'

Depois:

    ./scripts/deploy-aws.sh

O script:

1. valida a senha antes de qualquer criação na AWS;
2. valida as credenciais AWS;
3. identifica o Account ID;
4. identifica o IP público autorizado para SSH;
5. cria e configura o S3 e o DynamoDB do backend remoto;
6. inicializa o Remote State;
7. executa `terraform fmt`, `terraform validate` e `terraform plan`;
8. aplica a infraestrutura;
9. obtém a URL pública da API;
10. aguarda o endpoint `/health` responder com sucesso antes de declarar o deploy concluído.

O deploy somente termina com sucesso quando a API está acessível e conectada ao PostgreSQL.

---

## Terraform

Validação utilizada:

    cd infra
    terraform fmt -recursive
    terraform validate

Arquitetura modular:

    VPC
     |
     +--> Security Groups
     |
     +--> RDS
     |
     +--> EC2

    RDS endpoint
         |
         v
       EC2 / API

Os outputs de um módulo são utilizados como inputs de outros módulos.

Exemplos:

- o ID da VPC é utilizado pelo módulo de Security Groups;
- as subnets privadas são utilizadas pelo módulo RDS;
- o Security Group da EC2 é utilizado como origem permitida pelo RDS;
- o endpoint do RDS é enviado ao módulo EC2.

Após o deploy final foi executado um novo `terraform plan` com os mesmos parâmetros.

Resultado:

    No changes. Your infrastructure matches the configuration.

Isso confirmou que a infraestrutura implantada correspondia ao código Terraform versionado.

---

## Remote State

O projeto utiliza:

- Amazon S3 para armazenamento do Terraform State;
- versionamento do bucket;
- criptografia AES256;
- bloqueio de acesso público;
- DynamoDB para locking.

O AWS Academy possui restrições específicas de permissões S3. Durante o desenvolvimento, uma operação relacionada ao Object Lock foi bloqueada pela Service Control Policy do laboratório.

Por isso, a criação e configuração do bucket foi adaptada para utilizar AWS CLI, mantendo o Terraform responsável pelo DynamoDB e pela infraestrutura principal.

Na validação final foram conferidos diretamente:

- versionamento do bucket;
- criptografia AES256;
- Public Access Block;
- tags;
- existência do objeto `prova/terraform.tfstate`;
- tabela DynamoDB em estado `ACTIVE`;
- chave `LockID`.

---

## Segurança

As principais medidas aplicadas foram:

- RDS em subnets privadas;
- RDS não acessível publicamente;
- criptografia de armazenamento do RDS;
- porta 5432 disponível apenas para o Security Group da EC2;
- SSH limitado ao IP identificado durante o deploy;
- API exposta somente na porta necessária;
- nenhuma credencial versionada;
- `.env`, states e chaves ignorados pelo Git;
- uso do `LabInstanceProfile`;
- senha do RDS tratada como variável sensível no Terraform;
- transporte da senha para o `user_data` através de Base64 para evitar quebra de shell;
- conexão SSL entre a API e o RDS.

### Observação sobre TLS

No ambiente AWS a biblioteca `pg` é executada com SSL habilitado através de `DB_SSL=true`.

A configuração utiliza `rejectUnauthorized: false`, portanto o tráfego com o RDS é criptografado, porém a aplicação não realiza validação completa da cadeia do certificado do servidor.

Para um ambiente de produção fora do contexto acadêmico, a recomendação seria utilizar a CA oficial do Amazon RDS e habilitar a validação do certificado.

---

## Validação funcional

A versão final foi validada em um clone novo do repositório.

### Ambiente local

Foram confirmados:

- build da imagem Docker;
- PostgreSQL saudável;
- API saudável;
- POST de reserva;
- GET da lista;
- GET por ID;
- PUT;
- persistência após reiniciar apenas a API;
- DELETE;
- HTTP 404 após a exclusão.

### Ambiente AWS

Foram confirmados:

- deploy completo;
- `/health` retornando HTTP 200;
- conexão com o RDS;
- POST;
- GET;
- GET por ID;
- PUT;
- reinício somente do container da API através do AWS Systems Manager;
- persistência da reserva após o restart;
- DELETE;
- HTTP 404 após o DELETE.

Após os testes funcionais:

    No changes. Your infrastructure matches the configuration.

---

## Evidências

A pasta `evidencias/` contém os registros utilizados na validação final.

Principais arquivos:

- `docker-build.txt` — build Docker;
- `compose-ps.txt` — estado dos containers locais;
- `docker-clone-final.txt` — teste completo a partir de clone novo;
- `aws-deploy-final.txt` — provisionamento final da AWS e espera pelo `/health`;
- `aws-api-final.txt` — CRUD AWS, restart da API e persistência;
- `terraform-plan-final.txt` — confirmação de `No changes`;
- `backend-final.txt` — S3, Remote State e DynamoDB;
- `destroy-final.txt` — destruição completa e verificações finais.

---

## Git Workflow

O projeto utilizou:

- branch `main`;
- feature branch `feature/api-reservas`;
- branch de correção `fix/validacao-final-prova`;
- merges explícitos;
- Conventional Commits.

Exemplos do histórico:

    feat(api): implementa CRUD de reservas com PostgreSQL
    feat(docker): adiciona container da API de reservas
    feat(compose): adiciona API e PostgreSQL com healthcheck
    feat(terraform): adiciona backend S3 e DynamoDB
    fix(terraform): adapta backend as restricoes do AWS Academy
    fix(api): habilita SSL na conexao com RDS
    fix: reforca validacao e reproducibilidade da prova
    fix: valida senha do RDS antes do deploy
    fix: remove backend remoto no destroy

O projeto possui mais de seis commits utilizando o padrão Conventional Commits.

---

## Destruição da infraestrutura

Após capturar todas as evidências:

    ./scripts/destroy-aws.sh

O script realiza:

1. destruição da infraestrutura principal pelo Terraform;
2. confirmação de que o state principal ficou vazio;
3. destruição da tabela DynamoDB;
4. remoção de todas as versões e Delete Markers do bucket S3;
5. remoção do bucket;
6. verificação final de EC2, RDS, VPC, DynamoDB e S3.

Na execução final foram confirmados:

    State principal vazio.
    EC2 removida/terminada.
    RDS removido.
    VPC removida.
    DynamoDB removido.
    Bucket S3 removido.
    Destroy completo: todos os recursos removidos

---

## Ferramenta de IA

Foi utilizada IA como copiloto durante o desenvolvimento.

O uso da ferramenta, as validações realizadas, as sugestões que falharam e as correções necessárias estão documentados em:

    relatorio.md
