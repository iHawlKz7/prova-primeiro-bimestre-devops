# Relatório do Processo — Prova do Primeiro Bimestre

**Aluno:** Emar Cristian
**RA:** 6325192
**Ferramenta de IA utilizada:** ChatGPT

---

# Questão 1 — A Jornada Completa (Aulas 01 a 07)

A construção da API de Reservas foi realizada seguindo a evolução dos conteúdos apresentados durante o primeiro bimestre. O primeiro passo foi utilizar os conceitos da Aula 01 para criar o repositório Git, configurar a estrutura inicial e manter um histórico utilizando Conventional Commits. Também foi criada uma feature branch para desenvolver a solução antes de realizar o merge com a branch principal. Ainda com conteúdos da Aula 01, a API Node.js/Express foi containerizada utilizando Dockerfile multi-stage e execução com usuário não-root.

Na Aula 02, os conceitos de Docker Compose foram aplicados para criar um ambiente local contendo dois serviços: a API e o PostgreSQL. Foi criado um volume nomeado para persistência, uma rede bridge própria, healthcheck no banco e dependência da API em relação ao banco saudável. Dessa forma, todo o ambiente local passou a subir com um único comando utilizando docker compose up -d --build.

Os conceitos de Terraform vistos a partir da Aula 03 foram utilizados para transformar a infraestrutura AWS em código. Em vez de criar manualmente os recursos pelo console, VPC, subnets, Security Groups, EC2 e RDS foram declarados utilizando arquivos Terraform. Também foram utilizadas variáveis, outputs e providers.

Os conhecimentos de rede da Aula 04 foram utilizados para criar uma VPC com subnets públicas e privadas distribuídas entre duas zonas de disponibilidade. A EC2 foi colocada em uma subnet pública e recebeu acesso pela porta 3000, enquanto o RDS permaneceu em subnets privadas. O Internet Gateway e a Route Table foram responsáveis pelo acesso externo da aplicação.

Na Aula 05, os conhecimentos de RDS e Remote State foram aplicados. O PostgreSQL foi provisionado no RDS com criptografia habilitada, acesso público desabilitado e Security Group permitindo a porta 5432 somente a partir do Security Group da EC2. Para armazenar o Terraform State remotamente foi criado um bucket S3 e uma tabela DynamoDB para locking.

A Aula 06 apareceu principalmente na modularização. Foram criados módulos separados para VPC, Security Groups, EC2 e RDS. Os módulos foram compostos através de outputs e inputs. Por exemplo, o ID da VPC produzido pelo módulo de VPC é enviado ao módulo de Security Groups, os IDs das subnets privadas são enviados ao módulo de RDS e o endpoint do RDS é enviado para a EC2.

Por fim, a Aula 07 foi aplicada no processo de desenvolvimento. A solução não foi construída de uma só vez. O trabalho foi dividido em pequenas etapas: aplicação, Docker, Compose, backend remoto, módulos, infraestrutura, testes e documentação. Cada parte foi validada antes de seguir para a próxima, utilizando a IA como apoio, mas verificando seus resultados por meio de comandos reais.

---

# Questão 2 — O Processo com IA como Copiloto

A ferramenta de IA utilizada como copiloto durante o desenvolvimento foi o ChatGPT. O trabalho foi conduzido de forma incremental, utilizando prompts voltados para tarefas pequenas em vez de solicitar toda a prova em um único comando. Entre os principais pedidos realizados estavam a criação da estrutura da API Node.js/Express, configuração do Dockerfile, Docker Compose, módulos Terraform, scripts de deploy e análise dos erros encontrados durante as validações.

Um dos prompts utilizados foi equivalente a: "Crie a estrutura da API Node.js/Express com CRUD completo de reservas e persistência PostgreSQL". Outro prompt pediu a criação de um Dockerfile multi-stage com usuário não-root e outro solicitou um Docker Compose contendo API, PostgreSQL, volume, rede, healthcheck e depends_on. Na infraestrutura, foram solicitados módulos Terraform separados para VPC, Security Groups, EC2 e RDS, considerando explicitamente o ambiente AWS Academy Learner Lab.

A IA economizou bastante tempo na criação das estruturas iniciais dos arquivos e na organização da sequência de implementação. Ela também ajudou na investigação de erros porque foi possível fornecer diretamente os outputs do terminal e analisar o que estava acontecendo em cada etapa.

Ao mesmo tempo, nem todas as sugestões funcionaram na primeira tentativa. Um dos problemas ocorreu na criação do bucket S3 com Terraform. O AWS Academy possui uma Service Control Policy que bloqueou a operação s3:GetBucketObjectLockConfiguration. A primeira solução não havia considerado essa restrição específica do ambiente. Foi necessário analisar o erro e adaptar o processo para que o bucket fosse criado e configurado pela AWS CLI enquanto o restante continuava sendo gerenciado normalmente.

Outro problema aconteceu quando a aplicação foi executada na EC2. O Docker funcionava e o container era criado, mas permanecia reiniciando. A análise dos logs mostrou a mensagem "no pg_hba.conf entry ... no encryption". A aplicação funcionava corretamente com o PostgreSQL local, mas o RDS exigia conexão criptografada. Foi necessário corrigir a configuração do pg para utilizar SSL na AWS, mantendo o ambiente Docker local sem SSL.

Esses casos demonstraram uma diferença importante entre utilizar IA como geradora de código e utilizar IA como copiloto. O código sugerido precisou ser executado, observado e validado. Quando o comportamento real divergiu da sugestão, os logs e os comandos de diagnóstico foram utilizados para determinar o problema.

Comparado com fazer tudo manualmente, a IA reduziu bastante o tempo de escrita inicial e de consulta de sintaxe. Porém, quando uma sugestão não considerava uma limitação específica do Learner Lab, ela também aumentava o trabalho necessário para investigar e corrigir. Por isso, o maior benefício ocorreu quando a IA foi utilizada para acelerar tarefas pequenas enquanto cada resultado era validado antes de continuar.

---

# Questão 3 — Infraestrutura, Segurança e o Learner Lab

A arquitetura AWS criada para a prova possui uma VPC própria com quatro subnets distribuídas em duas zonas de disponibilidade. Existem duas subnets públicas e duas subnets privadas. A instância EC2 responsável pela API fica em uma subnet pública, enquanto o RDS PostgreSQL fica exclusivamente nas subnets privadas.

A EC2 precisa estar em uma subnet pública porque é o ponto de entrada da aplicação. Ela possui endereço IP público e sua porta 3000 é utilizada para acessar a API. A subnet pública possui rota para um Internet Gateway, permitindo que usuários externos façam requisições para a API.

O RDS não precisa receber conexões diretamente da Internet e, por isso, foi colocado nas subnets privadas. O atributo publicly_accessible foi configurado como false. Além disso, o Security Group do RDS permite conexões na porta 5432 somente quando a origem é o Security Group utilizado pela EC2. Assim, mesmo dentro da VPC, o banco não fica disponível de forma indiscriminada.

O RDS também foi configurado com storage_encrypted = true. Durante os testes foi identificado que a conexão da aplicação com o PostgreSQL precisava utilizar SSL. A API foi então configurada para ativar SSL no ambiente AWS através da variável DB_SSL, mantendo o funcionamento local compatível com o PostgreSQL do Docker Compose.

No AWS Academy Learner Lab existem restrições diferentes de uma conta AWS comum. As credenciais são temporárias e possuem Access Key, Secret Access Key e Session Token. Sempre que o laboratório é reiniciado, essas credenciais podem precisar ser atualizadas no arquivo ~/.aws/credentials. A região utilizada em toda a prova foi us-east-1.

Outra limitação importante é que o Learner Lab não permite criar livremente usuários, grupos e roles IAM. Por esse motivo não foi criado IAM próprio. A instância EC2 utiliza o LabInstanceProfile, que já existe no ambiente fornecido pelo Academy.

Também foi encontrada uma restrição específica relacionada ao S3. A Service Control Policy do laboratório bloqueou uma leitura relacionada ao Object Lock quando o Terraform tentou gerenciar o bucket diretamente. Para manter o Remote State funcionando, o processo foi adaptado e o bucket S3 passou a ser criado e configurado através da AWS CLI. O bucket utiliza versionamento, criptografia e bloqueio de acesso público. O DynamoDB continua sendo utilizado como mecanismo de locking conforme estudado nas aulas e exigido pelo enunciado.

Essa experiência mostrou que uma configuração válida em uma conta AWS comum pode precisar de adaptações dentro do Learner Lab, tornando a leitura das mensagens de erro e a validação prática essenciais.

---

# Questão 4 — Validação e Responsabilidade

Antes de executar qualquer terraform apply, foi utilizado um checklist de validação. Primeiro foi executado terraform fmt -recursive para garantir a formatação dos arquivos. Depois foi executado terraform validate para confirmar que as referências, módulos, variáveis e sintaxe estavam corretos. Somente após essa etapa foi executado terraform plan.

Durante o terraform plan, foram verificados os tipos e quantidades de recursos que seriam criados. Também foram revisados itens de segurança, principalmente o posicionamento do RDS, o atributo publicly_accessible = false, criptografia do armazenamento e a regra de Security Group limitando a porta 5432 à EC2.

Depois do terraform apply, a validação continuou. O estado da EC2 foi verificado pela AWS CLI e os status checks do sistema e da instância ficaram como ok. A instância também foi verificada através do AWS Systems Manager.

Os containers foram analisados utilizando docker ps -a e docker logs. Foi justamente através dessa validação que foi detectado o problema de SSL entre a aplicação e o RDS. O container existia, mas estava reiniciando. Sem analisar os logs, seria possível interpretar incorretamente que apenas a rede ou a EC2 estavam com problema.

Após a correção, o endpoint /health retornou status ok e database connected. Em seguida foram executadas operações reais de Create, Read, Update e Delete na API hospedada na EC2. A reserva criada foi armazenada no RDS, recuperada, atualizada, removida e posteriormente retornou HTTP 404, confirmando o funcionamento completo.

Se o código gerado pela IA tivesse sido aceito sem revisão, a infraestrutura poderia aparentar sucesso porque o Terraform criou os recursos corretamente, enquanto a aplicação continuaria indisponível devido à falha na conexão PostgreSQL. Da mesma forma, a tentativa inicial de gerenciamento do bucket S3 não funcionaria corretamente dentro das restrições do Learner Lab.

A evolução Git → Docker → Docker Compose → Terraform → Modules ajudou a desenvolver um processo de validação em camadas. Git permitiu registrar mudanças e correções; Docker tornou o ambiente reproduzível; Compose permitiu validar a integração local; Terraform permitiu revisar a infraestrutura antes da criação; e os módulos reduziram dependências implícitas, tornando os relacionamentos entre recursos mais visíveis.

Por isso, a IA foi utilizada como ferramenta de apoio e não como fonte final de verdade. Cada sugestão relevante foi confirmada através de comandos, logs, testes HTTP, Terraform Plan e observação direta dos recursos AWS antes de considerar a etapa concluída.