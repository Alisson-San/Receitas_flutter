class Instrucao {
  String? id;
  String? receitaId;
  final int? passo;
  final String? descricao;

  Instrucao({
    this.id,
    this.receitaId,
    this.passo,
    this.descricao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receitaId': receitaId,
      'passo': passo,
      'descricao': descricao,
    };
  }

  factory Instrucao.fromMap(Map<String, dynamic> map) {
    return Instrucao(
      id: map['id'],
      receitaId: map['receitaId'],
      passo: map['passo'],
      descricao: map['descricao'],
    );
  }

}