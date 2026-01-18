import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

Future<void> main() async {
  print('🔍 Scraping packages from pub.dev...');
  
  var packages = await scrapeUserPackages('gllb-apps.github.io');
  
  if (packages.isEmpty) {
    print('⚠️  Scraping failed, using fallback list...');
    packages = [
      'flux_wireframe_theme_cli',
      'wireframe_theme',
    ];
  }
  
  print('📦 Found ${packages.length} packages');
  
  final packageInfos = <Map<String, dynamic>>[];
  
  for (final packageName in packages) {
    try {
      final response = await http.get(
        Uri.parse('https://pub.dev/api/packages/$packageName'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        packageInfos.add({
          'package': packageName,
          'version': data['latest']['version'],
        });
        print('✓ $packageName v${data['latest']['version']}');
      }
    } catch (e) {
      print('⚠️  Could not fetch $packageName: $e');
    }
  }
  
  await createReadme(packageInfos);
  print('✅ Updated ${packageInfos.length} packages!');
}

Future<List<String>> scrapeUserPackages(String publisherOrEmail) async {
  final packages = <String>{};
  
  try {
    final publisherUrl = 'https://pub.dev/publishers/$publisherOrEmail/packages';
    print('Trying: $publisherUrl');
    
    final response = await http.get(Uri.parse(publisherUrl));
    if (response.statusCode == 200) {
      final found = extractPackagesFromHtml(response.body);
      if (found.isNotEmpty) {
        print('✓ Found ${found.length} packages');
        packages.addAll(found);
        return packages.toList();
      }
    }
  } catch (e) {
    print('Failed: $e');
  }
  
  return packages.toList();
}

List<String> extractPackagesFromHtml(String htmlContent) {
  final packages = <String>[];
  final document = html_parser.parse(htmlContent);
  
  final selectors = [
    'h3.packages-title a',
    'a[href^="/packages/"]',
    '.packages-item h3 a',
  ];
  
  for (final selector in selectors) {
    final links = document.querySelectorAll(selector);
    for (final link in links) {
      final href = link.attributes['href'];
      if (href != null && href.startsWith('/packages/')) {
        final packageName = href.split('/packages/')[1].split('/')[0].split('?')[0];
        if (packageName.isNotEmpty && !packageName.contains('/')) {
          packages.add(packageName);
        }
      }
    }
    
    if (packages.isNotEmpty) break;
  }
  
  return packages.toSet().toList();
}

Future<void> createReadme(List<Map<String, dynamic>> packages) async {
  final buffer = StringBuffer()
    ..writeln('# 📦 GLLB-Apps Dart Packages')
    ..writeln()
    ..writeln('My published packages on pub.dev')
    ..writeln();
  
  if (packages.isEmpty) {
    buffer.writeln('*No packages listed yet.*');
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
    ..writeln('*Last updated: ${DateTime.now().toUtc().toString().split('.')[0]} UTC*')
    ..writeln()
    ..writeln('*Auto-updated daily via GitHub Actions*');
  
  await File('../README.md').writeAsString(buffer.toString());
}