import 'dart:io';

import 'asset_type.dart';

abstract class AssetStrategy {
  File getTemplateFile(List<String> arguments);
  Future<String> getTemaplateContentByAssetType({
    required AssetType assetType,
    required File templateFile,
  });

  Future<void> generatePackageFromAssetsType({
    required List<String> arguments,
  });

  Future<bool> verifyIsFlutterProject();

  Future<void> createAssetWidgetFile({
    required String imageWidgetStrinfied,
  });

  String generateImageWidgetClassFromAssetsNames(
    List<String> assetsNames, [
    String? template,
  ]);

  List<String> getPropertiesFromString(String classString);

  List<String> getPropertyNames(String classString);

  String getClassName(String template) {
    final classNameRegex = RegExp(r'class\s+(\w+)\s+extends\s+StatelessWidget');
    final match = classNameRegex.firstMatch(template);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!;
    } else {
      return 'Nome da classe não encontrado';
    }
  }

  String camelCaseToSnakeCase(String input) {
    String result = input[0].toLowerCase();
    for (int i = 1; i < input.length; i++) {
      if (input[i].toUpperCase() == input[i]) {
        result += '_${input[i].toLowerCase()}';
      } else {
        result += input[i];
      }
    }
    return result;
  }

  bool containsKeyInTemplate(String template, String key) {
    return template.contains(key);
  }

  String pascalCaseToCamelCase(String input) {
    if (input.isEmpty) {
      return ''; // Caso a string de entrada esteja vazia, retorna uma string vazia
    }

    // Converte a primeira letra de PascalCase para minúscula
    String result = input[0].toLowerCase();

    // Adiciona o restante da string, já que a primeira letra já foi convertida
    result += input.substring(1);

    return result;
  }

  String snakeOrDashCaseToCamelCase(String input) {
    List<String> parts =
        input.trim().split('_'); // or input.split('-') if using dash_case
    String result = parts[0]; // first part remains as is
    for (int i = 1; i < parts.length; i++) {
      String capitalized =
          parts[i].substring(0, 1).toUpperCase() + parts[i].substring(1);
      result += capitalized;
    }
    return result;
  }

  String toComecase(String input) {
    if (isCamelCase(input)) {
      return input;
    } else if (isSnakeCase(input.split('.').first)) {
      return snakeOrDashCaseToCamelCase(input);
    } else {
      return pascalCaseToCamelCase(input.contains('_')
          ? input.replaceAll('_', '')
          : input.replaceAll('-', ''));
    }
  }

  // if (isCamelCase(e)) {
  //   return e;
  // } else if (isSnakeCase(e.split('.').first)) {
  //   return snakeOrDashCaseToCamelCase(e);
  // } else {
  //   return pascalCaseToCamelCase(
  //       e.contains('_') ? e.replaceAll('_', '') : e.replaceAll('-', ''));
  // }

  bool isCamelCase(String input) {
    // CamelCase deve começar com letra minúscula e não pode conter espaços ou caracteres especiais
    return RegExp(r'^[a-z]+(?:[A-Z][a-z]*)*$').hasMatch(input);
  }

  bool isSnakeCase(String input) {
    // Snake_case deve conter apenas letras minúsculas, números e sublinhados
    return RegExp(r'^[a-z0-9]+(?:_[a-z0-9]+)*$').hasMatch(input);
  }
}
