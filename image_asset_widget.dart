class Teste extends StatelessWidget {
  final String teste;
  final String teste1;
  final String path;

  const Teste._({
    super.key,
    required String teste,
    required String teste1,
    required String path,
  });

  factory Teste.add({
    Key? key,
    required final String teste,
    required final String teste1,
    required final String path,
  }) {
    return Teste._(
      key: key,
      teste: teste,
      teste1: teste1,
      path: 'add.svg',
    );
  }

  factory Teste.remove({
    Key? key,
    required final String teste,
    required final String teste1,
    required final String path,
  }) {
    return Teste._(
      key: key,
      teste: teste,
      teste1: teste1,
      path: 'remove.svg',
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
