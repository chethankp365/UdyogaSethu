import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/community/data/community_repository.dart';
import 'package:udyogasethu/features/community/domain/community_models.dart';
import 'package:udyogasethu/features/rewards/data/rewards_repository.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class LearningHubScreen extends ConsumerStatefulWidget {
  final String? initialModuleId;

  const LearningHubScreen({super.key, this.initialModuleId});

  @override
  ConsumerState<LearningHubScreen> createState() => _LearningHubScreenState();
}

class _LearningHubScreenState extends ConsumerState<LearningHubScreen> {
  void _openUploadCertificateDialog(BuildContext context, AppLocalizations l10n) {
    final titleController = TextEditingController();
    final orgController = TextEditingController();
    final pathController = TextEditingController(text: 'certificates/scan_doc_01.pdf');
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.learningUploadTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.learningUploadPendingNotice,
                            style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: l10n.learningUploadDocTitle,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: orgController,
                    decoration: InputDecoration(
                      labelText: l10n.learningUploadIssuingOrg,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: pathController,
                    decoration: InputDecoration(
                      labelText: l10n.learningUploadFile,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.headerGreenDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isSubmitting = true);
                              try {
                                await ref
                                    .read(communityRepositoryProvider)
                                    .uploadExternalCertificate(
                                      kind: 'external_credential',
                                      title: titleController.text.trim(),
                                      issuingOrg: orgController.text.trim(),
                                      certificatePath: pathController.text.trim(),
                                    );
                                if (context.mounted) {
                                  Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.learningUploadSuccess),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                  ref.invalidate(userCredentialsProvider);
                                }
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString().replaceAll('Exception: ', '')),
                                      backgroundColor: AppColors.errorRed,
                                    ),
                                  );
                                }
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(l10n.learningUploadTitle),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openModuleDetail(BuildContext context, LearningModule module,
      AppLocalizations l10n, String locale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      module.getTitle(locale),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.mintBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      module.category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.headerGreenDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.learningDurationMinutes(module.durationMinutes),
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  if (module.isCompleted) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.cardBorderGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.learningModuleCompleted,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.headerGreenDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                module.summary,
                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Module Content Sections
              ...module.sections.map((sec) => Padding(
                    padding: const EdgeInsets.only(bottom: 14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sec['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sec['body'] ?? '',
                          style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.headerGreenDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _openQuizModal(context, module, l10n);
                  },
                  icon: const Icon(Icons.quiz_outlined, size: 20),
                  label: Text(l10n.learningTakeQuiz),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _openQuizModal(BuildContext context, LearningModule module, AppLocalizations l10n) {
    final questions = module.questions;
    final Map<int, int> selectedAnswers = {};
    bool isSubmitting = false;
    int? resultScore;
    bool? passed;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            expand: false,
            builder: (_, scrollController) => Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.learningQuizTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.learningQuizPassMark,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),

                  if (resultScore != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: passed == true
                            ? AppColors.mintBackground
                            : AppColors.dangerBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: passed == true
                              ? AppColors.cardBorderGreen
                              : AppColors.errorRed.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            passed == true ? Icons.check_circle : Icons.cancel,
                            color: passed == true ? AppColors.success : AppColors.errorRed,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            passed == true
                                ? l10n.learningQuizPassed(resultScore!)
                                : l10n.learningQuizFailed(resultScore!),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: passed == true
                                  ? AppColors.headerGreenDark
                                  : AppColors.errorRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  ...List.generate(questions.length, (qIdx) {
                    final q = questions[qIdx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Q${qIdx + 1}. ${q.question}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(q.options.length, (optIdx) {
                            final opt = q.options[optIdx];
                            final isSelected = selectedAnswers[qIdx] == optIdx;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.mintBackground : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.headerGreenDark
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: InkWell(
                                onTap: () {
                                  setModalState(() => selectedAnswers[qIdx] = optIdx);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        size: 20,
                                        color: isSelected
                                            ? AppColors.headerGreenDark
                                            : Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          opt,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textDark,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.headerGreenDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: (selectedAnswers.length < questions.length || isSubmitting)
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);

                              // Calculate score
                              int correct = 0;
                              for (int i = 0; i < questions.length; i++) {
                                if (selectedAnswers[i] == questions[i].answerIndex) {
                                  correct++;
                                }
                              }
                              final score = ((correct / questions.length) * 100).round();

                              try {
                                final res = await ref
                                    .read(communityRepositoryProvider)
                                    .submitLearningQuiz(
                                      moduleId: module.id,
                                      score: score,
                                    );

                                setModalState(() {
                                  isSubmitting = false;
                                  resultScore = score;
                                  passed = res['passed'] == true;
                                });

                                ref.invalidate(learningModulesProvider);
                                ref.invalidate(userCredentialsProvider);
                                ref.invalidate(gamificationProfileProvider);
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString().replaceAll('Exception: ', '')),
                                      backgroundColor: AppColors.errorRed,
                                    ),
                                  );
                                }
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(l10n.learningQuizSubmit),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final credsAsync = ref.watch(userCredentialsProvider);
    final modulesAsync = ref.watch(learningModulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.learningHubTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: l10n.learningUploadCertificateAction,
            onPressed: () => _openUploadCertificateDialog(context, l10n),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.headerGreenDark,
        onRefresh: () async {
          ref.invalidate(userCredentialsProvider);
          ref.invalidate(learningModulesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Credentials Ribbon
              _buildCredentialsSection(context, credsAsync, l10n),
              const SizedBox(height: 20),

              // 2. Learning Modules Header
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  const Text(
                    'Micro-Courses (5 Mins Each)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mintBackground,
                      foregroundColor: AppColors.headerGreenDark,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _openUploadCertificateDialog(context, l10n),
                    icon: const Icon(Icons.file_upload_outlined, size: 16),
                    label: Text(l10n.learningUploadCertificateAction, style: const TextStyle(fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Module Cards
              modulesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: AppColors.headerGreenDark),
                  ),
                ),
                error: (err, _) => Text(err.toString(), style: const TextStyle(color: AppColors.textMuted)),
                data: (modules) {
                  if (modules.isEmpty) {
                    return const Text(
                      'No learning modules available.',
                      style: TextStyle(color: AppColors.textMuted),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: modules.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (ctx, index) {
                      final mod = modules[index];

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: mod.isCompleted
                                ? AppColors.cardBorderGreen
                                : Colors.grey.shade200,
                            width: mod.isCompleted ? 1.5 : 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _openModuleDetail(context, mod, l10n, locale),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: mod.isCompleted
                                          ? AppColors.cardBorderGreen
                                          : AppColors.mintBackground,
                                      child: Icon(
                                        mod.isCompleted ? Icons.check : Icons.menu_book,
                                        color: AppColors.headerGreenDark,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mod.getTitle(locale),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${mod.category.toUpperCase()} · ${l10n.learningDurationMinutes(mod.durationMinutes)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (mod.isCompleted)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.mintBackground,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          mod.bestScore != null ? '${mod.bestScore}% ✓' : 'Done ✓',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.headerGreenDark,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  mod.summary,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialsSection(
      BuildContext context, AsyncValue<List<MicroCredential>> credsAsync, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.verified, color: AppColors.headerGreenDark, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.learningEarnedCredentialsTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        credsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: AppColors.headerGreenDark),
            ),
          ),
          error: (err, _) => Text(err.toString(), style: const TextStyle(color: AppColors.textMuted)),
          data: (creds) {
            if (creds.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Text(
                  'No micro-credentials earned yet. Complete a 5-minute module to earn your first certified credential!',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              );
            }

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: creds.map((c) {
                return Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: c.isVerified ? AppColors.mintBackground : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: c.isVerified
                          ? AppColors.cardBorderGreen
                          : Colors.amber.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        c.isVerified ? Icons.check_circle : Icons.hourglass_top,
                        size: 16,
                        color: c.isVerified
                            ? AppColors.headerGreenDark
                            : Colors.amber.shade900,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          c.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: c.isVerified
                                ? AppColors.headerGreenDark
                                : Colors.amber.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          c.isVerified
                              ? '(${l10n.learningVerifiedCredential})'
                              : '(${l10n.learningPendingReview})',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: c.isVerified
                                ? AppColors.headerGreenDark
                                : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
