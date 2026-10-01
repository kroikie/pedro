import 'dart:io';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:firebase_admin_sdk/auth.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';

void printUsage() {
  stdout.writeln('''
Usage: dart run bin/backfill_google_avatars.dart [options]

Options:
  --dry-run   Simulate the backfill without writing changes to Firestore.
  --force     Overwrite existing avatarUrl even if one is already set.
  --help      Show this help message.
''');
}

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    printUsage();
    return;
  }

  final isDryRun = args.contains('--dry-run');
  final isForce = args.contains('--force');

  stdout.writeln('==================================================');
  stdout.writeln('  Pedro Google Sign-In Avatar Backfill Tool');
  stdout.writeln('  Mode: ${isDryRun ? "DRY-RUN (no mutations)" : "LIVE"} | Force: $isForce');
  stdout.writeln('==================================================\n');

  final app = FirebaseApp.initializeApp();
  final auth = app.auth();
  final firestore = Firestore();

  int totalScanned = 0;
  int googleUsersFound = 0;
  int avatarsUpdated = 0;
  int avatarsSkipped = 0;
  int errorsEncountered = 0;

  String? pageToken;

  do {
    final listResult = await auth.listUsers(maxResults: 500, pageToken: pageToken);
    final users = listResult.users;
    totalScanned += users.length;

    for (final user in users) {
      // Check if user has Google provider
      final googleProvider = user.providerData.cast<UserInfo?>().firstWhere(
            (p) => p?.providerId == 'google.com',
            orElse: () => null,
          );

      if (googleProvider == null) {
        // Not a Google user
        continue;
      }

      googleUsersFound++;

      // Determine photo URL: check provider photoUrl, falling back to top-level user photoUrl
      final googlePhoto = googleProvider.photoUrl ?? user.photoUrl;
      if (googlePhoto == null || googlePhoto.trim().isEmpty) {
        stdout.writeln('[-] User ${user.uid} (${user.displayName ?? "No Name"}): Google account has no photo. Skipped.');
        avatarsSkipped++;
        continue;
      }

      try {
        final docRef = firestore.collection('users').doc(user.uid);
        final docSnapshot = await docRef.get();
        final currentData = docSnapshot.data();
        final currentAvatar = currentData?['avatarUrl'] as String?;

        final needsUpdate = isForce || currentAvatar == null || currentAvatar.trim().isEmpty;

        if (!needsUpdate) {
          stdout.writeln('[=] User ${user.uid} (${user.displayName ?? "No Name"}): Already has avatar ($currentAvatar). Skipped.');
          avatarsSkipped++;
          continue;
        }

        if (isDryRun) {
          stdout.writeln('[DRY-RUN] Would update user ${user.uid} (${user.displayName ?? "No Name"}):');
          stdout.writeln('          avatarUrl -> $googlePhoto');
          avatarsUpdated++;
        } else {
          await docRef.set({
            'avatarUrl': googlePhoto,
            if (currentData?['screenName'] == null && user.displayName != null)
              'screenName': user.displayName,
          }, options: const SetOptions.merge());

          stdout.writeln('[+] UPDATED user ${user.uid} (${user.displayName ?? "No Name"}):');
          stdout.writeln('    avatarUrl -> $googlePhoto');
          avatarsUpdated++;
        }
      } catch (e) {
        stderr.writeln('[!] Error processing user ${user.uid}: $e');
        errorsEncountered++;
      }
    }

    pageToken = listResult.pageToken;
  } while (pageToken != null && pageToken.isNotEmpty);

  stdout.writeln('\n==================================================');
  stdout.writeln('  Backfill Summary:');
  stdout.writeln('  Total Auth Users Scanned : $totalScanned');
  stdout.writeln('  Google Accounts Found    : $googleUsersFound');
  stdout.writeln('  Avatars Updated          : $avatarsUpdated');
  stdout.writeln('  Avatars Skipped          : $avatarsSkipped');
  stdout.writeln('  Errors                   : $errorsEncountered');
  stdout.writeln('==================================================');

  if (isDryRun) {
    stdout.writeln('\n* Note: Dry-run completed. Re-run without --dry-run to apply mutations.');
  }
}
