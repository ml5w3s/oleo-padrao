-- Óleo Padrão - Esquema de Banco de Dados Completo (Baseado no DER ERP/Logística)
-- Versão: 1.0.0
-- Descrição: Implementação fiel ao diagrama PDF, organizada por ordem de dependência.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. INFRAESTRUTURA BÁSICA E ENDEREÇOS
CREATE TABLE IF NOT EXISTS endereco (
    id_endereco SERIAL PRIMARY KEY,
    logradouro VARCHAR(255) NOT NULL,
    numero VARCHAR(20),
    complemento VARCHAR(255),
    bairro VARCHAR(100),
    cidade VARCHAR(100) NOT NULL,
    uf CHAR(2) NOT NULL,
    cep VARCHAR(10),
    referencia VARCHAR(255)
);

-- 2. PESSOAS (FÍSICA E JURÍDICA)
CREATE TABLE IF NOT EXISTS pessoa_fisica (
    id_pessoa_fisica SERIAL PRIMARY KEY,
    nome_completo VARCHAR(255) NOT NULL,
    cpf VARCHAR(14) UNIQUE NOT NULL,
    data_nascimento DATE,
    telefone VARCHAR(20),
    email VARCHAR(255),
    endereco_id INT REFERENCES endereco(id_endereco)
);

CREATE TABLE IF NOT EXISTS pessoa_juridica (
    id_pessoa_juridica SERIAL PRIMARY KEY,
    razao_social VARCHAR(255) NOT NULL,
    nome_fantasia VARCHAR(255),
    cnpj VARCHAR(18) UNIQUE NOT NULL,
    telefone VARCHAR(20),
    email VARCHAR(255),
    endereco_id INT REFERENCES endereco(id_endereco)
);

-- 3. FORNECEDORES E CONTRATOS
CREATE TABLE IF NOT EXISTS fornecedor (
    id_fornecedor SERIAL PRIMARY KEY,
    tipo_fornecedor VARCHAR(20) CHECK (tipo_fornecedor IN ('PF', 'PJ')),
    pessoa_fisica_id INT REFERENCES pessoa_fisica(id_pessoa_fisica),
    pessoa_juridica_id INT REFERENCES pessoa_juridica(id_pessoa_juridica),
    autorizado BOOLEAN DEFAULT TRUE,
    cancelado BOOLEAN DEFAULT FALSE,
    chave_pix_principal VARCHAR(255),
    email_contato VARCHAR(255),
    telefone VARCHAR(20),
    data_cadastro TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_fornecedor_pessoa CHECK (
        (pessoa_fisica_id IS NOT NULL AND pessoa_juridica_id IS NULL) OR 
        (pessoa_fisica_id IS NULL AND pessoa_juridica_id IS NOT NULL)
    )
);

CREATE TABLE IF NOT EXISTS fornecedor_contrato (
    id_fornecedor_contrato SERIAL PRIMARY KEY,
    fornecedor_id INT NOT NULL REFERENCES fornecedor(id_fornecedor),
    preco_litro DECIMAL(10,2) NOT NULL,
    data_inicio_vigencia DATE NOT NULL,
    data_fim_vigencia DATE,
    ativo BOOLEAN DEFAULT TRUE
);

-- 4. GESTÃO DE PESSOAL (FUNCIONÁRIOS, USUÁRIOS, MOTORISTAS)
CREATE TABLE IF NOT EXISTS funcionario (
    id_funcionario SERIAL PRIMARY KEY,
    pessoa_fisica_id INT NOT NULL REFERENCES pessoa_fisica(id_pessoa_fisica),
    tipo_funcionario VARCHAR(50), -- ex: Administrativo, Operacional, Motorista
    ativo BOOLEAN DEFAULT TRUE,
    data_admissao DATE,
    data_demissao DATE
);

CREATE TABLE IF NOT EXISTS motorista (
    id_motorista SERIAL PRIMARY KEY,
    funcionario_id INT NOT NULL REFERENCES funcionario(id_funcionario),
    numero_cnh VARCHAR(20) UNIQUE NOT NULL,
    categoria_cnh VARCHAR(5) NOT NULL,
    validade_cnh DATE NOT NULL,
    observacoes TEXT
);

CREATE TABLE IF NOT EXISTS usuario (
    id_usuario SERIAL PRIMARY KEY,
    funcionario_id INT REFERENCES funcionario(id_funcionario),
    login VARCHAR(100) UNIQUE NOT NULL,
    senha_hash VARCHAR(255) NOT NULL,
    ativo BOOLEAN DEFAULT TRUE,
    ultimo_acesso TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS perfil_acesso (
    id_perfil SERIAL PRIMARY KEY,
    nome_perfil VARCHAR(100) UNIQUE NOT NULL,
    descricao TEXT
);

CREATE TABLE IF NOT EXISTS usuario_perfil (
    usuario_id INT NOT NULL REFERENCES usuario(id_usuario),
    perfil_id INT NOT NULL REFERENCES perfil_acesso(id_perfil),
    PRIMARY KEY (usuario_id, perfil_id)
);

-- 5. FROTA E DOCUMENTAÇÃO
CREATE TABLE IF NOT EXISTS veiculo (
    id_veiculo SERIAL PRIMARY KEY,
    placa VARCHAR(10) UNIQUE NOT NULL,
    renavam VARCHAR(20) UNIQUE,
    modelo VARCHAR(100),
    marca VARCHAR(100),
    ano INT,
    capacidade_litros DECIMAL(10,2),
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS arquivo (
    id_arquivo SERIAL PRIMARY KEY,
    tipo_arquivo VARCHAR(50),
    nome_original VARCHAR(255),
    caminho_url TEXT NOT NULL,
    mime_type VARCHAR(100),
    tamanho_bytes BIGINT,
    data_upload TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    usuario_upload_id INT REFERENCES usuario(id_usuario)
);

CREATE TABLE IF NOT EXISTS documento_veiculo (
    id_documento SERIAL PRIMARY KEY,
    veiculo_id INT NOT NULL REFERENCES veiculo(id_veiculo),
    tipo_documento VARCHAR(50), -- CRLV, Seguro, etc
    numero_documento VARCHAR(100),
    data_emissao DATE,
    data_validade DATE,
    arquivo_id INT REFERENCES arquivo(id_arquivo)
);

-- 6. LOGÍSTICA (ROTAS E LOTE CCO)
CREATE TABLE IF NOT EXISTS rota (
    id_rota SERIAL PRIMARY KEY,
    nome_rota VARCHAR(100) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS rota_ponto (
    id_rota_ponto SERIAL PRIMARY KEY,
    rota_id INT NOT NULL REFERENCES rota(id_rota),
    ordem INT NOT NULL,
    descricao_ponto VARCHAR(255),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8)
);

CREATE TABLE IF NOT EXISTS motorista_rota (
    id_motorista_rota SERIAL PRIMARY KEY,
    motorista_id INT NOT NULL REFERENCES motorista(id_motorista),
    rota_id INT NOT NULL REFERENCES rota(id_rota),
    data_inicio_vinculo DATE DEFAULT CURRENT_DATE,
    data_fim_vinculo DATE
);

CREATE TABLE IF NOT EXISTS lote_cco (
    id_lote_cco SERIAL PRIMARY KEY,
    motorista_id INT NOT NULL REFERENCES motorista(id_motorista),
    numero_inicio INT NOT NULL,
    numero_fim INT NOT NULL,
    data_entrega DATE DEFAULT CURRENT_DATE,
    data_devolucao DATE,
    status VARCHAR(50) DEFAULT 'aberto',
    observacoes TEXT
);

CREATE TABLE IF NOT EXISTS cco (
    id_cco SERIAL PRIMARY KEY,
    lote_cco_id INT NOT NULL REFERENCES lote_cco(id_lote_cco),
    numero_cco INT NOT NULL,
    status VARCHAR(50) DEFAULT 'disponivel'
);

-- 7. OPERACIONAL (COLETA E COMPROVANTES)
CREATE TABLE IF NOT EXISTS localizacao (
    id_localizacao SERIAL PRIMARY KEY,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    endereco_texto TEXT,
    cidade VARCHAR(100),
    uf CHAR(2),
    cep VARCHAR(10),
    referencia VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS motivo_doc_nao_informado (
    id_motivo SERIAL PRIMARY KEY,
    descricao VARCHAR(255) NOT NULL,
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS coleta (
    id_coleta SERIAL PRIMARY KEY,
    fornecedor_id INT NOT NULL REFERENCES fornecedor(id_fornecedor),
    fornecedor_contrato_id INT REFERENCES fornecedor_contrato(id_fornecedor_contrato),
    motorista_id INT NOT NULL REFERENCES motorista(id_motorista),
    veiculo_id INT NOT NULL REFERENCES veiculo(id_veiculo),
    rota_id INT REFERENCES rota(id_rota),
    localizacao_id INT REFERENCES localizacao(id_localizacao),
    cco_id INT REFERENCES cco(id_cco),
    motivo_doc_nao_informado_id INT REFERENCES motivo_doc_nao_informado(id_motivo),
    data_hora_coleta TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    litros_coletados DECIMAL(10,2) NOT NULL,
    preco_por_litro DECIMAL(10,2) NOT NULL,
    valor_total DECIMAL(10,2) NOT NULL,
    status_coleta VARCHAR(50) DEFAULT 'concluida',
    telefone_fornecedor_snapshot VARCHAR(20),
    ajudante_nome_snapshot VARCHAR(255),
    observacoes TEXT
);

CREATE TABLE IF NOT EXISTS comprovante (
    id_comprovante SERIAL PRIMARY KEY,
    coleta_id INT NOT NULL REFERENCES coleta(id_coleta),
    numero_comprovante VARCHAR(100),
    data_hora_geracao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    dados_resumo TEXT,
    arquivo_imagem_id INT REFERENCES arquivo(id_arquivo)
);

-- 8. FINANCEIRO E PAGAMENTOS
CREATE TABLE IF NOT EXISTS limite_pix_motorista (
    id_limite SERIAL PRIMARY KEY,
    motorista_id INT NOT NULL REFERENCES motorista(id_motorista),
    limite_diario DECIMAL(10,2) NOT NULL,
    limite_mensal DECIMAL(10,2) NOT NULL,
    data_inicio_vigencia DATE NOT NULL,
    data_fim_vigencia DATE,
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS pagamento (
    id_pagamento SERIAL PRIMARY KEY,
    coleta_id INT REFERENCES coleta(id_coleta),
    motorista_id INT REFERENCES motorista(id_motorista), -- Pagamento pode ser adiantamento/reembolso
    fornecedor_id INT REFERENCES fornecedor(id_fornecedor),
    tipo_pagamento VARCHAR(50) NOT NULL, -- PIX, DINHEIRO, CONTRATO, ADIANTAMENTO
    valor_pagamento DECIMAL(10,2) NOT NULL,
    data_agendamento TIMESTAMP WITH TIME ZONE,
    data_hora_pagamento TIMESTAMP WITH TIME ZONE,
    status_pagamento VARCHAR(50) DEFAULT 'pendente',
    chave_pix VARCHAR(255),
    end_to_end_id VARCHAR(255) UNIQUE, -- Para conciliação bancária
    descricao TEXT,
    usuario_responsavel_id INT REFERENCES usuario(id_usuario)
);

-- 9. RESUMO E FECHAMENTO
CREATE TABLE IF NOT EXISTS resumo_diario_motorista (
    id_resumo_diario SERIAL PRIMARY KEY,
    data_resumo DATE NOT NULL DEFAULT CURRENT_DATE,
    motorista_id INT NOT NULL REFERENCES motorista(id_motorista),
    veiculo_id INT NOT NULL REFERENCES veiculo(id_veiculo),
    usuario_responsavel_id INT REFERENCES usuario(id_usuario),
    km DECIMAL(10,2),
    litros_coletados_dia DECIMAL(10,2),
    quantidade_tambores INT,
    preco_medio_tambor DECIMAL(10,2),
    total_gasto DECIMAL(10,2),
    valor_em_dinheiro DECIMAL(10,2),
    valor_adiantado DECIMAL(10,2),
    troco DECIMAL(10,2),
    vt_va DECIMAL(10,2),
    sobra DECIMAL(10,2),
    umidade_media DECIMAL(10,2),
    data_cadastro TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ativo BOOLEAN DEFAULT TRUE
);

-- 10. AUDITORIA E LOGS
CREATE TABLE IF NOT EXISTS auditoria (
    id_auditoria SERIAL PRIMARY KEY,
    entidade VARCHAR(100) NOT NULL, -- nome da tabela
    id_registro INT NOT NULL,
    campo VARCHAR(100),
    valor_anterior TEXT,
    valor_novo TEXT,
    tipo_operacao VARCHAR(20), -- INSERT, UPDATE, DELETE
    usuario_id INT REFERENCES usuario(id_usuario),
    data_hora TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    origem VARCHAR(255) -- IP, Sistema, etc
);

CREATE TABLE IF NOT EXISTS log_aplicacao (
    id_log SERIAL PRIMARY KEY,
    data_hora TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    nivel VARCHAR(20), -- INFO, WARN, ERROR
    origem VARCHAR(255),
    mensagem TEXT,
    detalhes TEXT,
    contexto JSONB
);

-- ÍNDICES PARA PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_coleta_data ON coleta(data_hora_coleta);
CREATE INDEX IF NOT EXISTS idx_pagamento_status ON pagamento(status_pagamento);
CREATE INDEX IF NOT EXISTS idx_pagamento_e2e ON pagamento(end_to_end_id);
CREATE INDEX IF NOT EXISTS idx_fornecedor_documento ON fornecedor(pessoa_fisica_id, pessoa_juridica_id);
