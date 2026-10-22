import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/widgets/common.dart';
import '../../../shared/providers/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parent = ref.watch(parentProvider);
    final students = ref.watch(studentsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: parent.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            ErrorState(onRetry: () => ref.invalidate(parentProvider)),
        data: (person) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.navy,
                child: Text(
                  person.name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              person.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              person.email,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (AppConfig.demoMode)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Align(child: DemoBanner(label: 'DEMO PROFILE')),
              ),
            const SizedBox(height: 28),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.phone_outlined),
                    title: const Text('Contact number'),
                    subtitle: Text(person.phone),
                  ),
                  ListTile(
                    leading: const Icon(Icons.family_restroom),
                    title: const Text('Linked children'),
                    subtitle: Text(students.map((s) => s.name).join(', ')),
                  ),
                  ListTile(
                    leading: const Icon(Icons.tune_rounded),
                    title: const Text('Settings & preferences'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/profile/settings'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy'),
                    subtitle: const Text(
                      'Location access is authorized by the backend only.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: AppColors.error,
              ),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Log out?'),
                    content: const Text(
                      'This removes your secure session from this device.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Log out'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true)
                  await ref.read(sessionProvider.notifier).logout();
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool boarding = true, safety = true, trips = true;
  @override
  Widget build(BuildContext context) {
    final dark = ref.watch(themeProvider) == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'NOTIFICATION PREFERENCES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: boarding,
                  onChanged: (v) => setState(() => boarding = v),
                  title: const Text('Boarding & drop-off'),
                  subtitle: const Text('Verified student movement updates'),
                ),
                SwitchListTile(
                  value: safety,
                  onChanged: (v) => setState(() => safety = v),
                  title: const Text('Safety alerts'),
                  subtitle: const Text(
                    'Wrong vehicle and verification exceptions',
                  ),
                ),
                SwitchListTile(
                  value: trips,
                  onChanged: (v) => setState(() => trips = v),
                  title: const Text('Trip updates'),
                  subtitle: const Text(
                    'Delays, starts, completion, and GPS issues',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'APPEARANCE & DEVICE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: dark,
                  onChanged: (v) => ref.read(themeProvider.notifier).toggle(v),
                  title: const Text('Dark theme'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Enable device notifications'),
                  subtitle: Text(
                    NotificationService.instance.configured
                        ? 'Firebase is configured on this device'
                        : 'Requires Firebase configuration',
                  ),
                  onTap: NotificationService.instance.configured
                      ? () async {
                          final token = await NotificationService.instance
                              .requestToken();
                          if (token != null)
                            await ref
                                .read(appRepositoryProvider)
                                .registerDeviceToken(token);
                          if (context.mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  token == null
                                      ? 'Notifications were not enabled.'
                                      : 'This device is registered.',
                                ),
                              ),
                            );
                        }
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'SafeRide-LK minimizes local storage of child data. Official attendance, vehicle assignment, and authorization remain controlled by the backend.',
                style: TextStyle(height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
