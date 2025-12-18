import 'package:cloud_firestore/cloud_firestore.dart';

class ProfessionalProfile {

  const ProfessionalProfile({
    required this.id,
    required this.userId,
    required this.userName,
    required this.jobTitle,
    required this.company,
    required this.industry,
    required this.country,
    required this.city,
    required this.experience,
    required this.skills,
    required this.certifications,
    required this.bio,
    required this.linkedinUrl,
    required this.portfolioUrl,
    required this.languages,
    required this.education,
    required this.university,
    required this.isAvailableForMentorship,
    required this.isSeekingMentorship,
    required this.mentorshipAreas,
    required this.createdAt,
    required this.updatedAt,
    required this.isVerified,
    required this.connectionsCount,
    required this.connectionIds,
  });

  factory ProfessionalProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfessionalProfile(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      jobTitle: data['jobTitle'] ?? '',
      company: data['company'] ?? '',
      industry: data['industry'] ?? '',
      country: data['country'] ?? '',
      city: data['city'] ?? '',
      experience: data['experience'] ?? 'Entry',
      skills: List<String>.from(data['skills'] ?? []),
      certifications: List<String>.from(data['certifications'] ?? []),
      bio: data['bio'] ?? '',
      linkedinUrl: data['linkedinUrl'] ?? '',
      portfolioUrl: data['portfolioUrl'] ?? '',
      languages: List<String>.from(data['languages'] ?? []),
      education: data['education'] ?? '',
      university: data['university'] ?? '',
      isAvailableForMentorship: data['isAvailableForMentorship'] ?? false,
      isSeekingMentorship: data['isSeekingMentorship'] ?? false,
      mentorshipAreas: List<String>.from(data['mentorshipAreas'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isVerified: data['isVerified'] ?? false,
      connectionsCount: data['connectionsCount'] ?? 0,
      connectionIds: List<String>.from(data['connectionIds'] ?? []),
    );
  }
  final String id;
  final String userId;
  final String userName;
  final String jobTitle;
  final String company;
  final String industry;
  final String country;
  final String city;
  final String experience; // 'Entry', 'Mid', 'Senior', 'Executive'
  final List<String> skills;
  final List<String> certifications;
  final String bio;
  final String linkedinUrl;
  final String portfolioUrl;
  final List<String> languages;
  final String education;
  final String university;
  final bool isAvailableForMentorship;
  final bool isSeekingMentorship;
  final List<String> mentorshipAreas;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified; // Professional verification
  final int connectionsCount;
  final List<String> connectionIds;

  Map<String, dynamic> toFirestore() => {
      'userId': userId,
      'userName': userName,
      'jobTitle': jobTitle,
      'company': company,
      'industry': industry,
      'country': country,
      'city': city,
      'experience': experience,
      'skills': skills,
      'certifications': certifications,
      'bio': bio,
      'linkedinUrl': linkedinUrl,
      'portfolioUrl': portfolioUrl,
      'languages': languages,
      'education': education,
      'university': university,
      'isAvailableForMentorship': isAvailableForMentorship,
      'isSeekingMentorship': isSeekingMentorship,
      'mentorshipAreas': mentorshipAreas,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVerified': isVerified,
      'connectionsCount': connectionsCount,
      'connectionIds': connectionIds,
    };
}

class MentorshipRequest {

  const MentorshipRequest({
    required this.id,
    required this.mentorId,
    required this.menteeId,
    required this.mentorName,
    required this.menteeName,
    required this.area,
    required this.message,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.completedAt,
    this.feedback,
  });

  factory MentorshipRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MentorshipRequest(
      id: doc.id,
      mentorId: data['mentorId'] ?? '',
      menteeId: data['menteeId'] ?? '',
      mentorName: data['mentorName'] ?? '',
      menteeName: data['menteeName'] ?? '',
      area: data['area'] ?? '',
      message: data['message'] ?? '',
      status: data['status'] ?? 'Pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      feedback: data['feedback'],
    );
  }
  final String id;
  final String mentorId;
  final String menteeId;
  final String mentorName;
  final String menteeName;
  final String area; // 'Career', 'Skills', 'Industry', 'Leadership'
  final String message;
  final String status; // 'Pending', 'Accepted', 'Declined', 'Completed'
  final DateTime createdAt;
  final DateTime? respondedAt;
  final DateTime? completedAt;
  final String? feedback;

  Map<String, dynamic> toFirestore() => {
      'mentorId': mentorId,
      'menteeId': menteeId,
      'mentorName': mentorName,
      'menteeName': menteeName,
      'area': area,
      'message': message,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt':
          respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'feedback': feedback,
    };
}
