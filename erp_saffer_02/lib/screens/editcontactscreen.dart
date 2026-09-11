import 'package:flutter/material.dart';
import '../models/contact_update_request.dart';
import '../models/student.dart';
import '../services/student_service.dart';
import '../theme/app_theme.dart';

class EditContactScreen extends StatefulWidget {
  final Student student;

  const EditContactScreen({
    super.key,
    required this.student,
  });

  @override
  State<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController emergencyNameController;
  late TextEditingController emergencyPhoneController;
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();

    emailController =
        TextEditingController(text: widget.student.email);

    phoneController =
        TextEditingController(text: widget.student.phone);

    emergencyNameController =
        TextEditingController(
            text: widget.student.emergencyContactName);

    emergencyPhoneController =
        TextEditingController(
            text: widget.student.emergencyContactPhone);

    addressController =
        TextEditingController(text: widget.student.address);
  }

  @override
  void dispose() {
    emailController.dispose();
    phoneController.dispose();
    emergencyNameController.dispose();
    emergencyPhoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  void saveChanges() async {

    bool hasChanged =
        emailController.text.trim() != widget.student.email ||
            phoneController.text.trim() != widget.student.phone ||
            addressController.text.trim() != widget.student.address ||
            emergencyNameController.text.trim() != widget.student.emergencyContactName ||
            emergencyPhoneController.text.trim() != widget.student.emergencyContactPhone;

    if (!hasChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please update at least one field before saving.",
          ),
        ),
      );
      return;
    }

    ContactUpdateRequest request = ContactUpdateRequest(
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      address: addressController.text.trim(),
      emergencyContactName: emergencyNameController.text.trim(),
      emergencyContactPhone: emergencyPhoneController.text.trim(),
    );

    try {
      await StudentService().updateContact(
        widget.student.id,
        request,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Contact details updated successfully."),
        ),
      );

      Navigator.pop(context, true);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Update failed: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(
        title: const Text("Edit Contact Details"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                  ),
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return "Enter email";
                  //   }
                  //   return null;
                  // },
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    prefixIcon: Icon(Icons.phone),
                  ),
                  // validator: (value) {
                  //   if (value == null || value.length != 10) {
                  //     return "Enter valid phone number";
                  //   }
                  //   return null;
                  // },
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: emergencyNameController,
                  decoration: const InputDecoration(
                    labelText: "Emergency Contact Name",
                    prefixIcon: Icon(Icons.person),
                  ),
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return "Enter emergency contact name";
                  //   }
                  //   return null;
                  // },
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: emergencyPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Emergency Contact Number",
                    prefixIcon: Icon(Icons.contact_phone),
                  ),
                  // validator: (value) {
                  //   if (value == null || value.length != 10) {
                  //     return "Enter valid emergency number";
                  //   }
                  //   return null;
                  // },
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: addressController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Address",
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return "Enter address";
                  //   }
                  //   return null;
                  // },
                ),

                const SizedBox(height: 35),

                Row(
                  children: [

                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel"),
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: saveChanges,
                        child: const Text("Save Changes"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}