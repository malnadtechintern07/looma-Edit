/// Abstract remote data source for cloud authentication and cross-device account sync
abstract class AuthRemoteDataSource {
  /// Fetch an account from the cloud by email (case-insensitive)
  Future<Map<String, dynamic>?> getAccountByEmail(String email);

  /// Fetch an account from the cloud by unique user ID
  Future<Map<String, dynamic>?> getAccountById(String id);

  /// Save a newly registered account to the cloud
  Future<bool> saveAccount(Map<String, dynamic> accountData);

  /// Update existing account credentials or profile data in the cloud
  Future<bool> updateAccount(Map<String, dynamic> accountData);

  /// Register a new account on the server with email, password, and displayName
  Future<Map<String, dynamic>> register(String email, String password, String displayName);

  /// Authenticate with the server using email and password
  Future<Map<String, dynamic>?> login(String email, String password);

  /// Check whether an email is registered on the server
  Future<bool> checkEmailExists(String email);

  /// Request password reset on the server
  Future<bool> forgotPassword(String email, String newPassword);
}
