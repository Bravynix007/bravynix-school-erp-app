import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/amount_text.dart';
import 'package:bravynix_school_erp/core/widgets/app_avatar.dart';
import 'package:bravynix_school_erp/core/widgets/app_bottom_sheet.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_date_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_dropdown_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_filter_bar.dart';
import 'package:bravynix_school_erp/core/widgets/app_icon_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_progress.dart';
import 'package:bravynix_school_erp/core/widgets/app_search_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_segmented_control.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_switch_tile.dart';
import 'package:bravynix_school_erp/core/widgets/app_tag.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/core/widgets/attendance_status_selector.dart';
import 'package:bravynix_school_erp/core/widgets/audit_footer.dart';
import 'package:bravynix_school_erp/core/widgets/choice_chip_group.dart';
import 'package:bravynix_school_erp/core/widgets/date_badge_card.dart';
import 'package:bravynix_school_erp/core/widgets/form_section_card.dart';
import 'package:bravynix_school_erp/core/widgets/greeting_card.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/key_value_row.dart';
import 'package:bravynix_school_erp/core/widgets/menu_list_tile.dart';
import 'package:bravynix_school_erp/core/widgets/person_list_tile.dart';
import 'package:bravynix_school_erp/core/widgets/photo_upload_tile.dart';
import 'package:bravynix_school_erp/core/widgets/quick_access_tile.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/core/widgets/selection_tile.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/stat_tile.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/status_chip.dart';
import 'package:bravynix_school_erp/core/widgets/timeline_row.dart';
import 'package:bravynix_school_erp/features/gallery/presentation/shell_gallery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Every shared widget on one page, with a switch for the seven accents. It is
/// a developer and designer tool, reachable at `/gallery` in debug and profile
/// builds only, so its sample text is plain English and not in the ARB files.
/// The shell pieces (top bar, tab bar, FAB, sticky actions, module header) have
/// their own page, opened from the first button, to keep this one short.
class ComponentGalleryPage extends StatefulWidget {
  const new({super.key});

  @override
  State<ComponentGalleryPage> createState() => _ComponentGalleryPageState();
}

class _ComponentGalleryPageState extends State<ComponentGalleryPage> {
  AppAccent _accent = AppAccent.defaultAccent;
  String _term = 'Term 1';
  String _view = 'Week';
  AttendanceMark? _mark = AttendanceMark.present;
  String? _class = '7-B';
  bool _notify = true;
  bool _copyOffice = false;
  String _frequency = 'Monthly';
  String? _filterClass = '7-B';
  bool _loading = false;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static const _labels = <AttendanceMark, AttendanceMarkLabel>{
    AttendanceMark.present: AttendanceMarkLabel(short: 'P', full: 'Present'),
    AttendanceMark.absent: AttendanceMarkLabel(short: 'A', full: 'Absent'),
    AttendanceMark.late: AttendanceMarkLabel(short: 'L', full: 'Late'),
    AttendanceMark.halfDay: AttendanceMarkLabel(short: 'HD', full: 'Half day'),
    AttendanceMark.leave: AttendanceMarkLabel(short: 'LV', full: 'On leave'),
  };

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light(accent: _accent),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Component gallery')),
          body: ListView(
            // Build everything, so Tab can reach every control (a lazy list would
            // leave the lower half without focus targets).
            scrollCacheExtent: const ScrollCacheExtent.pixels(100000),
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            children: [
              const SectionHeader(title: 'Accent'),
              const SizedBox(height: AppSpacing.xs),
              ChoiceChipGroup<AppAccent>(
                options: AppAccent.values,
                labelOf: (accent) => accent.label,
                selected: _accent,
                onSelected: (accent) => setState(() => _accent = accent),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppButton(
                label: 'Open the shell pieces',
                variant: AppButtonVariant.tonal,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Theme(data: Theme.of(context), child: const ShellGalleryPage()),
                  ),
                ),
              ),
              _gap,
              const SectionHeader(title: 'Buttons'),
              const SizedBox(height: AppSpacing.xs),
              AppButton(label: 'Save changes', onPressed: () {}),
              const SizedBox(height: AppSpacing.xs),
              AppButton(label: 'Add student', icon: Icons.add, variant: AppButtonVariant.tonal, onPressed: () {}),
              const SizedBox(height: AppSpacing.xs),
              AppButton(label: 'Cancel', variant: AppButtonVariant.secondary, onPressed: () {}),
              const SizedBox(height: AppSpacing.xs),
              AppButton(label: 'Delete class', variant: AppButtonVariant.danger, onPressed: () {}),
              const SizedBox(height: AppSpacing.xs),
              AppButton(label: 'Saving', loading: true, onPressed: () {}),
              const SizedBox(height: AppSpacing.xs),
              const AppButton(label: 'Disabled', onPressed: null),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AppButton(label: 'Medium', size: AppButtonSize.medium, onPressed: () {}),
                  AppButton(label: 'Small', size: AppButtonSize.small, onPressed: () {}),
                  AppButton(label: 'Link', variant: AppButtonVariant.text, size: AppButtonSize.small, onPressed: () {}),
                  AppIconButton(icon: Icons.notifications_none, tooltip: 'Notifications', onPressed: () {}),
                  AppIconButton(icon: Icons.edit_outlined, tooltip: 'Edit', tonal: true, onPressed: () {}),
                ],
              ),
              _gap,
              const SectionHeader(title: 'Fields'),
              const SizedBox(height: AppSpacing.xs),
              const AppTextField(
                label: 'Student name',
                hint: 'As on the birth certificate',
                required: true,
                requiredLabel: 'Required',
              ),
              const SizedBox(height: AppSpacing.sm),
              const AppTextField(label: 'Admission number', mono: true, helper: 'Printed on the fee receipt'),
              const SizedBox(height: AppSpacing.sm),
              const AppTextField(label: 'Mobile', error: 'Enter a 10-digit number.', prefixIcon: Icons.phone_outlined),
              const SizedBox(height: AppSpacing.sm),
              AppDropdownField<String>(
                label: 'Class',
                value: _class,
                required: true,
                requiredLabel: 'Required',
                items: const [
                  DropdownMenuItem(value: '7-A', child: Text('7-A')),
                  DropdownMenuItem(value: '7-B', child: Text('7-B')),
                ],
                onChanged: (value) => setState(() => _class = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppDateField(label: 'Date of birth', valueText: '12 Mar 2013', onTap: () {}),
              const SizedBox(height: AppSpacing.sm),
              AppSearchField(controller: _search, hint: 'Search students', clearTooltip: 'Clear search'),
              _gap,
              const SectionHeader(title: 'Choices'),
              const SizedBox(height: AppSpacing.xs),
              ChoiceChipGroup<String>(
                options: const ['Term 1', 'Term 2', 'Term 3'],
                labelOf: (term) => term,
                selected: _term,
                onSelected: (term) => setState(() => _term = term),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppSegmentedControl<String>(
                options: const ['Day', 'Week', 'Month'],
                labelOf: (view) => view,
                selected: _view,
                onChanged: (view) => setState(() => _view = view),
              ),
              const SizedBox(height: AppSpacing.sm),
              AttendanceStatusSelector(
                labels: _labels,
                selected: _mark,
                onChanged: (mark) => setState(() => _mark = mark),
              ),
              _gap,
              const SectionHeader(title: 'Forms and settings'),
              const SizedBox(height: AppSpacing.xs),
              FormSectionCard(
                number: 1,
                title: 'Student details',
                subtitle: 'As on the admission form',
                stepLabel: 'Step 1/5',
                stepSpokenLabel: 'Step 1 of 5',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PhotoUploadTile(label: 'Add photo', onPick: () {}, errorText: 'A photo is needed for the ID card'),
                    const SizedBox(height: AppSpacing.sm),
                    AppSwitchTile(
                      title: 'Notify parents when marked absent',
                      subtitle: 'Sent by SMS at 10 am',
                      icon: Icons.notifications_outlined,
                      value: _notify,
                      onChanged: (value) => setState(() => _notify = value),
                    ),
                    AppCheckboxTile(
                      title: 'Send a copy to the office',
                      value: _copyOffice,
                      onChanged: (value) => setState(() => _copyOffice = value),
                    ),
                    AppRadioGroup<String>(
                      label: 'Fee frequency',
                      options: const ['Monthly', 'Quarterly', 'Yearly'],
                      titleOf: (option) => option,
                      subtitleOf: (option) => option == 'Yearly' ? 'Due in April' : null,
                      value: _frequency,
                      onChanged: (option) => setState(() => _frequency = option),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppFilterBar(
                clearLabel: 'Clear filters',
                onClear: () => setState(() => _filterClass = null),
                filters: [
                  AppFilter(label: 'Class', value: _filterClass, onTap: () => setState(() => _filterClass = '7-B')),
                  AppFilter(label: 'Section', onTap: () {}),
                  AppFilter(label: 'Fee status', onTap: () {}),
                ],
              ),
              _gap,
              SectionHeader(title: 'Cards and lists', actionLabel: 'See all', onAction: () {}),
              const SizedBox(height: AppSpacing.xs),
              const StatTileRow(
                tiles: [
                  StatTile(label: 'Present today', value: '412', note: '96% of 429', icon: Icons.how_to_reg_outlined),
                  StatTile(label: 'Fees due', value: '₹1,24,500', note: '18 students'),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(
                  children: [
                    PersonListTile(
                      name: 'Asha Rao',
                      subtitle: 'Class 7-B · Roll 14',
                      trailing: const StatusChip(label: 'Paid', tone: StatusTone.success),
                      onTap: () {},
                    ),
                    const Divider(),
                    PersonListTile(
                      name: 'Vikram Shah',
                      subtitle: 'Class 7-B · Roll 21',
                      trailing: const StatusChip(label: 'Overdue', tone: StatusTone.error),
                      onTap: () {},
                    ),
                    const Divider(),
                    PersonListTile(name: 'Meera Nair', subtitle: 'Parent', onTap: () {}),
                    const Divider(),
                    const MenuListTile(icon: Icons.person_outline, title: 'Profile', subtitle: 'Name, phone, language'),
                    const Divider(),
                    const MenuListTile(icon: Icons.logout, title: 'Log out', destructive: true),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusChip(label: 'Pending', tone: StatusTone.warning),
                  StatusChip(label: 'Info', tone: StatusTone.info),
                  StatusChip(label: 'Draft'),
                  AppTag('Class 7-B'),
                  AppAvatar(name: 'Asha Rao', size: AvatarSize.small),
                  AppAvatar(name: 'Vikram Shah'),
                  AppAvatar(name: 'Meera Nair', size: AvatarSize.large),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const AuditFooter(lines: ['Added by Asha Rao on 3 Mar 2026', 'Updated by Ravi Kumar on 9 Mar 2026']),
              _gap,
              const SectionHeader(title: 'Messages and states'),
              const SizedBox(height: AppSpacing.xs),
              const InlineMessage.info('Fees for Term 2 open on 1 July.'),
              const SizedBox(height: AppSpacing.xs),
              const InlineMessage.warning('3 students have no guardian phone.'),
              const SizedBox(height: AppSpacing.xs),
              const InlineMessage.error("Can't reach the server. Check your connection and try again."),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: _loading ? 'Show content' : 'Show loading placeholder',
                variant: AppButtonVariant.secondary,
                onPressed: () => setState(() => _loading = !_loading),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_loading)
                const SkeletonList(semanticLabel: 'Loading', rows: 3)
              else ...[
                AppCard(
                  child: StatePanel.empty(
                    title: 'No students yet',
                    message: 'Add the first student to start taking attendance.',
                    actionLabel: 'Add student',
                    onAction: () {},
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  child: StatePanel.error(
                    title: 'Something went wrong',
                    message: 'Try again in a moment.',
                    actionLabel: 'Try again',
                    onAction: () {},
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const AppCard(
                  child: StatePanel.forbidden(
                    title: "You can't open this",
                    message: 'Ask your administrator for access.',
                  ),
                ),
              ],
              _gap,
              const SectionHeader(title: 'Display'),
              const SizedBox(height: AppSpacing.xs),
              const GreetingCard(
                greeting: 'Good afternoon',
                name: 'Asha Rao',
                message: '3 classes left today',
                trailing: Icon(Icons.wb_sunny_outlined),
              ),
              const SizedBox(height: AppSpacing.sm),
              QuickAccessGrid(
                tiles: [
                  QuickAccessTile(icon: Icons.fact_check_outlined, label: 'Attendance', onTap: () {}),
                  QuickAccessTile(icon: Icons.payments_outlined, label: 'Fees', onTap: () {}),
                  QuickAccessTile(icon: Icons.menu_book_outlined, label: 'Homework', onTap: () {}),
                  QuickAccessTile(icon: Icons.event_outlined, label: 'Events', onTap: () {}),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AmountSplitRow(label: 'Tuition fee', amount: '40000', note: 'Due 5 Apr'),
                    AmountSplitRow(label: 'Transport', amount: '6500.5'),
                    Divider(),
                    AmountSplitRow(label: 'Total', amount: '46500.50', emphasis: true),
                    SizedBox(height: AppSpacing.xs),
                    AppProgressBar(value: 0.62, semanticLabel: 'Fee collected'),
                    SizedBox(height: AppSpacing.sm),
                    KeyValueRow(label: 'Admission no.', value: 'STU-2291', mono: true),
                    KeyValueRow(label: 'Class', value: '7-B'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Center(
                child: AppProgressRing(value: 0.94, semanticLabel: 'Attendance', center: Text('94%')),
              ),
              const SizedBox(height: AppSpacing.sm),
              const TimelineRow(
                title: 'Application received',
                subtitle: 'Submitted by the guardian',
                time: '3 Mar, 10:15 am',
                icon: Icons.check,
                isFirst: true,
              ),
              const TimelineRow(title: 'Interview scheduled', subtitle: 'Admissions office', time: '12 Mar'),
              const TimelineRow(title: 'Decision', done: false, isLast: true),
              const SizedBox(height: AppSpacing.sm),
              DateBadgeCard(
                date: DateTime(2026, 3, 7),
                title: 'Annual Day',
                subtitle: 'Auditorium, 10 am',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              _gap,
              const SectionHeader(title: 'Overlays'),
              const SizedBox(height: AppSpacing.xs),
              AppButton(
                label: 'Open bottom sheet',
                variant: AppButtonVariant.secondary,
                onPressed: () => showAppBottomSheet<void>(
                  context: context,
                  title: 'Add a note',
                  builder: (_) => Column(
                    children: [
                      const AppTextField(label: 'Note', maxLines: 3),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(label: 'Save', onPressed: () => Navigator.of(context).pop()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppButton(
                label: 'Open confirm dialog',
                variant: AppButtonVariant.secondary,
                onPressed: () => showConfirmDialog(
                  context: context,
                  title: 'Delete this class?',
                  message: 'Its students stay, but they will have no class.',
                  icon: Icons.delete_outline,
                  confirmLabel: 'Delete',
                  cancelLabel: 'Cancel',
                  destructive: true,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppButton(
                label: 'Show snackbar',
                variant: AppButtonVariant.secondary,
                onPressed: () => AppSnackbar.show(context, message: 'Attendance saved', kind: AppSnackbarKind.success),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppButton(
                label: 'Show error snackbar',
                variant: AppButtonVariant.secondary,
                onPressed: () => AppSnackbar.show(
                  context,
                  message: 'Could not save. Try again.',
                  kind: AppSnackbarKind.error,
                  actionLabel: 'Retry',
                  onAction: () {},
                  dismissLabel: 'Dismiss',
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  static const _gap = SizedBox(height: AppSpacing.xl);
}
