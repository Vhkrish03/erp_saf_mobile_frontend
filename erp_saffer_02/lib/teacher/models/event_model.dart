class EventModel {
  final int? id;
  final String title;
  final String description;
  final String eventType; // "COLLEGE_EVENT" or "EXTERNAL_EVENT"
  final String? organizerName;
  final String? organizerDepartment;
  final String? venue;
  final DateTime eventDate;
  final String? startTime; // "HH:mm:ss" or "HH:mm"
  final String? endTime;
  final DateTime? registrationStartDate;
  final DateTime? registrationEndDate;
  final bool registrationRequired;
  final String? registrationLink;
  final String? contactPerson;
  final String? contactEmail;
  final String? contactPhone;
  final String? eligibility;
  final String? targetAudience; // "ALL", "STUDENTS", "TEACHERS"
  final String? department;
  final String? year;
  final String? section;
  final String? imageUrl;
  final String? attachmentUrl;
  final String
  status; // "DRAFT", "PENDING_APPROVAL", "PUBLISHED", "REJECTED", "CANCELLED"
  final String? rejectionReason;
  final int? createdById;
  final String? createdByName;
  final String? createdByRole;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  EventModel({
    this.id,
    required this.title,
    required this.description,
    required this.eventType,
    this.organizerName,
    this.organizerDepartment,
    this.venue,
    required this.eventDate,
    this.startTime,
    this.endTime,
    this.registrationStartDate,
    this.registrationEndDate,
    required this.registrationRequired,
    this.registrationLink,
    this.contactPerson,
    this.contactEmail,
    this.contactPhone,
    this.eligibility,
    this.targetAudience,
    this.department,
    this.year,
    this.section,
    this.imageUrl,
    this.attachmentUrl,
    required this.status,
    this.rejectionReason,
    this.createdById,
    this.createdByName,
    this.createdByRole,
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      eventType: json['eventType'] as String? ?? 'COLLEGE_EVENT',
      organizerName: json['organizerName'] as String?,
      organizerDepartment: json['organizerDepartment'] as String?,
      venue: json['venue'] as String?,
      eventDate:
          json['eventDate'] != null
              ? DateTime.parse(json['eventDate'] as String)
              : DateTime.now(),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      registrationStartDate:
          json['registrationStartDate'] != null
              ? DateTime.parse(json['registrationStartDate'] as String)
              : null,
      registrationEndDate:
          json['registrationEndDate'] != null
              ? DateTime.parse(json['registrationEndDate'] as String)
              : null,
      registrationRequired: json['registrationRequired'] as bool? ?? false,
      registrationLink: json['registrationLink'] as String?,
      contactPerson: json['contactPerson'] as String?,
      contactEmail: json['contactEmail'] as String?,
      contactPhone: json['contactPhone'] as String?,
      eligibility: json['eligibility'] as String?,
      targetAudience: json['targetAudience'] as String?,
      department: json['department'] as String?,
      year: json['year'] as String?,
      section: json['section'] as String?,
      imageUrl: json['imageUrl'] as String?,
      attachmentUrl: json['attachmentUrl'] as String?,
      status: json['status'] as String? ?? 'DRAFT',
      rejectionReason: json['rejectionReason'] as String?,
      createdById: json['createdById'] as int?,
      createdByName: json['createdByName'] as String?,
      createdByRole: json['createdByRole'] as String?,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : null,
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : null,
      publishedAt:
          json['publishedAt'] != null
              ? DateTime.parse(json['publishedAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'eventType': eventType,
      'organizerName': organizerName,
      'organizerDepartment': organizerDepartment,
      'venue': venue,
      'eventDate':
          "${eventDate.year.toString().padLeft(4, '0')}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}",
      'startTime': startTime,
      'endTime': endTime,
      'registrationStartDate':
          registrationStartDate != null
              ? "${registrationStartDate!.year.toString().padLeft(4, '0')}-${registrationStartDate!.month.toString().padLeft(2, '0')}-${registrationStartDate!.day.toString().padLeft(2, '0')}"
              : null,
      'registrationEndDate':
          registrationEndDate != null
              ? "${registrationEndDate!.year.toString().padLeft(4, '0')}-${registrationEndDate!.month.toString().padLeft(2, '0')}-${registrationEndDate!.day.toString().padLeft(2, '0')}"
              : null,
      'registrationRequired': registrationRequired,
      'registrationLink': registrationLink,
      'contactPerson': contactPerson,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'eligibility': eligibility,
      'targetAudience': targetAudience,
      'department': department,
      'year': year,
      'section': section,
      'imageUrl': imageUrl,
      'attachmentUrl': attachmentUrl,
      'status': status,
      'rejectionReason': rejectionReason,
      'createdById': createdById,
      'createdByName': createdByName,
      'createdByRole': createdByRole,
    };
  }
}
