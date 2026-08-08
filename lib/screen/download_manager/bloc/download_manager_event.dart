import 'package:bamabin_desktop/data/local/model/download_task.dart';

enum DownloadFilter { all, active, completed, paused, error }

sealed class DownloadManagerEvent {
  const DownloadManagerEvent();
}

class DownloadManagerStarted extends DownloadManagerEvent {
  const DownloadManagerStarted();
}

class DownloadTasksUpdated extends DownloadManagerEvent {
  const DownloadTasksUpdated(this.tasks);

  final List<DownloadTask> tasks;
}

class DownloadEnqueued extends DownloadManagerEvent {
  const DownloadEnqueued({
    required this.url,
    required this.title,
    this.posterUrl = '',
    this.quality = '',
    this.sizeLabel = '',
  });

  final String url;
  final String title;
  final String posterUrl;
  final String quality;
  final String sizeLabel;
}

class DownloadPaused extends DownloadManagerEvent {
  const DownloadPaused(this.id);

  final String id;
}

class DownloadResumed extends DownloadManagerEvent {
  const DownloadResumed(this.id);

  final String id;
}

class DownloadRetried extends DownloadManagerEvent {
  const DownloadRetried(this.id);

  final String id;
}

class DownloadDeleted extends DownloadManagerEvent {
  const DownloadDeleted(this.id);

  final String id;
}

class DownloadFilterChanged extends DownloadManagerEvent {
  const DownloadFilterChanged(this.filter);

  final DownloadFilter filter;
}

class DownloadSelectionModeToggled extends DownloadManagerEvent {
  const DownloadSelectionModeToggled();
}

class DownloadSelectionCleared extends DownloadManagerEvent {
  const DownloadSelectionCleared();
}

class DownloadItemSelectionToggled extends DownloadManagerEvent {
  const DownloadItemSelectionToggled(this.id);

  final String id;
}

class DownloadSelectAllAndDelete extends DownloadManagerEvent {
  const DownloadSelectAllAndDelete();
}

class DownloadDeleteSelected extends DownloadManagerEvent {
  const DownloadDeleteSelected();
}

class DownloadOpenCompleted extends DownloadManagerEvent {
  const DownloadOpenCompleted(this.id);

  final String id;
}
