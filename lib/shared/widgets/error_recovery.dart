import 'package:flutter/material.dart';

/// Collection of error recovery UI components with helpful suggestions
class ErrorRecovery {
  /// Generic error widget with recovery options
  static Widget create({
    required BuildContext context,
    required String title,
    required String message,
    IconData? icon,
    String? primaryActionText,
    VoidCallback? onPrimaryAction,
    String? secondaryActionText,
    VoidCallback? onSecondaryAction,
    List<String>? suggestions,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 64,
                    color: iconColor ?? theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (suggestions != null && suggestions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Try these solutions:',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...suggestions.map((suggestion) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  suggestion,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (secondaryActionText != null && onSecondaryAction != null) ...[
                      OutlinedButton(
                        onPressed: onSecondaryAction,
                        child: Text(secondaryActionText),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (primaryActionText != null && onPrimaryAction != null)
                      ElevatedButton(
                        onPressed: onPrimaryAction,
                        child: Text(primaryActionText),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Network error recovery widget
class NetworkErrorRecovery extends StatelessWidget {

  const NetworkErrorRecovery({
    super.key,
    this.onRetry,
    this.onGoOffline,
  });
  final VoidCallback? onRetry;
  final VoidCallback? onGoOffline;

  @override
  Widget build(BuildContext context) => ErrorRecovery.create(
      context: context,
      title: 'Connection Problem',
      message: "We're having trouble connecting to our servers. Don't worry, your progress is saved locally!",
      icon: Icons.wifi_off,
      primaryActionText: 'Try Again',
      onPrimaryAction: onRetry,
      secondaryActionText: 'Continue Offline',
      onSecondaryAction: onGoOffline,
      suggestions: [
        'Check your internet connection',
        "Make sure you're connected to Wi-Fi or mobile data",
        'Try switching between Wi-Fi and mobile data',
        'Restart your router if using Wi-Fi',
        'The app works offline - your data will sync later',
      ],
      iconColor: Colors.orange,
    );
}

/// Sync error recovery widget
class SyncErrorRecovery extends StatelessWidget {

  const SyncErrorRecovery({
    super.key,
    this.onRetrySync,
    this.onViewOfflineData,
    this.pendingChanges,
  });
  final VoidCallback? onRetrySync;
  final VoidCallback? onViewOfflineData;
  final int? pendingChanges;

  @override
  Widget build(BuildContext context) {
    final changesText = pendingChanges != null && pendingChanges! > 0
        ? 'You have $pendingChanges unsaved changes that will sync when the connection is restored.'
        : 'Your recent changes are saved locally and will sync automatically.';

    return ErrorRecovery.create(
      context: context,
      title: 'Sync Failed',
      message: "We couldn't sync your latest changes to the cloud. $changesText",
      icon: Icons.sync_problem,
      primaryActionText: 'Retry Sync',
      onPrimaryAction: onRetrySync,
      secondaryActionText: 'Continue Working',
      onSecondaryAction: onViewOfflineData,
      suggestions: [
        'Check your internet connection',
        'Your data is safe and stored locally',
        'Sync will happen automatically when connection improves',
        'You can continue using the app normally',
      ],
      iconColor: Colors.amber,
    );
  }
}

/// Database error recovery widget
class DatabaseErrorRecovery extends StatelessWidget {

  const DatabaseErrorRecovery({
    super.key,
    this.onRetry,
    this.onResetData,
    this.onContactSupport,
  });
  final VoidCallback? onRetry;
  final VoidCallback? onResetData;
  final VoidCallback? onContactSupport;

  @override
  Widget build(BuildContext context) => ErrorRecovery.create(
      context: context,
      title: 'Data Error',
      message: 'We encountered a problem accessing your data. This is usually temporary and can be fixed.',
      icon: Icons.storage,
      primaryActionText: 'Try Again',
      onPrimaryAction: onRetry,
      secondaryActionText: 'Get Help',
      onSecondaryAction: onContactSupport,
      suggestions: [
        'Close and reopen the app',
        'Restart your device',
        'Make sure you have enough storage space',
        'Your data should be recoverable',
        'Contact support if the problem persists',
      ],
      iconColor: Colors.red,
    );
}

/// Permission error recovery widget
class PermissionErrorRecovery extends StatelessWidget {

  const PermissionErrorRecovery({
    required this.permissionType, super.key,
    this.onOpenSettings,
    this.onSkip,
  });
  final String permissionType;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) => ErrorRecovery.create(
      context: context,
      title: 'Permission Required',
      message: 'We need $permissionType permission to provide you with the best experience. You can enable this in your device settings.',
      icon: Icons.security,
      primaryActionText: 'Open Settings',
      onPrimaryAction: onOpenSettings,
      secondaryActionText: 'Skip for Now',
      onSecondaryAction: onSkip,
      suggestions: [
        'Go to your device Settings',
        'Find this app in the app list',
        'Enable $permissionType permission',
        'Return to the app',
        'Some features may be limited without this permission',
      ],
      iconColor: Colors.blue,
    );
}

/// Generic app crash recovery widget
class CrashRecovery extends StatelessWidget {

  const CrashRecovery({
    super.key,
    this.onRestart,
    this.onReportBug,
    this.errorDetails,
  });
  final VoidCallback? onRestart;
  final VoidCallback? onReportBug;
  final String? errorDetails;

  @override
  Widget build(BuildContext context) => ErrorRecovery.create(
      context: context,
      title: 'Oops! Something Went Wrong',
      message: "The app encountered an unexpected error. Don't worry - your progress is saved and we're working to fix this.",
      icon: Icons.error_outline,
      primaryActionText: 'Restart App',
      onPrimaryAction: onRestart,
      secondaryActionText: 'Report Bug',
      onSecondaryAction: onReportBug,
      suggestions: [
        'Your progress and data are safe',
        'Try restarting the app',
        'Update to the latest version if available',
        'Report the bug to help us improve',
        'Contact support if the problem continues',
      ],
      iconColor: Colors.red,
    );
}

/// Loading timeout error recovery widget
class TimeoutErrorRecovery extends StatelessWidget {

  const TimeoutErrorRecovery({
    super.key,
    this.onRetry,
    this.onGoOffline,
  });
  final VoidCallback? onRetry;
  final VoidCallback? onGoOffline;

  @override
  Widget build(BuildContext context) => ErrorRecovery.create(
      context: context,
      title: 'Taking Too Long',
      message: 'The request is taking longer than expected. This might be due to a slow connection or server issues.',
      icon: Icons.hourglass_empty,
      primaryActionText: 'Try Again',
      onPrimaryAction: onRetry,
      secondaryActionText: 'Work Offline',
      onSecondaryAction: onGoOffline,
      suggestions: [
        'Check your internet speed',
        'Try switching to a different network',
        'The servers might be busy - try again in a moment',
        'You can continue working offline',
      ],
      iconColor: Colors.orange,
    );
}

/// Version mismatch error recovery widget
class VersionMismatchRecovery extends StatelessWidget {

  const VersionMismatchRecovery({
    super.key,
    this.onUpdate,
    this.onContinue,
    this.currentVersion,
    this.requiredVersion,
  });
  final VoidCallback? onUpdate;
  final VoidCallback? onContinue;
  final String? currentVersion;
  final String? requiredVersion;

  @override
  Widget build(BuildContext context) {
    final versionText = currentVersion != null && requiredVersion != null
        ? "You're using version $currentVersion, but version $requiredVersion is required."
        : 'Your app version is outdated.';

    return ErrorRecovery.create(
      context: context,
      title: 'Update Required',
      message: '$versionText Please update to continue enjoying all features.',
      icon: Icons.system_update,
      primaryActionText: 'Update Now',
      onPrimaryAction: onUpdate,
      secondaryActionText: 'Continue Anyway',
      onSecondaryAction: onContinue,
      suggestions: [
        'Update from the App Store or Google Play',
        'New versions include bug fixes and improvements',
        'Some features may not work with older versions',
        'Updates are usually quick and automatic',
      ],
      iconColor: Colors.blue,
    );
  }
}

/// Storage full error recovery widget
class StorageFullRecovery extends StatelessWidget {

  const StorageFullRecovery({
    super.key,
    this.onClearCache,
    this.onManageStorage,
  });
  final VoidCallback? onClearCache;
  final VoidCallback? onManageStorage;

  @override
  Widget build(BuildContext context) => ErrorRecovery.create(
      context: context,
      title: 'Storage Full',
      message: 'Your device is running low on storage space. Free up some space to continue using the app smoothly.',
      icon: Icons.storage,
      primaryActionText: 'Clear Cache',
      onPrimaryAction: onClearCache,
      secondaryActionText: 'Manage Storage',
      onSecondaryAction: onManageStorage,
      suggestions: [
        'Delete unused apps or files',
        'Clear app cache and temporary files',
        'Move photos and videos to cloud storage',
        'Remove downloaded content you no longer need',
        'Restart your device after freeing space',
      ],
      iconColor: Colors.orange,
    );
}

/// Error boundary widget that catches and displays errors
class ErrorBoundary extends StatefulWidget {

  const ErrorBoundary({
    required this.child, super.key,
    this.errorBuilder,
  });
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!, _stackTrace) ??
          CrashRecovery(
            onRestart: () {
              setState(() {
                _error = null;
                _stackTrace = null;
              });
            },
            errorDetails: _error.toString(),
          );
    }

    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FlutterError.onError = (details) {
      setState(() {
        _error = details.exception;
        _stackTrace = details.stack;
      });
    };
  }
}

/// Retry button with loading state
class RetryButton extends StatefulWidget {

  const RetryButton({
    required this.onRetry, super.key,
    this.text = 'Try Again',
    this.isLoading = false,
  });
  final VoidCallback onRetry;
  final String text;
  final bool isLoading;

  @override
  State<RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<RetryButton> {
  bool _isRetrying = false;

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.isLoading || _isRetrying;

    return ElevatedButton.icon(
      onPressed: isLoading ? null : _handleRetry,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh),
      label: Text(isLoading ? 'Retrying...' : widget.text),
    );
  }

  Future<void> _handleRetry() async {
    setState(() {
      _isRetrying = true;
    });

    try {
      widget.onRetry();
      // Add a small delay to show the loading state
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }
}