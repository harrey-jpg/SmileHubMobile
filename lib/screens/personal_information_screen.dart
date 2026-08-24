import 'package:flutter/material.dart';

import '../services/profile_service.dart';
import '../widgets/app_widgets.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends State<PersonalInformationScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _name =
      TextEditingController();

  final TextEditingController _email =
      TextEditingController();

  final TextEditingController _mobile =
      TextEditingController();

  final TextEditingController _clinic =
      TextEditingController();

  final ProfileService _profileService = ProfileService();

  static const List<String> _buyerTypes = <String>[
    'Dental Professional',
    'Dental Student',
    'Clinic Staff',
  ];

  String _buyerType = 'Dental Professional';

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    _clinic.dispose();
    super.dispose();
  }

  String get _initials {
    final List<String> nameParts = _name.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();

    if (nameParts.isEmpty) {
      return 'SH';
    }

    if (nameParts.length == 1) {
      return nameParts.first[0].toUpperCase();
    }

    return '${nameParts.first[0]}${nameParts.last[0]}'
        .toUpperCase();
  }

  Future<void> _loadProfile() async {
    try {
      final Map<String, String> profile =
          await _profileService.loadProfile();

      if (!mounted) return;

      final String loadedBuyerType =
          profile['buyerType'] ?? 'Dental Professional';

      _name.text = profile['fullName'] ?? '';
      _email.text = profile['email'] ?? '';
      _mobile.text = profile['mobile'] ?? '';
      _clinic.text = profile['clinic'] ?? '';

      setState(() {
        _buyerType = _buyerTypes.contains(loadedBuyerType)
            ? loadedBuyerType
            : 'Dental Professional';

        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      showAppSnackBar(
        context,
        'Unable to load personal information.',
      );

      debugPrint('Load profile error: $error');
    }
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _profileService.saveProfile(
        fullName: _name.text,
        mobile: _mobile.text,
        clinic: _clinic.text,
        buyerType: _buyerType,
      );

      if (!mounted) return;

      showAppSnackBar(
        context,
        'Personal information saved.',
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      showAppSnackBar(
        context,
        'Unable to save personal information.',
      );

      debugPrint('Save profile error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileScaffold(
      appBar: const ScreenTitleBar(
        title: 'Personal Information',
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                18,
                8,
                18,
                28,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    CircleAvatar(
                      radius: 43,
                      child: Text(
                        _initials,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        showAppSnackBar(
                          context,
                          'Profile photo picker simulated.',
                        );
                      },
                      child: const Text(
                        'Change profile photo',
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                        ),
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                      validator: (String? value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Enter your name';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _email,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                        ),
                        helperText:
                            'Your login email cannot be changed here.',
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _mobile,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Mobile number',
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                        ),
                      ),
                      validator: (String? value) {
                        final String digits = value
                                ?.replaceAll(
                                  RegExp(r'[^0-9]'),
                                  '',
                                ) ??
                            '';

                        if (digits.length < 10) {
                          return 'Enter a valid mobile number';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _clinic,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText:
                            'Clinic / Organization',
                        prefixIcon: Icon(
                          Icons.business_outlined,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: _buyerType,
                      decoration: const InputDecoration(
                        labelText: 'Buyer type',
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                        ),
                      ),
                      items: _buyerTypes
                          .map(
                            (String type) =>
                                DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: _isSaving
                          ? null
                          : (String? value) {
                              if (value == null) return;

                              setState(() {
                                _buyerType = value;
                              });
                            },
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed:
                          _isSaving ? null : _saveProfile,
                      child: Text(
                        _isSaving
                            ? 'Saving...'
                            : 'Save Changes',
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}