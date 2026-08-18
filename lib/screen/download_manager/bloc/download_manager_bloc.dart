import 'dart:async';

import 'package:bamabin_desktop/data/local/model/download_task.dart';
import 'package:bamabin_desktop/repository/download_repository.dart';
import 'package:bamabin_desktop/screen/download_manager/bloc/download_manager_event.dart';
import 'package:bamabin_desktop/screen/download_manager/bloc/download_manager_state.dart';
import 'package:bloc/bloc.dart';

class DownloadManagerBloc
    extends Bloc<DownloadManagerEvent, DownloadManagerState> {
  DownloadManagerBloc(this._repository) : super(const DownloadManagerState()) {
    on<DownloadManagerStarted>(_onStarted);
    on<DownloadTasksUpdated>(_onTasksUpdated);
    on<DownloadEnqueued>(_onEnqueued);
    on<DownloadPaused>(_onPaused);
    on<DownloadResumed>(_onResumed);
    on<DownloadRetried>(_onRetried);
    on<DownloadDeleted>(_onDeleted);
    on<DownloadFilterChanged>(_onFilterChanged);
    on<DownloadSelectionModeToggled>(_onSelectionModeToggled);
    on<DownloadSelectionCleared>(_onSelectionCleared);
    on<DownloadItemSelectionToggled>(_onItemSelectionToggled);
    on<DownloadSelectAllAndDelete>(_onSelectAllAndDelete);
    on<DownloadDeleteSelected>(_onDeleteSelected);
    on<DownloadOpenCompleted>(_onOpenCompleted);
  }

  final DownloadRepository _repository;
  StreamSubscription<List<DownloadTask>>? _sub;

  Future<void> _onStarted(
    DownloadManagerStarted event,
    Emitter<DownloadManagerState> emit,
  ) async {
    await _repository.init();
    await _sub?.cancel();
    _sub = _repository.tasksStream.listen((tasks) {
      add(DownloadTasksUpdated(tasks));
    });
    emit(
      state.copyWith(
        tasks: _repository.tasks,
        initialized: true,
      ),
    );
  }

  void _onTasksUpdated(
    DownloadTasksUpdated event,
    Emitter<DownloadManagerState> emit,
  ) {
    final validIds = event.tasks.map((t) => t.id).toSet();
    emit(
      state.copyWith(
        tasks: event.tasks,
        selectedIds: state.selectedIds.intersection(validIds),
      ),
    );
  }

  Future<void> _onEnqueued(
    DownloadEnqueued event,
    Emitter<DownloadManagerState> emit,
  ) async {
    if (!state.initialized) {
      await _repository.init();
      emit(state.copyWith(initialized: true, tasks: _repository.tasks));
      await _sub?.cancel();
      _sub = _repository.tasksStream.listen((tasks) {
        add(DownloadTasksUpdated(tasks));
      });
    }
    await _repository.enqueue(
      url: event.url,
      title: event.title,
      posterUrl: event.posterUrl,
      quality: event.quality,
      sizeLabel: event.sizeLabel,
    );
    emit(state.copyWith(enqueueTick: state.enqueueTick + 1));
  }

  Future<void> _onPaused(
    DownloadPaused event,
    Emitter<DownloadManagerState> emit,
  ) async {
    await _repository.pause(event.id);
  }

  Future<void> _onResumed(
    DownloadResumed event,
    Emitter<DownloadManagerState> emit,
  ) async {
    await _repository.resume(event.id);
  }

  Future<void> _onRetried(
    DownloadRetried event,
    Emitter<DownloadManagerState> emit,
  ) async {
    await _repository.retry(event.id);
  }

  Future<void> _onDeleted(
    DownloadDeleted event,
    Emitter<DownloadManagerState> emit,
  ) async {
    await _repository.delete(event.id);
  }

  void _onFilterChanged(
    DownloadFilterChanged event,
    Emitter<DownloadManagerState> emit,
  ) {
    emit(state.copyWith(filter: event.filter));
  }

  void _onSelectionModeToggled(
    DownloadSelectionModeToggled event,
    Emitter<DownloadManagerState> emit,
  ) {
    if (state.selectionMode) {
      emit(state.copyWith(selectionMode: false, selectedIds: {}));
    } else {
      emit(state.copyWith(selectionMode: true));
    }
  }

  void _onSelectionCleared(
    DownloadSelectionCleared event,
    Emitter<DownloadManagerState> emit,
  ) {
    emit(state.copyWith(selectedIds: {}, selectionMode: false));
  }

  void _onItemSelectionToggled(
    DownloadItemSelectionToggled event,
    Emitter<DownloadManagerState> emit,
  ) {
    final next = Set<String>.from(state.selectedIds);
    if (next.contains(event.id)) {
      next.remove(event.id);
    } else {
      next.add(event.id);
    }
    emit(state.copyWith(selectedIds: next, selectionMode: true));
  }

  Future<void> _onSelectAllAndDelete(
    DownloadSelectAllAndDelete event,
    Emitter<DownloadManagerState> emit,
  ) async {
    final ids = state.tasks.map((t) => t.id).toList();
    await _repository.deleteMany(ids);
    emit(state.copyWith(selectionMode: false, selectedIds: {}));
  }

  Future<void> _onDeleteSelected(
    DownloadDeleteSelected event,
    Emitter<DownloadManagerState> emit,
  ) async {
    await _repository.deleteMany(state.selectedIds);
    emit(state.copyWith(selectionMode: false, selectedIds: {}));
  }

  Future<void> _onOpenCompleted(
    DownloadOpenCompleted event,
    Emitter<DownloadManagerState> emit,
  ) async {
    DownloadTask? task;
    for (final t in state.tasks) {
      if (t.id == event.id) {
        task = t;
        break;
      }
    }
    if (task == null || task.filePath.isEmpty) return;
    await _repository.revealInFileManager(task.filePath);
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
