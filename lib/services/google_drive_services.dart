import 'dart:convert';
import 'dart:io';
import 'package:digital_bookshelf/models/book_category.dart';
import 'package:digital_bookshelf/models/book_document.dart';
import 'package:digital_bookshelf/services/shelf_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class _BearerClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _inner;

  _BearerClient(this._accessToken) : _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

// GoogleDriveSyncService
class GoogleDriveService extends ChangeNotifier {
  static const _appFolder = 'Digital Bookshelf';
  static const _docsFolder = 'documents';
  static const _imagesFolder = 'images';
  static const _metaFile = 'bookshelf_metadata.json';

  bool isSyncing = false;
  bool isRestoring = false;
  String syncProgress = '';

  void _updateProgress(String message) {
    syncProgress = message;
    notifyListeners();
  }

  /// Authenticates with Google and returns a Drive API client.
  /// Requests the `drive.file` scope (app-only, most privacy-respecting).
  Future<drive.DriveApi> _getDriveApi() async {
    try {
      // Try to get the currently signed in account first to avoid prompting
      GoogleSignInAccount? account =
          await GoogleSignIn.instance.attemptLightweightAuthentication();

      // If no account found, force a sign in.
      // authenticate() throws if canceled.
      account ??= await GoogleSignIn.instance.authenticate();

      // Check if the selected account matches the Firebase logged-in user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && account.email != currentUser.email) {
        await GoogleSignIn.instance.signOut();
        throw Exception(
          'Account mismatch: Please select the Google account you are '
          'currently logged in with (${currentUser.email}).',
        );
      }

      // authorizeScopes returns non-nullable auth and throws if denied.
      final auth = await account.authorizationClient.authorizeScopes(
        [drive.DriveApi.driveFileScope],
      );

      return drive.DriveApi(_BearerClient(auth.accessToken));
    } on PlatformException catch (e) {
      if (e.code == 'network_error') {
        throw Exception('No internet connection. Please check your network and try again.');
      } else if (e.code == 'sign_in_canceled' || e.code == 'sign_in_cancelled') {
        throw Exception('Google Sign-In was cancelled. No account was chosen.');
      }
      throw Exception('Google Sign-In failed: ${e.message ?? e.code}');
    } catch (e) {
      if (e.toString().contains('access_denied')) {
        throw Exception('Permission denied. You must grant Google Drive access to sync.');
      }
      rethrow;
    }
  }

  // Finds an existing Drive folder or creates it. Returns the folder ID.
  Future<String> _ensureFolder(
    drive.DriveApi api,
    String name, {
    String? parentId,
  }) async {
    final q = StringBuffer(
      "mimeType='application/vnd.google-apps.folder' "
      "and name='$name' and trashed=false",
    );
    if (parentId != null) q.write(" and '$parentId' in parents");

    final list = await api.files.list(
      q: q.toString(),
      spaces: 'drive',
      $fields: 'files(id)',
    );

    if (list.files != null && list.files!.isNotEmpty) {
      return list.files!.first.id!;
    }

    final folder = drive.File()
      ..name = name
      ..mimeType = 'application/vnd.google-apps.folder';
    if (parentId != null) folder.parents = [parentId];

    final created = await api.files.create(folder, $fields: 'id');
    return created.id!;
  }

  // Returns the Drive file ID of the first match, or null.
  Future<String?> _findFile(
    drive.DriveApi api,
    String name,
    String folderId,
  ) async {
    final list = await api.files.list(
      q: "name='$name' and '$folderId' in parents and trashed=false",
      spaces: 'drive',
      $fields: 'files(id)',
    );
    return list.files?.firstOrNull?.id;
  }

  // Uploads bytes to Drive (creates or overwrites). Returns the Drive file ID.
  Future<String> _upload(
    drive.DriveApi api, {
    required List<int> bytes,
    required String name,
    required String mimeType,
    required String folderId,
    String? existingId,
  }) async {
    final media = drive.Media(
      Stream.fromIterable([bytes]),
      bytes.length,
      contentType: mimeType,
    );

    if (existingId != null) {
      final updated = await api.files.update(
        drive.File()..name = name,
        existingId,
        uploadMedia: media,
        $fields: 'id',
      );
      return updated.id!;
    }

    final file = drive.File()
      ..name = name
      ..parents = [folderId];
    final created = await api.files.create(file, uploadMedia: media, $fields: 'id');
    return created.id!;
  }

  // Downloads a Drive file and returns its bytes.
  Future<List<int>> _download(drive.DriveApi api, String driveFileId) async {
    final media = await api.files.get(
      driveFileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    return media.stream.expand((chunk) => chunk).toList();
  }

  // Backup or serialises Hive data to JSON + uploads all files to Drive.
  Future<void> syncToCloud() async {
    isSyncing = true;
    notifyListeners();
    try {
    _updateProgress('Connecting to Google Drive…');
    final api = await _getDriveApi();

    _updateProgress('Preparing Drive folders…');
    final rootId    = await _ensureFolder(api, _appFolder);
    final docsId    = await _ensureFolder(api, _docsFolder,   parentId: rootId);
    final imagesId  = await _ensureFolder(api, _imagesFolder, parentId: rootId);

    final categories = ShelfServices.getCategories();
    final allDocs = <BookDocument>[
      for (final c in categories) ...ShelfServices.getDocuments(c.id),
    ];

    _updateProgress(
      'Found ${categories.length} ${categories.length == 1 ? "category" : "categories"} '
      'and ${allDocs.length} ${allDocs.length == 1 ? "document" : "documents"}.',
    );

    // Upload category cover images
    final Map<String, String> catImageIds = {};

    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];
      _updateProgress('Category ${i + 1}/${categories.length}: "${cat.name}"');

      if (cat.imagePath != null) {
        final f = File(cat.imagePath!);
        if (await f.exists()) {
          _updateProgress('  Uploading cover image…');
          final ext = cat.imagePath!.split('.').last.toLowerCase();
          final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
          final fileName = '${cat.id}.$ext';
          final existingId = await _findFile(api, fileName, imagesId);
          catImageIds[cat.id] = await _upload(
            api,
            bytes: await f.readAsBytes(),
            name: fileName,
            mimeType: mime,
            folderId: imagesId,
            existingId: existingId,
          );
        }
      }
    }

    // Upload document files 
    final Map<String, String> docFileIds = {};

    for (int i = 0; i < allDocs.length; i++) {
      final doc = allDocs[i];
      _updateProgress('Document ${i + 1}/${allDocs.length}: "${doc.name}"');

      final f = File(doc.filePath);
      if (await f.exists()) {
        _updateProgress('  Uploading file…');
        final fileName = '${doc.id}.${doc.fileType}';
        final existingId = await _findFile(api, fileName, docsId);
        docFileIds[doc.id] = await _upload(
          api,
          bytes: await f.readAsBytes(),
          name: fileName,
          mimeType: 'application/octet-stream',
          folderId: docsId,
          existingId: existingId,
        );
      } else {
        _updateProgress('  File not found locally, skipping upload.');
      }
    }

    // Upload metadata JSON
    _updateProgress('Saving metadata…');

    final metadata = {
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': [
        for (final c in categories)
          {
            'id': c.id,
            'name': c.name,
            'colorHex': c.colorHex,
            'createdAt': c.createdAt.toIso8601String(),
            'order': c.order,
            'localImagePath': c.imagePath,
            'driveImageId': catImageIds[c.id],
          },
      ],
      'documents': [
        for (final d in allDocs)
          {
            'id': d.id,
            'categoryId': d.categoryId,
            'name': d.name,
            'fileType': d.fileType,
            'addedAt': d.addedAt.toIso8601String(),
            'fileSizeBytes': d.fileSizeBytes,
            'driveFileId': docFileIds[d.id],
          },
      ],
    };

    final jsonBytes = utf8.encode(jsonEncode(metadata));
    final existingMetaId = await _findFile(api, _metaFile, rootId);
    await _upload(
      api,
      bytes: jsonBytes,
      name: _metaFile,
      mimeType: 'application/json',
      folderId: rootId,
      existingId: existingMetaId,
    );

    _updateProgress('Sync complete! ✓');
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  // Restore or downloads metadata from Drive and rebuilds Hive + local files.
  Future<void> restoreFromCloud() async {
    isRestoring = true;
    notifyListeners();
    try {
    _updateProgress('Connecting to Google Drive…');
    final api = await _getDriveApi();

    _updateProgress('Looking for backup…');

    // Find root app folder
    final rootList = await api.files.list(
      q: "mimeType='application/vnd.google-apps.folder' "
          "and name='$_appFolder' and trashed=false",
      spaces: 'drive',
      $fields: 'files(id)',
    );
    if (rootList.files == null || rootList.files!.isEmpty) {
      throw Exception(
        'No backup found in your Google Drive.\n'
        'Sync from another device first.',
      );
    }
    final rootId = rootList.files!.first.id!;

    // Download metadata JSON
    final metaId = await _findFile(api, _metaFile, rootId);
    if (metaId == null) {
      throw Exception('Backup metadata not found. Please sync from your other device first.');
    }

    _updateProgress('Downloading metadata…');
    final metaBytes = await _download(api, metaId);
    final meta = jsonDecode(utf8.decode(metaBytes)) as Map<String, dynamic>;

    final appDir = await getApplicationDocumentsDirectory();
    final categoriesRaw = meta['categories'] as List<dynamic>;
    final documentsRaw  = meta['documents']  as List<dynamic>;

    _updateProgress(
      'Restoring ${categoriesRaw.length} categories '
      'and ${documentsRaw.length} documents…',
    );

    // Restore categories
    for (final raw in categoriesRaw) {
      final m = raw as Map<String, dynamic>;
      final id = m['id'] as String;

      String? localImagePath;
      final driveImageId = m['driveImageId'] as String?;

      if (driveImageId != null) {
        try {
          final imgDir = Directory('${appDir.path}/category_images');
          await imgDir.create(recursive: true);
          // guess extension from stored local path if available
          final storedPath = m['localImagePath'] as String?;
          final ext = storedPath != null
              ? storedPath.split('.').last
              : 'jpg';
          localImagePath = '${imgDir.path}/$id.$ext';
          final imgBytes = await _download(api, driveImageId);
          await File(localImagePath).writeAsBytes(imgBytes);
        } catch (_) {
          localImagePath = null; // fall back to colour tile
        }
      }

      // Only add if not already present (idempotent restore)
      final existing = ShelfServices.getCategories().where((c) => c.id == id);
      if (existing.isEmpty) {
        await ShelfServices.addCategory(BookCategory(
          id: id,
          name: m['name'] as String,
          colorHex: m['colorHex'] as String,
          createdAt: DateTime.parse(m['createdAt'] as String),
          order: m['order'] as int,
          imagePath: localImagePath,
        ));
      }
    }

    // Restore documents
    for (int i = 0; i < documentsRaw.length; i++) {
      final m = documentsRaw[i] as Map<String, dynamic>;
      _updateProgress('Restoring document ${i + 1}/${documentsRaw.length}…');

      final id       = m['id']       as String;
      final fileType = m['fileType'] as String;
      final driveId  = m['driveFileId'] as String?;

      String localFilePath = '';
      if (driveId != null) {
        try {
          final dlDir = Directory('${appDir.path}/restored_documents');
          await dlDir.create(recursive: true);
          localFilePath = '${dlDir.path}/$id.$fileType';
          final fileBytes = await _download(api, driveId);
          await File(localFilePath).writeAsBytes(fileBytes);
        } catch (_) {
          localFilePath = ''; // file unavailable
        }
      }

      final existing = ShelfServices.getDocuments(m['categoryId'] as String)
          .where((d) => d.id == id);
      if (existing.isEmpty) {
        await ShelfServices.addDocument(BookDocument(
          id: id,
          categoryId: m['categoryId'] as String,
          name: m['name'] as String,
          filePath: localFilePath,
          fileType: fileType,
          addedAt: DateTime.parse(m['addedAt'] as String),
          fileSizeBytes: m['fileSizeBytes'] as int,
        ));
      }
    }

    _updateProgress('Restore complete! ✓');
    } finally {
      isRestoring = false;
      notifyListeners();
    }
  }
}
