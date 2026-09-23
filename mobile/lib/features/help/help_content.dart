import 'package:flutter/material.dart';
import '../../core/localization/app_translations.dart';
import '../../core/theme/app_theme.dart';

/// A single help article inside a [HelpCategory]. [body] supports simple
/// paragraph breaks (blank line) and bullet lines starting with "• ".
/// [title]/[body] are resolved from [titleKey]/[bodyKey] via [tr] at access
/// time, so they always reflect the admin's currently selected language.
class HelpTopic {
  final String titleKey;
  final String bodyKey;

  const HelpTopic({required this.titleKey, required this.bodyKey});

  String get title => tr(titleKey);
  String get body => tr(bodyKey);
}

class HelpCategory {
  final IconData icon;
  final String titleKey;
  final String descKey;
  final List<HelpTopic> topics;

  const HelpCategory({
    required this.icon,
    required this.titleKey,
    required this.descKey,
    required this.topics,
  });

  String get title => tr(titleKey);
  String get description => tr(descKey);
}

/// Complete, hand-written admin documentation for every feature in the app.
/// Content is written to reflect actual app behavior (verified against the
/// source), not generic assumptions — treat this as the single source of
/// truth for "how does X actually work" and "what should I do when Y happens".
const List<HelpCategory> helpCategories = [
  HelpCategory(
    icon: Icons.rocket_launch_rounded,
    titleKey: 'help_cat_getting_started_title',
    descKey: 'help_cat_getting_started_desc',
    topics: [
      HelpTopic(
        titleKey: 'help_topic_setup_wizard_title',
        bodyKey: 'help_topic_setup_wizard_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_login_mpin_title',
        bodyKey: 'help_topic_login_mpin_body',
      ),
    ],
  ),
  HelpCategory(
    icon: Icons.people_alt_rounded,
    titleKey: 'help_cat_members_title',
    descKey: 'help_cat_members_desc',
    topics: [
      HelpTopic(
        titleKey: 'help_topic_onboarding_title',
        bodyKey: 'help_topic_onboarding_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_edit_vs_change_title',
        bodyKey: 'help_topic_edit_vs_change_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_archive_vs_delete_title',
        bodyKey: 'help_topic_archive_vs_delete_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_profile_overview_title',
        bodyKey: 'help_topic_profile_overview_body',
      ),
    ],
  ),
  HelpCategory(
    icon: Icons.receipt_long_rounded,
    titleKey: 'help_cat_billing_title',
    descKey: 'help_cat_billing_desc',
    topics: [
      HelpTopic(
        titleKey: 'help_topic_due_date_meaning_title',
        bodyKey: 'help_topic_due_date_meaning_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_bill_statuses_title',
        bodyKey: 'help_topic_bill_statuses_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_auto_bill_gen_title',
        bodyKey: 'help_topic_auto_bill_gen_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_manual_bill_gen_title',
        bodyKey: 'help_topic_manual_bill_gen_body',
      ),
    ],
  ),
  HelpCategory(
    icon: Icons.payments_rounded,
    titleKey: 'help_cat_payments_title',
    descKey: 'help_cat_payments_desc',
    topics: [
      HelpTopic(
        titleKey: 'help_topic_recording_payment_title',
        bodyKey: 'help_topic_recording_payment_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_receipt_contents_title',
        bodyKey: 'help_topic_receipt_contents_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_receipt_validity_title',
        bodyKey: 'help_topic_receipt_validity_body',
      ),
    ],
  ),
  HelpCategory(
    icon: Icons.pause_circle_outline_rounded,
    titleKey: 'help_cat_returning_member_title',
    descKey: 'help_cat_returning_member_desc',
    topics: [
      HelpTopic(
        titleKey: 'help_topic_bills_pile_up_title',
        bodyKey: 'help_topic_bills_pile_up_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_resume_billing_title',
        bodyKey: 'help_topic_resume_billing_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_resume_end_date_title',
        bodyKey: 'help_topic_resume_end_date_body',
      ),
    ],
  ),
  HelpCategory(
    icon: Icons.sports_gymnastics_rounded,
    titleKey: 'help_cat_trainers_title',
    descKey: 'help_cat_trainers_desc',
    topics: [
      HelpTopic(
        titleKey: 'help_topic_add_deactivate_trainers_title',
        bodyKey: 'help_topic_add_deactivate_trainers_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_pt_fees_title',
        bodyKey: 'help_topic_pt_fees_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_trainer_payouts_title',
        bodyKey: 'help_topic_trainer_payouts_body',
      ),
    ],
  ),
  HelpCategory(
    icon: Icons.event_rounded,
    titleKey: 'help_cat_events_title',
    descKey: 'help_cat_events_desc',
    topics: [
      HelpTopic(
        titleKey: 'help_topic_scheduling_event_title',
        bodyKey: 'help_topic_scheduling_event_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_event_reminders_title',
        bodyKey: 'help_topic_event_reminders_body',
      ),
    ],
  ),
  HelpCategory(
    icon: Icons.currency_rupee_rounded,
    titleKey: 'help_cat_expenses_title',
    descKey: 'help_cat_expenses_desc',
    topics: [
      HelpTopic(
        titleKey: 'help_topic_logging_expense_title',
        bodyKey: 'help_topic_logging_expense_body',
      ),
    ],
  ),
  HelpCategory(
    icon: Icons.campaign_rounded,
    titleKey: 'help_cat_announcements_title',
    descKey: 'help_cat_announcements_desc',
    topics: [
      HelpTopic(
        titleKey: 'help_topic_broadcasting_title',
        bodyKey: 'help_topic_broadcasting_body',
      ),
    ],
  ),
  HelpCategory(
    icon: Icons.notifications_active_rounded,
    titleKey: 'help_cat_notifications_title',
    descKey: 'help_cat_notifications_desc',
    topics: [
      HelpTopic(
        titleKey: 'help_topic_reminders_timing_title',
        bodyKey: 'help_topic_reminders_timing_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_configuring_reminders_title',
        bodyKey: 'help_topic_configuring_reminders_body',
      ),
    ],
  ),
  HelpCategory(
    icon: Icons.bar_chart_rounded,
    titleKey: 'help_cat_reports_title',
    descKey: 'help_cat_reports_desc',
    topics: [
      HelpTopic(
        titleKey: 'help_topic_reports_overview_title',
        bodyKey: 'help_topic_reports_overview_body',
      ),
    ],
  ),
  HelpCategory(
    icon: Icons.settings_rounded,
    titleKey: 'help_cat_settings_data_title',
    descKey: 'help_cat_settings_data_desc',
    topics: [
      HelpTopic(
        titleKey: 'help_topic_gym_info_logo_title',
        bodyKey: 'help_topic_gym_info_logo_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_packages_plans_title',
        bodyKey: 'help_topic_packages_plans_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_payment_settings_title',
        bodyKey: 'help_topic_payment_settings_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_print_format_title',
        bodyKey: 'help_topic_print_format_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_backup_restore_title',
        bodyKey: 'help_topic_backup_restore_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_online_offline_title',
        bodyKey: 'help_topic_online_offline_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_security_title',
        bodyKey: 'help_topic_security_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_reset_data_title',
        bodyKey: 'help_topic_reset_data_body',
      ),
    ],
  ),
  HelpCategory(
    icon: Icons.help_rounded,
    titleKey: 'help_cat_troubleshooting_title',
    descKey: 'help_cat_troubleshooting_desc',
    topics: [
      HelpTopic(
        titleKey: 'help_topic_logo_missing_title',
        bodyKey: 'help_topic_logo_missing_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_dates_wrong_title',
        bodyKey: 'help_topic_dates_wrong_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_no_alert_title',
        bodyKey: 'help_topic_no_alert_body',
      ),
      HelpTopic(
        titleKey: 'help_topic_delete_bill_faq_title',
        bodyKey: 'help_topic_delete_bill_faq_body',
      ),
    ],
  ),
];

/// Flattened (category, topic) pairs — used for search across all help content.
List<MapEntry<HelpCategory, HelpTopic>> get allHelpTopics => [
      for (final category in helpCategories)
        for (final topic in category.topics) MapEntry(category, topic),
    ];

const Color helpAccentColor = AppTheme.statusActive;
