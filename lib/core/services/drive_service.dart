import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:path_provider/path_provider.dart';

class DriveService {
  final _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );
  static const String _folderName = 'KeyBudget Documentos';

  Future<drive.DriveApi?> _getDriveApi() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null;
    }
    final httpClient = await _googleSignIn.authenticatedClient();
    if (httpClient == null) {
      return null;
    }
    return drive.DriveApi(httpClient);
  }

  Future<String?> _getFolderId(drive.DriveApi driveApi) async {
    final response = await driveApi.files.list(
      q: "mimeType='application/vnd.google-apps.folder' and name='$_folderName'",
      spaces: 'drive',
    );

    if (response.files != null && response.files!.isNotEmpty) {
      return response.files!.first.id;
    } else {
      final folder = drive.File()
        ..name = _folderName
        ..mimeType = 'application/vnd.google-apps.folder';
      final createdFolder = await driveApi.files.create(folder);
      return createdFolder.id;
    }
  }

  Future<drive.File?> uploadFile(File file) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return null;

    final folderId = await _getFolderId(driveApi);
    if (folderId == null) return null;

    final driveFile = drive.File()
      ..name = file.path.split('/').last
      ..parents = [folderId];

    final result = await driveApi.files.create(
      driveFile,
      uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
    );
    return result;
  }

  Future<void> deleteFile(String fileId) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return;
    try {
      await driveApi.files.delete(fileId);
    } catch (e) {
      // Ignora erro se o arquivo não existir
    }
  }

  Future<File?> downloadFile(String fileId, String fileName) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return null;

    final media = (await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    )) as drive.Media;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');

    final List<int> dataStore = [];
    await for (var data in media.stream) {
      dataStore.addAll(data);
    }
    await file.writeAsBytes(dataStore);
    return file;
  }
}