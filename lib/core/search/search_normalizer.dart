class SearchNormalizer {
  static String normalize(String input) {
    var text = input.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    const accented = 'áàãâäéèêëíìîïóòõôöúùûüçñ';
    const plain = 'aaaaaeeeeiiiiooooouuuucn';
    for (var index = 0; index < accented.length; index++) {
      text = text.replaceAll(accented[index], plain[index]);
    }
    return text;
  }
}
