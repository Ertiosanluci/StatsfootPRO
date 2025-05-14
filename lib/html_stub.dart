/// This is a stub file that provides empty implementations of html classes
/// for platforms other than web, so the imports don't break
library html;

/// A stub implementation of html.File for non-web platforms
class File {
  // Add any necessary properties or methods used in the app
}

/// A stub implementation of html.Url for non-web platforms  
class Url {
  // Add any necessary properties or methods used in the app
  static String createObjectUrlFromBlob(Object blob) => '';
  static void revokeObjectUrl(String url) {}
}
