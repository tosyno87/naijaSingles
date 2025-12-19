part of 'diary_bloc.dart';

abstract class DiaryState extends Equatable {
  const DiaryState();

  @override
  List<Object> get props => [];
}

class DiaryInitial extends DiaryState {}

class DiaryLoading extends DiaryState {}

class DiaryLoaded extends DiaryState {
  const DiaryLoaded(this.entries);
  final List<DiaryEntry> entries;

  @override
  List<Object> get props => [entries];
}

class DiaryError extends DiaryState {
  const DiaryError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
