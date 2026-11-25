class SyncPlan<T> {
  final Map<int, T> merged;
  final List<T> toUpload;

  const SyncPlan({required this.merged, required this.toUpload});
}

SyncPlan<T> planSync<T>({
  required Map<int, T> local,
  required Map<int, T> cloud,
  required Set<int> pending,
}) {
  final merged = <int, T>{};
  final toUpload = <T>[];

  for (final id in {...local.keys, ...cloud.keys}) {
    final localRecord = local[id];
    final cloudRecord = cloud[id];

    if (localRecord != null && pending.contains(id)) {
      merged[id] = localRecord;
    } else if (cloudRecord != null) {
      merged[id] = cloudRecord;
    } else {
      merged[id] = localRecord as T;
      toUpload.add(localRecord);
    }
  }

  return SyncPlan(merged: merged, toUpload: toUpload);
}
