// Text normalising, masking and the word filter (FR-06, FR-14, FR-29).
// English and Roman Urdu synonyms come from a small dictionary.

const _synonyms = <String, String>{
  // bags
  'backpack': 'bag', 'bag': 'bag', 'basta': 'bag', 'schoolbag': 'bag',
  'satchel': 'bag', 'rucksack': 'bag', 'handbag': 'bag',
  // wallets
  'wallet': 'wallet', 'purse': 'wallet', 'batua': 'wallet',
  // phones
  'phone': 'phone', 'mobile': 'phone', 'smartphone': 'phone',
  'iphone': 'phone', 'cellphone': 'phone',
  // keys
  'key': 'key', 'keys': 'key', 'chabi': 'key', 'chaabi': 'key',
  // chargers
  'charger': 'charger', 'adapter': 'charger', 'cable': 'charger',
  // colours
  'black': 'black', 'dark': 'black', 'kala': 'black', 'kaala': 'black',
  'white': 'white', 'safaid': 'white',
  'blue': 'blue', 'neela': 'blue', 'nila': 'blue',
  'red': 'red', 'laal': 'red', 'lal': 'red',
  'green': 'green', 'hara': 'green',
  'grey': 'grey', 'gray': 'grey', 'silver': 'grey',
  'brown': 'brown', 'bhura': 'brown',
  // other items
  'card': 'card', 'studentcard': 'card',
  'notebook': 'notebook', 'copy': 'notebook', 'register': 'notebook',
  'umbrella': 'umbrella', 'chatri': 'umbrella',
  'bottle': 'bottle', 'laptop': 'laptop', 'calculator': 'calculator',
  'watch': 'watch', 'glasses': 'glasses', 'specs': 'glasses',
  'earbuds': 'earbuds', 'airpods': 'earbuds',
};

const colourWords = <String>{
  'black', 'white', 'blue', 'red', 'green', 'grey', 'brown',
};

const _markWords = <String>{
  'sticker', 'logo', 'scratch', 'crack', 'cracked', 'case', 'keychain',
  'strap', 'zip', 'initials', 'name', 'tag', 'nike', 'adidas', 'samsung',
  'apple', 'oppo', 'vivo', 'xiaomi', 'infinix', 'tecno', 'dell', 'hp',
  'lenovo', 'casio', 'sony', 'jansport', 'pocket',
};

const _stopWords = <String>{
  'a', 'an', 'the', 'my', 'is', 'it', 'its', 'was', 'i', 'in', 'at', 'on',
  'of', 'and', 'or', 'to', 'with', 'for', 'from', 'by', 'near', 'outside',
  'inside', 'left', 'lost', 'found', 'main', 'yesterday', 'today',
  'morning', 'afternoon', 'evening', 'night', 'has', 'have', 'had', 'this',
  'that', 'some', 'small', 'big', 'please', 'help', 'around', 'there',
};

String _canonical(String word) {
  final direct = _synonyms[word];
  if (direct != null) return direct;
  if (word.length > 3 && word.endsWith('s')) {
    final single = _synonyms[word.substring(0, word.length - 1)];
    if (single != null) return single;
  }
  return word;
}

/// Lowercase, drop symbols and emojis, remove filler words, map synonyms.
Set<String> tokens(String text) {
  final cleaned = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  final out = <String>{};
  for (final w in cleaned.split(RegExp(r'\s+'))) {
    if (w.length < 2 || _stopWords.contains(w)) continue;
    out.add(_canonical(w));
  }
  return out;
}

bool hasColourOrMark(String text, String? chosenColour) {
  if (chosenColour != null && chosenColour.isNotEmpty) return true;
  final t = tokens(text);
  return t.any((w) => colourWords.contains(w) || _markWords.contains(w));
}

class Masked {
  const Masked(this.text, this.changed);
  final String text;
  final bool changed;
}

/// Hides CNIC, card and Pakistani mobile numbers before text is saved.
Masked maskPersonalData(String input) {
  var text = input;
  // 13 to 19 digits, with optional spaces or dashes: CNICs and card numbers.
  text = text.replaceAll(RegExp(r'\b(?:\d[ -]?){12,18}\d\b'), '[number hidden]');
  // Pakistani mobile numbers: 03xx-xxxxxxx, +92 3xx xxxxxxx.
  text = text.replaceAll(
      RegExp(r'(?:\+92|0092|0)?[\s-]?3\d{2}[\s-]?\d{7}\b'), '[number hidden]');
  return Masked(text, text != input);
}

// A short stand-in list. The real list is longer and maintained by admins.
const _blocked = <String>{'idiot', 'stupid', 'scam', 'spam'};

bool containsBlockedWord(String text) {
  final cleaned = text.toLowerCase().replaceAll(RegExp(r'[^a-z\s]'), ' ');
  return cleaned.split(RegExp(r'\s+')).any(_blocked.contains);
}

/// Share of the words in [expected] that also appear in [given] (0 to 1).
double containment(String expected, String given) {
  final a = tokens(expected);
  final b = tokens(given);
  if (a.isEmpty) return 0;
  return a.intersection(b).length / a.length;
}
