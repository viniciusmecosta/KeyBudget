import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as path;

class DriveService {
  final _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  Future<drive.DriveApi?> _getDriveApi() async {
    try {
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        return null;
      }
      return drive.DriveApi(httpClient);
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadFile(File file) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return null;

    final folderId = await _getFolderId(driveApi);
    if (folderId == null) return null;

    final driveFile = drive.File()
      ..name = path.basename(file.absolute.path)
      ..parents = [folderId];

    final result = await driveApi.files.create(
      driveFile,
      uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
    );

    return result.id;
  }

  Future<String?> _getFolderId(drive.DriveApi driveApi) async {
    const folderName = 'KeyBudget Documentos';
    final query =
        "mimeType='application/vnd.google-apps.folder' and name='$folderName' and trashed=false";

    final response = await driveApi.files.list(q: query);
    if (response.files != null && response.files!.isNotEmpty) {
      return response.files!.first.id;
    } else {
      final folder = drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder';
      final createdFolder = await driveApi.files.create(folder);
      return createdFolder.id;
    }
  }

  Future<List<int>?> downloadFile(String fileId) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return null;

    final response = (await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    )) as drive.Media;

    final bytes = <int>[];
    await response.stream.forEach((element) {
      bytes.addAll(element);
    });

    return bytes;
  }
}
