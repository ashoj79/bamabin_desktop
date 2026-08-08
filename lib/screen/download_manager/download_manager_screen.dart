import 'package:bamabin_desktop/config/color.dart';
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

class DownloadManagerScreen extends StatelessWidget {
  const DownloadManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DownloadManagerBody();
  }
}

class _DownloadManagerBody extends StatelessWidget {
  const _DownloadManagerBody();

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
      color: desktopBgColor,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1001),
          child: BlocBuilder<DownloadManagerBloc, DownloadManagerState>(
            builder: (context, state) {
              final items = state.filteredTasks;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'دانلود های من',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
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
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                            child: Text(
                              'دانلودی وجود ندارد',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.48),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final task = items[index];
                              return DownloadItemTile(
                                task: task,
                                selected: state.selectedIds.contains(task.id),
                                selectionMode: state.selectionMode,
                                onDelete: () => context
                                    .read<DownloadManagerBloc>()
                                    .add(DownloadDeleted(task.id)),
                                onAction: () => _onItemAction(context, task),
                                onToggleSelect: () => context
                                    .read<DownloadManagerBloc>()
                                    .add(DownloadItemSelectionToggled(task.id)),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
