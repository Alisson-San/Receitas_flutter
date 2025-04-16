import 'dart:ffi';

import 'package:uuid/uuid.dart';

class Instrucao {
  final String? id;
  final String? receitaId;
  final Int? passo;
  final String? descricao;

  Instrucao({
    String? id,
    this.receitaId,
    this.passo,
    this.descricao,
  }) : id = id ?? const Uuid().v4();

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