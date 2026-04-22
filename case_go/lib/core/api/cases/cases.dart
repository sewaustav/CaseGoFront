abstract class CaseGoApi {
  Future<List<Map<String, dynamic>>> getCases({
    int limit = 20,
    int page = 1,
    String? topic,
    int? category,
  });

  Future<Map<String, dynamic>> getCaseById(int caseId);

  /// Starts a dialog for the given case.
  /// Returns CaseDto {dialog_id, question, model, step}.
  Future<Map<String, dynamic>> startCase(int caseId);

  /// Sends an interaction step in a dialog.
  /// Body: {dialog_id, step, question, answer}
  /// Returns CaseDto with next question.
  Future<Map<String, dynamic>> sendInteraction(
    int dialogId,
    Map<String, dynamic> body,
  );

  /// Completes the dialog and returns Result.
  Future<Map<String, dynamic>> completeDialog(int dialogId);

  /// Returns Conversation {dialog, interactions}.
  Future<Map<String, dynamic>> getDialogById(int dialogId);

  /// Returns list of user's dialogs.
  Future<List<Map<String, dynamic>>> getUserDialogs(
    int userId, {
    int limit = 20,
    int page = 1,
  });

  // Admin methods

  Future<Map<String, dynamic>> getStats();

  Future<Map<String, dynamic>> createCase(Map<String, dynamic> body);

  Future<Map<String, dynamic>> updateCase(int caseId, Map<String, dynamic> body);

  Future<void> deleteCase(int caseId);
}
