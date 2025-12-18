class BlockUserModel {

  BlockUserModel({
    required this.id,
    required this.chatID,
    required this.name,
    required this.imageUrl,
    required this.blockedTimestamp,
  });
  final String name;
  final String imageUrl;
  final String id;
  final String chatID;
  final DateTime blockedTimestamp;
}
