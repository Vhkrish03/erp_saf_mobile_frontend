enum NoticeCategory { academic, event, exam, holiday, general }

class Notice {
  final String id;
  final String title;
  final String description;
  final String date;
  final NoticeCategory category;
  final bool isImportant;
  final String uploaderRole;
  final String department;
  final String purpose;
  final String? fileUrl;
  final String status;

  Notice({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.category,
    this.isImportant = false,
    this.uploaderRole = 'ADMIN',
    this.department = 'ALL',
    this.purpose = '',
    this.fileUrl,
    this.status = 'APPROVED',
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json["id"]?.toString() ?? '',
      title: json["title"] ?? '',
      description: json["description"] ?? '',
      date: json["date"] ?? '',
      category: NoticeCategory.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
            (json["category"]?.toString().toLowerCase() ?? ''),
        orElse: () => NoticeCategory.general,
      ),
      isImportant:
          (json["isImportant"] ?? json["important"])
              ?.toString()
              .toLowerCase() ==
          'true',
      uploaderRole: json["uploaderRole"] ?? 'ADMIN',
      department: json['department'] ?? 'ALL',
      purpose: json['purpose'] ?? '',
      fileUrl: json['fileUrl'],
      status: json['status'] ?? 'APPROVED',
    );
  }
}

class FeeItem {
  final String particular;
  final double amount;
  final bool isPaid;
  final String dueDate;

  const FeeItem({
    required this.particular,
    required this.amount,
    required this.isPaid,
    required this.dueDate,
  });
}

class LibraryBook {
  final String title;
  final String author;
  final String issueDate;
  final String dueDate;
  final bool isOverdue;

  const LibraryBook({
    required this.title,
    required this.author,
    required this.issueDate,
    required this.dueDate,
    required this.isOverdue,
  });
}
