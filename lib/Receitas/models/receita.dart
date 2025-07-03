import '../models/Instrucao.dart';
import '../models/Ingrediente.dart';
import 'package:json_annotation/json_annotation.dart';

part 'receita.g.dart';

@JsonSerializable(explicitToJson: true)
class Receita {
  String? id;
  String? nome;
  final String? dataCriacao;
  List<Ingrediente> ingredientes;
  List<Instrucao> instrucoes;
  String? userId;


  Receita ({
    required this.id,
    required this.nome,
    required this.dataCriacao,
    required this.ingredientes,
    required this.instrucoes,
    required this.userId,
    });

  factory Receita.fromJson(Map<String, dynamic> json) => _$ReceitaFromJson(json);
    Map<String, dynamic> toJson() => _$ReceitaToJson(this);
}