import 'dart:typed_data';

import 'package:image/image.dart' as im;
import 'package:pdfx/pdfx.dart';

class PdfDarkRenderer {
  PdfDarkRenderer(this.document);

  final PdfDocument document;

  Future<Uint8List> renderPagePng({required int pageNumber, bool darkMode = false, int? targetWidth, int? targetHeight}) async {
    final page = await document.getPage(pageNumber);
    try {
      final double width = targetWidth != null ? targetWidth.toDouble() : page.width;
      final double height = targetHeight != null ? targetHeight.toDouble() : page.height;
      final img = await page.render(
        width: width,
        height: height,
        format: PdfPageImageFormat.png,
        backgroundColor: '#000000',
      );
      final bytes = img!.bytes;
      if (!darkMode) return Uint8List.fromList(bytes);

      final decoded = im.decodePng(bytes);
      if (decoded == null) return Uint8List.fromList(bytes);

      final saturationThreshold = 0.25;
      final valueDarkThreshold = 0.55;

      for (int y = 0; y < decoded.height; y++) {
        for (int x = 0; x < decoded.width; x++) {
          final c = decoded.getPixel(x, y);
          final r = im.getRed(c);
          final g = im.getGreen(c);
          final b = im.getBlue(c);
          final a = im.getAlpha(c);

          final hsv = _rgbToHsv(r, g, b);
          final h = hsv[0];
          double s = hsv[1];
          double v = hsv[2];

          if (s < saturationThreshold && v < valueDarkThreshold) {
            s = 0.0;
            v = 1.0 - (v * 0.6);
            if (v < 0.85) v = 0.92;
            final out = _hsvToRgb(h, s, v);
            decoded.setPixelRgba(x, y, out[0], out[1], out[2], a);
          }
        }
      }

      final outBytes = im.encodePng(decoded);
      return Uint8List.fromList(outBytes);
    } finally {
      await page.close();
    }
  }

  static List<double> _rgbToHsv(int r, int g, int b) {
    final rf = r / 255.0;
    final gf = g / 255.0;
    final bf = b / 255.0;
    final max = [rf, gf, bf].reduce((a, b) => a > b ? a : b);
    final min = [rf, gf, bf].reduce((a, b) => a < b ? a : b);
    final delta = max - min;

    double h = 0.0;
    if (delta != 0) {
      if (max == rf) {
        h = 60 * (((gf - bf) / delta) % 6);
      } else if (max == gf) {
        h = 60 * (((bf - rf) / delta) + 2);
      } else {
        h = 60 * (((rf - gf) / delta) + 4);
      }
    }
    if (h < 0) h += 360;

    final double s = max == 0 ? 0.0 : delta / max;
    final double v = max;
    return <double>[h.toDouble(), s, v];
  }

  static List<int> _hsvToRgb(double h, double s, double v) {
    final c = v * s;
    final x = c * (1 - ((h / 60) % 2 - 1).abs());
    final m = v - c;
    double rf = 0, gf = 0, bf = 0;

    if (0 <= h && h < 60) {
      rf = c; gf = x; bf = 0;
    } else if (60 <= h && h < 120) {
      rf = x; gf = c; bf = 0;
    } else if (120 <= h && h < 180) {
      rf = 0; gf = c; bf = x;
    } else if (180 <= h && h < 240) {
      rf = 0; gf = x; bf = c;
    } else if (240 <= h && h < 300) {
      rf = x; gf = 0; bf = c;
    } else {
      rf = c; gf = 0; bf = x;
    }

    final r = ( ((rf + m) * 255.0).clamp(0.0, 255.0) ).toInt();
    final g = ( ((gf + m) * 255.0).clamp(0.0, 255.0) ).toInt();
    final b = ( ((bf + m) * 255.0).clamp(0.0, 255.0) ).toInt();
    return [r, g, b];
  }
}



