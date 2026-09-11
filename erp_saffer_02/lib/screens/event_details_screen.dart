import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../teacher/models/event_model.dart';
import '../theme/app_theme.dart';

class EventDetailsScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailsScreen({Key? key, required this.event}) : super(key: key);

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return "${dt.day} ${months[dt.month - 1]}, ${dt.year}";
  }

  void _openRegistrationLink(BuildContext context) async {
    if (event.registrationLink == null || event.registrationLink!.isEmpty)
      return;
    final urlString = event.registrationLink!;
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not launch registration link: $urlString"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error launching URL: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = event.imageUrl != null && event.imageUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Event Details",
          style: TextStyle(color: AppColors.brass, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image/Gradient Block
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.navy, AppColors.navyLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                image:
                    hasImage
                        ? DecorationImage(
                          image: NetworkImage(event.imageUrl!),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            event.eventType == 'COLLEGE_EVENT'
                                ? AppColors.brass
                                : const Color(0xFF2A5C99),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.eventType == 'COLLEGE_EVENT'
                            ? 'College Event'
                            : 'External Event',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta Info Grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        _metaItem(
                          Icons.calendar_month_outlined,
                          "Date",
                          _formatDate(event.eventDate),
                        ),
                        const Divider(height: 24),
                        _metaItem(
                          Icons.access_time_outlined,
                          "Time",
                          "${event.startTime ?? '09:00'} - ${event.endTime ?? '17:00'}",
                        ),
                        const Divider(height: 24),
                        _metaItem(
                          Icons.location_on_outlined,
                          "Venue",
                          event.venue ?? 'Main Campus Auditorium',
                        ),
                        if (event.targetAudience != null &&
                            event.targetAudience!.isNotEmpty) ...[
                          const Divider(height: 24),
                          _metaItem(
                            Icons.groups_outlined,
                            "Target Audience",
                            "${event.targetAudience!} "
                                "${event.department != null && event.department != 'ALL' ? '(${event.department})' : ''}"
                                "${event.year != null && event.year != 'ALL' ? ' - Year ${event.year}' : ''}",
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Description
                  const Text(
                    "About the Event",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.5,
                      color: AppColors.ink,
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Organizer / Contact details
                  const Text(
                    "Organizer & Contact Details",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (event.organizerName != null) ...[
                          Text(
                            event.organizerName!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.navy,
                            ),
                          ),
                          if (event.organizerDepartment != null)
                            Text(
                              "${event.organizerDepartment!} Department",
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          const SizedBox(height: 12),
                        ],
                        if (event.contactPerson != null &&
                            event.contactPerson!.isNotEmpty)
                          _contactField("Contact Person", event.contactPerson!),
                        if (event.contactEmail != null &&
                            event.contactEmail!.isNotEmpty)
                          _contactField("Email", event.contactEmail!),
                        if (event.contactPhone != null &&
                            event.contactPhone!.isNotEmpty)
                          _contactField("Phone", event.contactPhone!),
                        if (event.eligibility != null &&
                            event.eligibility!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            "Eligibility",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brass,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.eligibility!,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Registration Banner
                  if (event.registrationRequired) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.brass.withOpacity(0.08),
                        border: Border.all(
                          color: AppColors.brass.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.app_registration,
                                color: AppColors.brass,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Registration Required",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.navy,
                                ),
                              ),
                            ],
                          ),
                          if (event.registrationStartDate != null ||
                              event.registrationEndDate != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              "Registration Period:\n"
                              "${event.registrationStartDate != null ? _formatDate(event.registrationStartDate!) : 'Open'} to "
                              "${event.registrationEndDate != null ? _formatDate(event.registrationEndDate!) : 'Closing Date'}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navy,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text(
                              "Register Now",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed:
                                (event.registrationLink != null &&
                                        event.registrationLink!.isNotEmpty)
                                    ? () => _openRegistrationLink(context)
                                    : null,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle_outline, color: Colors.green),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              "Registration Not Required\nOpen entry for all targeted students.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.navy.withOpacity(0.65), size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contactField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13.5, color: AppColors.ink),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
