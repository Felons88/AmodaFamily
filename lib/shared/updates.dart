/// Update checker — compares the installed version against a remote
/// manifest and offers a download link. For Play Store builds the same
/// surface can be swapped to the in-app-update API; sideloaded APKs use the
/// manifest flow below.
///
/// Manifest JSON (hosted anywhere, e.g. GitHub Releases or Supabase Storage):
///   { "version": "0.2.0", "build": 2, "apkUrl": "https://…/app-release.apk",
///     "notes": "What's new", "mandatory": false }
///
/// Configure with --dart-define=UPDATE_MANIFEST_URL=https://…/version.json
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  const UpdateInfo({required this.version, required this.build, required this.apkUrl, this.notes, this.mandatory = false});

  final String version;
  final int build;
  final String apkUrl;
  final String? notes;
  final bool mandatory;
}

class UpdateChecker {
  static const manifestUrl = String.fromEnvironment('UPDATE_MANIFEST_URL');

  /// Returns update info when the remote build is newer, else null.
  /// Silent on any failure — an update check must never break the app.
  static Future<UpdateInfo?> check() async {
    if (manifestUrl.isEmpty) return null;
    try {
      final res = await http.get(Uri.parse(manifestUrl)).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final remoteBuild = (body['build'] as num?)?.toInt() ?? 0;
      final remoteVersion = body['version'] as String? ?? '';
      final apkUrl = body['apkUrl'] as String? ?? '';
      if (remoteVersion.isEmpty || apkUrl.isEmpty) return null;
      final info = await PackageInfo.fromPlatform();
      final localBuild = int.tryParse(info.buildNumber) ?? 0;
      final localNewer = _compareVersion(info.version, remoteVersion) >= 0 && localBuild >= remoteBuild;
      if (localNewer) return null;
      return UpdateInfo(
        version: remoteVersion,
        build: remoteBuild,
        apkUrl: apkUrl,
        notes: body['notes'] as String?,
        mandatory: body['mandatory'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  static int _compareVersion(String a, String b) {
    final pa = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final pb = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }

  static Future<void> promptIfAvailable(BuildContext context) async {
    final update = await check();
    if (update == null || !context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: !update.mandatory,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update available: ${update.version}'),
        content: Text(update.notes?.isNotEmpty == true ? update.notes! : 'A newer version of Family Circle is ready.'),
        actions: [
          if (!update.mandatory)
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Later')),
          FilledButton.icon(
            icon: const Icon(Icons.download_outlined),
            label: const Text('Download'),
            onPressed: () {
              launchUrl(Uri.parse(update.apkUrl), mode: LaunchMode.externalApplication);
              if (!update.mandatory) Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    );
  }
}
