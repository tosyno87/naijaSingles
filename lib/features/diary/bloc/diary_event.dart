part of 'diary_bloc.dart';

abstract class DiaryEvent extends Equatable {
  const DiaryEvent();

  @override
  List<Object> get props => [];
}

class LoadDiaryEntries extends DiaryEvent {}

class AddDiaryEntryEvent extends DiaryEvent {
  final String userId;
  final String content;
  final String userName;
  final String? userImage;

  const AddDiaryEntryEvent({
    required this.userId,
    required this.content,
    required this.userName,
    required this.userImage,
  });

  @override
  List<Object> get props => [userId, content, userName, userImage ?? ''];
}
