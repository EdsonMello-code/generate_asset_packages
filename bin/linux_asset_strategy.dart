import 'dart:io';

import 'asset_strategy.dart';
import 'asset_type.dart';

class LinuxAssetStrategy extends AssetStrategy {
  @override
  File getTemplateFile(List<String> arguments) {
    final path = arguments.firstWhere(
      (element) => element.contains('--template='),
      orElse: () => '',
    );

    if (path.isEmpty) {
      throw Exception('O argumento --template é obrigatório');
    }

    final templateFile = File('./${path.split('--template=')[1]}');

    return templateFile;
  }

  @override
  Future<String> getTemaplateContentByAssetType({
    required AssetType assetType,
    required File templateFile,
  }) async {
    final templateContent = await templateFile.readAsString();

    if (templateContent.isEmpty) {
      throw Exception('O template está vazio');
    }

    final isTemplateContainsKey = containsKeyInTemplate(
      templateContent,
      assetType.assetName,
    );

    if (!isTemplateContainsKey) {
      throw Exception('O template não contém a propriedade [image]');
    }

    final content = templateContent.split('${assetType.assetName}:')[1];

    return content.substring(1, content.length - 2).trim();
  }

  @override
  Future<void> generatePackageFromAssetsType({
    required List<String> arguments,
  }) async {
    String? templateContent;

    final templateArgs = arguments.firstWhere(
        (element) => element.contains('--template='),
        orElse: () => '');

    final assetTypeString = arguments.firstWhere(
      (element) => element.contains('--asset-type='),
      orElse: () => '',
    );

    late final AssetType assetType;

    if (assetTypeString.isNotEmpty) {
      assetType = AssetType.fromMap(assetTypeString.split('--asset-type=')[1]);
    } else {
      assetType = AssetType.image;
    }

    if (templateArgs.isNotEmpty) {
      final templateFile = getTemplateFile(arguments);

      final content = await getTemaplateContentByAssetType(
        assetType: assetType,
        templateFile: templateFile,
      );

      if (content.contains('path')) {
        templateContent = content;
      }
    }

    final isFlutterProject = await verifyIsFlutterProject();

    if (!isFlutterProject) {
      throw Exception('\x1B[31m Esse não é um projeto Flutter ou dart\x1B[0m');
    }

    final assetsFileName = await getAssetsFileName(assetType);

    final imageWidgetStrinfied = generateImageWidgetClassFromAssetsNames(
      assetsFileName,
      templateContent,
    );

    await createAssetWidgetFile(
      imageWidgetStrinfied: imageWidgetStrinfied,
    );
  }

  @override
  Future<bool> verifyIsFlutterProject() async {
    final currentWorkDirectory = await Process.run('pwd', []);
    final listedContentDirectory = await Process.run('ls', [
      (currentWorkDirectory.stdout.toString().trim()),
    ]);

    final isFlutterProject =
        listedContentDirectory.stdout.toString().contains('pubspec.yaml');

    return isFlutterProject;
  }

  @override
  Future<void> createAssetWidgetFile({
    required String imageWidgetStrinfied,
  }) async {
    final currentWorkDirectory = await Process.run('pwd', []);

    final nameOfWidget = getClassName(imageWidgetStrinfied);

    final nameOfWidgetInSnakeCase = camelCaseToSnakeCase(nameOfWidget);

    final File imageAssetFile = File(
      '${currentWorkDirectory.stdout.toString().trim()}/$nameOfWidgetInSnakeCase.dart',
    );

    await imageAssetFile.writeAsString(imageWidgetStrinfied);
  }

  Future<List<String>> getAssetsFileName(AssetType assetType) async {
    final currentWorkDirectory = await Process.run('pwd', []);

    final assetsPath =
        '${currentWorkDirectory.stdout.toString().trim()}/assets/${assetType.assetName}';

    final listedContentDirectory = await Process.run('ls', [
      assetsPath,
    ]);

    final output = listedContentDirectory.stdout.toString().trim().split('\n');

    return output.toList();
  }

  @override
  String generateImageWidgetClassFromAssetsNames(
    List<String> assetsNames, [
    String? template,
  ]) {
    final nameOfWidget = getClassName(template ?? '');

    print('nameOfWidget: $nameOfWidget');

    final proprieties = getPropertiesFromString(template ?? '');
    final propertyNames = getPropertyNames(template ?? '');

    if (template != null) {
      return template.replaceAll(
        '{{}}',
        (assetsNames.map((fileName) =>
            '''factory $nameOfWidget.${toComecase(fileName.split('.').first)}({
    Key? key,
    ${proprieties.map((e) => e.toString().replaceAll(';', ',')).join('\n')}
  }) {
    return $nameOfWidget._(
      key: key,
      ${propertyNames.map((e) => e.toString().replaceAll(';', ',')).join('\n').replaceAll(':path', ": '$fileName'").replaceAll(': path', ": '$fileName'")}

    );
  }
''')).join('\n'),
      );
    }

    return '''import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ImageAssetsWidget extends StatelessWidget {
  final String path;
  final Color color;
  final double width;
  final double height;
  final BoxFit fit;

  const ImageAssetsWidget._({
    super.key,
    required this.path,
    required this.color,
    required this.width,
    required this.height,
    required this.fit,
  });

  ${(assetsNames.map((fileName) => '''factory ImageAssetsWidget.${fileName.split('.').first}({
    Key? key,
    Color? color,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return ImageAssetsWidget._(
      key: key,
      path: '$fileName',
      color: color ?? Colors.transparent,
      width: width ?? 24,
      height: height ?? 24,
      fit: fit ?? BoxFit.contain,
    );
  }
''')).join('\n')}

@override
Widget build(BuildContext context) {
    return path.contains('.svg')
        ? SvgPicture.asset(
            'assets/images/\$path',
            color: color,
            width: width,
            height: height,
            fit: fit,
          )
        : Image.asset(
            'assets/images/\$path',
            color: color,
            width: width,
            height: height,
            fit: fit,
          );
  }
}''';
  }

  @override
  List<String> getPropertiesFromString(String classString) {
    // Encontrar as propriedades da classe
    final propertiesRegExp = RegExp(r'(final)?\s*(\w+)\s+(\w+)\s*;');
    final matches = propertiesRegExp.allMatches(classString);

    final properties = <String>[];

    for (Match match in matches) {
      final isFinal = match.group(1) != null;
      final propertyType = match.group(2) ?? "";
      final propertyName = match.group(3) ?? '';

      final formattedProperty = isFinal
          ? "required final $propertyType $propertyName;"
          : "required $propertyType $propertyName;";
      properties.add(formattedProperty);
    }

    return properties;
  }

  @override
  List<String> getPropertyNames(String classString) {
    // Encontrar as propriedades da classe
    RegExp propertiesRegExp = RegExp(r'(?:final)?\s*\w+\s+(\w+)\s*;');
    Iterable<Match> matches = propertiesRegExp.allMatches(classString);

    final List<String> propertyNames = [];

    for (Match match in matches) {
      String propertyName = match.group(1) ?? '';
      propertyNames.add('$propertyName: $propertyName,');
    }

    return propertyNames;
  }
}
