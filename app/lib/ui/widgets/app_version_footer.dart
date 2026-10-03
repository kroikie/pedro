import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/app_info_service.dart';

/// A reusable footer widget displaying the current app version and build number.
///
/// Features:
/// - Single tap: copies the formatted app version to the clipboard.
/// - Long press: copies a comprehensive diagnostic report (Version, Build, Platform, UID, Game ID).
class AppVersionFooter extends StatefulWidget {
  final AppInfoService? appInfoService;
  final String? userId;
  final String? gameId;
  final TextStyle? textStyle;
  final bool enableDiagnostics;

  const AppVersionFooter({
    super.key,
    this.appInfoService,
    this.userId,
    this.gameId,
    this.textStyle,
    this.enableDiagnostics = true,
  });

  @override
  State<AppVersionFooter> createState() => _AppVersionFooterState();
}

class _AppVersionFooterState extends State<AppVersionFooter> {
  late final AppInfoService _appInfoService =
      widget.appInfoService ?? AppInfoService();
  late Future<String> _versionFuture;

  @override
  void initState() {
    super.initState();
    _versionFuture = _appInfoService.getFormattedVersion();
  }

  Future<void> _copyVersion(String versionText) async {
    await Clipboard.setData(ClipboardData(text: versionText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App version copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _copyDiagnostics() async {
    String? effectiveUid = widget.userId;
    if (effectiveUid == null) {
      try {
        effectiveUid = FirebaseAuth.instance.currentUser?.uid;
      } catch (_) {
        effectiveUid = null;
      }
    }
    final diagnostics = await _appInfoService.getDiagnosticsInfo(
      userId: effectiveUid,
      gameId: widget.gameId,
    );
    await Clipboard.setData(ClipboardData(text: diagnostics));
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diagnostic details copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.outline,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    return FutureBuilder<String>(
      future: _versionFuture,
      builder: (context, snapshot) {
        final versionText = snapshot.data ?? 'Pedro';

        return Tooltip(
          message: widget.enableDiagnostics
              ? 'Tap to copy version, long-press for diagnostics'
              : 'Tap to copy version',
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: snapshot.hasData ? () => _copyVersion(versionText) : null,
            onLongPress: widget.enableDiagnostics && snapshot.hasData
                ? _copyDiagnostics
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                versionText,
                textAlign: TextAlign.center,
                style: widget.textStyle ?? defaultStyle,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Displays an informative About dialog for Pedro with application version
/// details and an action to copy full diagnostic info to the clipboard.
Future<void> showPedroAboutDialog(
  BuildContext context, {
  String? gameId,
  String? userId,
  AppInfoService? appInfoService,
}) async {
  final service = appInfoService ?? AppInfoService();
  final info = await service.getPackageInfo();
  String? currentUid = userId;
  if (currentUid == null) {
    try {
      currentUid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      currentUid = null;
    }
  }
  if (!context.mounted) return;

  final version = info.version.isNotEmpty ? info.version : '1.0.0';
  final build = info.buildNumber.isNotEmpty ? info.buildNumber : '1';

  showAboutDialog(
    context: context,
    applicationName: 'Pedro',
    applicationVersion: 'v$version (Build $build)',
    applicationIcon: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Text(
          '♠',
          style: TextStyle(color: Colors.white, fontSize: 28),
        ),
      ),
    ),
    children: [
      const SizedBox(height: 12),
      const Text(
        'Pedro is a fast-paced multiplayer card game with strategic bidding, real-time banter, and AI companions.',
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Diagnostics'),
            onPressed: () async {
              final diag = await service.getDiagnosticsInfo(
                userId: currentUid,
                gameId: gameId,
                forceRefresh: true,
              );
              await Clipboard.setData(ClipboardData(text: diag));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Diagnostic details copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.security, size: 16),
            label: const Text('Test Attestation (Live)'),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Testing App Check attestation with server...'),
                  duration: Duration(seconds: 1),
                ),
              );
              final result = await service.testAppCheckAttestation(forceRefresh: true);
              await Clipboard.setData(ClipboardData(text: result));
              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
          ),
        ],
      ),
    ],
  );
}
