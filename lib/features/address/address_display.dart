String formatAddressForCell(String address, double textScaleFactor) {
  const prefix = '0x';
  final hasPrefix = address.startsWith(prefix);

  final body = hasPrefix ? address.substring(prefix.length) : address;

  if (body.length <= 12) {
    return address;
  }

  final int keepStart = textScaleFactor < 1.6 ? 6 : 4;
  const int keepEnd = 4;

  final start = body.substring(0, keepStart);
  final end = body.substring(body.length - keepEnd);

  final formatted = '$start…$end';

  return hasPrefix ? '$prefix$formatted' : formatted;
}
