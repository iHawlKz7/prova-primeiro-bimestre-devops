# Prova do Primeiro Bimestre — DevOps

**Aluno:** Emar Cristian  
**RA:** 6325192  
**Disciplina:** DevOps  
**Curso:** Análise e Desenvolvimento de Sistemas

## API de Reservas — TechNova

Projeto desenvolvido para a prova do primeiro bimestre da disciplina de DevOps.

A aplicação implementa uma API REST para gerenciamento de reservas utilizando:

- Node.js
- Express
- PostgreSQL
- Docker
- Docker Compose
- Terraform
- AWS VPC
- Amazon EC2
- Amazon RDS
- Amazon S3
- Amazon DynamoDB

A solução possui dois ambientes:

- Local: Docker Compose
- Nuvem: AWS Academy Learner Lab

## Rotas

| Método | Rota | Descrição |
|---|---|---|
| POST | `/reservas` | Criar reserva |
| GET | `/reservas` | Listar reservas |
| GET | `/reservas/:id` | Buscar reserva |
| PUT | `/reservas/:id` | Atualizar reserva |
| DELETE | `/reservas/:id` | Excluir reserva |
| GET | `/health` | Health check |

## Execução local

```bash
docker compose up -d --build