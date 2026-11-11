/// Keeps what is on the screen out of screenshots, screen recordings and the app switcher preview, for as long as
/// something sensitive, such as a whole Aadhaar number, is shown.
abstract interface class ScreenProtection {
  /// Starts keeping the screen out of them. Asking again changes nothing.
  Future<void> protect();

  /// Lets go of it. Asking when it is not on changes nothing.
  Future<void> release();
}
