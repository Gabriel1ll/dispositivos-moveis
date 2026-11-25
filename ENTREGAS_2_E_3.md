# Apoio para as entregas 2 e 3

## Entrega 2: modelo de relato sobre o uso de IA

> Preencham com o que **realmente** aconteceu na equipe. O professor vai perguntar sobre isso, então o relato precisa ser verdadeiro.

**Ferramentas usadas:** (ex.: Claude, ChatGPT, Copilot...)

**Em que atividades a IA foi usada:**
- Geração da estrutura inicial do projeto (modelos, banco, store com signals, telas).
- Explicação de conceitos de signals (`signal`, `computed`, `batch`).
- (outros: correção de erros, textos, testes...)

**Como a equipe verificou os resultados:**
- Rodamos `flutter test` (testes do store, dos formatadores e de widget).
- Testamos manualmente cada operação CRUD no emulador/celular.
- Fechamos e reabrimos o app para confirmar a persistência.
- Cada integrante leu e explicou para os outros uma parte do código: (quem ficou com o quê)
- Problemas encontrados no código gerado e como corrigimos: (descrever)

**O que aprendemos / cuidados:** (ex.: a IA pode usar uma versão antiga da API de um pacote; conferimos na documentação do pub.dev)

---

## Roteiro sugerido: vídeo da Entrega 2 (até 3 min)

1. **0:00–0:20** Abrir o app e mostrar as 3 abas.
2. **0:20–1:10** Categorias: criar uma, editar a cor e o orçamento, excluir outra.
3. **1:10–2:10** Despesas: lançar 2 ou 3, editar uma, excluir deslizando, filtrar por categoria, trocar de mês.
4. **2:10–2:40** Mostrar que a barra de orçamento e o Resumo se atualizaram sozinhos (signals).
5. **2:40–3:00** Fechar o app por completo e reabrir: os dados continuam lá.

## Roteiro sugerido: vídeo final (até 2 min)

1. **0:00–0:40** CRUD de Categoria completo (criar, listar, editar, excluir).
2. **0:40–1:20** CRUD de Despesa completo, ultrapassando um orçamento de propósito.
3. **1:20–1:45** Signals em ação: o alerta de orçamento estourado aparece no Resumo e a barra fica vermelha, sem recarregar nada. Trocar o mês numa aba e mostrar que mudou nas outras.
4. **1:45–2:00** Fechar e reabrir o app para mostrar a persistência.

## Divisão sugerida para a arguição

Cada integrante domina uma parte, mas todos devem saber o fluxo geral (README, seção "Arquitetura").

| Parte | Arquivos |
|---|---|
| Signals / estado | `lib/state/app_store.dart`, `lib/state/store_scope.dart` |
| Persistência | `lib/data/*`, `lib/models/*` |
| Telas e formulários | `lib/screens/*`, `lib/widgets/*` |
| Testes e validações | `test/*`, `lib/util/formatadores.dart` |
