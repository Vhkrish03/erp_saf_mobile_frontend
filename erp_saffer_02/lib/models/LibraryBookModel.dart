class LibraryBook {
  final String title;
  final String author;
  final String issueDate;
  final String dueDate;
  final bool isOverdue;

  LibraryBook({
    required this.title,
    required this.author,
    required this.issueDate,
    required this.dueDate,
    required this.isOverdue,
  });

  factory LibraryBook.fromJson(Map<String, dynamic> json) {
    return LibraryBook(
      title: json["title"],
      author: json["author"],
      issueDate: json["issueDate"],
      dueDate: json["dueDate"],
      isOverdue: json["overdue"] ?? json["isOverdue"],
    );
  }
}