import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Models/task_model.dart';
import '../../Service/api_services.dart';
import '../../Core/font_provider.dart';

class EditTaskScreen extends StatefulWidget {
  final TaskModel task;
  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late bool _isCompleted;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController(text: widget.task.description);
    _isCompleted = widget.task.isCompleted;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final updatedTask = TaskModel(
      id: widget.task.id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      isCompleted: _isCompleted,
    );

    final success = await _apiService.updateTask(updatedTask);
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, true); // أشعر HomeScreen بالتحديث
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update task. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scale = context.watch<FontProvider>().textScaleFactor;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Task', style: TextStyle(fontSize: 20 * scale, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text('Save', style: TextStyle(fontSize: 14 * scale)),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Status Banner ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _isCompleted
                          ? Colors.green.withOpacity(0.1)
                          : colorScheme.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _isCompleted
                            ? Colors.green.withOpacity(0.3)
                            : colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: _isCompleted ? Colors.green : colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status',
                                style: TextStyle(
                                  fontSize: 12 * scale,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              Text(
                                _isCompleted ? 'Completed' : 'In Progress',
                                style: TextStyle(
                                  fontSize: 14 * scale,
                                  fontWeight: FontWeight.bold,
                                  color: _isCompleted ? Colors.green : colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _isCompleted,
                          onChanged: (v) => setState(() => _isCompleted = v),
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Title Field ────────────────────────────────────────
                  Text('Title', style: TextStyle(fontSize: 13 * scale, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.7))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleCtrl,
                    style: TextStyle(fontSize: 15 * scale, fontWeight: FontWeight.w600),
                    decoration: _inputDeco(
                      context: context,
                      hint: 'Task title',
                      icon: Icons.title_rounded,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Description Field ──────────────────────────────────
                  Text('Description', style: TextStyle(fontSize: 13 * scale, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.7))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 5,
                    style: TextStyle(fontSize: 14 * scale),
                    decoration: _inputDeco(
                      context: context,
                      hint: 'Add more details about this task...',
                      icon: Icons.notes_rounded,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Save Button ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _saveChanges,
                      icon: const Icon(Icons.save_rounded),
                      label: Text('Save Changes', style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  InputDecoration _inputDeco({
    required BuildContext context,
    required String hint,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: colorScheme.primary),
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    );
  }
}
