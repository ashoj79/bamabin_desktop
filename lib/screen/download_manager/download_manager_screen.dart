import 'package:bamabin_desktop/data/local/model/download_task.dart';
import 'package:bamabin_desktop/screen/download_manager/bloc/download_manager_bloc.dart';
import 'package:bamabin_desktop/screen/download_manager/bloc/download_manager_event.dart';
import 'package:bamabin_desktop/screen/download_manager/bloc/download_manager_state.dart';
import 'package:bamabin_desktop/screen/download_manager/widgets/download_bulk_actions.dart';
import 'package:bamabin_desktop/screen/download_manager/widgets/download_filter_bar.dart';
import 'package:bamabin_desktop/screen/download_manager/widgets/download_item_tile.dart';
import 'package:bamabin_desktop/screen/download_manager/widgets/download_stats_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DownloadManagerScreen extends StatelessWidget {
  const DownloadManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DownloadManagerBody();
  }
}

class _DownloadManagerBody extends StatelessWidget {
  const _DownloadManagerBody();

  static const _bg = Color(0xFF0C0C14);

  void _onItemAction(BuildContext context, DownloadTask task) {
    final bloc = context.read<DownloadManagerBloc>();
    switch (task.status) {
      case DownloadTaskStatus.active:
      case DownloadTaskStatus.queued:
        bloc.add(DownloadPaused(task.id));
      case DownloadTaskStatus.paused:
        bloc.add(DownloadResumed(task.id));
      case DownloadTaskStatus.error:
        bloc.add(DownloadRetried(task.id));
      case DownloadTaskStatus.completed:
        bloc.add(DownloadOpenCompleted(task.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _bg,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1001),
          child: BlocBuilder<DownloadManagerBloc, DownloadManagerState>(
            builder: (context, state) {
              final items = state.filteredTasks;
              return Padding(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'دانلود های من',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'vazir',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 30 / 24,
                        letterSpacing: -0.15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DownloadStatsRow(
                      allCount: state.allCount,
                      activeCount: state.activeCount,
                      completedCount: state.completedCount,
                      pausedCount: state.pausedCount,
                      errorCount: state.errorCount,
                    ),
                    const SizedBox(height: 16),
                    DownloadFilterBar(
                      selected: state.filter,
                      onChanged: (f) => context
                          .read<DownloadManagerBloc>()
                          .add(DownloadFilterChanged(f)),
                    ),
                    if (items.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DownloadBulkActions(
                        selectionMode: state.selectionMode,
                        hasSelection: state.selectedIds.isNotEmpty,
                        onToggleSelectionMode: () => context
                            .read<DownloadManagerBloc>()
                            .add(const DownloadSelectionModeToggled()),
                        onClearSelection: () => context
                            .read<DownloadManagerBloc>()
                            .add(const DownloadSelectionCleared()),
                        onDeleteSelected: () => context
                            .read<DownloadManagerBloc>()
                            .add(const DownloadDeleteSelected()),
                        onSelectAllAndDelete: () => context
                            .read<DownloadManagerBloc>()
                            .add(const DownloadSelectAllAndDelete()),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Expanded(
                      child: items.isEmpty
                          ? const _DownloadEmptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 48),
                              itemCount: items.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final task = items[index];
                                return DownloadItemTile(
                                  task: task,
                                  selected:
                                      state.selectedIds.contains(task.id),
                                  selectionMode: state.selectionMode,
                                  onDelete: () => context
                                      .read<DownloadManagerBloc>()
                                      .add(DownloadDeleted(task.id)),
                                  onAction: () =>
                                      _onItemAction(context, task),
                                  onToggleSelect: () => context
                                      .read<DownloadManagerBloc>()
                                      .add(
                                        DownloadItemSelectionToggled(task.id),
                                      ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DownloadEmptyState extends StatelessWidget {
  const _DownloadEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/img/download_empty_smiley.svg',
            width: 110,
            height: 110,
          ),
          const SizedBox(height: 24),
          Text(
            'نتیجه ای برای دانلود های شما پیدا نشد.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'vazir',
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 24 / 20,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
