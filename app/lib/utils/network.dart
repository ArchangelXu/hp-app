import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:app/models/hooh_api_error_response.dart';
import 'package:app/models/network/requests.dart';
import 'package:app/models/network/responses.dart';
import 'package:app/models/post.dart';
import 'package:app/utils/date_util.dart';
import 'package:app/utils/device_info.dart';
import 'package:app/utils/preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:pretty_json/pretty_json.dart';
import 'package:universal_io/io.dart';

//顶层变量
Network network = Network._internal();

enum HttpMethod { get, post, put, delete }

class Network {
  /// 顶层变量，单例模式
  Network._internal() {
    _prepareHttpClient();
  }

  static const HOST_LOCAL = "192.168.31.136:8080";

  static const HOST_STAGING = "hp.fygtapp.cn";
  static const HOST_PRODUCTION = "xxx";
  static const SERVER_HOSTS = {
    TYPE_LOCAL: HOST_LOCAL,
    TYPE_STAGING: HOST_STAGING,
    TYPE_PRODUCTION: HOST_PRODUCTION,
  };
  static const SERVER_HOST_NAMES = {
    TYPE_LOCAL: "本地服务器",
    TYPE_STAGING: "测试服",
    TYPE_PRODUCTION: "正式服",
  };

/*
*
docker pull registry.cn-beijing.aliyuncs.com/newlogichaos/hp:staging-latest
docker stop hp-staging
docker rm hp-staging
docker run --name hp-staging  -d --restart always -p 9000:8080 --log-opt max-size=100m --log-opt max-file=3 -v /mnt/www/staging/api/tmp:/tmp -v /mnt/www/staging/api/storage:/storage -d registry.cn-beijing.aliyuncs.com/newlogichaos/hp:staging-latest

* */
  static const TYPE_LOCAL = 0;
  static const TYPE_STAGING = 1;
  static const TYPE_PRODUCTION = 2;

  static const SERVER_PATH_PREFIX = "";
  static const DEFAULT_PAGE_SIZE = 20;
  static const DEFAULT_PAGE = 1;

  late int serverType;

  late final http.Client _client;
  bool _isUsingLocalServer = false;

  String getStorageImageKey(String? url) {
    if (url == null) {
      return "";
    }
    if (url.contains("?") && url.contains("com/")) {
      return url.substring(url.indexOf("com/") + "com/".length, url.indexOf("?"));
    }
    return url;
  }

  void requestAsync<T>(Future<T> request, Function(T data) onSuccess, Function(HoohApiErrorResponse error) onError) {
    request.then((data) {
      onSuccess(data);
    }).catchError((Object error, StackTrace stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      if (error is HoohApiErrorResponse) {
        onError(error);
      }
    });
  }

  void setUserToken(String? token) {
    preferences.putString(Preferences.KEY_USER_ACCESS_TOKEN, token);
  }

  void reloadServerType() {
    serverType = preferences.getInt(Preferences.KEY_SERVER) ?? TYPE_PRODUCTION;
    debugPrint("serverType=$serverType");
  }

  Future<RequestUploadingFileResponse> requestUploadingPostImage(File file) {
    String fileMd5 = md5.convert(file.readAsBytesSync()).toString().toLowerCase();
    String ext = file.path;
    debugPrint("upload file md5=$fileMd5 path=$ext");
    ext = ext.substring(ext.lastIndexOf(".") + 1);
    return _getResponseObject<RequestUploadingFileResponse>(HttpMethod.post, _buildHoohUri("posts/request-uploading-post-image"),
        body: RequestUploadingFileRequest(fileMd5, ext).toJson(), deserializer: RequestUploadingFileResponse.fromJson);
  }

  Future<Post> createPost(CreatePostRequest request) {
    return _getResponseObject<Post>(HttpMethod.post, _buildHoohUri("posts/create"), body: request.toJson(), deserializer: Post.fromJson);
  }

  Future<List<Post>> getFeeds({DateTime? date, int size = DEFAULT_PAGE_SIZE}) {
    Map<String, dynamic> params = {
      "size": size,
    };
    if (date != null) {
      params["timestamp"] = DateUtil.getUtcDateString(date);
    }
    return _getResponseList<Post>(HttpMethod.get, _buildHoohUri("posts/feeds", params: params), deserializer: Post.fromJson);
  }

//region core
  Future<bool> uploadFile(String url, Uint8List fileBytes, {Map<String, String>? headers}) async {
    int id = Random().nextInt(10000);
    logRequest(id, HttpMethod.put, Uri.parse(url), headers: headers, body: {'data': "<file bytes>"});
    var response = await http.put(Uri.parse(url), headers: headers, body: fileBytes);
    logResponse(id, response, null);
    if (response.statusCode >= 200 && response.statusCode < 400) {
      return true;
    } else {
      return false;
    }
  }

  Future<M> _getResponseObject<M>(HttpMethod method, Uri uri,
      {Map<String, dynamic>? extraHeaders, Map<String, dynamic>? body, M Function(Map<String, dynamic>)? deserializer}) async {
    extraHeaders ??= {};
    _prepareHeaders(extraHeaders);
    dynamic data;
    try {
      data = await _getRawResponse(method, uri, extraHeaders: extraHeaders, body: body, deserializer: deserializer);
    } catch (e) {
      data = HoohApiErrorResponse(0, e.toString());
    }
    if (data is HoohApiErrorResponse) {
      return Future.error(data);
    } else {
      if (deserializer != null) {
        return deserializer(data as Map<String, dynamic>);
      } else {
        return Future.value(null);
      }
    }
  }

  Future<List<M>> _getResponseList<M>(HttpMethod method, Uri uri,
      {Map<String, dynamic>? extraHeaders, Map<String, dynamic>? body, M Function(Map<String, dynamic>)? deserializer}) async {
    extraHeaders ??= {};
    _prepareHeaders(extraHeaders);
    // var data = await _getRawResponse(method, uri, extraHeaders: extraHeaders, body: body, deserializer: deserializer);
    dynamic data;
    try {
      data = await _getRawResponse(method, uri, extraHeaders: extraHeaders, body: body, deserializer: deserializer);
    } catch (e) {
      data = HoohApiErrorResponse(0, e.toString());
    }
    if (data is HoohApiErrorResponse) {
      return Future.error(data);
    } else {
      if (M == String) {
        return (data as List<dynamic>).map((e) => e as M).toList();
      } else {
        if (deserializer != null) {
          return (data as List<dynamic>).map((e) => deserializer(e as Map<String, dynamic>)).toList();
        } else {
          return Future.value([]);
        }
      }
    }
  }

// Future<String> _getUserAgent() async {
//
// }
  void _prepareHeaders(Map<String, dynamic> headers) {
    String? token = preferences.getString(Preferences.KEY_USER_ACCESS_TOKEN);
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }
    headers["Content-Type"] = "application/json";
    if (!kIsWeb) {
      headers["User-Agent"] = deviceInfo.getUserAgent();
    } else {
      headers['Access-Control-Allow-Origin'] = '*';
    }
    // headers["Language"] = Platform.localeName;
    // headers["Accept-Language"] = preferences.getString(Preferences.KEY_LANGUAGE) ?? Platform.localeName;
    String languageCode = preferences.getString(Preferences.KEY_LANGUAGE) ?? "en";
    if (languageCode != "system") {
      headers["Accept-Language"] = languageCode;
    }
  }

  Future<dynamic> _getRawResponse<M>(HttpMethod method, Uri uri,
      {Map<String, dynamic>? extraHeaders, Map<String, dynamic>? body, M Function(Map<String, dynamic>)? deserializer}) async {
    int id = Random().nextInt(10000);
    logRequest(id, method, uri, body: body);
    http.Response response;
    try {
      switch (method) {
        case HttpMethod.get:
          response = await _client.get(uri, headers: extraHeaders?.map((key, value) => MapEntry(key, value.toString())));
          break;
        case HttpMethod.post:
          response = await _client.post(uri, body: json.encode(body), headers: extraHeaders?.map((key, value) => MapEntry(key, value.toString())));
          break;
        case HttpMethod.put:
          response = await _client.put(uri, body: json.encode(body), headers: extraHeaders?.map((key, value) => MapEntry(key, value.toString())));
          break;
        case HttpMethod.delete:
          response = await _client.delete(uri, body: json.encode(body), headers: extraHeaders?.map((key, value) => MapEntry(key, value.toString())));
          break;
      }
    } catch (e) {
      print(e);
      rethrow;
    }
    dynamic returnedJson;
    try {
      if (response.bodyBytes.isNotEmpty) {
        returnedJson = jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    try {
      logResponse(id, response, returnedJson);
    } catch (e) {
      debugPrint(e.toString());
    }
    if (response.statusCode >= 200 && response.statusCode < 400) {
      //success
      return returnedJson;
    } else {
      //failed
      HoohApiErrorResponse hoohApiErrorResponse;
      if (returnedJson != null) {
        hoohApiErrorResponse = HoohApiErrorResponse.fromJson(returnedJson);
        if (hoohApiErrorResponse.message.isEmpty) {
          hoohApiErrorResponse.message = "<未返回错误信息>";
        }
      } else {
        debugPrint("response=${response.reasonPhrase}");
        hoohApiErrorResponse = HoohApiErrorResponse(response.statusCode, "<无法解析>");
      }
      return hoohApiErrorResponse;
    }
  }

  void logResponse(int id, http.Response response, dynamic returnedJson) {
    debugPrint("[RESPONSE $id] HTTP ${response.statusCode}\njson=${returnedJson == null ? "null" : prettyJson(returnedJson)}");
    if (response.statusCode >= 400) {
      debugPrint("error=${response.body}");
    }
  }

  void logRequest(int id, HttpMethod method, Uri uri, {Map<String, String>? headers, Map<String, dynamic>? body}) {
    debugPrint(
        "[REQUEST  $id] ${method.name.toUpperCase()} url=${uri.toString()},\n headers:${"\n" + prettyJson(headers)},\n query:${"\n" + prettyJson(uri.queryParameters)},\n body:${body == null ? "null" : ("\n" + prettyJson(body))}");
  }

  Uri _buildUri(bool ssl, String host, String path, {Map<String, dynamic>? params}) {
    var queryParameters = params?.map((key, value) => MapEntry(key, value.toString()));
    return ssl ? Uri.https(host, path, queryParameters) : Uri.http(host, path, queryParameters);
  }

  Uri _buildHoohUri(String path, {bool hasPrefix = true, Map<String, dynamic>? params}) {
    String unencodedPath = (hasPrefix ? SERVER_PATH_PREFIX : "") + path;
    return _buildUri(serverType != TYPE_LOCAL, SERVER_HOSTS[serverType] ?? HOST_PRODUCTION, unencodedPath, params: params);
  }

  // void _prepareHttpClient() {
  //   reloadServerType();
  //   _client = http.Client();
  // }

//endregion
  ///准备一个可以支持Let's Encrypt证书的client
  void _prepareHttpClient() {
    /// This is LetsEncrypt's self-signed trusted root certificate authority
    /// certificate, issued under common name: ISRG Root X1 (Internet Security
    /// Research Group).  Used in handshakes to negotiate a Transport Layer Security
    /// connection between endpoints.  This certificate is missing from older devices
    /// that don't get OS updates such as Android 7 and older.  But, we can supply
    /// this certificate manually to our HttpClient via SecurityContext so it can be
    /// used when connecting to URLs protected by LetsEncrypt SSL certificates.
    /// PEM format LE self-signed cert from here: https://letsencrypt.org/certificates/
    const String ISRG_X1 = """-----BEGIN CERTIFICATE-----
MIIFazCCA1OgAwIBAgIRAIIQz7DSQONZRGPgu2OCiwAwDQYJKoZIhvcNAQELBQAw
TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMTUwNjA0MTEwNDM4
WhcNMzUwNjA0MTEwNDM4WjBPMQswCQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJu
ZXQgU2VjdXJpdHkgUmVzZWFyY2ggR3JvdXAxFTATBgNVBAMTDElTUkcgUm9vdCBY
MTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAK3oJHP0FDfzm54rVygc
h77ct984kIxuPOZXoHj3dcKi/vVqbvYATyjb3miGbESTtrFj/RQSa78f0uoxmyF+
0TM8ukj13Xnfs7j/EvEhmkvBioZxaUpmZmyPfjxwv60pIgbz5MDmgK7iS4+3mX6U
A5/TR5d8mUgjU+g4rk8Kb4Mu0UlXjIB0ttov0DiNewNwIRt18jA8+o+u3dpjq+sW
T8KOEUt+zwvo/7V3LvSye0rgTBIlDHCNAymg4VMk7BPZ7hm/ELNKjD+Jo2FR3qyH
B5T0Y3HsLuJvW5iB4YlcNHlsdu87kGJ55tukmi8mxdAQ4Q7e2RCOFvu396j3x+UC
B5iPNgiV5+I3lg02dZ77DnKxHZu8A/lJBdiB3QW0KtZB6awBdpUKD9jf1b0SHzUv
KBds0pjBqAlkd25HN7rOrFleaJ1/ctaJxQZBKT5ZPt0m9STJEadao0xAH0ahmbWn
OlFuhjuefXKnEgV4We0+UXgVCwOPjdAvBbI+e0ocS3MFEvzG6uBQE3xDk3SzynTn
jh8BCNAw1FtxNrQHusEwMFxIt4I7mKZ9YIqioymCzLq9gwQbooMDQaHWBfEbwrbw
qHyGO0aoSCqI3Haadr8faqU9GY/rOPNk3sgrDQoo//fb4hVC1CLQJ13hef4Y53CI
rU7m2Ys6xt0nUW7/vGT1M0NPAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNV
HRMBAf8EBTADAQH/MB0GA1UdDgQWBBR5tFnme7bl5AFzgAiIyBpY9umbbjANBgkq
hkiG9w0BAQsFAAOCAgEAVR9YqbyyqFDQDLHYGmkgJykIrGF1XIpu+ILlaS/V9lZL
ubhzEFnTIZd+50xx+7LSYK05qAvqFyFWhfFQDlnrzuBZ6brJFe+GnY+EgPbk6ZGQ
3BebYhtF8GaV0nxvwuo77x/Py9auJ/GpsMiu/X1+mvoiBOv/2X/qkSsisRcOj/KK
NFtY2PwByVS5uCbMiogziUwthDyC3+6WVwW6LLv3xLfHTjuCvjHIInNzktHCgKQ5
ORAzI4JMPJ+GslWYHb4phowim57iaztXOoJwTdwJx4nLCgdNbOhdjsnvzqvHu7Ur
TkXWStAmzOVyyghqpZXjFaH3pO3JLF+l+/+sKAIuvtd7u+Nxe5AW0wdeRlN8NwdC
jNPElpzVmbUq4JUagEiuTDkHzsxHpFKVK7q4+63SM1N95R1NbdWhscdCb+ZAJzVc
oyi3B43njTOQ5yOf+1CceWxG1bQVs5ZufpsMljq4Ui0/1lvh+wjChP4kqKOJ2qxq
4RgqsahDYVvTH9w7jXbyLeiNdd8XM2w9U/t7y0Ff/9yi0GE44Za4rF2LN9d11TPA
mRGunUHBcnWEvgJBQl9nJEiU0Zsnvgc/ubhPgXRR4Xq37Z0j4r7g1SgEEzwxA57d
emyPxgcYxn/eR44/KJ4EBs+lVDR3veyJm+kXQ99b21/+jh5Xos1AnX5iItreGCc=
-----END CERTIFICATE-----""";
    HttpClient customHttpClient(String? cert) {
      SecurityContext context = SecurityContext.defaultContext;
      try {
        if (cert != null) {
          Uint8List bytes = Uint8List.fromList(utf8.encode(cert));
          context.setTrustedCertificatesBytes(bytes);
        }
        print('createHttpClient() - cert added!');
      } on TlsException catch (e) {
        print(e);
      } finally {}
      HttpClient httpClient = HttpClient(context: context);
      return httpClient;
    }

    reloadServerType();

    /// Use package:http Client with our custom dart:io HttpClient with added
    /// LetsEncrypt trusted certificate
    http.Client createLEClient() {
      IOClient ioClient;
      ioClient = IOClient(customHttpClient(ISRG_X1));
      return ioClient;
    }

    /// Using a custom package:http Client
    /// that will work with devices missing LetsEncrypt
    /// ISRG Root X1 certificates, like old Android 7 devices.
    _client = createLEClient();
  }
}

class DownloadInfo {
  Uint8List? bytes;
  String? filename;

  DownloadInfo({this.bytes, this.filename});
}
