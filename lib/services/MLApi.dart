// import 'package:dio/dio.dart';

// class MlApi {
//   final Dio _dio;

//   MlApi(String baseUrl, {String? token, int timeoutMs = 12000})
//     : _dio = Dio(
//         BaseOptions(
//           baseUrl: baseUrl,
//           connectTimeout: Duration(milliseconds: timeoutMs),
//           receiveTimeout: Duration(milliseconds: timeoutMs),
//           headers: {
//             'Content-Type': 'application/json',
//             if (token != null) 'Authorization': 'Bearer $token',
//           },
//         ),
//       );

//   /// Si ton backend attend un vecteur (texte/chiffres)
//   Future<List<double>> inferVector(List<double> features) async {
//     final res = await _dio.post('/infer', data: {'features': features});
//     final data = res.data as Map<String, dynamic>;
//     return (data['pred'] as List).map((e) => (e as num).toDouble()).toList();
//   }

//   /// Si ton backend attend une image (multipart)
//   Future<Map<String, dynamic>> inferImage(String filePath) async {
//     final form = FormData.fromMap({
//       'file': await MultipartFile.fromFile(filePath, filename: 'plate.jpg'),
//     });
//     final res = await _dio.post('/infer_image', data: form);
//     return res.data
//         as Map<String, dynamic>; // ex: { plate: "AA-123-BB", score: 0.98 }
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class MlApi {
  final String baseUrl; // ex: https://.../v2/models/niit
  final Dio _dio;

  MlApi(this.baseUrl)
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          headers: {'Accept': 'application/json'},
        ),
      ) {
    // (Optionnel) proxy/trace réseau:
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('[MLApi] → ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            '[MLApi] ← ${response.statusCode} ${response.requestOptions.uri}',
          );
          return handler.next(response);
        },
        onError: (e, handler) {
          debugPrint('[MLApi][ERROR] ${e.requestOptions.uri}');
          if (e.response != null) {
            debugPrint('Status: ${e.response?.statusCode}');
            debugPrint('Data  : ${e.response?.data}');
            debugPrint('Headers: ${e.response?.headers}');
          } else {
            debugPrint('No response (timeout / DNS / cert / réseau).');
          }
          return handler.next(e);
        },
      ),
    );

    // ⚠️ DEV UNIQUEMENT: bypass cert si cluster auto-signé (ne PAS activer en prod)
    // (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
    //   client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    //   return client;
    // };
  }

  /// ========= VARIANTE A: serveur attend *multipart file upload*
  /// Endpoint ex: POST {baseUrl}/infer  (ou /predict)
  Future<Map<String, dynamic>> inferImageMultipart(String imagePath) async {
    final fileName = imagePath.split('/').last;
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(imagePath, filename: fileName),
    });

    // Ajuste le path exact (ex: si baseUrl finit déjà par /infer, retire /infer ici)
    final url = baseUrl.endsWith('/infer') ? baseUrl : '$baseUrl/infer';

    final res = await _dio.post(url, data: form);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.data}');
    }
    if (res.data is Map<String, dynamic>) {
      return res.data as Map<String, dynamic>;
    }
    // si le backend renvoie du texte JSON
    return jsonDecode(res.data.toString()) as Map<String, dynamic>;
  }

  /// ========= VARIANTE B: serveur KServe v2 (JSON base64)
  /// Endpoint ex: POST {baseUrl}/infer
  /// Payload attendu: { "inputs": [ { "name":"input", "datatype":"BYTES", "shape":[1], "data":["<base64>"] } ] }
  // Future<Map<String, dynamic>> inferImageKServe(String imagePath) async {
  //   final bytes = await File(imagePath).readAsBytes();
  //   final b64 = base64Encode(bytes);

  //   final url = baseUrl.endsWith('/infer') ? baseUrl : '$baseUrl/infer';

  //   final payload = {
  //     "inputs": [
  //       {
  //         "name": "input", // ⚠️ à adapter selon ton modèle
  //         "datatype": "BYTES",
  //         "shape": [1],
  //         "data": [b64],
  //       },
  //     ],
  //   };

  //   final res = await _dio.post(
  //     url,
  //     data: jsonEncode(payload),
  //     options: Options(headers: {'Content-Type': 'application/json'}),
  //   );
  //   if (res.statusCode != 200) {
  //     throw Exception('HTTP ${res.statusCode}: ${res.data}');
  //   }
  //   return (res.data is Map<String, dynamic>)
  //       ? res.data as Map<String, dynamic>
  //       : jsonDecode(res.data.toString()) as Map<String, dynamic>;
  // }
  Future<Map<String, dynamic>> inferImageKServe(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final b64 = base64Encode(bytes);

    final url = baseUrl.endsWith('/infer') ? baseUrl : '$baseUrl/infer';

    // ⚠️ Le modèle KServe attend un input nommé "images"
    final payload = {
      "inputs": [
        {
          "name": "images", // <= IMPORTANT : "images" (pas "input")
          "datatype": "BYTES",
          "shape": [1],
          "data": [b64],
          // Souvent pas obligatoire, mais peut aider selon le handler :
          "parameters": {
            "content_type": "image/jpeg", // ou "image/png" si besoin
          },
        },
      ],
    };

    final res = await _dio.post(
      url,
      data: jsonEncode(payload),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.data}');
    }

    return (res.data is Map<String, dynamic>)
        ? res.data as Map<String, dynamic>
        : jsonDecode(res.data.toString()) as Map<String, dynamic>;
  }

  /// Appel public utilisé par ton écran — choisis A ou B selon ton backend
  Future<Map<String, dynamic>> inferImage(String imagePath) async {
    // ===== CHOISIS LA BONNE VARIANTE =====
    // return await inferImageMultipart(imagePath); // Si backend attend multipart
    return await inferImageKServe(imagePath); // Si backend est KServe v2
  }
}
