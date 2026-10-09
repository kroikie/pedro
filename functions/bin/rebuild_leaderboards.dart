import 'dart:io';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:functions/game/leaderboard.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';

void printUsage() {
  stdout.writeln('''
Usage: dart run bin/rebuild_leaderboards.dart [options]

Deterministically reconciles all Pedro leaderboard and head-to-head rivalry
rollups from persisted round archives (`games/{gameId}/rounds/*`).
Legacy games missing the `rounds` subcollection are automatically ignored.

Options:
  --dry-run   Simulate the rebuild without writing or deleting Firestore documents.
  --help      Show this help message.
''');
}

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    printUsage();
    return;
  }

  final isDryRun = args.contains('--dry-run');

  stdout.writeln('============================================================');
  stdout.writeln('  Pedro Leaderboard & Rivalry Reconciliation CLI Tool');
  stdout.writeln(
    '  Mode: ${isDryRun ? "DRY-RUN (no Firestore mutations)" : "LIVE RECONCILIATION"}',
  );
  stdout.writeln('============================================================\n');

  FirebaseApp.initializeApp();
  final firestore = Firestore();

  try {
    final summary = await rebuildAllLeaderboards(
      firestore,
      isDryRun: isDryRun,
      onLog: (msg) => stdout.writeln('  $msg'),
    );

    stdout.writeln('\n============================================================');
    stdout.writeln('  Reconciliation Summary:');
    stdout.writeln(
      '  Games With Rounds Reconciled        : ${summary.gamesWithRoundsReconciled}',
    );
    stdout.writeln(
      '  Legacy Games Without Rounds Ignored : ${summary.legacyGamesIgnored}',
    );
    stdout.writeln(
      '  Total Archived Rounds Scanned       : ${summary.totalRoundsScanned}',
    );
    stdout.writeln(
      '  Periods Rebuilt                     : ${summary.periodsRebuilt.isEmpty ? "None" : summary.periodsRebuilt.join(", ")}',
    );
    stdout.writeln(
      '  Player Rollups ${isDryRun ? "(Simulated)     " : "Written         "}    : ${summary.playerRollupsWritten}',
    );
    stdout.writeln(
      '  Rivalry Rollups ${isDryRun ? "(Simulated)    " : "Written        "}    : ${summary.rivalryRollupsWritten}',
    );
    stdout.writeln('============================================================');

    if (isDryRun) {
      stdout.writeln(
        '\n* Note: Dry-run completed. Re-run without --dry-run to apply changes.',
      );
    }
  } catch (e, st) {
    stderr.writeln('\n[!] Fatal error during leaderboard reconciliation: $e');
    stderr.writeln(st);
    exitCode = 1;
  } finally {
    await firestore.terminate();
  }
}
