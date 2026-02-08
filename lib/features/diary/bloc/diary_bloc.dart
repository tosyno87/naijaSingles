import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/diary_repository.dart';

part 'diary_event.dart';
part 'diary_state.dart';

class DiaryBloc extends Bloc<DiaryEvent, DiaryState> {
  DiaryBloc({required this.repository}) : super(DiaryInitial()) {
    on<LoadDiaryEntries>(_onLoad);
    on<AddDiaryEntryEvent>(_onAdd);
    on<_DiaryEntriesUpdated>(_onEntriesUpdated);
  }
  final DiaryRepository repository;
  StreamSubscription<List<DiaryEntry>>? _subscription;

  Future<void> _onLoad(LoadDiaryEntries event, Emitter<DiaryState> emit) async {
    emit(DiaryLoading());
    await _subscription?.cancel();
    _subscription = repository.entriesStream().listen((entries) {
      add(_DiaryEntriesUpdated(entries));
    });
  }

  Future<void> _onAdd(
    AddDiaryEntryEvent event,
    Emitter<DiaryState> emit,
  ) async {
    try {
      await repository.addEntry(
        userId: event.userId,
        content: event.content,
        userName: event.userName,
        userImage: event.userImage,
      );
    } catch (e) {
      emit(DiaryError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  void _onEntriesUpdated(_DiaryEntriesUpdated event, Emitter<DiaryState> emit) {
    emit(DiaryLoaded(event.entries));
  }
}

class _DiaryEntriesUpdated extends DiaryEvent {
  const _DiaryEntriesUpdated(this.entries);
  final List<DiaryEntry> entries;

  @override
  List<Object> get props => [entries];
}
