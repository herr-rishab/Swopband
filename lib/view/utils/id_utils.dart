String? normalizeBackendUserId(dynamic raw) {
  if (raw == null) {
    return null;
  }

  if (raw is String) {
    final value = raw.trim();
    return value.isEmpty ? null : value;
  }

  if (raw is num) {
    return raw.toString();
  }

  if (raw is Map) {
    const preferredKeys = ['id', 'uuid', 'value', '_id', 'uid'];
    for (final key in preferredKeys) {
      if (raw.containsKey(key)) {
        final normalized = normalizeBackendUserId(raw[key]);
        if (normalized != null && normalized.isNotEmpty) {
          return normalized;
        }
      }
    }
    if (raw.length == 1) {
      final normalized = normalizeBackendUserId(raw.values.first);
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    }
  }

  if (raw is Iterable && raw.isNotEmpty) {
    final normalized = normalizeBackendUserId(raw.first);
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
  }

  return raw.toString();
}
