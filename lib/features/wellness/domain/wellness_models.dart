import 'package:flutter/material.dart';

class EmergencyHelplineItem {
  final String name;
  final String number;
  final String subtitle;
  final String badge;
  final IconData icon;

  const EmergencyHelplineItem({
    required this.name,
    required this.number,
    required this.subtitle,
    required this.badge,
    required this.icon,
  });
}

class SafetyGuidelineItem {
  final String title;
  final String category;
  final String summary;
  final List<String> tips;
  final IconData icon;

  const SafetyGuidelineItem({
    required this.title,
    required this.category,
    required this.summary,
    required this.tips,
    required this.icon,
  });
}
