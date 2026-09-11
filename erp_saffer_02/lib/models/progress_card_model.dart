// Model for the complete verified Progress Card response from backend

class ProgressCardModel {
  final Map<String, dynamic> studentInfo;
  final Map<String, dynamic> verificationTrail;
  final Map<String, dynamic> semesterResult;
  final List<SubjectInternalModel> internalPerformance;
  final double cgpa;
  final List<SemesterOverviewModel> overallProgress;
  final Map<String, dynamic> performanceOverview;
  final List<RemarkModel> remarks;

  ProgressCardModel({
    required this.studentInfo,
    required this.verificationTrail,
    required this.semesterResult,
    required this.internalPerformance,
    required this.cgpa,
    required this.overallProgress,
    required this.performanceOverview,
    required this.remarks,
  });

  factory ProgressCardModel.fromJson(Map<String, dynamic> json) {
    return ProgressCardModel(
      studentInfo: Map<String, dynamic>.from(json['studentInfo'] ?? {}),
      verificationTrail: Map<String, dynamic>.from(
        json['verificationTrail'] ?? {},
      ),
      semesterResult: Map<String, dynamic>.from(json['semesterResult'] ?? {}),
      internalPerformance:
          (json['internalPerformance'] as List<dynamic>? ?? [])
              .map(
                (e) =>
                    SubjectInternalModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList(),
      cgpa: (json['cgpa'] as num?)?.toDouble() ?? 0.0,
      overallProgress:
          (json['overallProgress'] as List<dynamic>? ?? [])
              .map(
                (e) => SemesterOverviewModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList(),
      performanceOverview: Map<String, dynamic>.from(
        json['performanceOverview'] ?? {},
      ),
      remarks:
          (json['remarks'] as List<dynamic>? ?? [])
              .map((e) => RemarkModel.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
    );
  }

  String get overallInternalStatus =>
      verificationTrail['overallInternalStatus']?.toString() ?? 'NO_DATA';

  bool get isFinalized => overallInternalStatus == 'FINALIZED';

  double get sgpa => (semesterResult['sgpa'] as num?)?.toDouble() ?? 0.0;

  String get semesterResultStatus =>
      semesterResult['status']?.toString() ?? 'NOT_PUBLISHED';

  bool get isResultPublished => semesterResultStatus == 'PUBLISHED';
}

class SubjectInternalModel {
  final String subjectCode;
  final String subjectName;
  final int credits;
  final Map<String, dynamic> dailyTests;
  final String weeklyTestStatus;
  final Map<String, dynamic> iat1;
  final Map<String, dynamic> iat2;
  final double iat1Internal;
  final double iat2Internal;
  final String iat1Status;
  final String iat2Status;
  final double consolidatedInternal;
  final int finalInternal;
  final Map<String, dynamic>? storedInternalMark;

  SubjectInternalModel({
    required this.subjectCode,
    required this.subjectName,
    required this.credits,
    required this.dailyTests,
    required this.weeklyTestStatus,
    required this.iat1,
    required this.iat2,
    required this.iat1Internal,
    required this.iat2Internal,
    required this.iat1Status,
    required this.iat2Status,
    required this.consolidatedInternal,
    required this.finalInternal,
    this.storedInternalMark,
  });

  factory SubjectInternalModel.fromJson(Map<String, dynamic> json) {
    return SubjectInternalModel(
      subjectCode: json['subjectCode'] ?? '',
      subjectName: json['subjectName'] ?? '',
      credits: json['credits'] ?? 3,
      dailyTests: Map<String, dynamic>.from(json['dailyTests'] ?? {}),
      weeklyTestStatus: json['weeklyTestStatus'] ?? 'DRAFT',
      iat1: Map<String, dynamic>.from(json['iat1'] ?? {}),
      iat2: Map<String, dynamic>.from(json['iat2'] ?? {}),
      iat1Internal: (json['iat1Internal'] as num?)?.toDouble() ?? 0.0,
      iat2Internal: (json['iat2Internal'] as num?)?.toDouble() ?? 0.0,
      iat1Status: json['iat1Status'] ?? 'DRAFT',
      iat2Status: json['iat2Status'] ?? 'DRAFT',
      consolidatedInternal:
          (json['consolidatedInternal'] as num?)?.toDouble() ?? 0.0,
      finalInternal: (json['finalInternal'] as num?)?.toInt() ?? 0,
      storedInternalMark:
          json['storedInternalMark'] != null
              ? Map<String, dynamic>.from(json['storedInternalMark'])
              : null,
    );
  }

  bool get isWeeklyFinalized => weeklyTestStatus == 'DEAN_APPROVED';
  bool get isIat1Finalized => iat1Status == 'DEAN_APPROVED';
  bool get isIat2Finalized => iat2Status == 'DEAN_APPROVED';
}

class SemesterOverviewModel {
  final String semesterName;
  final double sgpa;
  final String? examSession;
  final String? publishedAt;

  SemesterOverviewModel({
    required this.semesterName,
    required this.sgpa,
    this.examSession,
    this.publishedAt,
  });

  factory SemesterOverviewModel.fromJson(Map<String, dynamic> json) {
    return SemesterOverviewModel(
      semesterName: json['semesterName'] ?? '',
      sgpa: (json['sgpa'] as num?)?.toDouble() ?? 0.0,
      examSession: json['examSession'],
      publishedAt: json['publishedAt']?.toString(),
    );
  }
}

class RemarkModel {
  final String remarkBy;
  final String? remarkByName;
  final String remarkByRole;
  final String remarkText;
  final String? createdAt;

  RemarkModel({
    required this.remarkBy,
    this.remarkByName,
    required this.remarkByRole,
    required this.remarkText,
    this.createdAt,
  });

  factory RemarkModel.fromJson(Map<String, dynamic> json) {
    return RemarkModel(
      remarkBy: json['remarkBy'] ?? '',
      remarkByName: json['remarkByName'],
      remarkByRole: json['remarkByRole'] ?? '',
      remarkText: json['remarkText'] ?? '',
      createdAt: json['createdAt']?.toString(),
    );
  }
}
