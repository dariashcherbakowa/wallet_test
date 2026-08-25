import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_test/features/address/address_display.dart';

void main() {
  group('formatAddressForCell', () {
    const longWithPrefix = '0x1234567890abcdef1234567890abcdef12345678';
    const longNoPrefix = '1234567890abcdef1234567890abcdef12345678';
    const shortWithPrefix = '0x1234';
    const shortNoPrefix = '1234';

    test('короткий адрес с 0x не меняется', () {
      expect(formatAddressForCell(shortWithPrefix, 1.0), '0x1234');
      expect(formatAddressForCell(shortWithPrefix, 2.0), '0x1234');
    });

    test('короткий адрес без 0x не меняется', () {
      expect(formatAddressForCell(shortNoPrefix, 1.0), '1234');
      expect(formatAddressForCell(shortNoPrefix, 2.0), '1234');
    });

    test('длинный адрес с 0x сокращается как 6+4 при textScaleFactor < 1.6',
        () {
      expect(formatAddressForCell(longWithPrefix, 1.0), '0x123456…5678');
      expect(formatAddressForCell(longWithPrefix, 1.5), '0x123456…5678');
    });

    test('длинный адрес без 0x сокращается как 6+4 при textScaleFactor < 1.6',
        () {
      expect(formatAddressForCell(longNoPrefix, 1.0), '123456…5678');
      expect(formatAddressForCell(longNoPrefix, 1.5), '123456…5678');
    });

    test('при textScaleFactor >= 1.6 сокращается как 4+4', () {
      expect(formatAddressForCell(longWithPrefix, 1.6), '0x1234…5678');
      expect(formatAddressForCell(longWithPrefix, 2.0), '0x1234…5678');
      expect(formatAddressForCell(longNoPrefix, 2.0), '1234…5678');
    });

    test('префикс 0x не теряется', () {
      expect(formatAddressForCell('0xabc', 1.0), '0xabc');
      expect(formatAddressForCell('0x1234567890ab', 1.0), '0x1234567890ab');
    });

    test('граница 12 символов: 12 не сокращается, 13 сокращается', () {
      expect(formatAddressForCell('0x123456789012', 1.0), '0x123456789012');
      expect(formatAddressForCell('0x1234567890123', 1.0), '0x123456…0123');
    });

    test('граничное значение textScaleFactor = 1.6', () {
      expect(formatAddressForCell(longWithPrefix, 1.6), '0x1234…5678');
      expect(formatAddressForCell(longWithPrefix, 1.599), '0x123456…5678');
    });
  });
}
