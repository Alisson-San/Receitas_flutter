import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:receitas/models/Ingrediente.dart';
import 'package:receitas/models/Instrucao.dart';
import 'package:receitas/models/receita.dart';

class ReceitaService {


  // ========= CONFIGURAÇÕES DA API =========
  static const String _apiBaseUrl = 'https://randommer.io/api/Text';
  static const String _endpoint = '/lorentpsum';
  static const String _apiKey = 'b64997d395a24599b3ce8d8ff73395b3'; 
  static const String _lorenType = 'normal'; 
  static const String _type = 'paragraphs';  
  static const int _numeroPadrao = 2; 
  // ========================================



  static Future<String> fetchRandomRecipe({int? numero}) async {
    try {
          final paramNumber = numero ?? _numeroPadrao;
          final url = Uri.parse(
            '$_apiBaseUrl$_endpoint?lorenType=$_lorenType&type=$_type&number=$paramNumber'
          );

          final response = await http.get(
            url,
            headers: {
              'accept': '*/*',
              'X-Api-Key': _apiKey,
            },
          );

          if (response.statusCode == 200) {
            // A API retorna um array de parágrafos (conforme 'number')
            final paragraphs = jsonDecode(response.body) as List;
            // Converte cada parágrafo em uma string
            return paragraphs.join('\n\n'); 
          } 
          else {
            throw Exception('API Error: ${response.statusCode} - ${response.body}');
          }
        } 
        catch (e) {
          throw Exception('Falha de texto: $e');
        } 
  }

  static Receita parseRecipeFromText(String text) {
    final words = text.split(' ');
    if (words.isEmpty) return _createDefaultRecipe();

    // Pega a primeira palavra como título
    final title = words[0];
    final _random = Random();
    
    // Pega algumas palavras para ingredientes (número aleatório entre 3 e 7)
    final ingredientCount = 3 + _random.nextInt(5);
    final ingredients = words.sublist(1, 1 + ingredientCount).map((word) => 
      Ingrediente(
        receitaId: '', 
        nome: word,
        quantidade: '${1 + _random.nextInt(10)} ${['kg', 'g', 'ml'][_random.nextInt(3)]}',
      )
    ).toList();

    // Pega o restante para instruções (dividido em frases)
    final remainingWords = words.sublist(1 + ingredientCount);
    final instructionCount = 2 + _random.nextInt(3); // Número aleatório entre 2 e 5
    final instructions = <Instrucao>[];
    
    if (remainingWords.isNotEmpty) {
      final chunkSize = remainingWords.length ~/ instructionCount;
      for (int i = 0; i < instructionCount && i * chunkSize < remainingWords.length; i++) {
        final start = i * chunkSize;
        final end = (i + 1) * chunkSize;
        final phrase = remainingWords.sublist(start, end > remainingWords.length ? remainingWords.length : end).join(' ');
        
        instructions.add(Instrucao(
          receitaId: '', // Será preenchido depois
          descricao: phrase,
          passo: i + 1,
        ));
      }
    }

    return Receita(
      id: '',
      nome: title,
      dataCriacao: DateTime.now().toIso8601String().split('T')[0],
      ingredientes: ingredients,
      instrucoes: instructions,
    );
  }

  static Receita _createDefaultRecipe() {
    return Receita(
      id: '',
      nome: 'Receita Padrão',
      dataCriacao: DateTime.now().toIso8601String().split('T')[0],
      ingredientes: [
        Ingrediente(receitaId: '', nome: 'Ingrediente 1', quantidade: '1'),
        Ingrediente(receitaId: '', nome: 'Ingrediente 2', quantidade: '2'),
      ],
      instrucoes: [
        Instrucao(receitaId: '', descricao: 'Instrução 1', passo: 1),
        Instrucao(receitaId: '', descricao: 'Instrução 2', passo: 2),
      ],
    );
  }
}