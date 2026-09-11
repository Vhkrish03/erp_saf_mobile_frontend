class RouteModel {
  final int id;
  final String routeName;
  final String description;
  final String status;

  RouteModel({
    required this.id,
    required this.routeName,
    required this.description,
    required this.status,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      routeName: json['routeName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'routeName': routeName,
      'description': description,
      'status': status,
    };
    if (id != 0) {
      data['id'] = id;
    }
    return data;
  }
}
