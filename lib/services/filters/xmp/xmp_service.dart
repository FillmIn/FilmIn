import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class XmpFilterData {
  final String name;
  final String group;
  final String description;
  final Map<String, dynamic> settings;
  final List<Map<String, double>> toneCurve;
  final List<Map<String, double>> toneCurveRed;
  final List<Map<String, double>> toneCurveGreen;
  final List<Map<String, double>> toneCurveBlue;

  const XmpFilterData({
    required this.name,
    required this.group,
    required this.description,
    required this.settings,
    required this.toneCurve,
    required this.toneCurveRed,
    required this.toneCurveGreen,
    required this.toneCurveBlue,
  });

  factory XmpFilterData.fromXmpString(String xmpContent) {
    final settings = <String, dynamic>{};
    final toneCurve = <Map<String, double>>[];
    final toneCurveRed = <Map<String, double>>[];
    final toneCurveGreen = <Map<String, double>>[];
    final toneCurveBlue = <Map<String, double>>[];

    String name = '';
    String group = '';
    String description = '';

    final lines = xmpContent.split('\n');

    for (final line in lines) {
      final trimmedLine = line.trim();

      if (trimmedLine.contains('<rdf:li xml:lang="x-default">') && trimmedLine.contains('</rdf:li>')) {
        final content = trimmedLine.split('<rdf:li xml:lang="x-default">')[1].split('</rdf:li>')[0];
        if (name.isEmpty && trimmedLine.contains('Name')) {
          name = content;
        }
      }

      if (trimmedLine.contains('Group')) {
        final matches = RegExp(r'<rdf:li xml:lang="x-default">(.*?)</rdf:li>').allMatches(trimmedLine);
        for (final match in matches) {
          group = match.group(1) ?? '';
        }
      }

      if (trimmedLine.contains('Description')) {
        final matches = RegExp(r'<rdf:li xml:lang="x-default">(.*?)</rdf:li>').allMatches(trimmedLine);
        for (final match in matches) {
          description = match.group(1) ?? '';
        }
      }

      if (trimmedLine.startsWith('crs:')) {
        final parts = trimmedLine.split('=');
        if (parts.length == 2) {
          final key = parts[0].replaceAll('crs:', '').trim();
          final value = parts[1].replaceAll('"', '').trim();

          if (value.contains('+') || value.contains('-') || RegExp(r'^\d+$').hasMatch(value) || RegExp(r'^\d+\.\d+$').hasMatch(value)) {
            final numValue = double.tryParse(value.replaceAll('+', ''));
            if (numValue != null) {
              settings[key] = numValue;
            } else {
              settings[key] = value;
            }
          } else {
            settings[key] = value;
          }
        }
      }

      if (trimmedLine.contains('<rdf:li>') && trimmedLine.contains(', ')) {
        final content = trimmedLine.split('<rdf:li>')[1].split('</rdf:li>')[0];
        final coords = content.split(', ');
        if (coords.length == 2) {
          final x = double.tryParse(coords[0]);
          final y = double.tryParse(coords[1]);
          if (x != null && y != null) {
            final point = {'x': x, 'y': y};

            if (line.contains('ToneCurvePV2012Red')) {
              toneCurveRed.add(point);
            } else if (line.contains('ToneCurvePV2012Green')) {
              toneCurveGreen.add(point);
            } else if (line.contains('ToneCurvePV2012Blue')) {
              toneCurveBlue.add(point);
            } else if (line.contains('ToneCurvePV2012')) {
              toneCurve.add(point);
            }
          }
        }
      }
    }

    return XmpFilterData(
      name: name,
      group: group,
      description: description,
      settings: settings,
      toneCurve: toneCurve,
      toneCurveRed: toneCurveRed,
      toneCurveGreen: toneCurveGreen,
      toneCurveBlue: toneCurveBlue,
    );
  }
}

class XmpService {
  static final XmpService _instance = XmpService._internal();
  factory XmpService() => _instance;
  XmpService._internal();

  final Map<String, XmpFilterData> _filterCache = {};
  List<String> _availableFilters = [];

  Future<void> initialize() async {
    try {
      debugPrint('XMP Service: Starting initialization...');

      // AssetManifest.json에서 XMP 파일 목록 가져오기
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      debugPrint('AssetManifest loaded, total assets: ${manifestMap.keys.length}');

      _availableFilters = manifestMap.keys
          .where((String key) => key.startsWith('assets/filters/xmp/') && key.endsWith('.xmp'))
          .toList();

      debugPrint('Found ${_availableFilters.length} XMP files: $_availableFilters');

      if (_availableFilters.isEmpty) {
        debugPrint('No XMP files found in assets. Check if assets/filters/xmp/ is correctly added to pubspec.yaml');
        // Fallback: 직접 알려진 파일들을 시도
        _availableFilters = [
          'assets/filters/xmp/PORTRA 160 #1.xmp',
          'assets/filters/xmp/Fuji C200 #1.xmp',
          'assets/filters/xmp/Cinestill 800T #1 (Daylight).xmp',
        ];
        debugPrint('Using fallback filter list: $_availableFilters');
      }

      for (final filterPath in _availableFilters) {
        await _loadFilter(filterPath);
      }

      debugPrint('XMP Service initialization complete. Loaded ${_filterCache.length} filters.');
    } catch (e, stackTrace) {
      debugPrint('XMP 초기화 오류: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<XmpFilterData?> _loadFilter(String assetPath) async {
    try {
      debugPrint('Loading XMP filter: $assetPath');
      final xmpContent = await rootBundle.loadString(assetPath);
      final filterData = XmpFilterData.fromXmpString(xmpContent);

      final fileName = assetPath.split('/').last.replaceAll('.xmp', '');
      _filterCache[fileName] = filterData;

      debugPrint('Successfully loaded filter: ${filterData.name} (${filterData.group})');
      return filterData;
    } catch (e) {
      debugPrint('XMP 파일 로드 오류 ($assetPath): $e');
      return null;
    }
  }

  List<String> getAvailableFilterNames() {
    return _filterCache.keys.toList();
  }

  XmpFilterData? getFilterByName(String name) {
    return _filterCache[name];
  }

  List<XmpFilterData> getAllFilters() {
    return _filterCache.values.toList();
  }

  Map<String, List<XmpFilterData>> getFiltersByGroup() {
    final grouped = <String, List<XmpFilterData>>{};

    for (final filter in _filterCache.values) {
      final group = filter.group.isNotEmpty ? filter.group : 'Default';
      grouped.putIfAbsent(group, () => []).add(filter);
    }

    return grouped;
  }

  Future<void> reloadFilters() async {
    _filterCache.clear();
    await initialize();
  }
}
