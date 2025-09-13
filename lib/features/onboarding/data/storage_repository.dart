import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../app/di/main_di.dart';
import '../../../app/debug/debug_settings.dart';

// Configure your bucket URL here (can be overridden by reading this provider).
final storageBucketProvider = Provider<String>((ref) {
  return 'gs://filmin-2a766.firebasestorage.app';
});

// Optional: subfolder to list (e.g., 'onboarding/')
final storageFolderProvider = Provider<String>((ref) => '');

final storageImageUrlsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final bucket = ref.watch(storageBucketProvider);
  final folder = ref.watch(storageFolderProvider);

  // Ensure Firebase is initialized, otherwise degrade gracefully.
  final ok = await ref.read(firebaseInitProvider.future);
  if (!ok || Firebase.apps.isEmpty) {
    wlog('Skipping Storage fetch: Firebase not initialized.');
    return <String>[];
  }

  try {
    final storage = FirebaseStorage.instanceFor(bucket: bucket);
    final refFolder = storage.ref(folder);
    final result = await refFolder.listAll();
    final items = result.items;
    // If you also want to include subfolders, iterate result.prefixes and listAll again.
    final urls = await Future.wait(items.map((i) => i.getDownloadURL()));
    // Newest first if filenames sort lexicographically by time; otherwise leave as-is
    return urls.reversed.toList();
  } on FirebaseException catch (e, st) {
    // No default app / permission errors etc. -> warn and degrade
    wlog('Storage fetch failed: ${e.code} ${e.message}', st);
    return <String>[];
  } catch (e, st) {
    wlog('Storage fetch failed: $e', st);
    return <String>[];
  }
});
