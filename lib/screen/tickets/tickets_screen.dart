import 'dart:ui';

import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/core/widgets/bamabin_snackbar.dart';
import 'package:bamabin_desktop/core/widgets/loading_widget.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/app/department.dart';
import 'package:bamabin_desktop/data/remote/model/user/ticket.dart';
import 'package:bamabin_desktop/screen/tickets/bloc/tickets_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _titleFocus = FocusNode();

  static const _telegramUrl = 'https://t.me/Bamabin_Support';
  static const _baleUrl = 'https://ble.ir/Bamabin_Support';

  @override
  void initState() {
    super.initState();
    context.read<TicketsBloc>().add(TicketsLoadEvent());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<TicketsBloc>().add(
      TicketsCreateEvent(
        title: _titleController.text,
        content: _contentController.text,
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openTicket(int ticketId, TicketsListType listType) {
    context.push(
      Routes.ticketDetails,
      extra: {
        'id': ticketId,
        'type': listType.apiValue,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0C0C14),
      child: BlocConsumer<TicketsBloc, TicketsState>(
        listenWhen: (previous, current) {
          if (current is! TicketsLoaded) return false;
          if (previous is! TicketsLoaded) {
            return current.feedbackMessage != null ||
                current.navigateToTicketId != null;
          }
          return (current.feedbackMessage != null &&
                  current.feedbackMessage != previous.feedbackMessage) ||
              (current.navigateToTicketId != null &&
                  current.navigateToTicketId != previous.navigateToTicketId);
        },
        listener: (context, state) {
          if (state is! TicketsLoaded) return;
          final message = state.feedbackMessage;
          if (message != null && message.isNotEmpty) {
            showBamabinSnackbar(context, message);
            if (!state.feedbackIsError) {
              _titleController.clear();
              _contentController.clear();
            }
            context.read<TicketsBloc>().add(TicketsClearFeedbackEvent());
          }
          final ticketId = state.navigateToTicketId;
          if (ticketId != null) {
            context.read<TicketsBloc>().add(TicketsClearNavigationEvent());
            _openTicket(ticketId, TicketsListType.ticket);
          }
        },
        builder: (context, state) {
          if (state is TicketsLoading || state is TicketsInitial) {
            return const Center(child: LoadingWidget());
          }
          if (state is TicketsError) {
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
                    onPressed: () =>
                        context.read<TicketsBloc>().add(TicketsLoadEvent()),
                    child: Text(
                      'تلاش مجدد',
                      style: TextStyle(color: blueColor),
                    ),
                  ),
                ],
              ),
            );
          }

          final loaded = state as TicketsLoaded;
          final telegramLink = TempDb.supportLink.trim().isNotEmpty
              ? TempDb.supportLink.trim()
              : _telegramUrl;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 937),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(48, 0, 48, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'پشتیبانی بامابین',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'vazir',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 30 / 24,
                        letterSpacing: -0.15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SupportChannelsRow(
                      onBale: () => _openUrl(_baleUrl),
                      onTelegram: () => _openUrl(telegramLink),
                    ),
                    const SizedBox(height: 24),
                    _NewTicketCard(
                      departments: loaded.departments,
                      selectedDepartmentId: loaded.selectedDepartmentId,
                      titleController: _titleController,
                      contentController: _contentController,
                      titleFocus: _titleFocus,
                      isSubmitting: loaded.isSubmitting,
                      onDepartmentChanged: (id) => context
                          .read<TicketsBloc>()
                          .add(TicketsSelectDepartmentEvent(id)),
                      onSubmit: loaded.isSubmitting ? null : _submit,
                    ),
                    const SizedBox(height: 24),
                    _TicketsListCard(
                      tickets: loaded.tickets,
                      listType: loaded.listType,
                      isListLoading: loaded.isListLoading,
                      onListTypeChanged: (type) => context
                          .read<TicketsBloc>()
                          .add(TicketsSelectListTypeEvent(type)),
                      onTicketTap: (id) => _openTicket(id, loaded.listType),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SupportChannelsRow extends StatelessWidget {
  const _SupportChannelsRow({
    required this.onBale,
    required this.onTelegram,
  });

  final VoidCallback onBale;
  final VoidCallback onTelegram;

  @override
  Widget build(BuildContext context) {
    // Match Figma LTR visual in RTL: Bale left (green), Telegram right (blue)
    return Row(
      children: [
        Expanded(
          child: _ChannelCard(
            title: 'ارتباط با پشتیبانی در تلگرام',
            handle: '@Bamabin_Support',
            iconAsset: 'assets/img/ic_telegram_support.svg',
            glowColor: const Color(0xFF0EA5E9),
            onTap: onTelegram,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ChannelCard(
            title: 'ارتباط با پشتیبانی در بله',
            handle: '@Bamabin_Support',
            iconAsset: 'assets/img/ic_bale_support.svg',
            glowColor: const Color(0xFF10B981),
            onTap: onBale,
          ),
        ),
      ],
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.title,
    required this.handle,
    required this.iconAsset,
    required this.glowColor,
    required this.onTap,
  });

  final String title;
  final String handle;
  final String iconAsset;
  final Color glowColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                // Figma base: linear #131321 80% → 48%
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xCC131321),
                          Color(0x7A131321),
                        ],
                      ),
                    ),
                  ),
                ),
                // Figma radial glow: ellipse from above top-center, opacity 0.8
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.8,
                    child: Transform.scale(
                      scaleX: 2.4,
                      alignment: Alignment.topCenter,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, -1.68),
                            radius: 1.5,
                            colors: [
                              glowColor,
                              glowColor.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Top hairline only (Figma border-t)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          iconAsset,
                          width: 38,
                          height: 38,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              title,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'vazir',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                height: 24 / 20,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              handle,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: 'vazir',
                                fontSize: 14,
                                height: 20 / 14,
                                letterSpacing: -0.16,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewTicketCard extends StatelessWidget {
  const _NewTicketCard({
    required this.departments,
    required this.selectedDepartmentId,
    required this.titleController,
    required this.contentController,
    required this.titleFocus,
    required this.isSubmitting,
    required this.onDepartmentChanged,
    required this.onSubmit,
  });

  final List<Department> departments;
  final int? selectedDepartmentId;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final FocusNode titleFocus;
  final bool isSubmitting;
  final ValueChanged<int?> onDepartmentChanged;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return _SupportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FieldLabel('موضوع تیکت'),
          const SizedBox(height: 8),
          _DepartmentDropdown(
            departments: departments,
            value: selectedDepartmentId,
            onChanged: onDepartmentChanged,
          ),
          const SizedBox(height: 20),
          _FieldLabel('عنوان تیکت'),
          const SizedBox(height: 8),
          _TicketTextField(
            controller: titleController,
            focusNode: titleFocus,
            hint: 'مثال: عدم لود زیرنویس سریال',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          _FieldLabel('توضیحات تیکت'),
          const SizedBox(height: 8),
          _TicketTextField(
            controller: contentController,
            hint: 'لطفاً جزییات مشکل خود را بنویسید...',
            minLines: 5,
            maxLines: 8,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 20),
          _SubmitButton(
            label: 'ارسال تیکت پشتیبانی',
            loading: isSubmitting,
            onTap: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _TicketsListCard extends StatelessWidget {
  const _TicketsListCard({
    required this.tickets,
    required this.listType,
    required this.isListLoading,
    required this.onListTypeChanged,
    required this.onTicketTap,
  });

  final List<Ticket> tickets;
  final TicketsListType listType;
  final bool isListLoading;
  final ValueChanged<TicketsListType> onListTypeChanged;
  final ValueChanged<int> onTicketTap;

  @override
  Widget build(BuildContext context) {
    return _SupportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _TicketsListTabs(
              listType: listType,
              onChanged: onListTypeChanged,
            ),
          ),
          const SizedBox(height: 24),
          if (isListLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: LoadingWidget()),
            )
          else if (tickets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                listType.emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'vazir',
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            )
          else ...[
            _TicketsHeaderRow(subjectLabel: listType.subjectHeader),
            const SizedBox(height: 12),
            for (var i = 0; i < tickets.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _TicketRow(
                ticket: tickets[i],
                onTap: () => onTicketTap(tickets[i].id),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TicketsListTabs extends StatelessWidget {
  const _TicketsListTabs({
    required this.listType,
    required this.onChanged,
  });

  final TicketsListType listType;
  final ValueChanged<TicketsListType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TicketsListTab(
          label: 'تیکت های من',
          selected: listType == TicketsListType.ticket,
          onTap: () => onChanged(TicketsListType.ticket),
        ),
        const SizedBox(width: 8),
        _TicketsListTab(
          label: 'گزارش های من',
          selected: listType == TicketsListType.report,
          onTap: () => onChanged(TicketsListType.report),
        ),
      ],
    );
  }
}

class _TicketsListTab extends StatelessWidget {
  const _TicketsListTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(999);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.09)
                  : Colors.white.withValues(alpha: 0.2),
            ),
            color: selected ? blueColor : Colors.white.withValues(alpha: 0.09),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'vazir',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.18,
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF131321).withValues(alpha: 0.8),
            const Color(0xFF131321).withValues(alpha: 0.48),
          ],
        ),
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'vazir',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _TicketTextField extends StatelessWidget {
  const _TicketTextField({
    required this.controller,
    required this.hint,
    this.focusNode,
    this.minLines = 1,
    this.maxLines = 1,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;
  final int minLines;
  final int maxLines;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction: textInputAction,
      style: const TextStyle(
        fontFamily: 'vazir',
        fontSize: 14,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'vazir',
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.35),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.09)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.09)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: blueColor.withValues(alpha: 0.55)),
        ),
      ),
    );
  }
}

class _DepartmentDropdown extends StatelessWidget {
  const _DepartmentDropdown({
    required this.departments,
    required this.value,
    required this.onChanged,
  });

  final List<Department> departments;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      dropdownColor: const Color(0xFF1A1A28),
      iconEnabledColor: Colors.white.withValues(alpha: 0.6),
      style: const TextStyle(
        fontFamily: 'vazir',
        fontSize: 14,
        color: Colors.white,
      ),
      hint: Text(
        'انتخاب موضوع پشتیبانی (مالی، فنی، اکانت...)',
        style: TextStyle(
          fontFamily: 'vazir',
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.09)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.09)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: blueColor.withValues(alpha: 0.55)),
        ),
      ),
      items: [
        for (final d in departments)
          DropdownMenuItem<int>(
            value: d.id,
            child: Text(d.name, textAlign: TextAlign.right),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: blueColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
          ),
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'vazir',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

class _TicketsHeaderRow extends StatelessWidget {
  const _TicketsHeaderRow({required this.subjectLabel});

  final String subjectLabel;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'vazir',
      fontSize: 12,
      color: Colors.white.withValues(alpha: 0.75),
    );

    return Opacity(
      opacity: 0.6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text('تاریخ ثبت', style: style),
              ),
              SizedBox(
                width: 120,
                child: Text(
                  'وضعیت',
                  textAlign: TextAlign.center,
                  style: style,
                ),
              ),
              Expanded(
                child: Text(
                  subjectLabel,
                  textAlign: TextAlign.right,
                  style: style,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({
    required this.ticket,
    required this.onTap,
  });

  final Ticket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _TicketStatusStyle.fromName(ticket.statusName);
    final title = ticket.title?.trim().isNotEmpty == true
        ? ticket.title!
        : 'بدون عنوان';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131321).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    ticket.createdAt,
                    style: TextStyle(
                      fontFamily: 'vazir',
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: status.background,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: status.border),
                      ),
                      child: Text(
                        status.label,
                        style: TextStyle(
                          fontFamily: 'vazir',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: status.foreground,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'vazir',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '#${ticket.id}',
                        style: TextStyle(
                          fontFamily: 'vazir',
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketStatusStyle {
  const _TicketStatusStyle({
    required this.label,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final String label;
  final Color foreground;
  final Color background;
  final Color border;

  static _TicketStatusStyle fromName(String raw) {
    final name = raw.trim();
    final lower = name.toLowerCase();

    if (name.contains('پاسخ') ||
        lower.contains('answer') ||
        lower.contains('replied') ||
        lower.contains('resolved')) {
      return const _TicketStatusStyle(
        label: 'پاسخ داده شده',
        foreground: Color(0xFF4ADE80),
        background: Color(0x1A22C55E),
        border: Color(0x404ADE80),
      );
    }

    if (name.contains('بسته') ||
        lower.contains('close') ||
        lower.contains('done')) {
      return _TicketStatusStyle(
        label: 'بسته شده',
        foreground: Colors.white.withValues(alpha: 0.6),
        background: Colors.white.withValues(alpha: 0.06),
        border: Colors.white.withValues(alpha: 0.12),
      );
    }

    return _TicketStatusStyle(
      label: name.isNotEmpty ? name : 'در انتظار بررسی',
      foreground: const Color(0xFF38BDF8),
      background: const Color(0xFF38BDF8).withValues(alpha: 0.12),
      border: const Color(0xFF38BDF8).withValues(alpha: 0.25),
    );
  }
}

