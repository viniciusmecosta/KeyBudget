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
  final _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  Future<drive.DriveApi?> _getDriveApi() async {
    try {
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      googleUser ??= await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final headers = await googleUser.authHeaders;
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

  Future<drive.File?> uploadFile(
      File file, void Function(int, int) onProgress) async {
    final driveApi = await _getDriveApi();
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

  Future<List<int>?> downloadFile(String fileId) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return null;

    final response = (await driveApi.files.get(fileId,
        downloadOptions: drive.DownloadOptions.fullMedia)) as drive.Media;

    final bytes = <int>[];
    await response.stream.forEach((element) {
      bytes.addAll(element);
    });

    return bytes;
  }
}
