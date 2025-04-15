import '../models/Instrucao.dart';
import '../models/Ingrediente.dart';

class Receita {
  final int? id;
  final String? nome;
  final DateTime? dataCriacao;
  final List<Ingrediente> ingredientes;
  final List<Instrucao> instrucoes;


Receita ({
  this.id,
  required this.nome,
  required this.dataCriacao,
  required this.ingredientes,
  required this.instrucoes
  }) : dataCriacao =  dataCriacao ?? DateTime.now();

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
