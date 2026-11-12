-- ============================================================
-- PROJETO ACADÊMICO: CRM - ARMAZÉM CASA & PET
-- Etapa 4: Criação do Banco de Dados Físico (DDL/DML Avançado)
-- Versão: 2.0 — Cobertura lógica completa (estoque + triggers UPDATE/DELETE)
-- Autor: Thiago Ferraz de Jesus
-- Instituição: COLTEC / UFMG
-- SGBD: MySQL 8.0+ / phpMyAdmin
-- ============================================================

-- ------------------------------------------------------------
-- 1. INFRAESTRUTURA E AMBIENTE DO BANCO DE DADOS
-- ------------------------------------------------------------
DROP DATABASE IF EXISTS crm_armazem_casa_pet;

CREATE DATABASE crm_armazem_casa_pet
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE crm_armazem_casa_pet;

-- ------------------------------------------------------------
-- 2. DDL - CRIAÇÃO DAS TABELAS INDEPENDENTES (NÍVEL 1)
-- ------------------------------------------------------------

-- Tabela: PERFIL (Classificação de Pessoas para o CRM)
CREATE TABLE perfil (
    id          INT UNSIGNED    AUTO_INCREMENT,
    tipo        VARCHAR(2)      NOT NULL,
    descricao   VARCHAR(100)    NOT NULL,
    CONSTRAINT pk_perfil      PRIMARY KEY (id),
    CONSTRAINT ck_perfil_tipo CHECK (tipo IN ('PF', 'PJ'))
) ENGINE = InnoDB;

-- Tabela: PRODUTO (Catálogo do Empório: Pets, Roça e Casa)
CREATE TABLE produto (
    id          INT UNSIGNED    AUTO_INCREMENT,
    nome        VARCHAR(100)    NOT NULL,
    categoria   VARCHAR(50)     NOT NULL,   -- 'Rações', 'Acessórios', 'Roça/Quitanda', 'Rotisseria'
    preco       DECIMAL(10,2)   NOT NULL,
    estoque     INT UNSIGNED    NOT NULL DEFAULT 0,
    ativo       BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_produto       PRIMARY KEY (id),
    CONSTRAINT ck_produto_preco CHECK (preco >= 0)
) ENGINE = InnoDB;

-- ------------------------------------------------------------
-- 3. DDL - CRIAÇÃO DAS TABELAS DEPENDENTES (NÍVEIS 2 E 3)
-- ------------------------------------------------------------

-- Tabela: CLIENTE (Dados de cadastro do tutor/comprador)
CREATE TABLE cliente (
    id              INT UNSIGNED    AUTO_INCREMENT,
    perfil_id       INT UNSIGNED    NOT NULL,
    nome            VARCHAR(100)    NOT NULL,
    cpf_cnpj        VARCHAR(18)     NOT NULL,
    email           VARCHAR(120)    NOT NULL,
    telefone        VARCHAR(20)     NOT NULL,
    endereco        VARCHAR(200),
    data_cadastro   DATE            NOT NULL,
    CONSTRAINT pk_cliente           PRIMARY KEY (id),
    CONSTRAINT uq_cliente_cpf_cnpj  UNIQUE (cpf_cnpj),
    CONSTRAINT uq_cliente_email     UNIQUE (email),
    CONSTRAINT fk_cliente_perfil    FOREIGN KEY (perfil_id)
        REFERENCES perfil (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE = InnoDB;

-- Tabela: PET (Ficha do animal associado ao cliente para CRM)
CREATE TABLE pet (
    id                  INT UNSIGNED    AUTO_INCREMENT,
    cliente_id          INT UNSIGNED    NOT NULL,
    nome                VARCHAR(50)     NOT NULL,
    especie             VARCHAR(30)     NOT NULL,   -- 'Cão', 'Gato', 'Ave'
    raca                VARCHAR(50),
    porte               VARCHAR(20),                -- 'Pequeno', 'Médio', 'Grande'
    saude_observacao    TEXT,                       -- Histórico alimentar, alergias e alertas de recompra
    CONSTRAINT pk_pet           PRIMARY KEY (id),
    CONSTRAINT fk_pet_cliente   FOREIGN KEY (cliente_id)
        REFERENCES cliente (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE = InnoDB;

-- Tabela: INTERACAO (Registro das vendas de balcão e atendimentos)
CREATE TABLE interacao (
    id              INT UNSIGNED    AUTO_INCREMENT,
    pet_id          INT UNSIGNED    NOT NULL,
    data_hora       DATETIME        NOT NULL,
    tipo            VARCHAR(50)     NOT NULL DEFAULT 'Venda Balcão Empório',
    observacao      TEXT,
    valor_total     DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    forma_pagamento VARCHAR(30)     NOT NULL,   -- 'PIX', 'Cartão de Crédito', 'Dinheiro'
    CONSTRAINT pk_interacao         PRIMARY KEY (id),
    CONSTRAINT fk_interacao_pet     FOREIGN KEY (pet_id)
        REFERENCES pet (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_interacao_valor   CHECK (valor_total >= 0)
) ENGINE = InnoDB;

-- ------------------------------------------------------------
-- 4. DDL - TABELA ASSOCIATIVA (RELACIONAMENTO N:M)
-- ------------------------------------------------------------

-- Tabela: INCLUI / ITEM_INTERACAO (Itens de cada venda)
CREATE TABLE inclui (
    interacao_id    INT UNSIGNED    NOT NULL,
    produto_id      INT UNSIGNED    NOT NULL,
    quantidade      INT UNSIGNED    NOT NULL DEFAULT 1,
    preco_unitario  DECIMAL(10,2)   NOT NULL,   -- Preserva o histórico financeiro da transação
    CONSTRAINT pk_inclui            PRIMARY KEY (interacao_id, produto_id),
    CONSTRAINT fk_inclui_interacao  FOREIGN KEY (interacao_id)
        REFERENCES interacao (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_inclui_produto    FOREIGN KEY (produto_id)
        REFERENCES produto (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_inclui_quantidade CHECK (quantidade > 0),
    CONSTRAINT ck_inclui_preco      CHECK (preco_unitario >= 0)
) ENGINE = InnoDB;

-- ============================================================
-- 5. TRIGGERS — AUTOMAÇÃO COMPLETA (TOTAL + ESTOQUE)
-- Cobertura dos 3 eventos de escrita: INSERT, UPDATE, DELETE
-- ============================================================

DELIMITER //

-- ------------------------------------------------------------
-- TRIGGER 1/3 — INSERT
-- Ao adicionar um item à venda:
--   • Recalcula o valor_total da interação
--   • Decrementa o estoque do produto vendido
-- ------------------------------------------------------------
CREATE TRIGGER trg_inclui_after_insert
AFTER INSERT ON inclui
FOR EACH ROW
BEGIN
    -- Atualiza o total somando quantidade × preço de todos os itens da venda
    UPDATE interacao
    SET valor_total = (
        SELECT SUM(quantidade * preco_unitario)
        FROM inclui
        WHERE interacao_id = NEW.interacao_id
    )
    WHERE id = NEW.interacao_id;

    -- Decrementa o estoque do produto incluído na venda
    UPDATE produto
    SET estoque = estoque - NEW.quantidade
    WHERE id = NEW.produto_id;
END;
//

-- ------------------------------------------------------------
-- TRIGGER 2/3 — UPDATE
-- Ao alterar a quantidade de um item já registrado:
--   • Recalcula o valor_total da interação
--   • Ajusta o estoque: devolve a quantidade antiga e deduz a nova
-- ------------------------------------------------------------
CREATE TRIGGER trg_inclui_after_update
AFTER UPDATE ON inclui
FOR EACH ROW
BEGIN
    -- Recalcula o total com os novos valores
    UPDATE interacao
    SET valor_total = (
        SELECT SUM(quantidade * preco_unitario)
        FROM inclui
        WHERE interacao_id = NEW.interacao_id
    )
    WHERE id = NEW.interacao_id;

    -- Ajusta o estoque: devolve a quantidade antiga e subtrai a nova
    -- Exemplo: era 2 unidades, virou 5 → estoque cai mais 3
    -- Exemplo: era 5 unidades, virou 2 → estoque volta 3
    UPDATE produto
    SET estoque = estoque + OLD.quantidade - NEW.quantidade
    WHERE id = NEW.produto_id;
END;
//

-- ------------------------------------------------------------
-- TRIGGER 3/3 — DELETE
-- Ao remover um item da venda:
--   • Recalcula o valor_total da interação
--   • Devolve ao estoque a quantidade que havia sido reservada
-- ------------------------------------------------------------
CREATE TRIGGER trg_inclui_after_delete
AFTER DELETE ON inclui
FOR EACH ROW
BEGIN
    -- Recalcula o total sem o item removido
    UPDATE interacao
    SET valor_total = COALESCE(
        (
            SELECT SUM(quantidade * preco_unitario)
            FROM inclui
            WHERE interacao_id = OLD.interacao_id
        ),
        0.00    -- Se não sobrou nenhum item, total vai a zero
    )
    WHERE id = OLD.interacao_id;

    -- Devolve ao estoque a quantidade do item removido
    UPDATE produto
    SET estoque = estoque + OLD.quantidade
    WHERE id = OLD.produto_id;
END;
//

DELIMITER ;

-- ============================================================
-- 6. DML - POVOAMENTO INICIAL DE TESTES (DADOS DO EMPÓRIO)
-- ============================================================

-- Inserção de Perfis
INSERT INTO perfil (tipo, descricao) VALUES
('PF', 'Pessoa Física - Cliente Final'),
('PJ', 'Pessoa Jurídica - Fornecedor / Parceiro');

-- Inserção de Produtos (com estoques iniciais)
INSERT INTO produto (nome, categoria, preco, estoque, ativo) VALUES
('Ração Quatree Supreme Cães Adultos 15kg',  'Rações',        210.00, 25, TRUE),
('Petisco Pet Cão Biscoito Natural 250g',    'Acessórios',     15.50, 50, TRUE),
('Queijo Artesanal Alagoa Peça',             'Roça/Quitanda',  45.00, 18, TRUE),
('Frango Assado Especial de Domingo',        'Rotisseria',     55.00, 12, TRUE),
('Mel Puro Florada Silvestre 500g',          'Roça/Quitanda',  32.00, 30, TRUE);

-- Inserção de Clientes
INSERT INTO cliente (perfil_id, nome, cpf_cnpj, email, telefone, endereco, data_cadastro) VALUES
(1, 'Thiago Ferraz de Jesus', '123.456.789-00', 'thiago@email.com', '(31) 99999-8888', 'Contagem - MG',      '2026-08-01'),
(1, 'João Afonso',            '987.654.321-11', 'joao@email.com',   '(31) 98888-7777', 'Belo Horizonte - MG','2026-08-15');

-- Inserção de Pets
INSERT INTO pet (cliente_id, nome, especie, raca, porte, saude_observacao) VALUES
(1, 'Thor', 'Cão', 'Golden Retriever', 'Grande',  'Consome 1 bag de Ração Quatree 15kg a cada 30 dias. Sem alergias.'),
(2, 'Luna', 'Gato', 'Siamês',          'Pequeno', 'Gosta de petiscos naturais. Alergia a corantes.');

-- Registrando Vendas (valor_total começa em 0.00 — será preenchido pela trigger de INSERT)
INSERT INTO interacao (pet_id, data_hora, tipo, observacao, valor_total, forma_pagamento) VALUES
(1, '2026-09-25 10:30:00', 'Venda Balcão Empório', 'Compra mensal do Thor + itens da quitanda', 0.00, 'PIX'),
(2, '2026-09-28 16:15:00', 'Venda Balcão Empório', 'Compra rápida de petiscos e mel',           0.00, 'Cartão de Crédito');

-- Inserção dos Itens Vendidos
-- ► Aqui as 3 triggers entram em ação automaticamente:
--   trg_inclui_after_insert → atualiza valor_total E desconta estoque
INSERT INTO inclui (interacao_id, produto_id, quantidade, preco_unitario) VALUES
(1, 1, 1, 210.00),  -- 1 Ração Quatree 15kg  → estoque: 25 → 24
(1, 3, 1,  45.00),  -- 1 Queijo Alagoa        → estoque: 18 → 17
(1, 4, 1,  55.00),  -- 1 Frango Assado        → estoque: 12 → 11
(2, 2, 2,  15.50),  -- 2 Biscoitos Pet        → estoque: 50 → 48
(2, 5, 1,  32.00);  -- 1 Mel Puro             → estoque: 30 → 29

-- ============================================================
-- 7. VIEW PARA O DASHBOARD DO CRM
-- ============================================================

-- Consolida Cliente, Pet, Venda, Itens e Estoque pós-venda num único relatório
CREATE OR REPLACE VIEW vw_relatorio_vendas_crm AS
SELECT
    i.id            AS venda_id,
    c.nome          AS cliente,
    p.nome          AS pet,
    p.especie,
    i.data_hora,
    i.tipo          AS tipo_atendimento,
    i.forma_pagamento,
    i.valor_total
FROM interacao i
JOIN pet      p ON i.pet_id      = p.id
JOIN cliente  c ON p.cliente_id  = c.id;

-- View de controle de estoque: lista produtos com saldo atual após as vendas
CREATE OR REPLACE VIEW vw_estoque_atual AS
SELECT
    id,
    nome,
    categoria,
    preco,
    estoque         AS saldo_atual,
    ativo,
    CASE
        WHEN estoque = 0  THEN 'SEM ESTOQUE'
        WHEN estoque <= 5 THEN 'ESTOQUE BAIXO'
        ELSE                   'OK'
    END             AS status_estoque
FROM produto
ORDER BY estoque ASC;

-- ============================================================
-- 8. TESTE E CONFERÊNCIA FINAL
-- ============================================================
SHOW TABLES;

-- Conferência 1: Relatório de vendas com totais calculados pela trigger
SELECT * FROM vw_relatorio_vendas_crm;

-- Conferência 2: Estoques após as vendas — devem estar decrementados
SELECT * FROM vw_estoque_atual;

-- Conferência 3: Simula uma correção de quantidade (aciona trg_inclui_after_update)
-- Cenário: o atendente registrou 2 biscoitos, mas o cliente levou 3
UPDATE inclui
SET quantidade = 3
WHERE interacao_id = 2 AND produto_id = 2;

-- Verificação pós-UPDATE: total da venda 2 deve ser 78,50 (3×15,50 + 1×32,00)
--                         estoque do biscoito deve ser 47 (50 - 3)
SELECT id, valor_total FROM interacao WHERE id = 2;
SELECT id, nome, estoque FROM produto WHERE id = 2;

-- Conferência 4: Simula remoção de um item (aciona trg_inclui_after_delete)
-- Cenário: cliente desistiu do mel
DELETE FROM inclui WHERE interacao_id = 2 AND produto_id = 5;

-- Verificação pós-DELETE: total da venda 2 deve ser 46,50 (3×15,50 apenas)
--                         estoque do mel deve voltar a 30
SELECT id, valor_total FROM interacao WHERE id = 2;
SELECT id, nome, estoque FROM produto WHERE id = 5;