part of 'diary_bloc.dart';

abstract class DiaryState extends Equatable {
  const DiaryState();

  @override
  List<Object> get props => [];
}

class DiaryInitial extends DiaryState {}

class DiaryLoading extends DiaryState {}

class DiaryLoaded extends DiaryState {
  final List<DiaryEntry> entries;

  const DiaryLoaded(this.entries);

  @override
  List<Object> get props => [entries];
}

class DiaryError extends DiaryState {
  final String message;

  const DiaryError(this.message);

  @override
  List<Object> get props => [message];
}
