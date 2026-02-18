class AppState {
  static String? selectedDriverId;
  static bool isAdmin = false;

  static void selectAdmin() {
    isAdmin = true;
    selectedDriverId = null;
  }

  static void selectDriver(String driverId) {
    isAdmin = false;
    selectedDriverId = driverId;
  }
}
