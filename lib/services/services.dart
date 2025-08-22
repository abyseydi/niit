class SampleService {
  Future<List<String>> fetchItems() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ['Item A', 'Item B', 'Item C'];
  }
}
