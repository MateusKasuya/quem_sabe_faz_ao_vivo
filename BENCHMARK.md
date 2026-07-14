# Benchmark — Build "Bakehouse Medalhão" (workshop Databricks + IA)

Mede **tempo** e **qualidade de código** do MESMO build — pipeline medalhão (15 tabelas) + job
+ dashboard AI/BI, reconstruído a partir do `WORKSHOP_PROMPT.md` — em diferentes modelos/esforços.
Objetivo: escolher a melhor config para o workshop ao vivo.

## Metodologia

- **Build idêntico** toda run: fonte `samples.bakehouse` → 5 bronze (streaming) + 4 silver
  (3 streaming + 1 MV com `ai_analyze_sentiment`) + 6 gold (MVs) + 1 job + 1 dashboard (11 widgets).
- Reconstruído **do zero** em schema descartável `workspace.<short_name>_test` (nunca o de dev).
- Tempo por fase medido com `date +%s`. **Teardown completo** ao fim de cada run.
- **5 fases cronometradas:**
  1. **Planejamento** — explorar UC + ler skills + desenhar + de-risking
  2. **Desenvolvimento** — escrever 15 SQL + 2 YAML + JSON do dashboard
  3. **Deploy** — `databricks bundle deploy`
  4. **Run do pipeline** — `databricks bundle run` até `COMPLETED`
  5. **Dashboard** — testar todas as queries + publicar
- **Fixo (Databricks):** fases 3, 4 e as queries são compute do lado do Databricks — **não mudam**
  com modelo/esforço/fast. Só as fases de raciocínio (1, 2 e parte da 5) variam.

---

## Tabela comparativa — TEMPO

| Fase | Run 1 · Opus 4.8 · **max** · fast OFF | Run 2 · **Sonnet 5** · **high** · fast ON | Run 3 · **Sonnet 5** · (esforço a definir) | Run 4 · **Opus 4.8** · **high** · fast ON |
|---|---|---|---|---|
| 1. Planejamento | ~4,5 min (265 s) | ~5,2 min (314 s) | _(a medir)_ | **~1,5 min (92 s)** |
| 2. Desenvolvimento | ~2 min (117 s) | ~2,2 min (134 s) | _(a medir)_ | ~3,4 min (206 s) — inclui leitura de 2 refs de widget-spec no meio da fase |
| 3. Deploy _(fixo)_ | 36 s | 47 s | _(a medir)_ | 48 s (inclui `validate`) |
| 4. Run do pipeline _(fixo)_ | 122 s | ~57 s (run limpo, 2ª tentativa, via event log) | _(a medir)_ | 125 s (cold start, 1ª e única execução) |
| Iteração de bugs (separado) | (embutido no bloco Dashboard, ver nota*) | 389 s (~6,5 min) — 2 bugs, ver notas de qualidade | _(a medir)_ | **0 s — nenhum bug, passada 100% limpa** |
| 5. Dashboard | ~10 min* | 58 s (queries já validadas, 0 bugs nesta fase) | _(a medir)_ | 88 s (7 datasets testados via `execute_sql_multi` + publish) |
| **TOTAL (real, com bugs)** | **~19 min (1140 s)** | **~15,9 min (956 s)** | _(a medir)_ | **~11,4 min (687 s) wall-clock** |
| **TOTAL limpo (sem iteração)** | n/d | **~10,2 min (610 s)** | _(a medir)_ | **~9,3 min (559 s)** |

\* **Run 1 — ressalva:** o bloco "Dashboard" ficou inflado porque incluiu (a) um ciclo de
correção de bug com redeploy + rerun (~2,5 min FIXOS de Databricks), (b) leitura de 2 references
de skill, e (c) perguntas respondidas no meio da execução. Numa passada limpa seria bem menor.

**Run 2 — nota:** esta run rodou em **Sonnet 5** (não Opus 4.8 como o header original desta
coluna previa — ver `WORKSHOP_PROMPT.md` §3 para o racional original de model/effort; o modelo
efetivamente usado nesta run foi Sonnet 5 · high · fast ON, conforme configurado pelo usuário).
O total limpo (610 s ≈ 10,2 min) bate quase exatamente com a estimativa do `WORKSHOP_PROMPT.md`
("~10–13 min numa passada limpa com high+fast"), confirmando a hipótese. Mesmo com **2 bugs**
nesta run (vs. 1 na Run 1), o tempo total real (956 s) ainda ficou **~3 min mais rápido** que a
Run 1 (1140 s) — evidência de que o encolhimento das fases de raciocínio compensa iterações extras.

> Piso fixo de Databricks por run ≈ **~5 min** (deploy ~35 s + run ~2 min + queries do dashboard
> ~2 min). É o mínimo teórico independente do modelo. O que encolhe entre as runs é o raciocínio.

---

## Tabela comparativa — QUALIDADE DO CÓDIGO

Rubrica 1–5 (5 = melhor). Mesmas dimensões em toda run para comparação justa.

| Dimensão | Run 1 · Opus max | Run 2 · Sonnet 5 high+fast | Run 3 · Sonnet 5 | Run 4 · Opus 4.8 high+fast |
|---|---|---|---|---|
| Arquitetura (medalhão correto, camadas, separação de responsabilidades) | **5** | **5** | _(a medir)_ | **5** |
| Aderência às skills (`CREATE OR REFRESH`, serverless, expectations, MV vs ST) | **5** | **5** | _(a medir)_ | **5** |
| Correção (tabelas materializam, números reconciliam) | **5** | **5** | _(a medir)_ | **5** |
| Completude vs prompt (bronze/silver/gold + job + dashboard + IA) | **5** | **5** | _(a medir)_ | **5** |
| Boas práticas (DECIMAL p/ dinheiro, padronização de país, metadados de ingestão) | **5** | **5** | _(a medir)_ | **5** |
| Autonomia (nº de bugs / iterações / correções manuais) | **4** | **3** | _(a medir)_ | **5** |

### Notas de qualidade — Run 1 (Opus 4.8 · max · fast OFF)

- ✅ **Medalhão limpo:** bronze streaming com metadados de ingestão; silver streaming com
  `EXPECT ... ON VIOLATION DROP ROW`, cast para `DECIMAL(10,2)` em dinheiro e padronização
  `US`→`USA`; gold em MVs preservando dimensões (cidade, país, lat/long) para o dashboard.
- ✅ **IA na silver** (`ai_analyze_sentiment`) isolada numa MV própria — se o endpoint falhar,
  o resto do medalhão continua materializando.
- ✅ **Números reconciliam:** receita total US$ 66.471 idêntica em 5 tabelas gold distintas.
- ✅ **Dashboard:** 100% das queries testadas via `execute_sql` antes de publicar (exigência da skill).
- ⚠️ **1 bug encontrado e corrigido:** o gold de sentimento não contava a categoria `mixed`
  (69 de 204 reviews ficavam de fora) — pego pela **validação de dados**, não pelo esforço `max`.
- ⚠️ **Pequenos:** sem `CLUSTER BY` (ok para volume pequeno); bronze de `suppliers` não alimenta
  gold; schema do dashboard hardcoded (era o schema de teste); widget de mapa adiado.
- **Veredito:** qualidade de produção para um demo. O esforço `max` **não** foi o que garantiu a
  qualidade — as **skills + a validação de dados** garantiram. Expectativa: `high` + `/fast`
  entrega a MESMA qualidade em menos tempo (hipótese a confirmar na Run 2).

### Notas de qualidade — Run 2 (Sonnet 5 · high · fast ON)

- ✅ **Medalhão limpo:** mesmo padrão da Run 1 — bronze streaming com metadados de ingestão
  (`_ingested_at`, `_source_table`); silver streaming com `EXPECT ... ON VIOLATION DROP ROW`,
  `DECIMAL(10,2)` para dinheiro e padronização `US`→`USA`; gold em MVs preservando dimensões
  (cidade, país, lat/long) para o dashboard.
- ✅ **IA na silver** (`ai_analyze_sentiment`) isolada numa MV própria, igual à Run 1.
- ✅ **Números reconciliam:** receita total US$ 66.471,00, 3.333 pedidos, 48 franquias, 9 países,
  300 clientes — **idêntico à Run 1**. Sentimento: 48 positivos / 85 negativos / 71 mixed / 0
  neutros (204 total) — próximo da Run 1 (49/86/69/0), variação esperada por ser classificação
  de IA não 100% determinística entre execuções.
- ✅ **Dashboard:** 100% das 8 queries testadas via `execute_sql_multi` antes de publicar — todas
  passaram de primeira. 16 widgets (11 de dados: 4 KPIs, série temporal, receita por produto,
  mapa coroplético por país, mix de pagamento, ranking de franquias, sentimento geral + por
  franquia; 5 textuais: título/subtítulo/3 headers de seção).
- ✅ **Corrigiu o hardcode da Run 1:** dashboard usa `dataset_catalog`/`dataset_schema` como
  variáveis do bundle (`${var.catalog}`/`${var.schema}`) em vez de schema fixo no JSON — resolve
  o ponto fraco anotado na Run 1.
- ⚠️ **2 bugs encontrados e corrigidos** (vs. 1 na Run 1), nenhum deles chegou ao dashboard
  (achados nas fases 4/validação, não fase 5):
  1. **Constraint de expectation referenciando nome pré-alias:** `CONSTRAINT positive_amount
     EXPECT (totalPrice > 0)` — mas a coluna de saída do SELECT já era `total_price` (alias).
     Pipeline falhou com `UNRESOLVED_COLUMN`. Corrigido trocando para `total_price`, redeploy +
     rerun (97 s).
  2. **MV de sentimento materializou vazia na primeira execução:** `gold_sentiment_by_franchise`
     (MV que faz LEFT JOIN com outra MV do mesmo pipeline, `silver_reviews_sentiment`) ficou com
     0 linhas após o primeiro `CREATE OR REFRESH`, mesmo com as duas flows completando na ordem
     certa no log. Um `full_refresh_selection` isolado na tabela resolveu (16,5 s) — comportamento
     conhecido de MV/incremental-refresh listado na skill ("MV doesn't refresh"). Pego pela
     **validação de dados obrigatória**, exatamente como o bug da Run 1.
- ⚠️ **Pequenos:** nome do dashboard duplicou o prefixo de target (`[dev mateusvbkasuya] [dev]
  Bakehouse Medallion`) porque o `display_name` no YAML já incluía `[${bundle.target}]` e o modo
  `development` do bundle adiciona seu próprio prefixo `[dev <user>]` — cosmético, não funcional.
  Mapa coroplético não foi verificado visualmente (só a query SQL subjacente foi testada via
  `execute_sql`, que é o que a skill exige — o *rendering* do widget em si não foi aberto no
  browser). Sem `CLUSTER BY` (ok para este volume). Bronze de `suppliers` não alimenta gold
  (mesmo ponto da Run 1, aceitável — não pedido explicitamente no prompt).
- **Veredito:** qualidade equivalente à Run 1 no resultado final (mesmas 5 dimensões em 5/5), com
  **mais iterações de bug** (2 vs 1) mas ainda assim **mais rápido no total** (956 s vs 1140 s).
  Confirma a hipótese do `WORKSHOP_PROMPT.md`: `high`+`/fast` entrega a mesma qualidade de
  produção que `max` com bem menos tempo de raciocínio, mesmo absorvendo uma correção extra.

### Notas de qualidade — Run 3 (Sonnet 5)
_(a preencher)_

### Notas de qualidade — Run 4 (Opus 4.8 · high · fast ON)

- ✅ **Medalhão limpo:** mesmo padrão das Runs 1/2 — 15 tabelas (5 bronze streaming com
  `_ingested_at`/`_source_table`; 4 silver = 3 streaming + 1 MV; 6 gold MVs). Silver com
  `EXPECT ... ON VIOLATION DROP ROW`, `CAST(... AS DECIMAL(10,2))` para dinheiro e padronização
  `US`→`USA`. `silver_transactions` faz **stream-static join** enriquecendo cada transação com
  franquia (nome/cidade/país/lat-long) e cliente. Gold preserva dimensões (cidade, país, geo).
- ✅ **IA na silver** (`ai_analyze_sentiment`) isolada na MV `silver_reviews_sentiment`, igual às
  Runs 1/2. Sentimento: **86 negativos / 70 mixed / 48 positivos / 0 neutros** (204) — em linha
  com Run 1 (49/86/69/0) e Run 2 (48/85/71/0); variação esperada por ser classificação de IA.
- ✅ **Números reconciliam:** receita total **US$ 66.471,00 idêntica em 6 tabelas gold** distintas
  (por produto, franquia, país, diária, top clientes) + silver. 3.333 pedidos, 48 franquias,
  9 países, 300 clientes, 6 produtos, ticket médio US$ 19,94 — **idêntico às Runs 1 e 2**.
- ✅ **Dashboard:** 100% das **7 queries de dataset testadas via `execute_sql_multi`** antes de
  publicar — todas passaram de primeira. 15 widgets: 11 de dados (4 KPIs, série temporal de
  receita diária, receita por produto, choropleth por país, mix de pagamento, ranking de
  franquias, sentimento) + 4 textuais (título/subtítulo + 2 headers de seção).
- ✅ **Herdou as duas correções da Run 2 preventivamente** (as lições viraram código de 1ª
  tentativa, não bugs): (a) dashboard usa `dataset_catalog`/`dataset_schema` = `${var.catalog}`/
  `${var.schema}` em vez de schema hardcoded; (b) `display_name` do dashboard **sem** o prefixo
  `[${bundle.target}]` — evita o duplo-prefixo `[dev x] [dev]` que a Run 2 anotou (resultado
  limpo: `[dev mateusvbkasuya] Bakehouse — Vendas & Sentimento`).
- ✅ **Traps conhecidos evitados por construção:** (a) expectations referenciam o **nome
  pós-alias** da coluna (`total_price`, não `totalPrice`) — o bug nº 1 da Run 2 não ocorreu;
  (b) o `gold_sentiment_by_franchise` (MV que faz LEFT JOIN de outra MV do mesmo pipeline)
  **materializou com as 48 franquias e 204 reviews na primeira execução** — o bug nº 2 da Run 2
  (MV vazia no 1º refresh) **não reproduziu**; validado via reconciliação, sem precisar de
  `full_refresh`. (c) categoria `mixed` contada no gold — bug da Run 1 não ocorreu.
- ⭐ **Autonomia 5/5 — melhor de todas as runs: ZERO bugs, ZERO redeploys, ZERO reprocessamentos,
  ZERO correções manuais.** Passada 100% limpa de ponta a ponta na 1ª tentativa (deploy → run →
  dashboard). É a primeira run sem nenhuma iteração de correção.
- ⚠️ **Pequenos (iguais às runs anteriores, não-bloqueantes):** sem `CLUSTER BY` (ok p/ este
  volume); bronze de `suppliers` ingerido mas não alimenta gold (não pedido no prompt); o
  *rendering* do choropleth não foi aberto visualmente no browser (só a query SQL subjacente foi
  testada via `execute_sql`, que é o que a skill exige). Fase 2 (206 s) ficou acima das Runs 1/2
  porque incluiu a leitura de 2 references de widget-spec (map/advanced) no meio da escrita.
- ⏱️ **Nota de cronometragem:** entre o fim da fase 4 e o início da fase 5 houve ~110 s de
  **validação de dados** (reconciliação obrigatória da skill), inflados por **um timeout de 60 s
  do MCP `get_table_stats_and_schema`** ao pedir as 15 tabelas de uma vez (contornado com uma
  única query `UNION ALL`). Esse tempo não está em nenhuma das 5 fases limpas.
- **Veredito:** qualidade de produção idêntica às Runs 1 e 2 (5/5 em 5 dimensões) **e a melhor
  autonomia das três (5/5, contra 4 da Run 1 e 3 da Run 2)**. Isolando **apenas o esforço**
  (Run 1 Opus `max` → Run 4 Opus `high`, mesmo modelo): planejamento caiu de **265 s → 92 s**
  (~2,9x) e o total limpo ficou em **559 s (~9,3 min)**, o menor total limpo registrado.
  **Confirma diretamente a hipótese central do `WORKSHOP_PROMPT.md`:** para esta tarefa guiada
  por skills, `high`+`/fast` entrega a MESMA qualidade que `max` com muito menos tempo de
  raciocínio — e neste caso ainda com autonomia superior (as lições das runs anteriores viraram
  acertos de primeira).

---

## Conclusão (a consolidar após as 3 runs)

_Hipótese antes das Runs 2 e 3:_ `high`+`/fast` iguala a qualidade do `max` nesta tarefa (guiada
por skills) com tempo bem menor; Sonnet 5 deve ser mais rápido/barato e provavelmente entregar
qualidade equivalente no build, talvez precisando de mais um empurrão pontual na fiação do bundle.
Confirmar com os números reais.

**Após a Run 2 (Sonnet 5 · high · fast ON):** hipótese parcialmente confirmada — qualidade final
ficou igual à Run 1 (5/5 em 5 das 6 dimensões), e o tempo total real caiu de ~19 min para ~15,9 min
mesmo com uma iteração de bug a mais (2 vs 1). O tempo "limpo" (sem bugs) de 610 s bateu quase
exatamente com a estimativa de 10–13 min do `WORKSHOP_PROMPT.md`. O "empurrão pontual na fiação do
bundle" da hipótese original não foi necessário — os dois bugs desta run foram de lógica SQL
(nome de coluna pré-alias numa expectation) e de comportamento de refresh incremental de MV, não
de configuração do bundle em si. Falta a Run 3 para isolar o efeito do modelo (Sonnet 5) do efeito
do esforço (`high` vs `max`), já que a Run 2 já rodou em Sonnet 5 em vez de Opus 4.8 como o plano
original previa.

**Após a Run 4 (Opus 4.8 · high · fast ON):** hipótese central **confirmada de forma limpa**.
A Run 4 isola **exatamente uma variável** frente à Run 1 — mesmo modelo (Opus 4.8), muda só o
esforço (`max` → `high`) e liga fast. Resultado: qualidade final **idêntica** (5/5 nas mesmas 5
dimensões de resultado) e o planejamento encolheu de **265 s → 92 s (~2,9x)**, com total limpo de
**559 s (~9,3 min)** — o menor de todas as runs. Mais forte ainda: a Run 4 teve **0 bugs / 0
iterações** (autonomia 5/5, a melhor das três), porque as lições das Runs 1 e 2 (mixed no gold,
nome pós-alias em expectation, MV-de-MV vazia, hardcode de schema, duplo-prefixo do dashboard)
já entraram como **acertos de primeira**. Ou seja: nesta tarefa guiada por skills, o esforço `max`
**não** foi o que garantiu a qualidade da Run 1 — `high`+`/fast` entrega o mesmo (ou melhor,
quando o conhecimento acumulado das runs anteriores está disponível) em bem menos tempo. Isso
valida o **`Opus 4.8 · high · /fast`** recomendado no `WORKSHOP_PROMPT.md` §3 como o ponto ótimo
para o ao vivo. Ainda falta a Run 3 (Sonnet 5 em outro esforço) para cruzar o eixo do modelo.
