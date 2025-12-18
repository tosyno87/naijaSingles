import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../../common/providers/user_provider.dart';
import '../../bloc/diary_bloc.dart';
import '../../data/diary_repository.dart';

class DiaryFeedScreen extends StatefulWidget {
  const DiaryFeedScreen({super.key});

  @override
  State<DiaryFeedScreen> createState() => _DiaryFeedScreenState();
}

class _DiaryFeedScreenState extends State<DiaryFeedScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<DiaryBloc>().add(LoadDiaryEntries());
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: Text('Diary Feed'.tr()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        InputDecoration(hintText: 'Write something...'.tr()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      context.read<DiaryBloc>().add(AddDiaryEntryEvent(
                            userId: user.id!,
                            content: text,
                            userName: user.name ?? '',
                            userImage: user.imageUrl != null &&
                                    user.imageUrl!.isNotEmpty
                                ? user.imageUrl!.first
                                : null,
                          ),);
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<DiaryBloc, DiaryState>(
              builder: (context, state) {
                if (state is DiaryLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is DiaryLoaded) {
                  if (state.entries.isEmpty) {
                    return Center(child: Text('No entries'.tr()));
                  }
                  return ListView.builder(
                    itemCount: state.entries.length,
                    itemBuilder: (context, index) {
                      final entry = state.entries[index];
                      return ListTile(
                        leading: entry.userImage != null
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(entry.userImage!),
                              )
                            : const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(entry.userName),
                        subtitle: Text(entry.content),
                        trailing: Text(DateFormat('MMM d, HH:mm')
                            .format(entry.timestamp.toDate()),),
                      );
                    },
                  );
                } else if (state is DiaryError) {
                  return Center(child: Text(state.message));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DiaryFeedPage extends StatelessWidget {
  const DiaryFeedPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (_) => DiaryBloc(repository: DiaryRepository()),
      child: const DiaryFeedScreen(),
    );
}
