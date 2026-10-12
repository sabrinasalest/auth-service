# Modelagem de ameaças (ou modelo de risco) do serviço de autenticação.

_Em construção._

| Ameaça | Como acontece | Mitigação |
|---|---|---|
| Força bruta no login | Tentar muitas senhas | Rate limit e bloqueio temporário |
| Enumeração de usuários | Mensagens diferentes para e-mail existente ou não | Resposta genérica |
| Vazamento do banco | Acesso indevido às tabelas | Hash de senha e de tokens |
| Roubo de refresh token | Token copiado | Rotação e revogação |