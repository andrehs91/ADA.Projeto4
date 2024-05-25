# ADA Tech - Módulo 4 (Provisionamento como Código)

Este projeto utiliza como base a solução desenvolvida nas fases 1, 2 e 3 do curso, adaptada para utilizar os serviços de armazenamento da Azure.

### Regras de Negócio
O sistema calcula, através das coordenadas geográficas, a distância entre os pontos da última transação válida e a trnasação corrente. Caso a distância de deslocamento seja maior que 60km/h ela será considerada como fraudulenta.

### Estrutura da Solução
- Todos os serviços rodam em <u>Containers Docker</u>.
- O serviço de nuvem escolhido para hospedar os containers foi o <u>Azure Container Apps</u>.

**Componentes:**
- **Producer:** (ASP.NET Core Web API) contendo uma interface Swagger para envio das transações para processamento e consulta aos relatórios;
- **Mensageria:** (RabbitMQ) para comunicação assíncrona entre os serviços;
- **Consumer:** (Worker Service) para processamento das transações;
- **Cache:** (Redis) para melhora no desempenho do processamento das transações;
- **Armazenamento:** (Azure Storage Account) para armazenamento dos relatórios e para persistência dos containers;

### Como Executar este Projeto
> :warning: **Importante:** Você deve possuir uma assinatura na Azure e estar autenticado para executar os passos a seguir.

1. Acesse a pasta Terraform e execute o arquivo backend.sh: ` ./backend.sh `
2. Identifique o nome do container criado no Azure Storage Account e substitua o valor ` <SUBSTITUIR> ` do arquivo 01.main.tf por ele
3. Inicialize o projeto: ` terraform init `
4. Valide o projeto: ` terraform validate `
5. Crie um *workspace*: ` terraform workspace new dev `
6. Crie um arquivo de variáveis observando os itens necessários conforme o arquivo 00.variables.tf (sugestão de nome: dev.tfvars)
7. Planeje a implantação: ` terraform plan -var-file="dev.tfvars" `
8. Provisione os recursos definidos: ` terraform apply -var-file="dev.tfvars" `
9. Realize os teste desejados utilizando o endereço retornado ao final da execução: ` <SUBSTITUIR>/swagger/index.html `
10. Destrua o ambiente para evitar custos: ` terraform destroy -var-file="dev.tfvars" `

### Observações
1. O recurso "azurerm_container_app", que define uma instância do Container App, possui configurações complexas e transformá-lo em um componente não iria simplificar sua utilização, pelo contrário;
2. O Terraform não consegue realizar todas as configurações do Container App. Por isso, para a instância do RabbitMQ, na opção Ingress, a porta TCP 5672 deverá ser adicionada manualmente no bloco *Additional TCP ports* (o mesmo valor deverá ser informado para *Target port* e *Exposed port*)
3. Uma VNET e uma SUBNET foram criadas, mas não foram vinculadas aos serviços criados pois isto demandaria mais configurações para expor o Producer e eu não possuo conhecimentos suficientes em redes para tanto.
4. Um módulo para abstrair o *azurerm_storage_share* foi criado, mas tive problemas em referenciar suas intâncias em cláusulas de dependência, por isso ele não foi utilizado.
5. O container do RabbitMQ não possui volume montado pois a montagem gerava erros que eu não consegui solucionador.

### Justificativas
1. O Azure Container Apps foi escolhido como *host* pois ele possui configurações interessantes de orquestração de containers sem a complexidade do AKS, além de criar um ambiente isolado (que pode ser exposto) para a execução dos trabalhos.
2. Os componentes foram separados em aqruivos distintos conforme sua ordem de precedência e afinidade;
3. Foram incluidos *endpoint* para a conferência do valor das variáveis do sistema e para testes das conexões com os serviços de cache e mensageria.
