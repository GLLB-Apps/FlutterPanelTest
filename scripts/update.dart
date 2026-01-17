import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  print(' Fetching packages from pub.dev...');
  
  final response = await http.get(
    Uri.parse('https://pub.dev/api/search?q=publisher:gllb-apps.github.io&size=100'),
  );
  
  if (response.statusCode != 200) {
    print(' Failed to fetch packages: ${response.statusCode}');
    exit(1);
  }
  
  final data = jsonDecode(response.body);
  final packages = (data['packages'] as List? ?? []);
  
  if (packages.isEmpty) {
    print('  No packages found yet.');
    await _createReadme([]);
    return;
  }
  
  packages.sort((a, b) {
    final aPoints = a['grantedPoints'] ?? 0;
    final bPoints = b['grantedPoints'] ?? 0;
    return bPoints.compareTo(aPoints);
  });
  
  await _createReadme(packages);
  print('✅ Updated ${packages.length} packages!');
}

Future<void> _createReadme(List packages) async {
  final buffer = StringBuffer()
    ..writeln('# 📦 GLLB-Apps Dart Packages')
    ..writeln()
    ..writeln('Auto-updated list of packages published under [gllb-apps.github.io](https://pub.dev/publishers/gllb-apps.github.io/packages)')
    ..writeln();
  
  if (packages.isEmpty) {
    buffer.writeln('*No packages published yet.*');
  } else {
    buffer
      ..writeln('| Package | Version | Pub Points | Popularity | Link |')
      ..writeln('|---------|---------|------------|------------|------|');
    
    for (final pkg in packages) {
      final name = pkg['package'];
      buffer.writeln('| **$name** | '
          '![version](https://img.shields.io/pub/v/$name.svg?color=blue) | '
          '![points](https://img.shields.io/pub/points/$name?color=green) | '
          '![popularity](https://img.shields.io/pub/popularity/$name?color=orange) | '
          '[pub.dev](https://pub.dev/packages/$name) |');
    }
  }
  
  buffer
    ..writeln()
    ..writeln('---')
    ..writeln('*Last updated: ${DateTime.now().toUtc().toString().split('.')[0]} UTC*');
  
  await File('../README.md').writeAsString(buffer.toString());
}
