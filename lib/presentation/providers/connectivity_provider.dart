import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core_providers.dart';

/// True while the device has network connectivity. Starts by resolving the
/// current status, then follows live changes.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield await service.isOnlineNow();
  yield* service.onStatusChange;
});
