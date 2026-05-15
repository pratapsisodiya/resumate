import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:resumate/models/deployment.dart';
import 'package:resumate/models/website.dart';

class NetlifyClient {
  final Dio _dio;

  NetlifyClient({required String token})
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://api.netlify.com/api/v1',
          headers: {'Authorization': 'Bearer $token'},
        ));

  Future<DeploymentResult> deploy(Website website) async {
    final siteId = await _getOrCreateSite(website.name);
    final files = _files(website);
    final digests = {for (final e in files.entries) e.key: _sha1(e.value)};

    final depRes = await _dio.post('/sites/$siteId/deploys',
        data: {'files': digests, 'async': true});
    final deployId = depRes.data['id'] as String;
    final required = (depRes.data['required'] as List? ?? []).cast<String>();

    for (final entry in files.entries) {
      if (required.contains(entry.key)) {
        await _dio.put('/deploys/$deployId/files/${Uri.encodeComponent(entry.key)}',
            data: entry.value,
            options: Options(headers: {'Content-Type': 'application/octet-stream'}));
      }
    }

    return DeploymentResult(
      deployId: deployId,
      url: depRes.data['ssl_url'] as String? ?? depRes.data['url'] as String?,
      status: DeploymentStatus.building,
    );
  }

  Future<String> _getOrCreateSite(String name) async {
    try {
      final res = await _dio.get('/sites', queryParameters: {'name': name});
      final list = res.data as List;
      if (list.isNotEmpty) return list.first['id'] as String;
    } catch (_) {}
    final res = await _dio.post('/sites', data: {'name': name});
    return res.data['id'] as String;
  }

  Map<String, List<int>> _files(Website w) => {
        'index.html': utf8.encode(w.htmlContent),
        if (w.cssContent != null) 'styles.css': utf8.encode(w.cssContent!),
        if (w.jsContent != null) 'script.js': utf8.encode(w.jsContent!),
      };

  String _sha1(List<int> bytes) => sha1.convert(bytes).toString();
}
