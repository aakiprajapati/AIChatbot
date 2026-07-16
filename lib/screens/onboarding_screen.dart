import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class OnboardingScreen extends StatefulWidget {
  final String uid;
  const OnboardingScreen({super.key, required this.uid});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final Set<String> _selected = {};
  bool _saving = false;

  Future<void> _saveAndContinue() async {
    if (_selected.isEmpty) return;
    setState(() => _saving = true);
    await _firestoreService.saveInterests(widget.uid, _selected.toList());
    // AuthGate's stream listener will pick up onboardingComplete=true
    // and route to ChatScreen automatically.
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('What are you into?')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pick a few interests. We\'ll tailor your chat responses '
                    'around them — you can change these later.',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kAvailableInterests.map((interest) {
                  final isSelected = _selected.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selected.add(interest);
                        } else {
                          _selected.remove(interest);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                  _selected.isEmpty || _saving ? null : _saveAndContinue,
                  child: _saving
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
