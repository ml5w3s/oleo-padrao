/**
 * Definições compartilhadas para o ecossistema Óleo Padrão
 * Reflete o esquema ERP/Logística 1.0.0
 */

// --- Infraestrutura e Endereço ---

export interface Endereco {
  id_endereco: number;
  logradouro: string;
  numero?: string;
  complemento?: string;
  bairro?: string;
  cidade: string;
  uf: string;
  cep?: string;
  referencia?: string;
}

// --- Pessoas e Fornecedores ---

export interface PessoaFisica {
  id_pessoa_fisica: number;
  nome_completo: string;
  cpf: string;
  data_nascimento?: Date;
  telefone?: string;
  email?: string;
  endereco_id?: number;
}

export interface PessoaJuridica {
  id_pessoa_juridica: number;
  razao_social: string;
  nome_fantasia?: string;
  cnpj: string;
  telefone?: string;
  email?: string;
  endereco_id?: number;
}

export type TipoFornecedor = 'PF' | 'PJ';

export interface Fornecedor {
  id_fornecedor: number;
  tipo_fornecedor: TipoFornecedor;
  pessoa_fisica_id?: number;
  pessoa_juridica_id?: number;
  autorizado: boolean;
  cancelado: boolean;
  chave_pix_principal?: string;
  email_contato?: string;
  telefone?: string;
  data_cadastro: Date;
}

export interface FornecedorContrato {
  id_fornecedor_contrato: number;
  fornecedor_id: number;
  preco_litro: number;
  data_inicio_vigencia: Date;
  data_fim_vigencia?: Date;
  ativo: boolean;
}

// --- Gestão de Pessoal e Frota ---

export interface Funcionario {
  id_funcionario: number;
  pessoa_fisica_id: number;
  tipo_funcionario?: string;
  ativo: boolean;
  data_admissao?: Date;
  data_demissao?: Date;
}

export interface Motorista {
  id_motorista: number;
  funcionario_id: number;
  numero_cnh: string;
  categoria_cnh: string;
  validade_cnh: Date;
  observacoes?: string;
}

export interface Veiculo {
  id_veiculo: number;
  placa: string;
  renavam?: string;
  modelo?: string;
  marca?: string;
  ano?: number;
  capacidade_litros?: number;
  ativo: boolean;
}

// --- Logística e Operacional ---

export type ColetaStatus = 'concluida' | 'cancelada' | 'pendente';

export interface Coleta {
  id_coleta: number;
  fornecedor_id: number;
  fornecedor_contrato_id?: number;
  motorista_id: number;
  veiculo_id: number;
  rota_id?: number;
  localizacao_id?: number;
  cco_id?: number;
  motivo_doc_nao_informado_id?: number;
  data_hora_coleta: Date;
  litros_coletados: number;
  preco_por_litro: number;
  valor_total: number;
  status_coleta: ColetaStatus;
  telefone_fornecedor_snapshot?: string;
  ajudante_nome_snapshot?: string;
  observacoes?: string;
}

// --- Financeiro ---

export type PagamentoStatus = 'pendente' | 'confirmado' | 'falha';
export type TipoPagamento = 'PIX' | 'DINHEIRO' | 'CONTRATO' | 'ADIANTAMENTO';

export interface Pagamento {
  id_pagamento: number;
  coleta_id?: number;
  motorista_id?: number;
  fornecedor_id?: number;
  tipo_pagamento: TipoPagamento;
  valor_pagamento: number;
  data_agendamento?: Date;
  data_hora_pagamento?: Date;
  status_pagamento: PagamentoStatus;
  chave_pix?: string;
  end_to_end_id?: string;
  descricao?: string;
  usuario_responsavel_id?: number;
}

// --- DTOs das VIEWS (Para o Broker) ---

export interface ViewFinanceiroBroker {
  id_pagamento: number;
  data_hora_pagamento?: Date;
  tipo_pagamento: string;
  valor_pagamento: number;
  status_pagamento: string;
  end_to_end_id?: string;
  id_fornecedor: number;
  nome_fornecedor: string;
  documento_fornecedor: string;
}

export interface ViewOperacionalRotas {
  id_coleta: number;
  data_hora_coleta: Date;
  litros_coletados: number;
  valor_total: number;
  nome_rota: string;
  placa_veiculo: string;
  motorista_nome: string;
  status_coleta: string;
}

export interface ViewResumoFechamentoDiario {
  data_resumo: Date;
  km?: number;
  litros_coletados_dia?: number;
  total_gasto?: number;
  valor_em_dinheiro?: number;
  valor_adiantado?: number;
  sobra?: number;
  saldo_calculado: number;
}
