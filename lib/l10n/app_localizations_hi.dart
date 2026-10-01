// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'उद्योगसेतु';

  @override
  String get taglinePart1 => 'काम को जोड़ना।';

  @override
  String get taglinePart2 => 'जीवन को सशक्त बनाना।';

  @override
  String get splashInitializing => 'उद्योगसेतु शुरू हो रहा है...';

  @override
  String get chipAiMatching => 'एआई मैचिंग';

  @override
  String get chipSecure => 'सुरक्षित';

  @override
  String get chipVerified => 'सत्यापित';

  @override
  String versionLabel(String version) {
    return 'संस्करण $version';
  }

  @override
  String get introSkip => 'छोड़ें';

  @override
  String get introHeadline => 'भारत के लिए निर्मित। हर श्रमिक के लिए।';

  @override
  String get introSubtitle =>
      'पास के काम खोजें, कौशल बढ़ाएं, बेहतर कमाएं और गरिमा के साथ जिएं।';

  @override
  String get introFeature1Title => 'अपने पास काम खोजें';

  @override
  String get introFeature2Title => 'सुरक्षित भुगतान';

  @override
  String get introFeature3Title => 'एआई वॉयस असिस्टेंट';

  @override
  String get introNext => 'आगे ->';

  @override
  String get introGetStarted => 'शुरू करें ->';
}
