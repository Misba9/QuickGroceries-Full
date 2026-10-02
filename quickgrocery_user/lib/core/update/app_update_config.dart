/// Remote Config payload for in-app updates.
class AppUpdateConfig {
  const AppUpdateConfig({
    required this.minimumSupportedVersion,
    required this.latestVersion,
    required this.forceUpdate,
    required this.updateTitle,
    required this.updateMessage,
  });

  final String minimumSupportedVersion;
  final String latestVersion;
  final bool forceUpdate;
  final String updateTitle;
  final String updateMessage;

  static const defaults = AppUpdateConfig(
    minimumSupportedVersion: '0.0.0',
    latestVersion: '0.0.0',
    forceUpdate: false,
    updateTitle: 'New Update Available',
    updateMessage:
        "We've added new features and improved performance.",
  );

  factory AppUpdateConfig.fromJson(Map<String, dynamic> json) {
    return AppUpdateConfig(
      minimumSupportedVersion:
          (json['minimum_supported_version'] ?? '0.0.0').toString().trim(),
      latestVersion: (json['latest_version'] ?? '0.0.0').toString().trim(),
      forceUpdate: json['force_update'] == true ||
          json['force_update']?.toString().toLowerCase() == 'true',
      updateTitle: (json['update_title'] ?? defaults.updateTitle)
          .toString()
          .trim(),
      updateMessage: (json['update_message'] ?? defaults.updateMessage)
          .toString()
          .trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'minimum_supported_version': minimumSupportedVersion,
        'latest_version': latestVersion,
        'force_update': forceUpdate,
        'update_title': updateTitle,
        'update_message': updateMessage,
      };
}

/// Decision after comparing installed version to [AppUpdateConfig].
class UpdateDecision {
  const UpdateDecision({
    required this.installedVersion,
    required this.config,
    required this.updateAvailable,
    required this.forceUpdate,
  });

  final String installedVersion;
  final AppUpdateConfig config;
  final bool updateAvailable;
  final bool forceUpdate;

  bool get shouldPrompt => updateAvailable || forceUpdate;
}
