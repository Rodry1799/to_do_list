import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Core/auth_provider.dart';
import '../../Core/font_provider.dart';
import '../../Service/api_services.dart';

const _kAddCategories = ['General', 'Work', 'Personal', 'Urgent', 'Shopping', 'Health'];

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _titleCtrl       = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final ApiService _apiService                  = ApiService();

  String _selectedCategory = 'General';
  bool _isLoading          = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitTask() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('User not logged in')));
      setState(() => _isLoading = false);
      return;
    }

    final ok = await _apiService.addTask(
      _titleCtrl.text.trim(),
      _descriptionCtrl.text.trim(),
      userId,
      category: _selectedCategory,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to add task')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final scale = context.watch<FontProvider>().textScaleFactor;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('New Task',
            style: TextStyle(
                fontSize: 20 * scale,
                fontWeight: FontWeight.bold,
                color: cs.primary)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: cs.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What's on your mind?",
              style: TextStyle(
                  fontSize: 22 * scale,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface),
            ),
            const SizedBox(height: 28),

            // ── Title ───────────────────────────────────────────────
            _label('Title', cs, scale),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              style: TextStyle(fontSize: 15 * scale),
              decoration: _inputDeco(
                cs: cs, hint: 'e.g. Buy groceries', icon: Icons.title_rounded),
            ),
            const SizedBox(height: 20),

            // ── Description ──────────────────────────────────────────
            _label('Description', cs, scale),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionCtrl,
              maxLines: 4,
              style: TextStyle(fontSize: 14 * scale),
              decoration: _inputDeco(
                  cs: cs,
                  hint: 'Add details here...',
                  icon: Icons.notes_rounded),
            ),
            const SizedBox(height: 24),

            // ── Category Selector ────────────────────────────────────
            _label('Category', cs, scale),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kAddCategories.map((cat) {
                final selected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat,
                      style: TextStyle(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w600,
                          color: selected ? cs.onPrimary : cs.onSurface.withOpacity(0.7))),
                  selected: selected,
                  selectedColor: cs.primary,
                  backgroundColor: cs.surfaceContainerHighest.withOpacity(0.5),
                  side: BorderSide(
                      color: selected ? cs.primary : cs.outline.withOpacity(0.3)),
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),

            // ── Save Button ──────────────────────────────────────────
            _isLoading
                ? Center(child: CircularProgressIndicator(color: cs.primary))
                : SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _submitTask,
                      icon: const Icon(Icons.save_rounded),
                      label: Text('Save Task',
                          style: TextStyle(
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, ColorScheme cs, double scale) => Text(
        text,
        style: TextStyle(
            fontSize: 13 * scale,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withOpacity(0.65)),
      );

  InputDecoration _inputDeco(
      {required ColorScheme cs,
      required String hint,
      required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: cs.primary),
      filled: true,
      fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: cs.outline.withOpacity(0.2))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 2)),
    );
  }
}
