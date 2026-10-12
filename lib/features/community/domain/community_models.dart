import 'package:flutter/foundation.dart';

enum TrustLevel {
  high,
  medium,
  needsImprovement;

  static TrustLevel fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'high':
        return TrustLevel.high;
      case 'needs_improvement':
      case 'needs improvement':
      case 'low':
        return TrustLevel.needsImprovement;
      case 'medium':
      default:
        return TrustLevel.medium;
    }
  }
}

@immutable
class LocalityTrustIndex {
  final String localityName;
  final TrustLevel level;
  final double score;
  final int completedJobsCount;
  final int activeWorkersCount;
  final double disputeFreePercent;

  const LocalityTrustIndex({
    required this.localityName,
    required this.level,
    required this.score,
    required this.completedJobsCount,
    required this.activeWorkersCount,
    required this.disputeFreePercent,
  });

  factory LocalityTrustIndex.mockDefault() {
    return const LocalityTrustIndex(
      localityName: 'Bengaluru South & Rural Hub',
      level: TrustLevel.high,
      score: 4.9,
      completedJobsCount: 1420,
      activeWorkersCount: 380,
      disputeFreePercent: 99.2,
    );
  }
}

@immutable
class CommunityPost {
  final String id;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String? authorAvatar;
  final String kind; // 'story', 'hero', 'tip', 'update'
  final String title;
  final String body;
  final List<String> images;
  final String? locality;
  final DateTime createdAt;

  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    this.authorAvatar,
    required this.kind,
    required this.title,
    required this.body,
    this.images = const [],
    this.locality,
    required this.createdAt,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final imagesList = (json['images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return CommunityPost(
      id: (json['id'] as String?) ?? '',
      authorId: (json['author_id'] as String?) ?? '',
      authorName: (profile?['full_name'] as String?) ??
          (json['author_name'] as String?) ??
          'Community Member',
      authorRole: (profile?['role'] as String?) ??
          (json['author_role'] as String?) ??
          'Worker',
      authorAvatar: (profile?['avatar_path'] as String?) ??
          json['author_avatar'] as String?,
      kind: (json['kind'] as String?) ?? 'story',
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      images: imagesList,
      locality: json['locality'] as String? ?? 'Bengaluru Urban',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

@immutable
class TrainingEvent {
  final String id;
  final String kind; // 'workshop', 'camp', 'webinar'
  final String title;
  final String? description;
  final DateTime startsAt;
  final String venue;
  final int? capacity;
  final String language;
  final bool isRegistered;

  const TrainingEvent({
    required this.id,
    required this.kind,
    required this.title,
    this.description,
    required this.startsAt,
    required this.venue,
    this.capacity,
    required this.language,
    this.isRegistered = false,
  });

  factory TrainingEvent.fromJson(Map<String, dynamic> json, {bool isRegistered = false}) {
    return TrainingEvent(
      id: (json['id'] as String?) ?? '',
      kind: (json['kind'] as String?) ?? 'workshop',
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
      startsAt: json['starts_at'] != null
          ? DateTime.tryParse(json['starts_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      venue: (json['venue'] as String?) ?? '',
      capacity: (json['capacity'] as num?)?.toInt(),
      language: (json['language'] as String?) ?? 'en',
      isRegistered: isRegistered || (json['is_registered'] as bool? ?? false),
    );
  }

  TrainingEvent copyWith({bool? isRegistered}) {
    return TrainingEvent(
      id: id,
      kind: kind,
      title: title,
      description: description,
      startsAt: startsAt,
      venue: venue,
      capacity: capacity,
      language: language,
      isRegistered: isRegistered ?? this.isRegistered,
    );
  }
}

@immutable
class QuizQuestion {
  final String question;
  final List<String> options;
  final int answerIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: (json['q'] as String?) ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      answerIndex: (json['answer'] as num?)?.toInt() ?? 0,
      explanation: (json['explanation'] as String?) ?? '',
    );
  }
}

@immutable
class LearningModule {
  final String id;
  final String slug;
  final Map<String, dynamic> titles;
  final String category;
  final String summary;
  final String? videoUrl;
  final int durationMinutes;
  final List<Map<String, String>> sections;
  final int passPercent;
  final List<QuizQuestion> questions;
  final bool isCompleted;
  final int? bestScore;

  const LearningModule({
    required this.id,
    required this.slug,
    required this.titles,
    required this.category,
    required this.summary,
    this.videoUrl,
    required this.durationMinutes,
    required this.sections,
    required this.passPercent,
    required this.questions,
    this.isCompleted = false,
    this.bestScore,
  });

  String getTitle(String localeCode) {
    if (titles.containsKey(localeCode)) {
      return titles[localeCode].toString();
    }
    return titles['en']?.toString() ?? slug;
  }

  factory LearningModule.fromJson(Map<String, dynamic> json, {bool isCompleted = false, int? score}) {
    final content = (json['content'] as Map<String, dynamic>?) ?? {};
    final quiz = (json['quiz'] as Map<String, dynamic>?) ?? {};

    final rawSections = (content['sections'] as List<dynamic>?) ?? [];
    final sections = rawSections.map((s) {
      final map = s as Map<String, dynamic>;
      return {
        'title': (map['title'] as String?) ?? '',
        'body': (map['body'] as String?) ?? '',
      };
    }).toList();

    final rawQuestions = (quiz['questions'] as List<dynamic>?) ?? [];
    final questions = rawQuestions
        .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
        .toList();

    return LearningModule(
      id: (json['id'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
      titles: (json['titles'] as Map<String, dynamic>?) ?? {},
      category: (json['category'] as String?) ?? 'general',
      summary: (content['summary'] as String?) ?? '',
      videoUrl: content['video_url'] as String?,
      durationMinutes: (content['duration_minutes'] as num?)?.toInt() ?? 5,
      sections: sections,
      passPercent: (quiz['pass_percent'] as num?)?.toInt() ?? 80,
      questions: questions,
      isCompleted: isCompleted,
      bestScore: score,
    );
  }
}

@immutable
class MicroCredential {
  final String id;
  final String userId;
  final String kind;
  final String sourceType; // 'module', 'uploaded_certificate', 'admin_grant'
  final String? moduleId;
  final String? certificatePath;
  final bool isVerified;
  final DateTime? verifiedAt;
  final String title;
  final String? issuingOrganization;
  final DateTime issuedAt;

  const MicroCredential({
    required this.id,
    required this.userId,
    required this.kind,
    required this.sourceType,
    this.moduleId,
    this.certificatePath,
    required this.isVerified,
    this.verifiedAt,
    required this.title,
    this.issuingOrganization,
    required this.issuedAt,
  });

  factory MicroCredential.fromJson(Map<String, dynamic> json) {
    return MicroCredential(
      id: (json['id'] as String?) ?? '',
      userId: (json['user_id'] as String?) ?? '',
      kind: (json['kind'] as String?) ?? 'general',
      sourceType: (json['source_type'] as String?) ?? 'module',
      moduleId: json['module_id'] as String?,
      certificatePath: json['certificate_path'] as String?,
      isVerified: (json['is_verified'] as bool?) ?? false,
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'].toString())
          : null,
      title: (json['title'] as String?) ??
          (json['kind'] as String?) ??
          'Certificate',
      issuingOrganization: json['issuing_organization'] as String?,
      issuedAt: json['issued_at'] != null
          ? DateTime.tryParse(json['issued_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
