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

### Desenho medalhão

- **Bronze** — ingestão bruta das 5 tabelas de origem + metadados de ingestão.
- **Silver** — limpo e conformado: tipos, colunas de data derivadas, padronização de país,
  regras de qualidade (expectations), transações enriquecidas com franquia/cliente, e uma
  tabela de **reviews com sentimento** via `ai_analyze_sentiment` (destaque de IA).
- **Gold** — marts prontos para BI: vendas diárias por franquia, vendas por produto,
  ranking de franquias (com geo), vendas por país, top clientes, sentimento por franquia.
- **Dashboard AI/BI (Lakeview)** sobre a gold: KPIs, série temporal de receita, receita por
  produto, ranking de franquias, **mapa geográfico**, mix de pagamento e visão de sentimento.

Entregue como: **Lakeflow Declarative Pipeline serverless** (bronze→silver→gold) +
**Job** que orquestra/agenda o pipeline + **Dashboard** — todos como recursos do bundle
(`resources/*.yml` + `src/`), no target `dev`.

---

## 2. O prompt para colar ao vivo

> **Contexto:** quero construir um pipeline de dados completo em **arquitetura medalhão
> (bronze → silver → gold)** e um **dashboard AI/BI** no final, usando como fonte o dataset
> `samples.bakehouse` (rede de padarias). Faça **tudo como recursos de Asset Bundle** deste
> projeto (`resources/` + `src/`), com um **Lakeflow Declarative Pipeline serverless**,
> gravando no **catálogo e schema das variáveis do bundle** (`workspace` / schema do usuário).
> **Nunca escreva no catálogo `samples`** — ele é somente leitura.
>
> **Negócio:** a Bakehouse tem 48 franquias em 9 países. Quero acompanhar receita, pedidos,
> ticket médio, mix de produtos, desempenho por franquia/país e a satisfação dos clientes.
>
> **Camadas:**
> - **Bronze:** ingestão bruta de `sales_transactions`, `sales_franchises`, `sales_customers`,
>   `sales_suppliers` e `media_customer_reviews`, com colunas de metadados de ingestão.
> - **Silver:** dados limpos e conformados — tipos corretos, colunas de data derivadas
>   (dia/mês), **padronização de país** (`US` vs `USA`), enriquecimento das transações com
>   franquia e cliente, e **regras de qualidade (expectations)**. Inclua uma tabela de reviews
>   com **análise de sentimento usando `ai_analyze_sentiment`**.
> - **Gold:** tabelas de negócio prontas para BI — vendas diárias por franquia, vendas por
>   produto, **ranking de desempenho das franquias** (com cidade, país, latitude/longitude),
>   vendas por país, top clientes por gasto e sentimento por franquia.
>
> Depois crie um **dashboard AI/BI (Lakeview)** sobre as tabelas gold com: KPIs (receita total,
> pedidos, ticket médio, franquias ativas), **série temporal de receita diária**, receita por
> produto, ranking de franquias, **mapa geográfico das franquias por receita**, mix de meio de
> pagamento e visão de sentimento dos reviews. **Teste todas as queries SQL antes de publicar.**
>
> Por fim, adicione um **Job** que orquestra o pipeline, faça o **deploy do bundle no target
> `dev`** e **rode o pipeline** para materializar as tabelas. Vá explicando cada passo.

### Versão curta (se preferir algo mais enxuto ao vivo)

> Construa um pipeline medalhão (bronze→silver→gold) com **Lakeflow Declarative Pipeline
> serverless** a partir de `samples.bakehouse`, como recursos de **Asset Bundle** gravando no
> catálogo/schema das variáveis do bundle (nunca escreva em `samples`). Gold pronta para BI
> (vendas diárias por franquia, por produto, ranking de franquias com geo, sentimento dos
> reviews via `ai_analyze_sentiment`). Depois crie um **dashboard AI/BI** sobre a gold com KPIs,
> receita diária, ranking, mapa e sentimento. Faça deploy no `dev` e rode o pipeline.

### Versão em 3 passos (mais segura para palco — permite checkpoints)

1. *"Explore `samples.bakehouse` e me proponha o desenho medalhão (bronze/silver/gold) +
   o dashboard. Só o plano, ainda não construa."*
2. *"Implemente o Lakeflow Declarative Pipeline serverless (bronze→silver→gold) como recurso
   de Asset Bundle gravando em `workspace`/schema do bundle. Deploy no `dev` e rode."*
3. *"Crie o dashboard AI/BI sobre as tabelas gold (KPIs, receita diária, ranking, mapa,
   sentimento). Teste as queries e publique como recurso do bundle."*

---

## 3. Modelo e esforço recomendados (para o ao vivo)

**Recomendado: Opus 4.8 + esforço `high` + Fast mode (`/fast`) ligado.**

- **Opus 4.8** é o mais capaz — ao vivo você não quer o agente errando a fiação do bundle ou
  do pipeline. As skills (AI Dev Kit) + o MCP guiam o modelo, então ele acerta o fluxo.
- **`high`** dá raciocínio suficiente para seguir os workflows multi-arquivo das skills sem o
  excesso de "pensar demais" do `max`.
- **`/fast`** acelera a saída no Opus **sem** rebaixar o modelo — ideal para não ter demora.

**Troque o `max` que está ativo agora** — `max` é lento e superanalisa; ruim para palco.

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

- **`max` → `high`:** corta o "pensar demais". Nas fases de raciocínio costuma ser ~1,5–2,5x
  mais rápido, sem perder qualidade neste tipo de tarefa (ver abaixo).
- **Fast ON:** acelera a *saída* de tokens (throughput). Ganho de velocidade puro, **sem**
  rebaixar o modelo. Para palco, deixe sempre ligado.

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

---

## 4. Resultado da validação ao vivo (executada de ponta a ponta)

Rodei o prompt inteiro neste workspace (schema de teste `workspace.mateusvbkasuya_test`) para
provar que funciona e cronometrar. **Funcionou de ponta a ponta.**

**O que foi criado e validado:**
- Pipeline Lakeflow serverless `bakehouse_medallion` com **15 tabelas**: 5 bronze (streaming),
  4 silver (3 streaming + 1 MV com `ai_analyze_sentiment`), 6 gold (MVs).
- Job `bakehouse_medallion_job` orquestrando o pipeline (schedule diário, pausado em dev).
- Dashboard AI/BI publicado com 11 widgets (KPIs, receita diária, produto, país, pagamento,
  sentimento, ranking de franquias).
- Números conferem: receita total **US$ 66.471**, 3.333 pedidos, 48 franquias, 9 países,
  204 reviews (86 negativos / 69 mixed / 49 positivos via IA).

**Cronometragem (esforço `max`, fast OFF — ou seja, o cenário mais LENTO):**

| Fase | Tempo |
| --- | --- |
| Planejamento (ler skills + desenhar + de-risking) | ~4,5 min |
| Desenvolvimento (15 SQL + 2 YAML) | ~2 min |
| `bundle deploy` | ~35 s |
| Run do pipeline (cold start serverless) | ~2 min |
| Iteração (corrigir bug + redeploy + rerun) + dashboard | ~10 min |
| **Total (max, fast off)** | **~19 min** |

> O total de ~19 min está inflado por: esforço `max`, fast off, um ciclo de correção de bug e
> as perguntas respondidas no meio. **Numa passada limpa com `high` + `/fast`, estime ~10–13 min**
> (os ~5 min de compute do Databricks — deploy + run + queries — são fixos; o resto encolhe).

**Bug real que a validação pegou:** `ai_analyze_sentiment` devolve `positive/negative/neutral/
mixed` — mas a maioria dos reviews veio como `mixed`, categoria que a versão inicial do gold não
contava (só positive/negative/neutral), deixando 69 reviews fora. Corrigido adicionando a coluna
`mixed_reviews`. **Lição para o palco:** rode o pipeline e olhe os dados antes de plugar o
dashboard — é exatamente o que a skill de dashboard obriga a fazer.
