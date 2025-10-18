import 'dart:async';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class DriveService {
  final _googleSignIn = GoogleSignIn.instance;
  bool _isInitialized = false;
  GoogleSignInAccount? _currentUser;

  Future<void> _ensureGoogleSignInInitialized({String? serverClientId}) async {
    if (_isInitialized) return;

    try {
      await _googleSignIn.initialize(
        clientId: null,
        serverClientId: serverClientId,
      );

      _googleSignIn.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _currentUser = event.user;
        } else {
          _currentUser = null;
        }
      });

      _isInitialized = true;
    } catch (e) {
      rethrow;
    }
  }

  Future<drive.DriveApi?> _getDriveApi({String? serverClientId}) async {
    try {
      await _ensureGoogleSignInInitialized(serverClientId: serverClientId);

      GoogleSignInAccount? googleUser = _currentUser;

      if (googleUser == null) {
        if (_googleSignIn.supportsAuthenticate()) {
          googleUser = await _googleSignIn.authenticate();
        } else {
          throw Exception('Platform does not support authenticate method');
        }
      }

      const scopes = [drive.DriveApi.driveFileScope];

      final authorization =
          await googleUser.authorizationClient.authorizationForScopes(scopes);

      if (authorization == null) {
        await googleUser.authorizationClient.authorizeScopes(scopes);

        final newAuth =
            await googleUser.authorizationClient.authorizationForScopes(scopes);

        if (newAuth == null) {
          throw Exception('Failed to get authorization for Drive API');
        }

        final headers = {
          'Authorization': 'Bearer ${newAuth.accessToken}',
        };
        final client = GoogleAuthClient(headers);
        return drive.DriveApi(client);
      }

      final headers = {
        'Authorization': 'Bearer ${authorization.accessToken}',
      };

      final client = GoogleAuthClient(headers);
      return drive.DriveApi(client);
    } catch (e) {
      return null;
    }
  }

  Stream<List<int>> _createProgressStream(
      Stream<List<int>> source, int total, void Function(int, int) onProgress) {
    int uploaded = 0;
    return source.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          uploaded += data.length;
          onProgress(uploaded, total);
          sink.add(data);
        },
      ),
    );
  }

  Future<drive.File?> uploadFile(File file, void Function(int, int) onProgress,
      {String? serverClientId}) async {
    final driveApi = await _getDriveApi(serverClientId: serverClientId);
    if (driveApi == null) return null;

    final folderId = await _getFolderId(driveApi);
    if (folderId == null) return null;

    final driveFile = drive.File()
      ..name = path.basename(file.absolute.path)
      ..parents = [folderId];

    final fileLength = await file.length();
    final media = drive.Media(
      _createProgressStream(file.openRead(), fileLength, onProgress),
      fileLength,
    );

    final result = await driveApi.files.create(
      driveFile,
      uploadMedia: media,
      $fields: 'id, name',
    );

    return result;
  }

  Future<String?> _getFolderId(drive.DriveApi driveApi) async {
    const folderName = 'KeyBudget Documentos';
    final query =
        "mimeType='application/vnd.google-apps.folder' and name='$folderName' and trashed=false";

    final response = await driveApi.files.list(q: query, $fields: 'files(id)');
    if (response.files != null && response.files!.isNotEmpty) {
      return response.files!.first.id;
    } else {
      final folder = drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder';
      final createdFolder = await driveApi.files.create(folder, $fields: 'id');
      return createdFolder.id;
    }
  }

  Future<List<int>?> downloadFile(String fileId,
      {String? serverClientId}) async {
    final driveApi = await _getDriveApi(serverClientId: serverClientId);
    if (driveApi == null) return null;

    final response = (await driveApi.files.get(fileId,
        downloadOptions: drive.DownloadOptions.fullMedia)) as drive.Media;

    final bytes = <int>[];
    await response.stream.forEach((element) {
      bytes.addAll(element);
    });

    return bytes;
  }

  Future<void> deleteFile(String fileId, {String? serverClientId}) async {
    final driveApi = await _getDriveApi(serverClientId: serverClientId);
    if (driveApi == null) return;
    await driveApi.files.delete(fileId);
  }
}
