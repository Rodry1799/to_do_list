import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Models/task_model.dart';
import '../../Service/api_services.dart';
import '../../Core/font_provider.dart';
import '../../Core/auth_provider.dart';

import '../Setting/settings_screen.dart';
import 'add_task_screen.dart';
import 'edit_task_screen.dart';
import 'archive_trash_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Constants
// ─────────────────────────────────────────────────────────────────────────────
const _kCategories = ['All', 'General', 'Work', 'Personal', 'Urgent', 'Shopping', 'Health'];
const _kSortOptions = [
  ('newest', Icons.arrow_downward_rounded, 'Newest First'),
  ('oldest', Icons.arrow_upward_rounded, 'Oldest First'),
  ('completed', Icons.check_circle_outline_rounded, 'By Completion'),
];

// ─────────────────────────────────────────────────────────────────────────────
//  HomeScreen
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  // ── State Variables ──────────────────────────────────────────────────────
  List<TaskModel> _allTasks    = [];
  List<TaskModel> _filtered    = [];
  bool _loading                = true;
  String? _error;

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _searchVisible          = false;

  // Filter / Sort
  String _selectedCategory     = 'All';
  String _sortMode             = 'newest';

  // Animation controller for search bar
  late final AnimationController _searchAnim;
  late final Animation<double> _searchFade;

  @override
  void initState() {
    super.initState();
    _searchAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _searchFade = CurvedAnimation(parent: _searchAnim, curve: Curves.easeInOut);
    _searchCtrl.addListener(_onSearchChanged);
    _loadTasks();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    _searchAnim.dispose();
    super.dispose();
  }

  // ── Data Loading ─────────────────────────────────────────────────────────
  Future<void> _loadTasks() async {
    setState(() { _loading = true; _error = null; });
    try {
      final userId = context.read<AuthProvider>().user?.id;
      final tasks  = await _apiService.getTasks(userId: userId);
      if (mounted) {
        setState(() {
          _allTasks = tasks;
          _loading  = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Filtering Logic (client-side for real-time UX) ───────────────────────
  void _applyFilters() {
    final query = _searchCtrl.text.toLowerCase().trim();
    List<TaskModel> result = List.from(_allTasks);

    // Category filter
    if (_selectedCategory != 'All') {
      result = result.where((t) => t.category == _selectedCategory).toList();
    }

    // Search filter
    if (query.isNotEmpty) {
      result = result.where((t) =>
        t.title.toLowerCase().contains(query) ||
        t.description.toLowerCase().contains(query)
      ).toList();
    }

    // Sort
    switch (_sortMode) {
      case 'oldest':
        result.sort((a, b) => (a.createdAt ?? '').compareTo(b.createdAt ?? ''));
        break;
      case 'completed':
        result.sort((a, b) {
          if (a.isCompleted == b.isCompleted) return 0;
          return a.isCompleted ? 1 : -1;
        });
        break;
      default: // newest
        result.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
    }

    setState(() => _filtered = result);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _applyFilters);
  }

  void _toggleSearch() {
    setState(() => _searchVisible = !_searchVisible);
    if (_searchVisible) {
      _searchAnim.forward();
    } else {
      _searchAnim.reverse();
      _searchCtrl.clear();
      _applyFilters();
    }
  }

  // ── Navigation ───────────────────────────────────────────────────────────
  Future<void> _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const AddTaskScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOutCubic))
              .animate(anim),
          child: child,
        ),
      ),
    );
    if (result == true) _loadTasks();
  }

  Future<void> _navigateToEdit(TaskModel task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditTaskScreen(task: task)),
    );
    if (result == true) _loadTasks();
  }

  // ── Toggle Completion ────────────────────────────────────────────────────
  Future<void> _toggleComplete(TaskModel task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    final ok = await _apiService.updateTask(updated);
    if (ok) {
      _loadTasks();
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to update task')));
    }
  }

  // ── Trash (Soft Delete) ──────────────────────────────────────────────────
  Future<void> _trashTask(TaskModel task) async {
    final ok = await _apiService.trashTask(task.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? '🗑️ Moved to Trash' : '❌ Failed to delete'),
          behavior: SnackBarBehavior.floating,
          action: ok
              ? SnackBarAction(
                  label: 'Undo',
                  onPressed: () async {
                    await _apiService.restoreTask(task.id);
                    _loadTasks();
                  },
                )
              : null,
        ),
      );
      if (ok) _loadTasks();
    }
  }

  // ── Archive ──────────────────────────────────────────────────────────────
  Future<void> _archiveTask(TaskModel task) async {
    final ok = await _apiService.archiveTask(task.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? '📦 Archived' : '❌ Failed to archive'),
          behavior: SnackBarBehavior.floating,
          action: ok
              ? SnackBarAction(
                  label: 'Undo',
                  onPressed: () async {
                    await _apiService.archiveTask(task.id, archive: false);
                    _loadTasks();
                  },
                )
              : null,
        ),
      );
      if (ok) _loadTasks();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final scale = context.watch<FontProvider>().textScaleFactor;
    final user  = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: _buildAppBar(cs, scale, user?.username),
      body: Column(
        children: [
          // ── Search Bar (animated) ─────────────────────────────────────
          FadeTransition(
            opacity: _searchFade,
            child: SizeTransition(
              sizeFactor: _searchFade,
              axisAlignment: -1,
              child: _buildSearchBar(cs, scale),
            ),
          ),

          // ── Category Filter Chips ─────────────────────────────────────
          _buildCategoryFilter(cs, scale),

          // ── Sort Bar ─────────────────────────────────────────────────
          _buildSortBar(cs, scale),

          // ── Task List ─────────────────────────────────────────────────
          Expanded(child: _buildBody(cs, scale)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home_fab',
        onPressed: _navigateToAdd,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: Text('Add Task',
            style: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(ColorScheme cs, double scale, String? username) {
    return AppBar(
      backgroundColor: cs.surface,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${username ?? 'there'} 👋',
            style: TextStyle(
                fontSize: 13 * scale,
                color: cs.onSurface.withOpacity(0.55),
                fontWeight: FontWeight.w500),
          ),
          Text(
            'My Tasks',
            style: TextStyle(
                fontSize: 20 * scale,
                fontWeight: FontWeight.bold,
                color: cs.onSurface),
          ),
        ],
      ),
      actions: [
        // Search toggle
        IconButton(
          tooltip: _searchVisible ? 'Close Search' : 'Search',
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Icon(
              _searchVisible ? Icons.search_off_rounded : Icons.search_rounded,
              key: ValueKey(_searchVisible),
              color: _searchVisible ? cs.primary : cs.onSurface,
            ),
          ),
          onPressed: _toggleSearch,
        ),
        // Archive / Trash
        IconButton(
          tooltip: 'Archive & Trash',
          icon: Icon(Icons.inventory_2_outlined, color: cs.onSurface),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArchiveTrashScreen()),
            );
          },
        ),
        // Settings
        IconButton(
          tooltip: 'Settings',
          icon: Icon(Icons.settings_outlined, color: cs.onSurface),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSearchBar(ColorScheme cs, double scale) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        style: TextStyle(fontSize: 14 * scale),
        decoration: InputDecoration(
          hintText: 'Search by title or description…',
          hintStyle: TextStyle(fontSize: 13 * scale, color: cs.onSurface.withOpacity(0.45)),
          prefixIcon: Icon(Icons.search_rounded, color: cs.primary),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () { _searchCtrl.clear(); _applyFilters(); },
                )
              : null,
          filled: true,
          fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: cs.primary, width: 2)),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCategoryFilter(ColorScheme cs, double scale) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _kCategories.length,
        itemBuilder: (_, i) {
          final cat = _kCategories[i];
          final selected = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: ChoiceChip(
                label: Text(cat, style: TextStyle(fontSize: 12 * scale, fontWeight: FontWeight.w600)),
                selected: selected,
                selectedColor: cs.primary,
                labelStyle: TextStyle(
                    color: selected ? cs.onPrimary : cs.onSurface.withOpacity(0.7)),
                backgroundColor: cs.surfaceContainerHighest.withOpacity(0.5),
                side: BorderSide(
                    color: selected ? cs.primary : cs.outline.withOpacity(0.3)),
                onSelected: (_) {
                  setState(() => _selectedCategory = cat);
                  _applyFilters();
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSortBar(ColorScheme cs, double scale) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Icon(Icons.sort_rounded, size: 16, color: cs.onSurface.withOpacity(0.5)),
          const SizedBox(width: 6),
          Text('Sort:',
              style: TextStyle(
                  fontSize: 12 * scale,
                  color: cs.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _kSortOptions.map((opt) {
                  final (key, icon, label) = opt;
                  final selected = _sortMode == key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _sortMode = key);
                        _applyFilters();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? cs.primaryContainer
                              : cs.surfaceContainerHighest.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: selected
                                  ? cs.primary.withOpacity(0.5)
                                  : Colors.transparent),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon,
                                size: 13,
                                color: selected
                                    ? cs.primary
                                    : cs.onSurface.withOpacity(0.5)),
                            const SizedBox(width: 4),
                            Text(label,
                                style: TextStyle(
                                    fontSize: 11 * scale,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? cs.onPrimaryContainer
                                        : cs.onSurface.withOpacity(0.6))),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Results count
          Text(
            '${_filtered.length} task${_filtered.length != 1 ? 's' : ''}',
            style: TextStyle(
                fontSize: 11 * scale,
                color: cs.onSurface.withOpacity(0.4),
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBody(ColorScheme cs, double scale) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }
    if (_error != null) {
      return _buildError(cs, scale);
    }
    if (_allTasks.isEmpty) {
      return _buildEmpty(cs, scale);
    }
    if (_filtered.isEmpty) {
      return _buildNoResults(cs, scale);
    }

    final done  = _filtered.where((t) => t.isCompleted).length;
    final total = _filtered.length;

    return Column(
      children: [
        _buildProgressBanner(total, done, cs, scale),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTasks,
            color: cs.primary,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _filtered.length,
              itemBuilder: (_, i) => _buildTaskCard(_filtered[i], cs, scale),
            ),
          ),
        ),
      ],
    );
  }

  // ── Progress Banner ───────────────────────────────────────────────────────
  Widget _buildProgressBanner(int total, int done, ColorScheme cs, double scale) {
    final pct = total == 0 ? 0.0 : done / total;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$done / $total completed',
                style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w600,
                    color: cs.onPrimaryContainer),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                    color: cs.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: cs.onPrimaryContainer.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Task Card ─────────────────────────────────────────────────────────────
  Widget _buildTaskCard(TaskModel task, ColorScheme cs, double scale) {
    return Dismissible(
      key: Key('task_${task.id}'),
      // ← Swipe right = Archive
      background: _swipeBg(
        alignment: Alignment.centerLeft,
        color: const Color(0xFF4A90D9),
        icon: Icons.archive_rounded,
        label: 'Archive',
        padding: const EdgeInsets.only(left: 20),
      ),
      // → Swipe left = Trash
      secondaryBackground: _swipeBg(
        alignment: Alignment.centerRight,
        color: Colors.redAccent,
        icon: Icons.delete_rounded,
        label: 'Trash',
        padding: const EdgeInsets.only(right: 20),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Archive
          await _archiveTask(task);
          return false; // list refresh happens inside
        } else {
          // Trash
          await _trashTask(task);
          return false;
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 5),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: task.isCompleted
            ? cs.surfaceContainerHighest.withOpacity(0.4)
            : cs.surfaceContainerHighest.withOpacity(0.85),
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          // Completion circle
          leading: GestureDetector(
            onTap: () => _toggleComplete(task),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isCompleted ? Colors.green : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted ? Colors.green : cs.outline,
                  width: 2,
                ),
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w600,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted
                        ? cs.onSurface.withOpacity(0.4)
                        : cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Category chip
              _CategoryBadge(label: task.category, cs: cs, scale: scale),
            ],
          ),
          subtitle: task.description.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12 * scale,
                      color: cs.onSurface.withOpacity(0.55),
                    ),
                  ),
                )
              : null,
          trailing: IconButton(
            icon: Icon(Icons.edit_outlined, size: 20, color: cs.primary),
            onPressed: () => _navigateToEdit(task),
            tooltip: 'Edit task',
          ),
        ),
      ),
    );
  }

  Widget _swipeBg({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
    required EdgeInsets padding,
  }) {
    return Container(
      alignment: alignment,
      padding: padding,
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ── Empty States ──────────────────────────────────────────────────────────
  Widget _buildEmpty(ColorScheme cs, double scale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt_rounded, size: 72, color: cs.primary.withOpacity(0.25)),
          const SizedBox(height: 16),
          Text('No tasks yet!',
              style: TextStyle(
                  fontSize: 20 * scale,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface.withOpacity(0.4))),
          const SizedBox(height: 8),
          Text('Tap the button below to add your first task.',
              style:
                  TextStyle(fontSize: 13 * scale, color: cs.onSurface.withOpacity(0.3))),
        ],
      ),
    );
  }

  Widget _buildNoResults(ColorScheme cs, double scale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: cs.primary.withOpacity(0.25)),
          const SizedBox(height: 16),
          Text('No results found',
              style: TextStyle(
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface.withOpacity(0.4))),
          const SizedBox(height: 8),
          Text('Try a different keyword or category.',
              style:
                  TextStyle(fontSize: 13 * scale, color: cs.onSurface.withOpacity(0.3))),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme cs, double scale) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 64, color: Colors.redAccent.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('Connection Error',
                style: TextStyle(fontSize: 18 * scale, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12 * scale, color: cs.onSurface.withOpacity(0.5))),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadTasks,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Category Badge Widget
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryBadge extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  final double scale;

  const _CategoryBadge(
      {required this.label, required this.cs, required this.scale});

  // Color per category
  Color _color() {
    switch (label) {
      case 'Work':     return const Color(0xFF4A90D9);
      case 'Personal': return const Color(0xFF9B59B6);
      case 'Urgent':   return const Color(0xFFE74C3C);
      case 'Shopping': return const Color(0xFF27AE60);
      case 'Health':   return const Color(0xFF1ABC9C);
      default:         return const Color(0xFF7F8C8D);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10 * scale, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
