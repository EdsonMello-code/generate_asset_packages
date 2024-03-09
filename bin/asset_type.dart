enum AssetType {
  image('images'),
  font('fonts'),
  audio('audios'),
  video('videos');

  final String assetName;

  factory AssetType.fromMap(String assetNameString) {
    return switch (assetNameString) {
      'audios' => AssetType.audio,
      'fonts' => AssetType.font,
      'images' => AssetType.image,
      'videos' => AssetType.video,
      _ => throw Exception('AssetType not found'),
    };
  }

  const AssetType(this.assetName);
}
