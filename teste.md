Quero construir um pipeline de dados completo em arquitetura medalhão
(bronze → silver → gold) e um dashboard AI/BI no final, usando como fonte o dataset
`samples.bakehouse`. Faça tudo como recursos de Asset Bundle deste
projeto, com um único Lakeflow Declarative Pipeline serverless.
Nunca escreva no catálogo `samples` — ele é somente leitura.

Negócio: a Bakehouse tem 48 franquias em 9 países. Quero acompanhar receita, pedidos,
ticket médio, mix de produtos, desempenho por franquia/país e a satisfação dos clientes.

Estrutura — um schema por camada: o catálogo é `bakehouse_dev` (já existe,
não crie). Quero três schemas, com exatamente estes nomes: `bronze`, `silver`, `gold`,
declarados como **recursos `schemas:` do bundle. O schema é a camada, então as tabelas
não levam prefixo de camada: é `bronze.customers` e `silver.customers`, nunca `bronze_customers`.

- `bronze`: ingestão bruta de `sales_transactions`, `sales_franchises`, `sales_customers`,
`sales_suppliers` e `media_customer_reviews` → tabelas `transactions`, `franchises`,
`customers`, `suppliers`, `reviews`, com colunas de metadados de ingestão.
- `silver`:** dados limpos e conformados — tipos corretos, colunas de data derivadas
(dia/mês), padronização de país (`US` vs `USA`), transações enriquecidas com franquia e
cliente, e regras de qualidade (expectations). Tabelas: `customers`, `franchises`,
`transactions` e `reviews_sentiment` (esta com `ai_analyze_sentiment`).
- `gold`: marts prontos para BI — `daily_sales_by_franchise`, `sales_by_product`,
`franchise_performance` (com cidade, país, latitude/longitude), `sales_by_country`,
`top_customers` e `sentiment_by_franchise`.

Depois crie um dashboard AI/BI (Lakeview) sobre as tabelas gold com: KPIs (receita total,
pedidos, ticket médio, franquias ativas), série temporal de receita diária, receita por
produto, ranking de franquias, mapa geográfico das franquias por receita, mix de meio de
pagamento e visão de sentimento dos reviews. Teste todas as queries SQL antes de publicar.

Por fim, adicione um Job que orquestra o pipeline, faça o deploy do bundle no target
`dev` e rode o pipeline para materializar as tabelas. Valide os dados no fim (contagens
por camada). Vá explicando cada passo.