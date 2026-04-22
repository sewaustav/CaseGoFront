abstract class AdminApi {
  Future<List<Map<String, dynamic>>> getUsers();
  Future<Map<String, dynamic>> updateUserRole(int userId, int role);
}
