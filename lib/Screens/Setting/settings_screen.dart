import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Core/theme_provider.dart';
import '../../Core/font_provider.dart';
import '../../Core/auth_provider.dart';
import '../Auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final fontProvider = context.watch<FontProvider>();
    final authProvider = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final scale = fontProvider.textScaleFactor;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(fontSize: 20 * scale, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── User Info Card ─────────────────────────────────────────────
          if (authProvider.user != null)
            _SectionCard(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      authProvider.user!.username.isNotEmpty
                          ? authProvider.user!.username[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 18 * scale,
                      ),
                    ),
                  ),
                  title: Text(authProvider.user!.username,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16 * scale)),
                  subtitle: Text(authProvider.user!.email,
                      style: TextStyle(fontSize: 13 * scale)),
                ),
              ],
            ),

          const SizedBox(height: 16),
          _SectionHeader(title: 'Appearance', scale: scale),
          const SizedBox(height: 8),

          // ── Dark Mode ──────────────────────────────────────────────────
          _SectionCard(
            children: [
              SwitchListTile.adaptive(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text('Dark Mode', style: TextStyle(fontSize: 15 * scale, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  themeProvider.isDarkMode ? 'Dark theme active' : 'Light theme active',
                  style: TextStyle(fontSize: 12 * scale),
                ),
                value: themeProvider.isDarkMode,
                onChanged: (v) => context.read<ThemeProvider>().toggleDarkMode(v),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Color Scheme ──────────────────────────────────────────────
          _SectionCard(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Text('Color Scheme',
                    style: TextStyle(fontSize: 15 * scale, fontWeight: FontWeight.w600)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(ThemeProvider.colorOptions.length, (i) {
                    final option = ThemeProvider.colorOptions[i];
                    final isSelected = themeProvider.colorSchemeIndex == i;
                    return GestureDetector(
                      onTap: () => context.read<ThemeProvider>().setColorScheme(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: option['seed'] as Color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: colorScheme.onSurface,
                                  width: 3,
                                )
                              : null,
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: (option['seed'] as Color).withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 12),
                child: Text(
                  ThemeProvider.colorOptions[themeProvider.colorSchemeIndex]['name'] as String,
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _SectionHeader(title: 'Text', scale: scale),
          const SizedBox(height: 8),

          // ── Font Size ─────────────────────────────────────────────────
          _SectionCard(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Text('Font Size',
                    style: TextStyle(fontSize: 15 * scale, fontWeight: FontWeight.w600)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SegmentedButton<int>(
                  segments: List.generate(
                    FontProvider.fontSizeOptions.length,
                    (i) => ButtonSegment<int>(
                      value: i,
                      label: Text(
                        FontProvider.fontSizeOptions[i]['label'] as String,
                        style: TextStyle(fontSize: 13 * scale),
                      ),
                    ),
                  ),
                  selected: {fontProvider.fontSizeIndex},
                  onSelectionChanged: (Set<int> sel) =>
                      context.read<FontProvider>().setFontSize(sel.first),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 14),
                child: Text(
                  'Preview: The quick brown fox',
                  style: TextStyle(fontSize: 14 * fontProvider.textScaleFactor),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _SectionHeader(title: 'Account', scale: scale),
          const SizedBox(height: 8),

          // ── Logout ────────────────────────────────────────────────────
          _SectionCard(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                ),
                title: Text('Sign Out',
                    style: TextStyle(
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    )),
                subtitle: Text('You will be returned to the login screen',
                    style: TextStyle(fontSize: 12 * scale)),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.scale});
  final String title;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11 * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
      child: Column(children: children),
    );
  }
}
