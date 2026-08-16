import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/widgets/bamabin_snackbar.dart';
import 'package:bamabin_desktop/data/remote/model/app/department.dart';
import 'package:bamabin_desktop/screen/post_details/widgets/report_cubit.dart';
import 'package:bamabin_desktop/utils/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

Future<void> showPostReportDialog(
  BuildContext context, {
  required int postId,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (dialogContext) => BlocProvider(
      create: (_) => ReportCubit(locator(), postId),
      child: const _PostReportDialog(),
    ),
  );
}

class _PostReportDialog extends StatefulWidget {
  const _PostReportDialog();

  @override
  State<_PostReportDialog> createState() => _PostReportDialogState();
}

class _PostReportDialogState extends State<_PostReportDialog> {
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReportCubit, ReportState>(
      listenWhen: (previous, current) =>
          current.feedbackMessage != null &&
          current.feedbackMessage != previous.feedbackMessage,
      listener: (context, state) {
        final message = state.feedbackMessage;
        if (message == null || message.isEmpty) return;
        if (state.submitted) {
          Navigator.of(context).pop();
          showBamabinSnackbarMessage(message);
          return;
        }
        showBamabinSnackbar(context, message);
        context.read<ReportCubit>().clearFeedback();
      },
      builder: (context, state) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 624),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.09),
                    ),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF131321).withValues(alpha: 0.75),
                      const Color(0xFF0C0C14),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          children: [
                            _CloseButton(
                              onTap: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'ثبت گزارش جدید',
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontFamily: 'vazir',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  height: 16.1 / 24,
                                  color: Color(0xFFF5EFE6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (state.isLoadingDepartments)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      else if (state.departmentsError != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              Text(
                                state.departmentsError!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'vazir',
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () =>
                                    context.read<ReportCubit>().loadDepartments(),
                                child: Text(
                                  'تلاش مجدد',
                                  style: TextStyle(color: blueColor),
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        const _FieldLabel('عنوان گزارش'),
                        const SizedBox(height: 8),
                        _DepartmentDropdown(
                          departments: state.departments,
                          value: state.selectedDepartmentId,
                          onChanged: (id) =>
                              context.read<ReportCubit>().selectDepartment(id),
                        ),
                        const SizedBox(height: 20),
                        const _FieldLabel('توضیحات گزارش'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _contentController,
                          minLines: 5,
                          maxLines: 8,
                          textInputAction: TextInputAction.newline,
                          style: const TextStyle(
                            fontFamily: 'vazir',
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          decoration: _inputDecoration(
                            hint: 'لطفاً جزییات مشکل خود را بنویسید...',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Material(
                          color: blueColor,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: state.isSubmitting
                                ? null
                                : () => context
                                    .read<ReportCubit>()
                                    .submit(_contentController.text),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.09),
                                ),
                              ),
                              child: state.isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'ارسال گزارش پشتیبانی',
                                      style: TextStyle(
                                        fontFamily: 'vazir',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.09),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: SvgPicture.asset(
              'assets/img/ic_close_circle.svg',
              width: 32,
              height: 32,
            ),
          ),
        ),
      ),
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
        'مثال: عدم لود زیرنویس سریال',
        style: TextStyle(
          fontFamily: 'vazir',
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
      decoration: _inputDecoration(),
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

InputDecoration _inputDecoration({String? hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      fontFamily: 'vazir',
      fontSize: 14,
      color: Colors.white.withValues(alpha: 0.35),
    ),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.04),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
  );
}
