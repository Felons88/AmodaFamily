/// Update checker — auto-detects new builds from a remote manifest, offers
/// in-app download, and hands the APK to Android's package installer so the
/// user only has to tap "Update". Falls back to the browser on any failure.
///
/// Manifest JSON: { "version": "0.2.0", "build": 2,
///   "apkUrl": "https://…/app-release.apk", "notes": "…", "mandatory": false }
/// Configure with --dart-define=UPDATE_MANIFEST_URL=https://…/version.json
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
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
      final remoteIsNewer = remoteBuild > localBuild || _compareVersion(remoteVersion, info.version) > 0;
      if (!remoteIsNewer) return null;
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
        content: Text(update.notes?.isNotEmpty == true ? update.notes! : 'A newer version of Kinplora is ready.'),
        actions: [
          if (!update.mandatory)
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Later')),
          FilledButton.icon(
            icon: const Icon(Icons.system_update_alt),
            label: const Text('Update now'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _downloadAndInstall(context, update);
            },
          ),
        ],
      ),
    );
  }

  /// Streams the APK to temp storage with a progress dialog, then opens the
  /// platform installer (REQUEST_INSTALL_PACKAGES is in the manifest).
  static Future<void> _downloadAndInstall(BuildContext context, UpdateInfo update) async {
    final progress = ValueNotifier<double>(0);
    var cancelled = false;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Downloading update'),
          content: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (context, p, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: p == 0 ? null : p),
                const SizedBox(height: 12),
                Text('${(p * 100).round()}%'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                cancelled = true;
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );

    try {
      final request = http.Request('GET', Uri.parse(update.apkUrl));
      final response = await request.send().timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) throw StateError('download_failed');
      final total = response.contentLength ?? 0;
      final file = File('${Directory.systemTemp.path}/family-circle-update.apk');
      final sink = file.openWrite();
      var received = 0;
      await for (final chunk in response.stream) {
        if (cancelled) {
          await sink.close();
          await file.delete();
          return;
        }
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) progress.value = received / total;
      }
      await sink.close();
      progress.value = 1;
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // close progress
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) throw StateError('open_failed');
    } catch (_) {
      if (!context.mounted) return;
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      launchUrl(Uri.parse(update.apkUrl), mode: LaunchMode.externalApplication);
    }
  }
}
