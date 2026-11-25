/// Entidade 2: Despesa (um gasto realizado).
///
/// Cada despesa pertence a uma [Categoria] (chave estrangeira `categoria_id`).
/// O valor é guardado em centavos (inteiro) para evitar erros de
/// arredondamento de ponto flutuante (ex.: 0.1 + 0.2 != 0.3).
class Despesa {
  const Despesa({
    this.id,
    required this.descricao,
    required this.valorCentavos,
    required this.data,
    required this.categoriaId,
  });

  final int? id;
  final String descricao;
  final int valorCentavos;

  /// Apenas a data (sem horário).
  final DateTime data;
  final int categoriaId;

  Despesa copyWith({
    int? id,
    String? descricao,
    int? valorCentavos,
    DateTime? data,
    int? categoriaId,
  }) {
    return Despesa(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      valorCentavos: valorCentavos ?? this.valorCentavos,
      data: data ?? this.data,
      categoriaId: categoriaId ?? this.categoriaId,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'descricao': descricao,
      'valor_centavos': valorCentavos,
      // Formato ISO (AAAA-MM-DD): ordena corretamente como texto no SQLite.
      'data': dataParaTexto(data),
      'categoria_id': categoriaId,
    };
  }

  factory Despesa.fromMap(Map<String, Object?> map) {
    return Despesa(
      id: map['id'] as int,
      descricao: map['descricao'] as String,
      valorCentavos: map['valor_centavos'] as int,
      data: DateTime.parse(map['data'] as String),
      categoriaId: map['categoria_id'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Despesa &&
      other.id == id &&
      other.descricao == descricao &&
      other.valorCentavos == valorCentavos &&
      other.data == data &&
      other.categoriaId == categoriaId;

  @override
  int get hashCode =>
      Object.hash(id, descricao, valorCentavos, data, categoriaId);

  @override
  String toString() => 'Despesa($id, $descricao, $valorCentavos)';
}

String dataParaTexto(DateTime d) {
  final ano = d.year.toString().padLeft(4, '0');
  final mes = d.month.toString().padLeft(2, '0');
  final dia = d.day.toString().padLeft(2, '0');
  return '$ano-$mes-$dia';
}
