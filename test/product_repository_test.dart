import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:price_catalog_app/data/repositories/product_repository.dart';

void main() {
  group('ProductRepository.resolveContentType', () {
    test('returns application/pdf for pdf files', () {
      expect(
        ProductRepository.resolveContentType(File('catalog.pdf')),
        'application/pdf',
      );
    });

    test('returns image/png for png files', () {
      expect(
        ProductRepository.resolveContentType(File('image.png')),
        'image/png',
      );
    });

    test('falls back to application/octet-stream for unknown files', () {
      expect(
        ProductRepository.resolveContentType(File('archive.xyz')),
        'application/octet-stream',
      );
    });
  });
}
