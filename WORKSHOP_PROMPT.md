# Workshop — Ambiente local de Databricks com IA (Asset Bundles, MCP e AI Dev Kit)

Roteiro do demo ao vivo: construir um **pipeline em arquitetura medalhão** + **dashboard AI/BI**
a partir de dados reais do Unity Catalog, tudo como recursos de **Asset Bundle**, dirigido por
**Claude + MCP Databricks + AI Dev Kit (skills)**.

---

## 1. A ideia (fonte: `samples.bakehouse`)

`samples.bakehouse` é um dataset pronto no workspace (rede fictícia de padarias "Bakehouse").
É perfeito para medalhão porque é 100% de negócio, tem várias tabelas relacionadas, dados
geográficos (mapa) e texto (reviews → IA). Já validado neste workspace:

| Tabela de origem | Linhas | O que é |
| --- | --- | --- |
| `sales_transactions` | 3.333 | Vendas (1–17/maio/2024): produto, quantidade, preço, meio de pagamento |
| `sales_franchises` | 48 | Franquias em 9 países, com cidade + **latitude/longitude** |
| `sales_customers` | 300 | Clientes (USA, Austrália, Japão) |
| `sales_suppliers` | 27 | Fornecedores / ingredientes |
| `media_customer_reviews` | 204 | **Reviews em texto** → gancho para IA (sentimento) |

Fatos úteis (já checados): 6 produtos, ticket médio ~US$ 20, 3 meios de pagamento
(mastercard/amex/visa), e um bom "momento de ensino" de qualidade de dados: o país aparece
como `US` nas franquias e `USA` nos clientes → padronização na silver.

---

## 2. O desenho — um schema por camada

A mudança em relação à primeira versão: em vez de **um schema só com prefixos** nos nomes
(`bronze_customers`, `silver_customers`, …), agora **o schema É a camada**. O nome da tabela
fica limpo e a mesma entidade atravessa as camadas com o mesmo nome:

```
bakehouse_dev                      ← catálogo (já existe, criado fora do palco)
├── bronze                         ← ingestão bruta + metadados
│   ├── customers
│   ├── franchises
│   ├── suppliers
│   ├── transactions
│   └── reviews
├── silver                         ← limpo, conformado, com expectations
│   ├── customers
│   ├── franchises
│   ├── transactions              ← enriquecida com franquia + cliente
│   └── reviews_sentiment         ← ai_analyze_sentiment (destaque de IA)
└── gold                           ← marts prontos para BI
    ├── daily_sales_by_franchise
    ├── sales_by_product
    ├── franchise_performance     ← com cidade, país, lat/long (mapa)
    ├── sales_by_country
    ├── top_customers
    └── sentiment_by_franchise
```

`bakehouse_dev.bronze.customers` → `bakehouse_dev.silver.customers`. Lado a lado no Catalog
Explorer, a arquitetura se explica sozinha — é um ganho didático real para o palco.

**Como isso funciona num pipeline só** — anotação para quem apresenta; o prompt de §4 **não**
prescreve isso, porque a skill de SDP já leva o agente a um caminho que funciona. Os **dois**
caminhos foram testados neste workspace (§5) e ambos publicam certo:

- **Nome de 2 partes** — `CREATE OR REFRESH STREAMING TABLE silver.customers`, com o pipeline
  declarando `catalog` + `schema: bronze`. O catálogo é herdado; não precisa de `${}`.
- **Nome de 3 partes com substituição** — `CREATE OR REFRESH STREAMING TABLE
  ${medallion_catalog}.${silver_schema}.customers`, lendo as chaves do `configuration:` do
  pipeline. É o que a skill mostra no exemplo SQL dela.

Leitura cross-schema funciona nos dois (`FROM STREAM bronze.customers`). Se o agente escolher
um terceiro caminho estranho ao vivo, é aqui que você tem a munição para corrigir.

Entregue como: **Lakeflow Declarative Pipeline serverless** (bronze→silver→gold) + os **schemas
como recursos do bundle** + **Job** que orquestra + **Dashboard AI/BI**, todos em `resources/*.yml`
+ `src/`, no target `dev`.

---

## 3. Pré-requisito (fora do palco)

Os catálogos **`bakehouse_dev` e `bakehouse_prod` já existem** — criados antes do workshop com:

```sql
CREATE CATALOG IF NOT EXISTS bakehouse_dev;
CREATE CATALOG IF NOT EXISTS bakehouse_prod;   -- para o fecho em prod (ver §5)
```

**Por que não é recurso do bundle:** neste workspace (Free Edition, *Default Storage*), criar
catálogo pela API REST falha com `Metastore storage root URL does not exist`. O recurso
`catalogs:` do bundle usa exatamente essa API — e ainda exige `bundle.engine: direct`. Testado:
falha nos dois motores. Só o caminho **SQL** funciona. Os schemas (`bronze`/`silver`/`gold`), esses
sim, funcionam como recurso de bundle normalmente.

Estado atual do repo: `src/` e `resources/` estão **vazios** e o bundle está **destruído** —
o agente constrói tudo do zero ao vivo. `databricks.yml` continua com o esqueleto do
`bundle init` (variáveis `catalog`/`schema` antigas, `mode: development`): faz parte do
trabalho do agente reconfigurá-lo.

Uma coisa **já** foi consertada ali: os dois targets levam `workspace.profile: DEFAULT`. Dois
profiles locais casam com este host, e sem isso todo comando do CLI morre com
`multiple profiles matched` até alguém lembrar do `--profile DEFAULT`. Isso é encanamento da
máquina, não parte do demo — resolvido na raiz para não virar linha de prompt nem tropeço de
palco. Se o agente reescrever os targets, confira que a linha sobreviveu.

---

## 4. O prompt para colar ao vivo

> **Contexto:** quero construir um pipeline de dados completo em **arquitetura medalhão
> (bronze → silver → gold)** e um **dashboard AI/BI** no final, usando como fonte o dataset
> `samples.bakehouse` (rede de padarias). Faça **tudo como recursos de Asset Bundle** deste
> projeto (`resources/` + `src/`), com um **único Lakeflow Declarative Pipeline serverless**.
> **Nunca escreva no catálogo `samples`** — ele é somente leitura.
>
> **Negócio:** a Bakehouse tem 48 franquias em 9 países. Quero acompanhar receita, pedidos,
> ticket médio, mix de produtos, desempenho por franquia/país e a satisfação dos clientes.
>
> **Estrutura — um schema por camada (importante):** o catálogo é `bakehouse_dev` (**já existe,
> não crie**). Quero **três schemas, com exatamente estes nomes: `bronze`, `silver`, `gold`**,
> declarados como **recursos `schemas:` do bundle**. O schema é a camada, então as tabelas
> **não levam prefixo de camada**: é `bronze.customers` e `silver.customers`, nunca
> `bronze_customers`.
>
> - **`bronze`:** ingestão bruta de `sales_transactions`, `sales_franchises`, `sales_customers`,
>   `sales_suppliers` e `media_customer_reviews` → tabelas `transactions`, `franchises`,
>   `customers`, `suppliers`, `reviews`, com colunas de metadados de ingestão.
> - **`silver`:** dados limpos e conformados — tipos corretos, colunas de data derivadas
>   (dia/mês), **padronização de país** (`US` vs `USA`), transações enriquecidas com franquia e
>   cliente, e **regras de qualidade (expectations)**. Tabelas: `customers`, `franchises`,
>   `transactions` e `reviews_sentiment` (esta com **`ai_analyze_sentiment`**).
> - **`gold`:** marts prontos para BI — `daily_sales_by_franchise`, `sales_by_product`,
>   `franchise_performance` (com cidade, país, latitude/longitude), `sales_by_country`,
>   `top_customers` e `sentiment_by_franchise`.
>
> Depois crie um **dashboard AI/BI (Lakeview)** sobre as tabelas gold com: KPIs (receita total,
> pedidos, ticket médio, franquias ativas), **série temporal de receita diária**, receita por
> produto, ranking de franquias, **mapa geográfico das franquias por receita**, mix de meio de
> pagamento e visão de sentimento dos reviews. **Teste todas as queries SQL antes de publicar.**
>
> Por fim, adicione um **Job** que orquestra o pipeline, faça o **deploy do bundle no target
> `dev`** e **rode o pipeline** para materializar as tabelas. Valide os dados no fim (contagens
> por camada). Vá explicando cada passo.

### Versão em 3 passos (mais segura para palco — permite checkpoints)

1. *"Explore `samples.bakehouse` e me proponha o desenho medalhão com **um schema por camada**
   (`bakehouse_dev.bronze/silver/gold`, tabelas sem prefixo) + o dashboard. Só o plano, ainda
   não construa."*
2. *"Implemente o Lakeflow Declarative Pipeline serverless (bronze→silver→gold) como recurso de
   Asset Bundle, com os 3 schemas como recursos `schemas:`. Deploy no `dev` e rode."*
3. *"Crie o dashboard AI/BI sobre as tabelas gold (KPIs, receita diária, ranking, mapa,
   sentimento). Teste as queries e publique como recurso do bundle."*

---

## 5. O que já está validado (e o que não está)

**Validado de verdade, rodando neste workspace (16/07/2026):**

- **O mecanismo multi-schema funciona — e pelos dois caminhos possíveis.** Um pipeline serverless
  com `catalog: X` + `schema: bronze` publicou, numa única run, em `X.bronze.customers`,
  `X.silver.customers` e `X.gold.customers_by_country` usando **nome de 2 partes** (`silver.customers`,
  catálogo herdado). Num segundo teste, **nome de 3 partes com substituição**
  (`${medallion_catalog}.${silver_schema}.customers`, chaves vindas do `configuration:` do pipeline)
  resolveu igualmente certo — inclusive na leitura (`FROM STREAM ${medallion_catalog}.bronze.customers`).
  Ou seja: `${}` **funciona em posição de identificador**. Leitura cross-schema OK nos dois. Runs de
  ~40 s. **Por isso o prompt de §4 não prescreve a fiação** — qualquer um dos dois caminhos chega lá.
- **`schemas:` como recurso de bundle funciona** no motor padrão (terraform).
- **`catalogs:` não funciona** aqui: exige `bundle.engine: direct` **e** mesmo assim a API bate em
  `Metastore storage root URL does not exist` (Default Storage). Catálogo só via SQL.
- **`mode: development` renomeia schemas** para `dev_<usuario>_bronze` — e a run ainda assim termina
  verde, com bronze e silver em convenções diferentes (ver o roteiro de palco abaixo). `presets:
  name_prefix: ""` **não** corrige (string vazia = valor-zero em Go; o preset do dev-mode continua
  valendo). A saída é não usar `mode: development`. Já `mode: production` **não** renomeia nada.

**Ainda NÃO validado neste desenho:** o build completo ponta a ponta (15 tabelas + job +
dashboard) com um schema por camada. O mecanismo central está provado; a montagem inteira é o
que este prompt vai testar.

### O momento `mode: development` — roteiro de palco (deliberado)

O prompt **não** avisa sobre o `mode: development`, de propósito: o plano é deixar o dev sair
"errado", mostrar no telão, corrigir ao vivo e só então subir prod do jeito certo. **Reproduzido
neste workspace (16/07/2026) para você saber exatamente o que vai aparecer.**

Com `mode: development` e o pipeline apontando para o recurso de schema
(`schema: ${resources.schemas.bronze.name}`), a run termina **verde, COMPLETED** — e entrega isto:

```
bakehouse_dev
├── dev_mateusvbkasuya_bronze   ← os dados da BRONZE caem aqui (dev-mode renomeou o recurso,
│                                  e o pipeline aponta pro recurso)
├── dev_mateusvbkasuya_silver   ← VAZIO. O bundle criou; ninguém escreveu nele.
└── silver                       ← os dados da SILVER caem aqui (o nome de 2 partes no SQL
                                   cria o schema literal, ignorando o rename)
```

O ponto didático é forte porque **o pipeline não reclama de nada**: bronze e silver acabam em
convenções diferentes e ainda sobra um schema órfão vazio. É "build verde, resultado errado" —
visível em 2 segundos no Catalog Explorer.

**A correção ao vivo:** tirar `mode: development` do target e repor o que ele dava de graça com
`presets: {pipelines_development: true, trigger_pause_status: PAUSED}`. Cuidado: `presets:
name_prefix: ""` **não** funciona (string vazia = valor-zero em Go). Redeploy → schemas viram
`bronze`/`silver`/`gold` limpos.

**O fecho em prod:** `mode: production` **não** renomeia — validado: os schemas saem `bronze` e
`silver` e o pipeline sem o prefixo `[dev x]`. O catálogo **`bakehouse_prod` já existe** (criado
junto com o `bakehouse_dev`, mesma razão: o bundle não consegue criar catálogo aqui). Só lembre
de apontar `var.catalog` do target `prod` para ele.

---

### Bugs conhecidos deste build — colinha de palco (NÃO estão no prompt, de propósito)

O prompt de §4 **não** entrega estas lições: elas são o teste de verdade do agente + das skills, e
o `mixed` é justamente o "momento de ensino" que a validação obrigatória da skill pega ao vivo.
Guarde esta lista para **reconhecer o bug em 2 segundos** se ele aparecer — não para preveni-lo.

| Bug | Como se manifesta | Onde apareceu |
| --- | --- | --- |
| **`ai_analyze_sentiment` tem 4 categorias** (`positive`/`negative`/`neutral`/**`mixed`**) e a maioria cai em `mixed` | **Silencioso** — sem erro; ~1/3 dos reviews some do gold | Run 1 |
| **Expectation com nome PRÉ-alias** (`EXPECT (totalPrice > 0)` quando o SELECT já aliasou p/ `total_price`) | Barulhento — `UNRESOLVED_COLUMN` no run (não no deploy) | Run 2 |
| **MV que faz JOIN com outra MV do mesmo pipeline** materializa vazia no 1º refresh | **Silencioso** — pipeline reporta SUCCESS com 0 linhas; `full refresh` isolado resolve | Run 2 |
| **Dashboard com catálogo/schema hard-coded** no JSON | Cosmético — quebra ao trocar de target | Run 1 |

> **Nota para o BENCHMARK.md:** como o prompt **não** carrega essas lições, a dimensão *Autonomia*
> volta a ser comparável com as Runs 1–4. Atenção a uma variável nova, porém: a Run 4 fez 0 bugs
> em parte porque as lições estavam no *contexto da conversa* dela. Numa sessão limpa isso não
> existe — então um resultado pior em autonomia aqui **não** significa modelo pior; significa que
> a Run 4 estava com contexto acumulado que a sessão nova não tem. Além disso, este desenho muda a
> estrutura (multi-schema), então trate esta run como uma **nova linha de base**, não como Run 5
> comparável ponto a ponto.

**Números do dataset** (da validação da versão anterior — independem do desenho, servem de
gabarito para conferir no fim): receita total **US$ 66.471**, 3.333 pedidos, 48 franquias,
9 países, 204 reviews (86 negativos / 69 mixed / 49 positivos).

**Bug real que a validação anterior pegou:** `ai_analyze_sentiment` devolve `positive/negative/
neutral/mixed` — e a maioria dos reviews veio como `mixed`, categoria que a primeira versão do
gold não contava, deixando 69 reviews fora. **Lição para o palco:** rode o pipeline e olhe os
dados antes de plugar o dashboard — é exatamente o que a skill de dashboard obriga a fazer.

### Cronometragem (referência da versão anterior, esforço `max`, fast OFF — o cenário mais LENTO)

| Fase | Tempo |
| --- | --- |
| Planejamento (ler skills + desenhar + de-risking) | ~4,5 min |
| Desenvolvimento (15 SQL + 2 YAML) | ~2 min |
| `bundle deploy` | ~35 s |
| Run do pipeline (cold start serverless) | ~2 min |
| Iteração (corrigir bug + redeploy + rerun) + dashboard | ~10 min |
| **Total (max, fast off)** | **~19 min** |

> Esse total está inflado por: esforço `max`, fast off, um ciclo de correção de bug e perguntas
> respondidas no meio. **Numa passada limpa com `high` + `/fast`, estime ~10–13 min** (os ~5 min de
> compute do Databricks — deploy + run + queries — são fixos; o resto encolhe).

---

## 6. Modelo e esforço recomendados (para o ao vivo)

**Recomendado: Opus 4.8 + esforço `high` + Fast mode (`/fast`) ligado.**

- **Opus 4.8** é o mais capaz — ao vivo você não quer o agente errando a fiação do bundle ou
  do pipeline. As skills (AI Dev Kit) + o MCP guiam o modelo, então ele acerta o fluxo.
- **`high`** dá raciocínio suficiente para seguir os workflows multi-arquivo das skills sem o
  excesso de "pensar demais" do `max`.
- **`/fast`** acelera a saída no Opus **sem** rebaixar o modelo — ideal para não ter demora.

| Situação | Escolha |
| --- | --- |
| Padrão recomendado | **Opus 4.8 · `high` · `/fast`** |
| Tempo muito apertado / quer mais rápido | Opus 4.8 · `medium` · `/fast`  ·  ou  Sonnet 5 · `high` |
| Evite | `max` (lento, superanalisa) · Haiku 4.5 (fraco para build multi-etapa) |

**Dicas de palco:** deixe o SQL warehouse quente antes de começar; o MCP explora o UC ao vivo
em segundos (não precisa pré-carregar); e a versão em 3 passos permite pausar e narrar entre
pipeline e dashboard.

### Impacto de esforço e Fast mode — no TEMPO

Regra de ouro: **esforço e fast só afetam as fases de raciocínio/escrita do modelo. Os tempos
do Databricks (deploy, run do pipeline, execução de queries) são FIXOS** — não mudam com
modelo/esforço, porque são compute do lado do Databricks.

| Fase | Depende do modelo? | Efeito de `high`+`/fast` vs `max`+fast off |
| --- | --- | --- |
| Planejar + escrever código | Sim | Encolhe bastante (menos "overthinking" + saída mais rápida) |
| `bundle deploy` | Não (fixo ~35s) | Igual |
| Run do pipeline (cold start) | Não (fixo ~2 min) | Igual |
| Testar queries / publicar dashboard | Parcial | Queries fixas; raciocínio encolhe |

### Impacto de esforço e Fast mode — na QUALIDADE

- **Fast mode: ZERO impacto na qualidade.** É o mesmo modelo, mesmos pesos, só servido mais
  rápido. Não há trade-off — ligue sempre.
- **Esforço `high` ≈ `max` para ESTA tarefa.** O build é bem delimitado e guiado pelas skills
  (SDP, DAB, dashboards), então o espaço de solução é estreito; o raciocínio extra do `max`
  quase não agrega — só adiciona latência. O bug que a validação pegou (sentimento `mixed`)
  foi encontrado pela **validação de dados obrigatória da skill**, não pelo esforço `max` —
  `high` acharia igual.
- **Onde esforço alto (`max`/`xhigh`) REALMENTE ajuda a qualidade:** problemas abertos, ambíguos,
  com muitas restrições — decisões de arquitetura novas, debugging difícil, raciocínio sutil de
  correção. Se no workshop aparecer um erro cabeludo, subir para `max` **só naquele passo** ajuda.
- **Não desça de `high` para um build multi-etapa como este:** em `medium`/`low` o risco sobe —
  o agente pode pular a validação, errar a fiação do bundle ou ler as skills com menos cuidado,
  gerando mais correções ao vivo.

**Conclusão:** para o workshop, **`high` + `/fast`** é o ponto ótimo — qualidade praticamente
igual à do `max` nesta tarefa, porém bem mais rápido. Guarde o `max` para destravar um problema
pontual difícil.
