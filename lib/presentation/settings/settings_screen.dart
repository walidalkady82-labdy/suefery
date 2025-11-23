import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';
import 'package:suefery/core/l10n/app_localizations.dart';
import 'package:suefery/presentation/settings/settings_cubit.dart';
import 'package:suefery/presentation/settings/profile/profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return BlocBuilder<SettingsCubit, SettingsState>(builder: (context, state) {
      final settingsCubit = context.read<SettingsCubit>();
      return Scaffold(
        appBar: AppBar(
          title: Text(strings.settingsTitle),
        ),
        body: ListView(
          children: [
            /// -- user profile --
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(strings.profileTitle), // Add 'profileTitle' to localizations
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            /// -- language selection --
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(strings.changeLanguage),
              subtitle: Text(strings.currentLanguage(state.locale.languageCode)),
              onTap: () => _showLanguagePickerDialog(context, settingsCubit),
            ),
            /// -- light/dark theme --
            SwitchListTile(
              title: Text(strings.darkMode),
              value: state.themeMode == ThemeMode.dark,
              onChanged: (isDark) => settingsCubit.toggleDarkMode(isDark),
              secondary: const Icon(Icons.dark_mode_outlined),
            ),
            //TODO: --- TEMPORARY brands seed button ---
            ListTile(
              leading: const Icon(Icons.cloud_upload, color: Colors.red),
              title: const Text(
                'Upload Brands to Database', 
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
              ),
              subtitle: const Text('Press once to fill database'),
              onTap: () async {
                // Show loading indicator or confirm
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Uploading brands...')),
                );
                
                await settingsCubit.seedBrands();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Success! Brands added.')),
                  );
                }
              },
            ),
            // -----------------------------
          ],
        ),
      );
    });
  }

  void _showLanguagePickerDialog(
      BuildContext context, SettingsCubit settingsCubit) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(l10n.selectLanguage),
          children: AppLocalizations.supportedLocales.map((locale) {
            return SimpleDialogOption(
              onPressed: () {
                settingsCubit.setLocale(locale);
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                locale.languageCode == 'en' ? 'English' : 'العربية',
                style: TextStyle(
                  fontWeight: settingsCubit.state.locale == locale
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: settingsCubit.state.locale == locale
                      ? Theme.of(context).primaryColor
                      : null,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}