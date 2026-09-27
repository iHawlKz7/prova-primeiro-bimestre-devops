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
- volume nomeado;
- rede bridge própria;
- healthcheck do PostgreSQL;
- depends_on aguardando o banco ficar saudável.

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

- publicly_accessible = false;
- storage_encrypted = true;
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

Crie o arquivo .env:

    cp .env.example .env

Suba o ambiente:

    docker compose up -d --build

Verifique:

    docker compose ps

Teste:

    curl http://localhost:3000/health

Resultado esperado:

    {
      "status": "ok",
      "database": "connected"
    }

Para remover os containers:

    docker compose down

---

## AWS Academy

A solução foi desenvolvida utilizando o AWS Academy Learner Lab.

Região:

    us-east-1

Antes do deploy é necessário configurar as credenciais temporárias fornecidas pelo Learner Lab.

Validação:

    aws sts get-caller-identity

---

## Deploy AWS

A senha do RDS deve ser fornecida por variável de ambiente e não é versionada:

    export DB_PASSWORD='SUA_SENHA'

Depois:

    ./scripts/deploy-aws.sh

O script:

1. valida as credenciais AWS;
2. identifica o Account ID;
3. identifica o IP autorizado para SSH;
4. prepara S3 e DynamoDB;
5. inicializa o Remote State;
6. executa terraform validate;
7. executa terraform plan;
8. provisiona a infraestrutura.

---

## Terraform

Validação:

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

---

## Remote State

O projeto utiliza:

- Amazon S3 para armazenamento do Terraform State;
- versionamento do bucket;
- criptografia;
- bloqueio de acesso público;
- DynamoDB para locking.

O AWS Academy possui algumas restrições específicas de permissões S3. Por isso, a criação e configuração do bucket foi adaptada para utilizar AWS CLI, mantendo o Terraform responsável pelo restante da infraestrutura.

---

## Segurança

As principais medidas aplicadas foram:

- RDS em subnets privadas;
- RDS não acessível publicamente;
- criptografia do RDS habilitada;
- porta 5432 disponível apenas para o Security Group da EC2;
- SSH limitado ao IP identificado durante o deploy;
- API exposta na porta 3000;
- nenhuma credencial versionada;
- .env, states e chaves ignorados pelo Git;
- uso do LabInstanceProfile;
- conexão SSL entre a API e o RDS.

---

## Evidências

A pasta evidencias/ contém registros de:

- Docker build;
- Docker Compose;
- Terraform Plan;
- Terraform Outputs;
- testes da API AWS;
- histórico Git.

---

## Git Workflow

O projeto utilizou:

- branch main;
- feature branch feature/api-reservas;
- merge explícito;
- Conventional Commits.

Exemplos:

    feat(api): implementa CRUD de reservas com PostgreSQL
    feat(docker): adiciona container da API de reservas
    feat(compose): adiciona API e PostgreSQL com healthcheck
    feat(terraform): adiciona backend S3 e DynamoDB
    fix(terraform): adapta backend as restricoes do AWS Academy
    fix(api): habilita SSL na conexao com RDS
    docs(evidencias): adiciona validacoes local e AWS

---

## Destruição da infraestrutura

Após capturar as evidências, a infraestrutura deve ser removida para evitar consumo dos créditos do Learner Lab:

    ./scripts/destroy-aws.sh

---

## Ferramenta de IA

Foi utilizada IA como copiloto durante o desenvolvimento.

O uso, as validações realizadas, os erros encontrados e as correções feitas estão documentados em:

    relatorio.md