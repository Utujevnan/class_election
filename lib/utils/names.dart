String cleanName(String input) {
  final words = input.split(' ').where((word) => word.isNotEmpty);
  final capitalised = words.map(
        (word) => word[0].toUpperCase() + word.substring(1).toLowerCase(),
  );
  return capitalised.join(' ');
}