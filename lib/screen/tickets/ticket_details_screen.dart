import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/widgets/bamabin_snackbar.dart';
import 'package:bamabin_desktop/core/widgets/loading_widget.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/user/ticket_reply.dart';
import 'package:bamabin_desktop/screen/tickets/bloc/ticket_details_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class TicketDetailsScreen extends StatefulWidget {
  const TicketDetailsScreen({super.key});

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  final _composerController = TextEditingController();
  final _composerFocus = FocusNode();

  @override
  void dispose() {
    _composerController.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  void _send() {
    FocusScope.of(context).unfocus();
    context.read<TicketDetailsBloc>().add(
      TicketDetailsReplyEvent(_composerController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0C0C14),
      child: BlocConsumer<TicketDetailsBloc, TicketDetailsState>(
        listenWhen: (previous, current) {
          if (current is! TicketDetailsLoaded) return false;
          if (current.clearComposer) return true;
          if (previous is! TicketDetailsLoaded) {
            return current.feedbackMessage != null;
          }
          return current.feedbackMessage != null &&
              current.feedbackMessage != previous.feedbackMessage;
        },
        listener: (context, state) {
          if (state is! TicketDetailsLoaded) return;
          if (state.clearComposer) {
            _composerController.clear();
          }
          final message = state.feedbackMessage;
          if (message == null || message.isEmpty) return;
          showBamabinSnackbar(context, message);
          context.read<TicketDetailsBloc>().add(
            TicketDetailsClearFeedbackEvent(),
          );
        },
        builder: (context, state) {
          if (state is TicketDetailsLoading || state is TicketDetailsInitial) {
            return const Center(child: LoadingWidget());
          }
          if (state is TicketDetailsError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'vazir',
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'بازگشت',
                      style: TextStyle(color: blueColor),
                    ),
                  ),
                ],
              ),
            );
          }

          final loaded = state as TicketDetailsLoaded;
          final ticket = loaded.details.ticket;
          final title = ticket.title?.trim().isNotEmpty == true
              ? ticket.title!
              : 'بدون عنوان';
          final status = _TicketStatusChip.fromName(ticket.statusName);

          return LayoutBuilder(
            builder: (context, constraints) {
              const horizontalPad = 48.0;
              const bottomPad = 48.0;
              const maxCardWidth = 937.0;
              final availableWidth = (constraints.maxWidth - horizontalPad * 2)
                  .clamp(0.0, maxCardWidth);
              final availableHeight = (constraints.maxHeight - bottomPad).clamp(
                0.0,
                double.infinity,
              );

              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  horizontalPad,
                  0,
                  horizontalPad,
                  bottomPad,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: availableWidth,
                    height: availableHeight,
                    child: _TicketChatCard(
                      title: title,
                      status: status,
                      replies: loaded.details.replies,
                      fallbackDate: ticket.createdAt,
                      isClosed: loaded.isClosed,
                      isSending: loaded.isSending,
                      composerController: _composerController,
                      composerFocus: _composerFocus,
                      onBack: () => context.pop(),
                      onSend: loaded.isSending ? null : _send,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TicketChatCard extends StatelessWidget {
  const _TicketChatCard({
    required this.title,
    required this.status,
    required this.replies,
    required this.fallbackDate,
    required this.isClosed,
    required this.isSending,
    required this.composerController,
    required this.composerFocus,
    required this.onBack,
    required this.onSend,
  });

  final String title;
  final _TicketStatusChip status;
  final List<TicketReply> replies;
  final String fallbackDate;
  final bool isClosed;
  final bool isSending;
  final TextEditingController composerController;
  final FocusNode composerFocus;
  final VoidCallback onBack;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Figma wallpaper (opacity 20%)
            Image.asset(
              'assets/img/ticket_chat_bg.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.2),
            ),
            // Soft blue glow (matches Figma atmosphere)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.55, -0.1),
                  radius: 1.15,
                  colors: [
                    Color(0x3329B6F6),
                    Color(0x000C0C14),
                  ],
                ),
              ),
            ),
            // Dark glass overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF131321).withValues(alpha: 0.8),
                    const Color(0xFF131321).withValues(alpha: 0.48),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ChatHeader(
                    title: title,
                    status: status,
                    onBack: onBack,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: replies.isEmpty
                        ? Center(
                            child: Text(
                              'هنوز پیامی ثبت نشده است.',
                              style: TextStyle(
                                fontFamily: 'vazir',
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final bubbleMax =
                                  (constraints.maxWidth * 0.62).clamp(
                                    240.0,
                                    520.0,
                                  );
                              return ListView.separated(
                                reverse: true,
                                padding: EdgeInsets.zero,
                                itemCount: replies.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final reply =
                                      replies[replies.length - 1 - index];
                                  return _MessageBubble(
                                    reply: reply,
                                    fallbackDate: fallbackDate,
                                    maxWidth: bubbleMax,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
                  if (isClosed)
                    const _ClosedTicketBanner()
                  else
                    _ComposerBar(
                      controller: composerController,
                      focusNode: composerFocus,
                      isSending: isSending,
                      onSend: onSend,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.title,
    required this.status,
    required this.onBack,
  });

  final String title;
  final _TicketStatusChip status;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    // Match Figma LTR: back on physical left, title+status on physical right
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/img/ic_ticket_back_arrow.svg',
                    width: 15,
                    height: 12,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'بازگشت به پشتیبانی',
                    style: TextStyle(
                      fontFamily: 'vazir',
                      fontSize: 16,
                      height: 22 / 16,
                      letterSpacing: -0.18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'vazir',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 30 / 24,
                      letterSpacing: -0.15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  status.build(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.reply,
    required this.fallbackDate,
    required this.maxWidth,
  });

  final TicketReply reply;
  final String fallbackDate;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final isSupport = reply.isFromSupport;
    final author = isSupport
        ? 'پشتیبانی'
        : (reply.authorName?.trim().isNotEmpty == true
            ? reply.authorName!
            : (TempDb.username.trim().isNotEmpty
                ? TempDb.username.trim()
                : 'شما'));
    final date = reply.createdAt?.trim().isNotEmpty == true
        ? reply.createdAt!
        : fallbackDate;

    // Figma: user missing bottom-right; support missing bottom-left
    final radius = isSupport
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          );

    final gradient = isSupport
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF131321).withValues(alpha: 0.75),
              const Color(0xFF0C0C14),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF075985),
              Color(0xFF131321),
            ],
          );

    return Align(
      alignment: isSupport ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        author,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'vazir',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reply.content,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'vazir',
                      fontSize: 16,
                      height: 22 / 16,
                      letterSpacing: -0.18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        date,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'vazir',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    // Match Figma LTR: send on left, input on right
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onSend,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'ارسال',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'vazir',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.18,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 54,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend?.call(),
                  style: const TextStyle(
                    fontFamily: 'vazir',
                    fontSize: 16,
                    letterSpacing: -0.18,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'پیام خود را بنویسید ...',
                    hintStyle: TextStyle(
                      fontFamily: 'vazir',
                      fontSize: 16,
                      letterSpacing: -0.18,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.09),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.09),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: blueColor.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosedTicketBanner extends StatelessWidget {
  const _ClosedTicketBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4ADE80).withValues(alpha: 0.5),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'این تیکت بسته شده است',
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'vazir',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.18,
          color: Colors.white.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

class _TicketStatusChip {
  const _TicketStatusChip({
    required this.label,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final String label;
  final Color foreground;
  final Color background;
  final Color border;

  Widget build() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'vazir',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }

  static _TicketStatusChip fromName(String raw) {
    final name = raw.trim();
    final lower = name.toLowerCase();

    if (name.contains('پاسخ') ||
        lower.contains('answer') ||
        lower.contains('replied') ||
        lower.contains('resolved')) {
      return const _TicketStatusChip(
        label: 'پاسخ داده شده',
        foreground: Color(0xFF4ADE80),
        background: Color(0x1A22C55E),
        border: Color(0x404ADE80),
      );
    }

    if (name.contains('بسته') ||
        lower.contains('close') ||
        lower.contains('done')) {
      return _TicketStatusChip(
        label: 'بسته شده',
        foreground: Colors.white.withValues(alpha: 0.6),
        background: Colors.white.withValues(alpha: 0.06),
        border: Colors.white.withValues(alpha: 0.12),
      );
    }

    return _TicketStatusChip(
      label: name.isNotEmpty ? name : 'در انتظار بررسی',
      foreground: blueColor,
      background: blueColor.withValues(alpha: 0.12),
      border: blueColor.withValues(alpha: 0.25),
    );
  }
}
