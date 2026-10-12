# ADR-0001: Monolito modular

- **Status:** Proposto
- **Data:** 2026-10-12

## Contexto
Serviço pequeno que precisa ser simples de rodar e escalar sem depender de infraestrutura complexa.
Login, autenticação e tokens compartilham os mesmos dados, portanto fazem parte de um mesmo fluxo de negócio.


## Decisão
Um único deploy, organizado em pacotes por funcionalidade/feature.

## Alternativas consideradas
- Dividir as features do monolito em microsserviços = custo operacional acima do benefício neste tamanho.
- Maven multi-módulo: rejeitado. Adiciona complexidade de build sem ganho real para uma pessoa.

## Consequências
- Simples de testar e publicar; sem integração ou dependência entre serviços por agora.
- Negativas: sem isolamento físico entre módulos, a disciplina de fronteiras depende de convenção.