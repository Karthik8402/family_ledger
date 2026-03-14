import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/common/profile_avatar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BiometricService _biometricService = BiometricService();
  bool _isBiometricsEnabled = false;
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await _biometricService.isBiometricsEnabled();
    final supported = await _biometricService.isDeviceSupported();
    if (mounted) {
      setState(() {
        _isBiometricsEnabled = enabled;
        _canCheckBiometrics = supported;
      });
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      // If enabling, authenticate first to confirm ownership
      final authenticated = await _biometricService.authenticate();
      if (!authenticated) return;
    }

    await _biometricService.setBiometricsEnabled(value);
    if (mounted) {
      setState(() => _isBiometricsEnabled = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = context.read<AuthService>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Account Section
          if (user != null) ...[
            _buildSectionHeader('Account'),
            ListTile(
              leading: ProfileAvatar(
                url: user.photoURL,
                name: user.displayName ?? 'User',
                primaryColor: Theme.of(context).colorScheme.primary,
                radius: 20,
              ),
              title: Text(user.displayName ?? 'User'),
              subtitle: Text(user.email ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title:
                  const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out?'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sign Out')),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  await context.read<AuthService>().signOut();
                  if (mounted) Navigator.pop(context); // Close settings
                }
              },
            ),
            const Divider(),
          ],

          // Privacy Section
          _buildSectionHeader('Privacy & Security'),
          if (_canCheckBiometrics)
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('App Lock'),
              subtitle: const Text('Require biometrics to open app'),
              value: _isBiometricsEnabled,
              onChanged: _toggleBiometrics,
              activeThumbColor: Colors.teal,
              activeTrackColor: Colors.teal.withValues(alpha: 0.4),
            )
          else
            const ListTile(
              leading: Icon(Icons.fingerprint, color: Colors.grey),
              title: Text('App Lock Unavailable'),
              subtitle: Text('Biometrics not supported on this device'),
            ),

          const Divider(),

          // Appearance Section
          _buildSectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.brightness_auto),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode),
                  ),
                ],
                selected: {themeProvider.themeMode},
                onSelectionChanged: (Set<ThemeMode> newSelection) {
                  themeProvider.setThemeMode(newSelection.first);
                },
              ),
            ),
          ),

          const Divider(),

          // About Section
          _buildSectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.0+1'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
