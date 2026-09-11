import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_constants.dart';
import '../models/event_model.dart';

class EventService {
  static const String endpoint = "${ApiConstants.baseUrl}/api/events";

  Future<List<EventModel>> getPublishedEvents() async {
    final response = await http.get(
      Uri.parse("$endpoint/published"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => EventModel.fromJson(e)).toList();
    }
    throw Exception("Failed to load published events: ${response.statusCode}");
  }

  Future<List<EventModel>> getEventsForUser(
    String referenceId,
    String role,
  ) async {
    final response = await http.get(
      Uri.parse("$endpoint?referenceId=$referenceId&role=$role"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => EventModel.fromJson(e)).toList();
    }
    throw Exception("Failed to load events for user: ${response.statusCode}");
  }

  Future<List<EventModel>> getMyEvents(String referenceId, String role) async {
    final response = await http.get(
      Uri.parse("$endpoint/my-events?referenceId=$referenceId&role=$role"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => EventModel.fromJson(e)).toList();
    }
    throw Exception("Failed to load user's events: ${response.statusCode}");
  }

  Future<List<EventModel>> getPendingApprovals(
    String referenceId,
    String role,
  ) async {
    final response = await http.get(
      Uri.parse(
        "$endpoint/pending-approval?referenceId=$referenceId&role=$role",
      ),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => EventModel.fromJson(e)).toList();
    }
    throw Exception("Failed to load pending approvals: ${response.statusCode}");
  }

  Future<EventModel> createEvent(
    EventModel event,
    String referenceId,
    String role,
  ) async {
    final bodyMap = event.toJson();
    bodyMap['createdByReferenceId'] = referenceId;
    bodyMap['createdByRole'] = role;

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(bodyMap),
    );

    if (response.statusCode == 200) {
      return EventModel.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to create event: ${response.body}");
  }

  Future<EventModel> updateEvent(
    int eventId,
    EventModel event,
    String referenceId,
    String role,
  ) async {
    final response = await http.put(
      Uri.parse("$endpoint/$eventId?referenceId=$referenceId&role=$role"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(event.toJson()),
    );

    if (response.statusCode == 200) {
      return EventModel.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to update event: ${response.body}");
  }

  Future<EventModel> submitEvent(
    int eventId,
    String referenceId,
    String role,
  ) async {
    final response = await http.post(
      Uri.parse(
        "$endpoint/$eventId/submit?referenceId=$referenceId&role=$role",
      ),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return EventModel.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to submit event: ${response.body}");
  }

  Future<EventModel> approveEvent(
    int eventId,
    String referenceId,
    String role,
  ) async {
    final response = await http.post(
      Uri.parse(
        "$endpoint/$eventId/approve?referenceId=$referenceId&role=$role",
      ),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return EventModel.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to approve event: ${response.body}");
  }

  Future<EventModel> rejectEvent(
    int eventId,
    String reason,
    String referenceId,
    String role,
  ) async {
    final response = await http.post(
      Uri.parse(
        "$endpoint/$eventId/reject?reason=${Uri.encodeComponent(reason)}&referenceId=$referenceId&role=$role",
      ),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return EventModel.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to reject event: ${response.body}");
  }

  Future<EventModel> publishEvent(
    int eventId,
    String referenceId,
    String role,
  ) async {
    final response = await http.post(
      Uri.parse(
        "$endpoint/$eventId/publish?referenceId=$referenceId&role=$role",
      ),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return EventModel.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to publish event: ${response.body}");
  }

  Future<EventModel> cancelEvent(
    int eventId,
    String referenceId,
    String role,
  ) async {
    final response = await http.post(
      Uri.parse(
        "$endpoint/$eventId/cancel?referenceId=$referenceId&role=$role",
      ),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return EventModel.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to cancel event: ${response.body}");
  }

  Future<void> deleteEvent(int eventId, String referenceId, String role) async {
    final response = await http.delete(
      Uri.parse("$endpoint/$eventId?referenceId=$referenceId&role=$role"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Failed to delete event: ${response.body}");
    }
  }
}
