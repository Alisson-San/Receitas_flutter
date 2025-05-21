import 'package:uuid/uuid.dart';


class Ingrediente {
  String? id;
  String? receitaId;
  String? nome;
  String? quantidade;

  Ingrediente({
    String ? id,
    required this.receitaId,
    required this.nome,
    this.quantidade,
  }) : id = id ?? const Uuid().v4();

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
