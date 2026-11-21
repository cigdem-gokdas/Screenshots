import '../l10n/app_localizations.dart';
import '../sync/screenshot_sync.dart';
import '../sync/sync_models.dart';

String permissionLabel(PhotoAccess access, AppLocalizations l) =>
    switch (access) {
      PhotoAccess.notDetermined => l.accessNotDetermined,
      PhotoAccess.authorized => l.accessAuthorized,
      PhotoAccess.limited => l.accessLimited,
      PhotoAccess.denied => l.accessDenied,
      PhotoAccess.restricted => l.accessRestricted,
    };
String syncLabel(ScreenshotSync sync, AppLocalizations l) {
  if (!sync.supported) return l.syncIOSOnly;
  if (sync.activity == SyncActivity.error) return l.syncError;
  if (sync.initialized && !sync.permissionKnown) {
    return l.photoAccessUnavailable;
  }
  if (!sync.config.enabled && sync.activity != SyncActivity.error) {
    return l.syncOff;
  }
  if (sync.config.enabled &&
      !sync.permission.canRead &&
      sync.activity != SyncActivity.checking) {
    return permissionLabel(sync.permission, l);
  }
  return switch (sync.activity) {
    SyncActivity.off => l.syncOff,
    SyncActivity.checking => l.syncChecking,
    SyncActivity.scanning => l.syncScanning,
    SyncActivity.processing => l.syncProcessing,
    SyncActivity.idle =>
      sync.permission == PhotoAccess.limited ? l.accessLimited : l.syncIdle,
    SyncActivity.waiting => l.syncWaiting,
    SyncActivity.paused => l.syncPaused,
    SyncActivity.error => l.syncError,
    SyncActivity.unsupported => l.syncIOSOnly,
  };
}
