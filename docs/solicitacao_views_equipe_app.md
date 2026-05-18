# Guia Técnico: Implementação de Views para Integração (Broker)

Este documento descreve a criação de **Views** (Visões) no banco de dados. O objetivo é simplificar o acesso aos dados para a geração de relatórios financeiros e operacionais, garantindo que a lógica de negócio esteja centralizada no banco.

## O que é uma VIEW?
Uma VIEW funciona como uma "tabela virtual". Ela é, na verdade, uma consulta SQL (SELECT) que fica salva no banco de dados com um nome próprio. 

**Vantagens:**
1. **Facilidade:** Em vez de fazer JOINs complexos toda vez, fazemos um `SELECT *` na View.
2. **Segurança:** A API acessa apenas o que é necessário.
3. **Padronização:** Todos os relatórios usarão a mesma regra de cálculo.

---

## 1. View para Financeiro (Conciliação e Fluxo)
Esta visão une os dados de pagamentos com as informações dos fornecedores.

```sql
CREATE OR REPLACE VIEW vw_financeiro_broker AS
SELECT 
    p.id_pagamento,
    p.data_hora_pagamento,
    p.tipo_pagamento,
    p.valor_pagamento,
    p.status_pagamento,
    p.end_to_end_id, -- Chave para conciliação bancária
    f.id_fornecedor,
    CASE 
        WHEN f.tipo_fornecedor = 'PF' THEN pf.nome_completo
        WHEN f.tipo_fornecedor = 'PJ' THEN pj.razao_social
    END AS nome_fornecedor,
    COALESCE(pf.cpf, pj.cnpj) AS documento_fornecedor
FROM pagamento p
JOIN fornecedor f ON p.fornecedor_id = f.id_fornecedor
LEFT JOIN pessoa_fisica pf ON f.pessoa_fisica_id = pf.id_pessoa_fisica
LEFT JOIN pessoa_juridica pj ON f.pessoa_juridica_id = pj.id_pessoa_juridica;
```

---

## 2. View para Operacional (Relatório de Rotas)
Esta visão consolida os dados de coleta, rotas e veículos para análise de produtividade.

```sql
CREATE OR REPLACE VIEW vw_operacional_rotas AS
SELECT 
    c.id_coleta,
    c.data_hora_coleta,
    c.litros_coletados,
    c.valor_total,
    r.nome_rota,
    v.placa AS placa_veiculo,
    f_pf.nome_completo AS motorista_nome,
    c.status_coleta
FROM coleta c
JOIN rota r ON c.rota_id = r.id_rota
JOIN veiculo v ON c.veiculo_id = v.id_veiculo
JOIN motorista m ON c.motorista_id = m.id_motorista
JOIN funcionario func ON m.funcionario_id = func.id_funcionario
JOIN pessoa_fisica f_pf ON func.pessoa_fisica_id = f_pf.id_pessoa_fisica;
```

---

## 3. View para Resumo Diário (Excel)
Visão otimizada para alimentar planilhas de fechamento.

```sql
CREATE OR REPLACE VIEW vw_resumo_fechamento_diario AS
SELECT 
    data_resumo,
    km,
    litros_coletados_dia,
    total_gasto,
    valor_em_dinheiro,
    valor_adiantado,
    sobra,
    (valor_em_dinheiro + valor_adiantado - total_gasto) AS saldo_calculado
FROM resumo_diario_motorista
WHERE ativo = true;
```

---

## Como aplicar?
Basta copiar os comandos acima e executá-los no console do PostgreSQL (ou via ferramenta como DBeaver/pgAdmin). Uma vez criadas, a API poderá ler os dados simplesmente assim:

```sql
SELECT * FROM vw_financeiro_broker;
```
