import 'dart:async';
import 'package:case_go/core/theme/app_palete.dart';
import 'package:case_go/features/dialog/dialog_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class DialogScreen extends StatefulWidget {
  final int caseId;
  final String caseTopic;

  const DialogScreen(
      {super.key, required this.caseId, required this.caseTopic});

  @override
  State<DialogScreen> createState() => _DialogScreenState();
}

class _DialogScreenState extends State<DialogScreen> {
  final _answerCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _confirmExit = false;

  @override
  void initState() {
    super.initState();
    context
        .read<DialogCubit>()
        .startDialog(widget.caseId, widget.caseTopic);
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(BuildContext context) {
    final text = _answerCtrl.text.trim();
    if (text.isEmpty) return;
    _answerCtrl.clear();
    context.read<DialogCubit>().sendAnswer(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<AppPalette>() ?? AppPalette.defaultPalette;

    return BlocConsumer<DialogCubit, DialogState>(
      listener: (context, state) {
        if (state is DialogCompleted) {
          context.pushReplacement('/result', extra: state.result);
        }
        if (state is DialogActive) _scrollToBottom();
      },
      builder: (context, state) {
        if (state is DialogLoading) {
          return Scaffold(
            backgroundColor: palette.background,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: palette.primaryBtn),
                  const SizedBox(height: 16),
                  Text('Запускаем кейс...',
                      style: TextStyle(color: palette.contrastBg)),
                ],
              ),
            ),
          );
        }

        if (state is DialogError) {
          return Scaffold(
            backgroundColor: palette.background,
            appBar: AppBar(backgroundColor: palette.background),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: Colors.red[400]),
                  const SizedBox(height: 12),
                  Text('Не удалось запустить кейс',
                      style: TextStyle(
                          color: palette.contrastBg,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(state.message,
                      style: TextStyle(
                          color: palette.contrastBg.withOpacity(0.6),
                          fontSize: 12),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context
                        .read<DialogCubit>()
                        .startDialog(widget.caseId, widget.caseTopic),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: palette.primaryBtn),
                    child: Text('Попробовать снова',
                        style: TextStyle(color: palette.background)),
                  ),
                ],
              ),
            ),
          );
        }

        final active = state is DialogActive ? state : null;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!_confirmExit) {
              _showExitDialog(context, palette);
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: _buildAppBar(context, palette, active),
            body: Column(
              children: [
                Expanded(
                  child: active == null
                      ? const SizedBox()
                      : _MessageList(
                          messages: active.messages,
                          scrollCtrl: _scrollCtrl,
                          palette: palette,
                        ),
                ),
                _InputBar(
                  palette: palette,
                  ctrl: _answerCtrl,
                  isSending: active?.isSending ?? false,
                  canComplete: active?.canComplete ?? false,
                  onSend: () => _send(context),
                  onComplete: () =>
                      context.read<DialogCubit>().completeDialog(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(
      BuildContext context, AppPalette palette, DialogActive? active) {
    return AppBar(
      backgroundColor: palette.contrastBg,
      leading: IconButton(
        icon: Icon(Icons.close, color: palette.background),
        onPressed: () => _showExitDialog(context, palette),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.caseTopic,
            style: TextStyle(
                color: palette.background,
                fontSize: 15,
                fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          if (active != null)
            Text(
              'Шаг ${active.currentStep + 1}',
              style: TextStyle(
                  color: palette.background.withOpacity(0.6), fontSize: 12),
            ),
        ],
      ),
      actions: [
        if (active?.canComplete == true)
          TextButton(
            onPressed: () => context.read<DialogCubit>().completeDialog(),
            child: Text(
              'Завершить',
              style: TextStyle(
                  color: palette.altBtn, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  void _showExitDialog(BuildContext context, AppPalette palette) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из кейса?'),
        content: const Text(
            'Прогресс диалога будет потерян. Вы уверены?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Остаться'),
          ),
          ElevatedButton(
            onPressed: () {
              _confirmExit = true;
              Navigator.pop(ctx);
              context.go('/cases');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400]),
            child: const Text('Выйти',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Message List ──────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollCtrl;
  final AppPalette palette;

  const _MessageList(
      {required this.messages,
      required this.scrollCtrl,
      required this.palette});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return _MessageBubble(
          key: ValueKey(msg.id),
          message: msg,
          palette: palette,
        );
      },
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final AppPalette palette;

  const _MessageBubble({super.key, required this.message, required this.palette});

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  String _displayed = '';
  Timer? _timer;
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.message.role == MessageRole.ai && !widget.message.isTyping) {
      _startTypewriter();
    } else {
      _displayed = widget.message.text;
    }
  }

  void _startTypewriter() {
    _timer = Timer.periodic(const Duration(milliseconds: 18), (t) {
      if (_charIndex < widget.message.text.length) {
        setState(() {
          _displayed =
              widget.message.text.substring(0, _charIndex + 1);
          _charIndex++;
        });
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAI = widget.message.role == MessageRole.ai;
    final palette = widget.palette;

    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isAI ? palette.contrastBg : palette.primaryBtn,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isAI ? 4 : 18),
            bottomRight: Radius.circular(isAI ? 18 : 4),
          ),
        ),
        child: widget.message.isTyping
            ? _TypingIndicator(color: palette.background)
            : Text(
                isAI ? _displayed : widget.message.text,
                style: TextStyle(
                  color: palette.background,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  final Color color;
  const _TypingIndicator({required this.color});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final offset = ((_anim.value * 3 - i) % 3).abs();
          final opacity = offset < 1 ? offset : (2 - offset).clamp(0, 1);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.4 + 0.6 * opacity.toDouble()),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}

// ── Input Bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final AppPalette palette;
  final TextEditingController ctrl;
  final bool isSending;
  final bool canComplete;
  final VoidCallback onSend;
  final VoidCallback onComplete;

  const _InputBar({
    required this.palette,
    required this.ctrl,
    required this.isSending,
    required this.canComplete,
    required this.onSend,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 8 + MediaQuery.of(context).viewInsets.bottom),
      color: palette.background,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                maxLines: 4,
                minLines: 1,
                enabled: !isSending,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ваш ответ...',
                  hintStyle: TextStyle(
                      color: palette.contrastBg.withOpacity(0.35),
                      fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  filled: true,
                  fillColor: const Color(0xFFF0F0F0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            if (isSending)
              const SizedBox(
                width: 44,
                height: 44,
                child: Center(
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2))),
              )
            else
              GestureDetector(
                onTap: onSend,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: palette.primaryBtn,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.send_rounded,
                      color: palette.background, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
