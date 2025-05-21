import 'package:uuid/uuid.dart';

class Instrucao {
  String? id;
  String? receitaId;
  final int? passo;
  final String? descricao;

  Instrucao({
    String ? id,
    this.receitaId,
    this.passo,
    this.descricao,
  }): id = id ?? const Uuid().v4();

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