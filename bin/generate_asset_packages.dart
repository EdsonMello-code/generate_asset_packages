import 'dart:io';

const String version = '0.0.1';

void main(List<String> arguments) async {
  String? templateContent;
  final templateArgs = arguments.firstWhere(
      (element) => element.contains('--template='),
      orElse: () => '');
  if (templateArgs.isNotEmpty) {
    final templateFile = getTemplateFile(arguments);

    final content = await getTemaplateContentByAssetType(
      assetType: AssetType.image,
      templateFile: templateFile,
    );

    if (content.contains('path')) {
      templateContent = content;
    }
  }

  await _generatePackageFromAssetsType(
    template: templateContent,
  );
}

File getTemplateFile(List<String> arguments) {
  final path = arguments.firstWhere(
    (element) => element.contains('--template='),
    orElse: () => '',
  );

  if (path.isEmpty) {
    throw Exception('O argumento --template é obrigatório');
  }

  print('path: ${path.split('--template=')[1]}');

  final templateFile = File('./${path.split('--template=')[1]}');

  return templateFile;
}

Future<String> getTemaplateContentByAssetType({
  required AssetType assetType,
  required File templateFile,
}) async {
  final templateContent = await templateFile.readAsString();

  if (templateContent.isEmpty) {
    throw Exception('O template está vazio');
  }

  if (!templateContent.contains('image=')) {
    throw Exception('O template não contém a propriedade [image]');
  }

  final content = templateContent.split('image=')[1];

  return content;
}

Future<void> _generatePackageFromAssetsType({
  AssetType assetType = AssetType.image,
  String? template,
}) async {
  final isFlutterProject = await _isFlutterProject();

  if (!isFlutterProject) {
    throw Exception('\x1B[31m Esse não é um projeto Flutter ou dart\x1B[0m');
  }

  final assetsFileName = await _getAssetsFileName(assetType);

  final imageWidgetStrinfied = _generateImageWidgetClassFromAssetsNames(
    assetsFileName,
    template,
  );

  await _createAssetWidgetFile(
    imageWidgetStrinfied: imageWidgetStrinfied,
    assetType: assetType,
  );
}

Future<bool> _isFlutterProject() async {
  final currentWorkDirectory = await Process.run('pwd', []);
  final listedContentDirectory = await Process.run('ls', [
    (currentWorkDirectory.stdout.toString().trim()),
  ]);

  final isFlutterProject =
      listedContentDirectory.stdout.toString().contains('pubspec.yaml');

  return isFlutterProject;
}

Future<void> _createAssetWidgetFile({
  required String imageWidgetStrinfied,
  required AssetType assetType,
}) async {
  final currentWorkDirectory = await Process.run('pwd', []);

  final imageAssetFile = File(
      '${currentWorkDirectory.stdout.toString().trim()}/image_asset_widget.dart');

  await imageAssetFile.writeAsString(imageWidgetStrinfied);
}

Future<List<String>> _getAssetsFileName(AssetType assetType) async {
  final currentWorkDirectory = await Process.run('pwd', []);

  final assetsPath =
      '${currentWorkDirectory.stdout.toString().trim()}/assets/${assetType.assetName}';

  final listedContentDirectory = await Process.run('ls', [
    assetsPath,
  ]);

  return listedContentDirectory.stdout.toString().trim().split('\n');
}

String _generateImageWidgetClassFromAssetsNames(
  List<String> assetsNames, [
  String? template,
]) {
  final nameOfWidget = template?.split(' ')[1];
  final nameOfWidgetWithFirstLetterUpperCase = nameOfWidget?.replaceFirst(
      nameOfWidget[0], nameOfWidget[0].toUpperCase());

  final proprieties = getPropertiesFromString(template ?? '');
  final propertyNames = getPropertyNames(template ?? '');

  print(template);

  if (template != null) {
    return template.replaceAll(
      '{{}}',
      (assetsNames.map((fileName) =>
          '''factory $nameOfWidgetWithFirstLetterUpperCase.${fileName.split('.').first}({
    Key? key,
    ${proprieties.map((e) => e.toString().replaceAll(';', ',')).join('\n')}
  }) {
    return $nameOfWidgetWithFirstLetterUpperCase._(
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

  const ImageAssetWidget._({
    super.key,
    required this.path,
    required this.color,
    required this.width,
    required this.height,
    required this.fit,
  });

  ${(assetsNames.map((fileName) => '''factory ImageAssetWidget.${fileName.split('.').first}({
    Key? key,
    Color? color,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return ImageAssetWidget._(
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

enum AssetType {
  image('images');
  // font,
  // audio,
  // video,
  // other,

  final String assetName;

  const AssetType(this.assetName);
}

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



// /// Regras do template de imagem:
// /// - Tem que ser uma class e widget
// /// - Tem que ter um construtor privado
// /// - Tem que ter a propriedade path
// /// - Tem que ter esse "simbolo" {{}} para representar aonde vai ser substituido pela listagem das imagens
// /// - Tem que ter ´ para abrir o inicio das propriedades e ` para fechar


