import 'dart:io';

import 'linux_asset_strategy.dart';
import 'manager_strategy.dart';

const String version = '0.0.1';

void main(List<String> arguments) async {
  final manager = ManagerStrategy();
  final strategy = LinuxAssetStrategy();

  if (Platform.isLinux) {
    manager.setStrategy(strategy);
  } else {
    /// Has support for other platforms later
    throw Exception('Plataforma não suportada');
  }
  await manager.execute(arguments: arguments);
}

