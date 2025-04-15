class Ingrediente {
  final int id;
  final int receitaId;
  final String nome;
  final int? quantidade;

  Ingrediente({
    required this.id,
    required this.receitaId,
    required this.nome,
    this.quantidade,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receitaId': receitaId,
      'nome': nome,
      'quantidade': quantidade,
    };
  }

  factory Ingrediente.fromMap(Map<String, dynamic> map) {
    return Ingrediente(
      id: map['id'],
      receitaId: map['receitaId'],
      nome: map['nome'],
      quantidade: map['quantidade'],
    );
  }
}
