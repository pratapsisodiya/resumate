import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:resumate/models/deployment.dart';
import 'package:resumate/models/website.dart';

class VercelClient {
  final Dio _dio;

  VercelClient({required String token})
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://api.vercel.com',
          headers: {'Authorization': 'Bearer $token'},
        ));

  Future<DeploymentResult> deploy(Website website, {String? teamId}) async {
    final files = _files(website);
    final res = await _dio.post('/v13/deployments', data: {
      'name': website.name,
      'files': files
          .map((f) => {'file': f.$1, 'data': f.$2, 'encoding': 'base64'})
          .toList(),
      'target': 'production',
      if (teamId != null) 'teamId': teamId,
      'projectSettings': {'framework': null, 'buildCommand': null, 'outputDirectory': '.'},
    });
    final data = res.data as Map<String, dynamic>;
    return DeploymentResult(
      deployId: data['id'] as String?,
      url: data['url'] != null ? 'https://${data['url']}' : null,
      status: DeploymentStatus.building,
    );
  }

  Future<DeploymentStatus> checkStatus(String deploymentId, {String? teamId}) async {
    final res = await _dio.get('/v13/deployments/$deploymentId',
        queryParameters: {if (teamId != null) 'teamId': teamId});
    return switch ((res.data['readyState'] as String?)?.toLowerCase()) {
      'ready'    => DeploymentStatus.ready,
      'error'    => DeploymentStatus.error,
      _          => DeploymentStatus.building,
    };
  }

  List<(String, String)> _files(Website w) => [
        ('index.html', base64Encode(utf8.encode(w.htmlContent))),
        if (w.cssContent != null) ('styles.css', base64Encode(utf8.encode(w.cssContent!))),
        if (w.jsContent != null) ('script.js', base64Encode(utf8.encode(w.jsContent!))),
      ];
}
