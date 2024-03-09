import 'asset_strategy.dart';

class ManagerStrategy {
  late AssetStrategy strategy;

  void setStrategy(AssetStrategy strategy) {
    this.strategy = strategy;
  }

  Future<void> execute({
    required List<String> arguments,
  }) async {
    await strategy.generatePackageFromAssetsType(
      arguments: arguments,
    );
  }
}
