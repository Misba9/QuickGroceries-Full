/// How Play / App Store updates are enforced.
enum UpdateMode {
  /// Feature off — never prompt.
  disabled,

  /// Android flexible only; iOS optional dialog.
  flexible,

  /// Android immediate only; iOS force dialog.
  immediate,

  /// Decide from Remote Config (`force_update` / min version).
  remoteControlled,
}
