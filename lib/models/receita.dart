import '../models/Instrucao.dart';
import '../models/Ingrediente.dart';
import 'package:uuid/uuid.dart';

class Receita {
  final String? id;
  final String? nome;
  final DateTime? dataCriacao;
  final List<Ingrediente> ingredientes;
  final List<Instrucao> instrucoes;


Receita ({
  String? id,
  required this.nome,
  String? dataCriacao,
  required this.ingredientes,
  required this.instrucoes
  }) : id = id ?? const Uuid().v4(),
       dataCriacao =  dataCriacao ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'dataCriacao': dataCriacao,
    };
  }

  factory Receita.fromMap(Map<String, dynamic> map) {
    return Receita(
      id: map['id'],
      nome: map['nome'],
      dataCriacao: DateTime.parse(map['dataCriacao']),
      ingredientes: [], // Será carregado separadamente
      instrucoes: [], // Será carregado separadamente
    );
  }
}
