import 'package:case_go/core/api/cases/cases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Models ────────────────────────────────────────────────────────────────────

enum MessageRole { user, ai }

int _messageIdCounter = 0;

class ChatMessage {
  final int id;
  final String text;
  final MessageRole role;
  final bool isTyping;
  final int? step;

  ChatMessage({
    required this.text,
    required this.role,
    this.isTyping = false,
    this.step,
  }) : id = _messageIdCounter++;

  ChatMessage._withId({
    required this.id,
    required this.text,
    required this.role,
    required this.isTyping,
    required this.step,
  });

  ChatMessage copyWith({String? text, bool? isTyping}) => ChatMessage._withId(
        id: id,
        text: text ?? this.text,
        role: role,
        isTyping: isTyping ?? this.isTyping,
        step: step,
      );
}

// ── State ─────────────────────────────────────────────────────────────────────

abstract class DialogState {}

class DialogInitial extends DialogState {}

class DialogLoading extends DialogState {}

class DialogActive extends DialogState {
  final int dialogId;
  final int caseId;
  final String caseTopic;
  final List<ChatMessage> messages;
  final int currentStep;
  final String currentQuestion;
  final bool isSending;
  final bool canComplete;

  DialogActive({
    required this.dialogId,
    required this.caseId,
    required this.caseTopic,
    required this.messages,
    required this.currentStep,
    required this.currentQuestion,
    this.isSending = false,
    this.canComplete = false,
  });

  DialogActive copyWith({
    List<ChatMessage>? messages,
    int? currentStep,
    String? currentQuestion,
    bool? isSending,
    bool? canComplete,
  }) =>
      DialogActive(
        dialogId: dialogId,
        caseId: caseId,
        caseTopic: caseTopic,
        messages: messages ?? this.messages,
        currentStep: currentStep ?? this.currentStep,
        currentQuestion: currentQuestion ?? this.currentQuestion,
        isSending: isSending ?? this.isSending,
        canComplete: canComplete ?? this.canComplete,
      );
}

class DialogCompleted extends DialogState {
  final Map<String, dynamic> result;
  DialogCompleted(this.result);
}

class DialogError extends DialogState {
  final String message;
  DialogError(this.message);
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class DialogCubit extends Cubit<DialogState> {
  final CaseGoApi _api;
  static const _minStepsToComplete = 2;

  DialogCubit(this._api) : super(DialogInitial());

  Future<void> startDialog(int caseId, String caseTopic) async {
    emit(DialogLoading());
    try {
      final data = await _api.startCase(caseId);
      final dialogId = (data['dialog_id'] as num).toInt();
      final question = data['question'] as String? ??
          data['first_question'] as String? ??
          'Первый вопрос';
      final step = (data['step'] as num?)?.toInt() ?? 0;

      emit(DialogActive(
        dialogId: dialogId,
        caseId: caseId,
        caseTopic: caseTopic,
        messages: [
          ChatMessage(text: question, role: MessageRole.ai, step: step),
        ],
        currentStep: step,
        currentQuestion: question,
        canComplete: step >= _minStepsToComplete,
      ));
    } catch (e) {
      emit(DialogError(e.toString()));
    }
  }

  Future<void> sendAnswer(String answer) async {
    final current = state;
    if (current is! DialogActive || current.isSending) return;

    final userMsg = ChatMessage(text: answer, role: MessageRole.user);
    final typingMsg =
        ChatMessage(text: '', role: MessageRole.ai, isTyping: true);

    emit(current.copyWith(
      messages: [...current.messages, userMsg, typingMsg],
      isSending: true,
    ));

    try {
      final data = await _api.sendInteraction(
        current.dialogId,
        {
          'dialog_id': current.dialogId,
          'step': current.currentStep,
          'question': current.currentQuestion,
          'answer': answer,
        },
      );

      final nextQuestion = data['question'] as String? ?? '';
      final nextStep =
          (data['step'] as num?)?.toInt() ?? (current.currentStep + 1);

      final msgs = [...current.messages, userMsg]
        ..add(ChatMessage(
            text: nextQuestion, role: MessageRole.ai, step: nextStep));

      emit(current.copyWith(
        messages: msgs,
        currentStep: nextStep,
        currentQuestion: nextQuestion,
        isSending: false,
        canComplete: nextStep >= _minStepsToComplete,
      ));
    } catch (e) {
      // Remove typing indicator on error
      final msgs = [...current.messages, userMsg];
      emit(current.copyWith(
        messages: msgs,
        isSending: false,
      ));
    }
  }

  Future<void> completeDialog() async {
    final current = state;
    if (current is! DialogActive) return;
    emit(current.copyWith(isSending: true));
    try {
      final result = await _api.completeDialog(current.dialogId);
      emit(DialogCompleted(result));
    } catch (e) {
      emit(current.copyWith(isSending: false));
    }
  }
}
