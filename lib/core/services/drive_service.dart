import 'dart:async';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client;

  GoogleAuthClient(this._headers, {http.Client? client})
    : _client = client ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() => _client.close();
}

class DriveFileTooLargeException implements Exception {
  const DriveFileTooLargeException();
}

class DriveAuthorizationCancelled implements Exception {
  const DriveAuthorizationCancelled();
}

class _DriveSession {
  final drive.DriveApi api;
  final GoogleAuthClient client;

  const _DriveSession(this.api, this.client);

  void close() => client.close();
}

class DriveService {
  static final _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _initialization;
  static StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;
  static GoogleSignInAccount? _currentUser;

  Future<void> _ensureGoogleSignInInitialized({String? serverClientId}) async {
    if (_initialization != null) return _initialization;
    final initialization = _initializeSignIn(serverClientId: serverClientId);
    _initialization = initialization;
    try {
      await initialization;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<void> _initializeSignIn({String? serverClientId}) async {
    await _googleSignIn.initialize(serverClientId: serverClientId);
    await _authSubscription?.cancel();
    _authSubscription = _googleSignIn.authenticationEvents.listen((event) {
      _currentUser = event is GoogleSignInAuthenticationEventSignIn
          ? event.user
          : null;
    });
  }

  Future<_DriveSession?> _getDriveApi({String? serverClientId}) async {
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

      final authorization = await googleUser.authorizationClient
          .authorizationForScopes(scopes);

      if (authorization == null) {
        await googleUser.authorizationClient.authorizeScopes(scopes);

        final newAuth = await googleUser.authorizationClient
            .authorizationForScopes(scopes);

        if (newAuth == null) {
          throw Exception('Failed to get authorization for Drive API');
        }

        final headers = {'Authorization': 'Bearer ${newAuth.accessToken}'};
        final client = GoogleAuthClient(headers);
        return _DriveSession(drive.DriveApi(client), client);
      }

      final headers = {'Authorization': 'Bearer ${authorization.accessToken}'};

      final client = GoogleAuthClient(headers);
      return _DriveSession(drive.DriveApi(client), client);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const DriveAuthorizationCancelled();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Stream<List<int>> _createProgressStream(
    Stream<List<int>> source,
    int total,
    void Function(int, int) onProgress,
  ) {
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

  Future<drive.File?> uploadFile(
    File file,
    void Function(int, int) onProgress, {
    String? serverClientId,
    bool isBackup = false,
  }) async {
    final session = await _getDriveApi(serverClientId: serverClientId);
    if (session == null) return null;
    try {
      String? folderId = await _getFolderId(session.api);
      if (folderId == null) return null;
      if (isBackup) {
        folderId = await _getSubFolderId(session.api, folderId, 'Backup');
        if (folderId == null) return null;
      }

      final driveFile = drive.File()
        ..name = path.basename(file.absolute.path)
        ..parents = [folderId];
      final fileLength = await file.length();
      final media = drive.Media(
        _createProgressStream(file.openRead(), fileLength, onProgress),
        fileLength,
      );
      return await session.api.files.create(
        driveFile,
        uploadMedia: media,
        $fields: 'id, name',
      );
    } finally {
      session.close();
    }
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

  Future<String?> _getSubFolderId(
    drive.DriveApi driveApi,
    String parentId,
    String folderName,
  ) async {
    final query =
        "mimeType='application/vnd.google-apps.folder' and name='$folderName' and '$parentId' in parents and trashed=false";

    final response = await driveApi.files.list(q: query, $fields: 'files(id)');
    if (response.files != null && response.files!.isNotEmpty) {
      return response.files!.first.id;
    } else {
      final folder = drive.File()
        ..name = folderName
        ..parents = [parentId]
        ..mimeType = 'application/vnd.google-apps.folder';
      final createdFolder = await driveApi.files.create(folder, $fields: 'id');
      return createdFolder.id;
    }
  }

  Future<List<int>?> downloadFile(
    String fileId, {
    String? serverClientId,
  }) async {
    return downloadFileLimited(
      fileId,
      maxBytes: 100 * 1024 * 1024,
      serverClientId: serverClientId,
    );
  }

  Future<bool> downloadToFileLimited(
    String fileId,
    File destination, {
    required int maxBytes,
    String? serverClientId,
  }) async {
    final session = await _getDriveApi(serverClientId: serverClientId);
    if (session == null) return false;
    try {
      final response =
          (await session.api.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              ))
              as drive.Media;
      await writeLimitedStreamToFile(
        response.stream,
        destination,
        maxBytes: maxBytes,
      );
      return true;
    } finally {
      session.close();
    }
  }

  static Future<void> writeLimitedStreamToFile(
    Stream<List<int>> stream,
    File destination, {
    required int maxBytes,
  }) async {
    if (maxBytes <= 0) throw ArgumentError.value(maxBytes, 'maxBytes');
    final temporary = File('${destination.path}.part');
    IOSink? sink;
    var received = 0;
    try {
      sink = temporary.openWrite();
      await for (final chunk in stream) {
        received += chunk.length;
        if (received > maxBytes) throw const DriveFileTooLargeException();
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();
      sink = null;
      await temporary.rename(destination.path);
    } catch (_) {
      try {
        await sink?.close();
      } catch (_) {}
      if (await temporary.exists()) await temporary.delete();
      rethrow;
    }
  }

  Future<List<DriveBackupFile>> listBackupFiles({
    String? serverClientId,
  }) async {
    final session = await _getDriveApi(serverClientId: serverClientId);
    if (session == null) return [];
    try {
      final rootFolderId = await _getFolderId(session.api);
      if (rootFolderId == null) return [];
      final backupFolderId = await _getSubFolderId(
        session.api,
        rootFolderId,
        'Backup',
      );
      if (backupFolderId == null) return [];

      final query =
          "'$backupFolderId' in parents and trashed=false and (name contains '.kbudget' or name contains '.csv')";
      final files = <drive.File>[];
      final seenTokens = <String>{};
      String? pageToken;
      do {
        final response = await session.api.files.list(
          q: query,
          $fields: 'nextPageToken,files(id,name,size,modifiedTime,createdTime)',
          orderBy: 'modifiedTime desc',
          pageSize: 100,
          pageToken: pageToken,
        );
        files.addAll(response.files ?? []);
        pageToken = response.nextPageToken;
      } while (pageToken != null &&
          pageToken.isNotEmpty &&
          seenTokens.add(pageToken));

      return files.map((file) {
        return DriveBackupFile(
          id: file.id ?? '',
          name: file.name ?? '',
          sizeBytes: int.tryParse(file.size ?? '0') ?? 0,
          modifiedTime: file.modifiedTime,
        );
      }).toList();
    } finally {
      session.close();
    }
  }

  Future<List<int>?> downloadFileLimited(
    String fileId, {
    int maxBytes = 100 * 1024 * 1024,
    String? serverClientId,
  }) async {
    final session = await _getDriveApi(serverClientId: serverClientId);
    if (session == null) return null;
    try {
      final response =
          (await session.api.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              ))
              as drive.Media;
      final bytes = <int>[];
      await for (final chunk in response.stream) {
        if (bytes.length + chunk.length > maxBytes) {
          throw const DriveFileTooLargeException();
        }
        bytes.addAll(chunk);
      }
      return bytes;
    } finally {
      session.close();
    }
  }

  Future<bool> deleteFile(String fileId, {String? serverClientId}) async {
    final session = await _getDriveApi(serverClientId: serverClientId);
    if (session == null) return false;
    try {
      await session.api.files.delete(fileId);
    } on drive.DetailedApiRequestError catch (error) {
      if (error.status != 404) rethrow;
    } finally {
      session.close();
    }
    return true;
  }
}

class DriveBackupFile {
  final String id;
  final String name;
  final int sizeBytes;
  final DateTime? modifiedTime;

  const DriveBackupFile({
    required this.id,
    required this.name,
    required this.sizeBytes,
    this.modifiedTime,
  });
}
