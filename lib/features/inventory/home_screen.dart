import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import 'column_config_sheet.dart';
import 'inventory_session.dart';
import 'main_inventory_screen.dart';
import 'session_config.dart';
import 'state.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<InventorySession> _filtered(List<InventorySession> sessions) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return sessions;
    return sessions
        .where((s) => s.name.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _createSession(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final created = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.newSession),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.sessionName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.create),
          ),
        ],
      ),
    );
    if (created == null || created.isEmpty) return;

    // Let the user pick which columns to track for this session.
    final config =
        await showColumnConfig(context, SessionConfig.empty());
    if (config == null || !context.mounted) return;

    final session = await ref
        .read(sessionsProvider.notifier)
        .create(created, config);
    if (!context.mounted) return;
    ref.read(activeSessionIdProvider.notifier).open(session.id);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MainInventoryScreen()),
    );
  }

  void _openSession(BuildContext context, InventorySession session) {
    ref.read(activeSessionIdProvider.notifier).open(session.id);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MainInventoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [_SettingsMenu()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createSession(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.newSession),
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (allSessions) {
          if (allSessions.isEmpty) {
            return Center(
              child: Text(l10n.noSessions, textAlign: TextAlign.center),
            );
          }
          final sessions = _filtered(allSessions);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.searchSessions,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() {
                              _search.clear();
                              _query = '';
                            }),
                          ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: sessions.isEmpty
                    ? Center(
                        child:
                            Text(l10n.noResults, textAlign: TextAlign.center),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: sessions.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final s = sessions[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.inventory_2),
                              title: Text(s.name),
                              subtitle: Text(
                                _formatDate(context, s.createdAt),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: l10n.delete,
                                    onPressed: () =>
                                        _confirmDelete(context, ref, s.id),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: () => _openSession(context, s),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime dt) {
    return DateFormat.yMMMd().format(dt);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSessionTitle),
        content: Text(l10n.deleteSessionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(sessionsProvider.notifier).delete(id);
    }
  }
}

class _SettingsMenu extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (v) {
        final modeNotifier = ref.read(themeModeProvider.notifier);
        final localeNotifier = ref.read(localeProvider.notifier);
        switch (v) {
          case 'light':
            modeNotifier.set(ThemeMode.light);
            break;
          case 'dark':
            modeNotifier.set(ThemeMode.dark);
            break;
          case 'en':
            localeNotifier.set(const Locale('en'));
            break;
          case 'ar':
            localeNotifier.set(const Locale('ar'));
            break;
        }
      },
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: 'light',
          checked: themeMode == ThemeMode.light,
          child: Text(l10n.light),
        ),
        CheckedPopupMenuItem(
          value: 'dark',
          checked: themeMode == ThemeMode.dark,
          child: Text(l10n.dark),
        ),
        const PopupMenuDivider(),
        CheckedPopupMenuItem(
          value: 'en',
          checked: locale.languageCode == 'en',
          child: Text('English'),
        ),
        CheckedPopupMenuItem(
          value: 'ar',
          checked: locale.languageCode == 'ar',
          child: const Text('العربية'),
        ),
      ],
    );
  }
}
