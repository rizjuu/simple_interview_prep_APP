import 'package:flutter/material.dart';

class InterviewControls extends StatelessWidget {
  final String selectedNiche;
  final List<String> nicheKeys;
  final String selectedMode;
  final List<String> modeKeys;
  final Function(String?) onNicheChanged;
  final Function(String?) onModeChanged;
  final VoidCallback onRestart;

  const InterviewControls({
    super.key,
    required this.selectedNiche,
    required this.nicheKeys,
    required this.selectedMode,
    required this.modeKeys,
    required this.onNicheChanged,
    required this.onModeChanged,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Restart Button
        ElevatedButton(
          onPressed: onRestart,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white24,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _buildDropdown(selectedNiche, nicheKeys, onNicheChanged),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: _buildDropdown(selectedMode, modeKeys, onModeChanged),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map(
                (k) => DropdownMenuItem(
                  value: k,
                  child: Text(k, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
