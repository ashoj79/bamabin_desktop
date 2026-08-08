import 'package:bamabin_desktop/data/local/model/download_task.dart';
import 'package:bamabin_desktop/screen/download_manager/bloc/download_manager_event.dart';

class DownloadManagerState {
  const DownloadManagerState({
    this.tasks = const [],
    this.filter = DownloadFilter.all,
    this.selectionMode = false,
    this.selectedIds = const {},
    this.initialized = false,
  });

  final List<DownloadTask> tasks;
  final DownloadFilter filter;
  final bool selectionMode;
  final Set<String> selectedIds;
  final bool initialized;

  int get allCount => tasks.length;

  int get activeCount => tasks.where((t) => t.isActiveLike).length;

  int get completedCount =>
      tasks.where((t) => t.status == DownloadTaskStatus.completed).length;

  int get pausedCount =>
      tasks.where((t) => t.status == DownloadTaskStatus.paused).length;

  int get errorCount =>
      tasks.where((t) => t.status == DownloadTaskStatus.error).length;

  List<DownloadTask> get filteredTasks {
    switch (filter) {
      case DownloadFilter.all:
        return tasks;
      case DownloadFilter.active:
        return tasks.where((t) => t.isActiveLike).toList();
      case DownloadFilter.completed:
        return tasks
            .where((t) => t.status == DownloadTaskStatus.completed)
            .toList();
      case DownloadFilter.paused:
        return tasks
            .where((t) => t.status == DownloadTaskStatus.paused)
            .toList();
      case DownloadFilter.error:
        return tasks.where((t) => t.status == DownloadTaskStatus.error).toList();
    }
  }

  DownloadManagerState copyWith({
    List<DownloadTask>? tasks,
    DownloadFilter? filter,
    bool? selectionMode,
    Set<String>? selectedIds,
    bool? initialized,
  }) {
    return DownloadManagerState(
      tasks: tasks ?? this.tasks,
      filter: filter ?? this.filter,
      selectionMode: selectionMode ?? this.selectionMode,
      selectedIds: selectedIds ?? this.selectedIds,
      initialized: initialized ?? this.initialized,
    );
  }
}
