// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appName => 'ఉద్యోగసేతు';

  @override
  String get taglinePart1 => 'పని అనుసంధానం.';

  @override
  String get taglinePart2 => 'జీవితాల సాధికారత.';

  @override
  String get splashInitializing => 'ఉద్యోగసేతు ప్రారంభమవుతోంది...';

  @override
  String get chipAiMatching => 'AI మ్యాచింగ్';

  @override
  String get chipSecure => 'సురక్షితం';

  @override
  String get chipVerified => 'ధృవీకరించబడింది';

  @override
  String versionLabel(String version) {
    return 'వెర్షన్ $version';
  }

  @override
  String get introSkip => 'స్కిప్';

  @override
  String get introHeadline =>
      'భారత్ కోసం నిర్మించబడింది. ప్రతీ కార్మికుడి కోసం.';

  @override
  String get introSubtitle =>
      'దగ్గరలోని పనులు వెతకండి, నైపుణ్యాలు పెంచుకోండి, మెరుగ్గా సంపాదించండి.';

  @override
  String get introFeature1Title => 'మీ సమీపంలో పనులు వెతకండి';

  @override
  String get introFeature2Title => 'సురక్షిత చెల్లింపులు';

  @override
  String get introFeature3Title => 'AI వాయిస్ అసిస్టెంట్';

  @override
  String get introNext => 'తరువాత ->';

  @override
  String get introGetStarted => 'ప్రారంభించండి ->';
}
