import '../models/Instrucao.dart';
import '../models/Ingrediente.dart';

class Receita {
  String? id;
  String? nome;
  final String? dataCriacao;
  List<Ingrediente> ingredientes;
  List<Instrucao> instrucoes;


Receita ({
  required this.id,
  required this.nome,
  required this.dataCriacao,
  required this.ingredientes,
  required this.instrucoes
  });

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
      dataCriacao: map['dataCriacao'],
      ingredientes: [], // Será carregado separadamente
      instrucoes: [], // Será carregado separadamente
    );
  }
}
