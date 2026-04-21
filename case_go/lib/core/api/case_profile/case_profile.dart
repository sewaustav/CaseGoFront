abstract class CaseProfileApi {
  /// Returns skills profile: {user_id, total_cases, assertiveness, empathy, ...}
  Future<Map<String, dynamic>> getSkillsProfile();

  /// Returns list of result history entries. [from] is ISO-8601 date.
  Future<List<Map<String, dynamic>>> getHistory({String? from});
}
