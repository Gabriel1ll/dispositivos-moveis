# Cofrinho: controle de gastos com Flutter Signals

App de controle de gastos pessoais. Tem dois CRUDs (**Categorias** e **Despesas**), os dados ficam salvos em **SQLite** e o estado da interface é gerenciado com **Flutter Signals** (pacote [`signals`](https://pub.dev/packages/signals)).

---

## Como rodar

Pré-requisito: Flutter instalado (`flutter doctor` sem erros) e um emulador Android ou celular conectado.

```bash
cd cofrinho

# 1. Gera as pastas nativas (android/, ios/...). NÃO sobrescreve lib/ nem test/.
flutter create . --project-name cofrinho --org br.edu.cofrinho --platforms=android,ios

# 2. Baixa as dependências
flutter pub get

# 3. Roda os testes (devem passar todos)
flutter test

# 4. Abre o app
flutter run
```

Os scripts `preparar.sh` (Linux/macOS) e `preparar.bat` (Windows) fazem os passos 1 a 3 de uma vez.

**Testar no computador (opcional):** acrescente `windows` ou `linux` em `--platforms`. No Linux é preciso ter `libsqlite3-dev` instalado (`sudo apt install libsqlite3-dev`). **Web não é suportado**, porque o SQLite usado aqui é nativo.

---

## Funcionalidades

| Aba | O que faz |
|---|---|
| **Despesas** | Lista as despesas do mês, com total, filtro por categoria e troca de mês. "Nova despesa" cria; tocar num item edita; deslizar para a esquerda exclui (com confirmação). |
| **Categorias** | Lista as categorias com barra de progresso do orçamento do mês. "Nova categoria" cria; tocar edita; lixeira exclui (avisando quantas despesas serão apagadas junto). |
| **Resumo** | Gasto no mês, orçamento total, quanto ainda pode gastar, média por dia, maior despesa, alerta de orçamento estourado e ranking por categoria. |

Na primeira abertura o app cria 4 categorias de exemplo.

---

## Arquitetura

```
lib/
├── main.dart                  abre o banco, cria o store, carrega os dados, runApp
├── app.dart                   MaterialApp + tema + português do Brasil
├── models/
│   ├── categoria.dart         entidade 1 (imutável, toMap/fromMap)
│   └── despesa.dart           entidade 2 (imutável, toMap/fromMap)
├── data/
│   ├── app_database.dart      cria as tabelas SQLite (versão 1)
│   ├── categoria_repository.dart   CRUD SQL de categorias
│   ├── despesa_repository.dart     CRUD SQL de despesas
│   └── desktop_sqlite.dart    SQLite via FFI no Windows/Linux
├── state/
│   ├── app_store.dart         ★ todos os signals, computeds e ações
│   └── store_scope.dart       InheritedWidget que entrega o store às telas
├── screens/                   telas (abas e formulários)
├── widgets/                   seletor de mês e diálogos
└── util/formatadores.dart     R$, datas, leitura de valores digitados
```

Fluxo de uma ação (ex.: salvar despesa):

```
Tela ──chama──▶ store.salvarDespesa()
                  │ 1. grava no SQLite (repositório)
                  │ 2. despesas.value = nova lista        ← signal de origem
                  ▼
        computeds dependentes ficam "sujos"
        (despesasDoMes → totalDoMes, totalPorCategoria, maiorDespesa...)
                  ▼
        só os SignalBuilder que leram esses valores reconstroem
```

**O banco é a fonte da verdade; os signals são a cópia em memória que a tela observa.**

---

## Onde o recurso técnico (Signals) aparece

| Conceito | Onde | Para quê |
|---|---|---|
| `signal()` | `app_store.dart`: `categorias`, `despesas`, `mesSelecionado`, `filtroCategoriaId` | Estado de origem global |
| `computed()` | `app_store.dart`: `despesasDoMes`, `totalDoMes`, `totalPorCategoria`, `categoriasEstouradas`, `maiorDespesa`, `mediaDiaria`... | Valores derivados, recalculados de forma preguiçosa e só quando uma dependência muda |
| `batch()` | `carregar()` e `removerCategoria()` | Várias escritas viram uma única notificação |
| `SignalBuilder` | Todas as telas | Rebuild "cirúrgico": só o trecho que leu o signal é reconstruído |
| `peek()` | `despesa_form_screen.dart` | Ler o valor sem se inscrever |
| Signals locais + `dispose()` | `home_screen.dart` (aba), formulários (cor, data, categoria, "salvando") | Estado local da tela sem `setState` |

Uma boa demonstração para o vídeo: lance uma despesa e mostre que as abas **Categorias** (barra de progresso) e **Resumo** (totais e alerta) já aparecem atualizadas, sem nenhum código de "atualizar tela". Trocar o mês numa aba também muda nas outras, porque todas leem o mesmo signal.

---

## Persistência (SQLite)

```sql
CREATE TABLE categorias (
  id                 INTEGER PRIMARY KEY AUTOINCREMENT,
  nome               TEXT    NOT NULL,
  cor                INTEGER NOT NULL,          -- ARGB, ex.: 0xFF2E7D32
  orcamento_centavos INTEGER NOT NULL DEFAULT 0 -- 0 = sem orçamento
);

CREATE TABLE despesas (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  descricao      TEXT    NOT NULL,
  valor_centavos INTEGER NOT NULL CHECK (valor_centavos > 0),
  data           TEXT    NOT NULL,              -- 'AAAA-MM-DD'
  categoria_id   INTEGER NOT NULL REFERENCES categorias(id) ON DELETE CASCADE
);
```

O arquivo `cofrinho.db` fica na pasta privada do app (`getDatabasesPath()`), por isso os dados continuam lá depois de fechar e reabrir o app. Só são apagados se o app for desinstalado ou se os dados forem limpos nas configurações.

---

## Decisões técnicas (e o porquê)

1. **Dinheiro em centavos (`int`)**: `double` tem erro de arredondamento (`0.1 + 0.2 = 0.30000000000000004`). Somando centavos inteiros, o total é sempre exato.
2. **Modelos imutáveis + listas novas a cada mudança**: o signal notifica quando recebe um valor diferente. Se fizéssemos `despesas.value.add(x)`, a lista seria a mesma e ninguém seria avisado. Por isso sempre atribuímos uma lista nova (`[...antiga, nova]`).
3. **Repositórios com interface**: o store não conhece SQL. Nos testes trocamos o SQLite por repositórios em memória (`test/fakes.dart`).
4. **`PRAGMA foreign_keys = ON`**: o SQLite vem com chaves estrangeiras desligadas. Sem essa linha, o `ON DELETE CASCADE` não apagaria as despesas de uma categoria excluída.
5. **Exclusão otimista de despesa**: o `Dismissible` exige que o item saia da lista na hora. Então tiramos do signal primeiro e gravamos no banco depois; se o banco falhar, a lista volta ao estado anterior (há teste disso).
6. **Carregar tudo na memória**: num app de gastos pessoais são centenas ou poucos milhares de linhas, o que é leve. Os filtros por mês e categoria são `computed` em memória, instantâneos. Com muito mais dados, o certo seria consultar por mês no SQL.
7. **Data como texto ISO**: `'2026-11-24'` ordena corretamente como texto e é legível no banco.
8. **InheritedWidget em vez de pacote de injeção**: menos dependências e mais fácil de explicar. A reatividade vem dos signals, não do InheritedWidget.

---

## Perguntas prováveis na arguição

**O que é um signal?** Uma caixa reativa que guarda um valor. Quem lê `.value` dentro de um `computed`, `effect` ou `SignalBuilder` fica inscrito automaticamente e é avisado quando o valor muda.

**Diferença entre `signal` e `computed`?** `signal` é escrito por nós. `computed` é somente leitura, calculado a partir de outros signals. Ele guarda o resultado em cache e só recalcula quando alguma dependência muda e alguém lê o valor (avaliação preguiçosa).

**Por que não `setState`?** O `setState` reconstrói o widget inteiro e só funciona dentro dele. Com signals o estado é compartilhado entre telas e só o trecho que leu o valor reconstrói. A aba Resumo, por exemplo, nunca é avisada "na mão" de que uma despesa foi criada.

**E comparado a Provider/Riverpod/BLoC?** Signals têm menos código de cerimônia (sem `notifyListeners`, sem streams, sem eventos), rastreiam dependências automaticamente e fazem rebuild granular. Em compensação, a organização fica mais a cargo da equipe; aqui ela está toda concentrada no `AppStore`.

**Por que as telas leem `.value` dentro do `builder` e passam os valores para widgets filhos, em vez de o filho ler o signal?** O `SignalBuilder` só rastreia os signals lidos *durante a execução da função `builder`*. O `build` de um widget filho roda depois, fora desse rastreamento. Se o filho lesse `store.totalDoMes.value`, ninguém seria inscrito e a tela não atualizaria. (A primeira versão gerada com IA tinha exatamente esse erro.)

**Para que serve o `batch`?** Para agrupar várias escritas numa só notificação. Em `removerCategoria` mudamos três signals; sem `batch` a tela poderia reconstruir três vezes e passar por um estado intermediário inconsistente.

**Onde os dados ficam salvos?** No SQLite, arquivo `cofrinho.db` na pasta do app. Ao abrir, `main.dart` chama `store.carregar()`, que lê as duas tabelas e preenche os signals.

**O que acontece ao excluir uma categoria com despesas?** O app avisa quantas despesas serão apagadas. O SQLite apaga essas despesas por `ON DELETE CASCADE` e o store remove as mesmas despesas do signal dentro de um `batch`.

**Por que centavos?** Ver decisão 1.

**Como vocês verificaram o código gerado com IA?** `flutter test` com 3 arquivos de teste (store, formatadores e widget), além de testes manuais de cada operação CRUD e de fechar e reabrir o app para conferir a persistência.

---

## Testes

```bash
flutter test
```

- `test/app_store_test.dart`: computeds, troca de mês, filtro, CRUD das duas entidades, cascata e rollback da exclusão otimista.
- `test/formatadores_test.dart`: formatação de R$ e leitura de valores digitados.
- `test/widget_test.dart`: a tela reage a mudanças no store sem `setState`.
