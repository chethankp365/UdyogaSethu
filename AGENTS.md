# Agent Rules for UdyogaSethu

• **Always**: Before any work read AGENTS.md, docs/PROJECT_CONTEXT.md, docs/PROGRESS.md (and docs/UI_REFERENCE.md for UI work). Do only the step I gave. Never start the next step. If the step needs an unfinished earlier step, stop and tell me.

• **Finish protocol**: Run `flutter analyze`, the overflow test suite (`tool/check_overflow.sh` or `tool/check_overflow.bat`), and `flutter test` when tests exist, and fix every issue. Update docs/PROGRESS.md (status, files created, manual steps I must do, known issues). End with a short report: what was built, how to test it, what is NOT done.

• **Zero Layout Overflow**: Every new screen and reusable card/row widget must be covered by the overflow test suite (using `runOverflowMatrix` / `pumpAtAllSizes` across logical widths 320–600dp, text scales 1.0–2.0, and supported locales) before it is marked finished. Fix all overflows at the root cause (Flexible/Expanded, Wrap, FittedBox on compact labels, scrollable tab bars, SingleChildScrollView). Never suppress overflow warnings.

• **Plan first**: For backend, auth, payments and verification, list the files you will touch before editing.

• **Honesty**: Anything simulated must be labelled "Demo mode" in the UI and recorded in docs/DECISIONS.md. Never present mock results as real verification, payment or insurance.

• **UI fidelity**: Match docs/UI_REFERENCE.md and the reference PNGs: same structure, texts, green/orange palette, centre mic button. You may improve spacing, hierarchy, contrast, accessibility and states, never the layout structure.

• **Code**: Latest stable Flutter. Riverpod (no codegen except l10n), go_router, supabase_flutter. Feature-first folders `lib/features/<name>/{data,domain,presentation}`. UI never calls Supabase directly; use repositories. Plain Dart models with fromJson/toJson. Small files and widgets, null safety, const where possible.

• **Packages**: Add with `flutter pub add` so versions are current. Never invent package names or APIs. If unsure, check pub.dev or official docs and say so.

• **Localization**: No hardcoded user-facing text. Use AppLocalizations; add every new key to the en, kn, hi, te and ta ARB files. No hardcoded colours or sizes: use theme tokens and design-system widgets.

• **States**: Every screen handles loading, empty, error with retry, and offline.

• **Accessibility**: Touch targets at least 48dp, scalable text, semantic labels, icon plus text for actions.

• **Migrations**: New numbered file in `supabase/migrations`; never edit an applied migration.

• **App Roles & Scope**: App roles are strictly Job Seeker, Job Provider, and Farmer. The Admin Console is built in a separate web/desktop project and is OUT OF SCOPE for this Flutter app (Phase 9 is skipped).

• **Do not**: Add unneeded packages, rewrite unrelated files, leave stubs that look finished (mark them `// TODO(P#.#)` and list them in PROGRESS.md).
