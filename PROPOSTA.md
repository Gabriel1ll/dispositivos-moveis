# Entrega 1: Proposta do aplicativo

## Nome provisório e objetivo

**Cofrinho**: aplicativo de controle de gastos pessoais.

O objetivo é ajudar o usuário a registrar o que gasta no dia a dia, organizar esses gastos por categoria e acompanhar, mês a mês, se está dentro do orçamento que definiu para cada categoria.

## Principais funcionalidades

- Cadastro de **categorias** de gasto (nome, cor e orçamento mensal opcional).
- Lançamento de **despesas** (descrição, valor, data e categoria).
- Lista de despesas por mês, com navegação entre meses e filtro por categoria.
- Acompanhamento do orçamento: barra de progresso por categoria e alerta quando o orçamento é ultrapassado.
- Tela de resumo do mês: total gasto, saldo do orçamento, média diária, maior despesa e ranking de gastos por categoria.
- Dados salvos no aparelho (SQLite), disponíveis após fechar e reabrir o app.

## Entidades com operações CRUD

| Entidade | Atributos | Create | Read | Update | Delete |
|---|---|---|---|---|---|
| **Categoria** | nome, cor, orçamento mensal | Botão "Nova categoria" | Aba Categorias | Tocar na categoria | Lixeira (apaga junto as despesas dela) |
| **Despesa** | descrição, valor, data, categoria | Botão "Nova despesa" | Aba Despesas | Tocar na despesa | Deslizar o item ou lixeira na edição |

Relacionamento: cada despesa pertence a uma categoria (1 categoria : N despesas).

## Recurso técnico

**Flutter Signals** (pacote `signals`): gerenciamento de estado reativo.

- `signal` para o estado de origem (listas de categorias e despesas, mês selecionado, filtro);
- `computed` para tudo o que é derivado (totais do mês, total por categoria, orçamentos estourados, média diária, maior despesa);
- `batch` para agrupar atualizações;
- `SignalBuilder` para reconstruir somente as partes da tela afetadas por cada mudança.

Assim, ao lançar uma despesa, as telas de categorias e de resumo se atualizam sozinhas, sem `setState` e sem código manual de sincronização.

**Persistência:** SQLite (pacote `sqflite`).
