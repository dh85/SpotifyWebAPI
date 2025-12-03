import Foundation

extension RestrictedFileTokenStore {
  /// Create a token store with a full file path.
  ///
  /// This is a convenience factory method that simplifies initialization when you have
  /// a complete file path instead of separate filename and directory components.
  ///
  /// ## Example
  /// ```swift
  /// let store = RestrictedFileTokenStore.at(
  ///     path: URL(fileURLWithPath: "~/.my_app_tokens")
  /// )
  /// ```
  ///
  /// - Parameter path: Full path to the token file
  /// - Returns: A configured `RestrictedFileTokenStore`
  public static func at(path: URL) -> RestrictedFileTokenStore {
    RestrictedFileTokenStore(
      filename: path.lastPathComponent,
      directory: path.deletingLastPathComponent()
    )
  }
}
