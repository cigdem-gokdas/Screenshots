/// Host shown in the link confirmation. Punycode (`xn--`) labels are decoded so
/// look-alike domains are visible; the raw ASCII host is kept alongside.
String displayHost(String url) {
  final host = Uri.tryParse(url)?.host ?? '';
  if (host.isEmpty) return url;
  if (!host.toLowerCase().contains('xn--')) return host;
  final decoded = host
      .split('.')
      .map(
        (label) => label.toLowerCase().startsWith('xn--')
            ? (punycodeDecode(label.substring(4)) ?? label)
            : label,
      )
      .join('.');
  return decoded == host ? host : '$decoded ($host)';
}

/// RFC 3492 decoder. Returns null for malformed input.
String? punycodeDecode(String input) {
  const base = 36, tMin = 1, tMax = 26, skew = 38, damp = 700;
  var n = 128, i = 0, bias = 72;
  final delimiter = input.lastIndexOf('-');
  final output = <int>[
    if (delimiter > 0) ...input.substring(0, delimiter).runes,
  ];
  int digit(int c) {
    if (c >= 0x30 && c <= 0x39) return c - 0x30 + 26;
    if (c >= 0x41 && c <= 0x5A) return c - 0x41;
    if (c >= 0x61 && c <= 0x7A) return c - 0x61;
    return -1;
  }

  int adapt(int delta, int points, bool first) {
    delta = first ? delta ~/ damp : delta ~/ 2;
    delta += delta ~/ points;
    var k = 0;
    while (delta > ((base - tMin) * tMax) ~/ 2) {
      delta ~/= base - tMin;
      k += base;
    }
    return k + (((base - tMin + 1) * delta) ~/ (delta + skew));
  }

  var index = delimiter > 0 ? delimiter + 1 : 0;
  while (index < input.length) {
    final oldI = i;
    var w = 1;
    for (var k = base; ; k += base) {
      if (index >= input.length) return null;
      final d = digit(input.codeUnitAt(index++));
      if (d < 0) return null;
      i += d * w;
      final t = k <= bias ? tMin : (k >= bias + tMax ? tMax : k - bias);
      if (d < t) break;
      w *= base - t;
    }
    bias = adapt(i - oldI, output.length + 1, oldI == 0);
    n += i ~/ (output.length + 1);
    i %= output.length + 1;
    if (n > 0x10FFFF) return null;
    output.insert(i++, n);
  }
  return String.fromCharCodes(output);
}
