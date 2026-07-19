import 'dart:convert';
import 'dart:io';

import 'package:asn1lib/asn1lib.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/url_helper.dart';
import 'package:bamabin_desktop/utils/connection_checker.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:x509/x509.dart' as x509;

class DioHelper {
  Dio getLinkDio(int type) {
    String baseUrl = '';
    if (type == 1) {
      baseUrl =
          'https://onetwothreefour.s3.ir-thr-at1.arvanstorage.ir/newdata.txt';
    } else if (type == 2) {
      baseUrl = 'https://drive.google.com';
    }

    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
  }

  Dio getServerCheckingLinkDio(int type) {
    String baseUrl = '';
    if (type == 1) {
      baseUrl =
          'https://onetwothreefour.s3.ir-thr-at1.arvanstorage.ir/newdata.txt';
    } else if (type == 2) {
      baseUrl = 'https://drive.google.com';
    }

    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
  }

  Dio getServerCheckingkDio() {
    var baseUrl = 'https://nameitanary.space';

    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
  }

  Dio getDio() {
    String url = UrlHelper.getDecryptedUrl();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    url += '/api';
    final sha256Pin = UrlHelper.getDecryptedSSLHash();
    final host = Uri.parse(url).host;
    var options = BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    );
    var dio = Dio(options)
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            ConnectionStatus connectionStatus =
                await ConnectionChecker.isConnect();
            if (connectionStatus is ConnectionError) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    data: connectionStatus.message,
                  ),
                ),
              );
            } else {
              if (!options.headers.containsKey('Authorization')) {
                options.headers.addAll({
                  'BAMABIN-API-KEY': 'Bearer ${TempDb.apiKey}',
                  'BAMABIN-DESKTOP': getDeviceName(),
                });
              }

              return handler.next(options);
            }
          },
          onError: (error, handler) {
            return handler.next(error);
          },
          onResponse: (response, handler) {
            return handler.next(response);
          },
        ),
      );

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String certHost, int port) {
              if (certHost != host) return false;

              final fingerprint = _sha256SpkiPinBase64(cert);
              final expected = sha256Pin.replaceAll('sha256/', '').trim();

              return _base64FingerprintEquals(fingerprint, expected);
            };
        return client;
      },
    );

    return dio;
  }

  String _sha256SpkiPinBase64(X509Certificate cert) {
    final parser = ASN1Parser(cert.der);
    final seq = parser.nextObject() as ASN1Sequence;
    final x509cert = x509.X509Certificate.fromAsn1(seq);
    final spki = x509cert.tbsCertificate.subjectPublicKeyInfo!;
    final spkiDer = spki.toAsn1().encodedBytes;
    final digest = sha256.convert(spkiDer);
    return base64.encode(digest.bytes);
  }

  bool _base64FingerprintEquals(String a, String b) {
    try {
      return base64.decode(a) == base64.decode(b);
    } catch (_) {
      return a == b;
    }
  }

  String getDeviceName() {
    if (Platform.isWindows) {
      return 'Windows';
    } else if (Platform.isLinux) {
      return 'Linux';
    } else if (Platform.isMacOS) {
      return 'macOS';
    } else {
      return 'Unknown';
    }
  }
}
