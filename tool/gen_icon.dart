// Generates the original Pixel Cross app icon + splash assets.
// Run with: dart run tool/gen_icon.dart
import 'dart:io';
import 'package:image/image.dart' as img;

const indigo = [0x3D, 0x5A, 0xFE];
const indigoDark = [0x25, 0x36, 0xC9];

void drawFourSquares(img.Image image, {required double scale}) {
  final size = image.width.toDouble();
  final center = size / 2;
  final block = size * 0.36 * scale; // total 2x2 block size
  final gap = block * 0.16;
  final q = (block - gap) / 2; // one square side
  final radius = q * 0.22;
  final left = center - block / 2;
  final top = center - block / 2;
  final white = img.ColorRgba8(255, 255, 255, 255);

  final positions = [
    [left, top],
    [left + q + gap, top],
    [left, top + q + gap],
    [left + q + gap, top + q + gap],
  ];
  for (final p in positions) {
    img.fillRect(
      image,
      x1: p[0].round(),
      y1: p[1].round(),
      x2: (p[0] + q).round(),
      y2: (p[1] + q).round(),
      color: white,
      radius: radius,
    );
  }
}

void main() {
  Directory('assets/icon').createSync(recursive: true);

  // 1) Full launcher icon: indigo background + 4 white squares.
  final icon = img.Image(width: 1024, height: 1024, numChannels: 4);
  // Vertical indigo gradient for depth.
  for (var y = 0; y < icon.height; y++) {
    final t = y / icon.height;
    final r = (indigo[0] + (indigoDark[0] - indigo[0]) * t).round();
    final g = (indigo[1] + (indigoDark[1] - indigo[1]) * t).round();
    final b = (indigo[2] + (indigoDark[2] - indigo[2]) * t).round();
    img.fillRect(icon,
        x1: 0, y1: y, x2: icon.width - 1, y2: y, color: img.ColorRgba8(r, g, b, 255));
  }
  drawFourSquares(icon, scale: 1.0);
  File('assets/icon/icon.png').writeAsBytesSync(img.encodePng(icon));

  // 2) Adaptive foreground: transparent + 4 white squares (kept in safe zone).
  final fg = img.Image(width: 1024, height: 1024, numChannels: 4);
  drawFourSquares(fg, scale: 0.78);
  File('assets/icon/icon_foreground.png').writeAsBytesSync(img.encodePng(fg));

  // 3) Splash mark: white squares on transparent, used over the indigo splash.
  final splash = img.Image(width: 512, height: 512, numChannels: 4);
  drawFourSquares(splash, scale: 1.0);
  File('assets/icon/splash.png').writeAsBytesSync(img.encodePng(splash));

  stdout.writeln('Generated icon.png, icon_foreground.png, splash.png');
}
