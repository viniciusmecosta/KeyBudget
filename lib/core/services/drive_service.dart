import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:passfin/core/services/drive_connection_service.dart';
import 'package:passfin/core/services/google_sign_in_session.dart';
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
  final GoogleSignInSession _googleSession;
  final DriveConnectionService _connectionService;
  final FirebaseAuth? _customFirebaseAuth;
  final bool allowUserInteraction;
  final http.Client Function()? httpClientFactory;

  DriveService({
    GoogleSignInSession? googleSession,
    DriveConnectionService? connectionService,
    FirebaseAuth? firebaseAuth,
    this.allowUserInteraction = false,
    this.httpClientFactory,
  }) : _googleSession = googleSession ?? GoogleSignInSession.instance,
       _connectionService =
           connectionService ?? DriveConnectionService.instance,
       _customFirebaseAuth = firebaseAuth;

  FirebaseAuth get _firebaseAuth =>
      _customFirebaseAuth ?? FirebaseAuth.instance;

  Future<_DriveSession?> _getDriveApi({
    String? serverClientId,
    bool allowInteractive = true,
  }) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;
      final canInteract = allowUserInteraction && allowInteractive;
      final expectedGoogleAccountIds = firebaseUser.providerData
          .where((provider) => provider.providerId == 'google.com')
          .map((provider) => provider.uid)
          .whereType<String>()
          .toList();
      final saved = await _connectionService.readConnection(firebaseUser.uid);
      if (saved?.enabled == false && !canInteract) return null;
      DriveConnection? fallback;
      for (final provider in firebaseUser.providerData) {
        if (provider.providerId == 'google.com' &&
            provider.uid != null &&
            provider.email != null) {
          fallback = DriveConnection(
            accountId: provider.uid!,
            email: provider.email!,
          );
          break;
        }
      }
      var authorization = await _connectionService.restoreAuthorization(
        userId: firebaseUser.uid,
        fallback: fallback,
        expectedAccountIds: expectedGoogleAccountIds,
      );
      if (authorization == null) {
        final googleUser = await _googleSession.account(
          serverClientId: serverClientId,
          allowInteractive: canInteract,
          firebaseUserId: firebaseUser.uid,
          expectedGoogleAccountIds: expectedGoogleAccountIds.isNotEmpty
              ? expectedGoogleAccountIds
              : saved?.enabled == true
              ? [saved!.accountId]
              : const [],
        );
        if (googleUser == null) return null;
        if (_firebaseAuth.currentUser?.uid != firebaseUser.uid) return null;
        authorization = await _googleSession.authorizationFor(
          googleUser,
          const [drive.DriveApi.driveFileScope],
          allowInteractive: canInteract,
        );
        if (authorization != null &&
            _firebaseAuth.currentUser?.uid == firebaseUser.uid &&
            (saved?.enabled != true ||
                saved?.accountId != googleUser.id ||
                saved?.email != googleUser.email)) {
          await _connectionService.saveConnection(
            firebaseUser.uid,
            DriveConnection(accountId: googleUser.id, email: googleUser.email),
          );
        }
      }
      if (authorization == null) return null;
      if (_firebaseAuth.currentUser?.uid != firebaseUser.uid) return null;

      final headers = {'Authorization': 'Bearer ${authorization.accessToken}'};

      final client = GoogleAuthClient(
        headers,
        client: httpClientFactory?.call(),
      );
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

  Future<bool> ensureAuthorized({bool allowInteractive = true}) async {
    final session = await _getDriveApi(allowInteractive: allowInteractive);
    if (session == null) return false;
    session.close();
    return true;
  }

  /// Confirms that Drive actually responds, rather than only finding a token.
  Future<bool> verifyConnection() async {
    final session = await _getDriveApi(allowInteractive: false);
    if (session == null) return false;
    try {
      await session.api.files
          .list(pageSize: 1, $fields: 'files(id)')
          .timeout(const Duration(seconds: 15));
      return true;
    } on drive.DetailedApiRequestError catch (error) {
      if (error.status == 401) return false;
      rethrow;
    } finally {
      session.close();
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
    bool allowInteractive = true,
  }) async {
    final session = await _getDriveApi(
      serverClientId: serverClientId,
      allowInteractive: allowInteractive,
    );
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
    bool allowInteractive = true,
  }) async {
    final session = await _getDriveApi(
      serverClientId: serverClientId,
      allowInteractive: allowInteractive,
    );
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
    bool allowInteractive = true,
  }) async {
    final session = await _getDriveApi(
      serverClientId: serverClientId,
      allowInteractive: allowInteractive,
    );
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

  Future<bool> deleteFile(
    String fileId, {
    String? serverClientId,
    bool allowInteractive = true,
  }) async {
    final session = await _getDriveApi(
      serverClientId: serverClientId,
      allowInteractive: allowInteractive,
    );
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
