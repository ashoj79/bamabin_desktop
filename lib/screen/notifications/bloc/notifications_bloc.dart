import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/app/notification.dart'
    as app;
import 'package:bamabin_desktop/repository/app_repository.dart';
import 'package:bamabin_desktop/utils/data_state.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc(this._appRepository) : super(NotificationsInitial()) {
    on<NotificationsLoadEvent>(_onLoad);
    on<NotificationsLoadMoreEvent>(_onLoadMore);
  }

  final AppRepository _appRepository;

  int _page = 0;
  var _items = <app.Notification>[];
  var _isEnd = false;
  var _isFetching = false;

  Future<void> _onLoad(
    NotificationsLoadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    _page = 0;
    _items = [];
    _isEnd = false;
    emit(NotificationsLoading());
    await _fetch(emit: emit, reset: true);
  }

  Future<void> _onLoadMore(
    NotificationsLoadMoreEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    if (_isEnd || _isFetching) return;
    if (state is NotificationsLoading || state is NotificationsLoadingMore) {
      return;
    }

    emit(NotificationsLoadingMore(items: List.unmodifiable(_items)));
    await _fetch(emit: emit, reset: false);
  }

  Future<void> _fetch({
    required Emitter<NotificationsState> emit,
    required bool reset,
  }) async {
    _isFetching = true;
    final result = await _appRepository.getAllNotifications(_page + 1);
    if (isClosed) return;
    _isFetching = false;

    if (result is DataSuccess<List<app.Notification>>) {
      final pageItems = result.data ?? const <app.Notification>[];
      if (reset) {
        _items = [...pageItems];
        TempDb.haveUnreadNotif.value = false;
      } else {
        _items = [..._items, ...pageItems];
      }
      _page++;
      if (pageItems.isEmpty) {
        _isEnd = true;
      }
      emit(
        NotificationsSuccess(
          items: List.unmodifiable(_items),
          hasMore: !_isEnd,
        ),
      );
      return;
    }

    if (result is DataError) {
      if (reset) {
        emit(NotificationsError(message: result.errorMessage));
      } else {
        emit(
          NotificationsSuccess(
            items: List.unmodifiable(_items),
            hasMore: !_isEnd,
          ),
        );
      }
    }
  }
}
