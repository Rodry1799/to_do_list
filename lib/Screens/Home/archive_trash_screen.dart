import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Core/auth_provider.dart';
import '../../Core/font_provider.dart';
import '../../Models/task_model.dart';
import '../../Service/api_services.dart';

enum _ViewMode { archive, trash }

class ArchiveTrashScreen extends StatefulWidget {
  const ArchiveTrashScreen({super.key});

  @override
  State<ArchiveTrashScreen> createState() => _ArchiveTrashScreenState();
}

class _ArchiveTrashScreenState extends State<ArchiveTrashScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ApiService _api = ApiService();
  late Future<List<TaskModel>> _archiveFuture;
  late Future<List<TaskModel>> _trashFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    final userId = context.read<AuthProvider>().user?.id;
    setState(() {
      _archiveFuture = _api.getTasks(userId: userId, archived: true);
      _trashFuture   = _api.getTasks(userId: userId, trashed: true);
    });
  }

  Future<void> _restore(TaskModel task) async {
    final ok = await _api.restoreTask(task.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '✅ Restored: ${task.title}' : '❌ Failed to restore'),
        behavior: SnackBarBehavior.floating,
      ));
      if (ok) _refresh();
    }
  }

  Future<void> _deletePermanently(TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Permanently'),
        content: Text('This will permanently delete "${task.title}". This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await _api.deleteTask(task.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? '🗑️ Deleted permanently' : '❌ Failed'),
          behavior: SnackBarBehavior.floating,
        ));
        if (ok) _refresh();
      }
    }
  }

  Future<void> _unarchive(TaskModel task) async {
    final ok = await _api.archiveTask(task.id, archive: false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '📂 Unarchived: ${task.title}' : '❌ Failed'),
        behavior: SnackBarBehavior.floating,
      ));
      if (ok) _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final scale = context.watch<FontProvider>().textScaleFactor;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        title: Text('Archive & Trash',
            style: TextStyle(fontSize: 20 * scale, fontWeight: FontWeight.bold, color: cs.onSurface)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: cs.primary,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurface.withOpacity(0.5),
          tabs: const [
            Tab(icon: Icon(Icons.archive_outlined), text: 'Archive'),
            Tab(icon: Icon(Icons.delete_outline_rounded), text: 'Trash'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Archive Tab ──────────────────────────────────────
          _buildList(
            future: _archiveFuture,
            cs: cs,
            scale: scale,
            mode: _ViewMode.archive,
          ),
          // ── Trash Tab ────────────────────────────────────────
          _buildList(
            future: _trashFuture,
            cs: cs,
            scale: scale,
            mode: _ViewMode.trash,
          ),
        ],
      ),
    );
  }

  Widget _buildList({
    required Future<List<TaskModel>> future,
    required ColorScheme cs,
    required double scale,
    required _ViewMode mode,
  }) {
    return FutureBuilder<List<TaskModel>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: cs.primary));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: cs.error)));
        }
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) {
          return _buildEmpty(
            icon: mode == _ViewMode.archive ? Icons.archive_outlined : Icons.delete_outline_rounded,
            label: mode == _ViewMode.archive ? 'Archive is empty' : 'Trash is empty',
            cs: cs,
            scale: scale,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: tasks.length,
          itemBuilder: (_, i) => _buildCard(tasks[i], cs, scale, mode),
        );
      },
    );
  }

  Widget _buildCard(TaskModel task, ColorScheme cs, double scale, _ViewMode mode) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surfaceContainerHighest.withOpacity(0.6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Icon(
            mode == _ViewMode.archive ? Icons.archive_rounded : Icons.delete_rounded,
            color: cs.primary,
          ),
        ),
        title: Text(task.title,
            style: TextStyle(
                fontSize: 15 * scale,
                fontWeight: FontWeight.w600,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                color: cs.onSurface.withOpacity(task.isCompleted ? 0.5 : 1))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty)
              Text(task.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12 * scale, color: cs.onSurface.withOpacity(0.55))),
            const SizedBox(height: 4),
            _CategoryChip(label: task.category, cs: cs, scale: scale),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // استعادة
            IconButton(
              tooltip: 'Restore',
              icon: Icon(Icons.restore_rounded, color: Colors.green),
              onPressed: () => mode == _ViewMode.archive ? _unarchive(task) : _restore(task),
            ),
            // حذف نهائي (للسلة فقط)
            if (mode == _ViewMode.trash)
              IconButton(
                tooltip: 'Delete permanently',
                icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                onPressed: () => _deletePermanently(task),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String label,
    required ColorScheme cs,
    required double scale,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: cs.primary.withOpacity(0.25)),
          const SizedBox(height: 16),
          Text(label,
              style: TextStyle(
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface.withOpacity(0.35))),
        ],
      ),
    );
  }
}

// ── Small helper chip ─────────────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  final double scale;

  const _CategoryChip({required this.label, required this.cs, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10 * scale,
          fontWeight: FontWeight.w600,
          color: cs.onSecondaryContainer,
        ),
      ),
    );
  }
}
