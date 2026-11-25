/// Entidade 1: Categoria de gasto (ex.: Mercado, Transporte, Lazer).
///
/// Imutável: para "alterar" uma categoria criamos uma nova com [copyWith].
/// Isso combina com signals, porque o signal só notifica quando recebe um
/// objeto novo (comparação por igualdade / referência).
class Categoria {
  const Categoria({
    this.id,
    required this.nome,
    required this.cor,
    this.orcamentoCentavos = 0,
  });

  /// Chave primária no SQLite. É `null` enquanto a categoria não foi salva.
  final int? id;
  final String nome;

  /// Cor no formato ARGB (ex.: 0xFF2E7D32). Guardada como inteiro no banco.
  final int cor;

  /// Orçamento mensal em centavos. 0 significa "sem orçamento".
  final int orcamentoCentavos;

  bool get temOrcamento => orcamentoCentavos > 0;

  Categoria copyWith({
    int? id,
    String? nome,
    int? cor,
    int? orcamentoCentavos,
  }) {
    return Categoria(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cor: cor ?? this.cor,
      orcamentoCentavos: orcamentoCentavos ?? this.orcamentoCentavos,
    );
  }

  /// Converte para o formato de linha da tabela `categorias`.
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'cor': cor,
      'orcamento_centavos': orcamentoCentavos,
    };
  }

  factory Categoria.fromMap(Map<String, Object?> map) {
    return Categoria(
      id: map['id'] as int,
      nome: map['nome'] as String,
      cor: map['cor'] as int,
      orcamentoCentavos: map['orcamento_centavos'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Categoria &&
      other.id == id &&
      other.nome == nome &&
      other.cor == cor &&
      other.orcamentoCentavos == orcamentoCentavos;

  @override
  int get hashCode => Object.hash(id, nome, cor, orcamentoCentavos);

  @override
  String toString() => 'Categoria($id, $nome)';
}

/// Paleta de cores oferecida no formulário de categoria.
const List<int> paletaCategorias = [
  0xFF2E7D32, // verde
  0xFF1565C0, // azul
  0xFFC62828, // vermelho
  0xFFEF6C00, // laranja
  0xFF6A1B9A, // roxo
  0xFF00838F, // ciano
  0xFFAD1457, // rosa
  0xFF4E342E, // marrom
  0xFF546E7A, // cinza azulado
  0xFFF9A825, // amarelo
];

/// Categorias criadas automaticamente na primeira abertura do app.
const List<Categoria> categoriasIniciais = [
  Categoria(nome: 'Alimentação', cor: 0xFF2E7D32, orcamentoCentavos: 80000),
  Categoria(nome: 'Transporte', cor: 0xFF1565C0, orcamentoCentavos: 30000),
  Categoria(nome: 'Lazer', cor: 0xFF6A1B9A, orcamentoCentavos: 20000),
  Categoria(nome: 'Contas da casa', cor: 0xFFEF6C00),
];
