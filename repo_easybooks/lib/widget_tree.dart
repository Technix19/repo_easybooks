import 'package:flutter/material.dart';
import 'package:repo_easybooks/account_settings_page.dart';
import 'package:repo_easybooks/data/notifiers.dart';
import 'package:repo_easybooks/expenses_page.dart';
import 'package:repo_easybooks/home_page.dart';
import 'package:repo_easybooks/income_page.dart';
import 'package:repo_easybooks/select_vat_status_page.dart';
import 'package:repo_easybooks/tax_report_not_vat_registered_page.dart';
import 'package:repo_easybooks/tax_report_page.dart';
import 'package:repo_easybooks/theme/easybooks_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Keep the existing page indices. Other bookkeeping flows depend on them.
final List<Widget> pages = const [
  HomePage(),
  IncomePage(),
  ExpensesPage(),
  SelectVatStatusPage(),
  TaxReportNotVatRegisteredPage(),
  TaxReportPage(),
];

enum _AccountAction { settings, signOut }

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  final _client = Supabase.instance.client;
  late final Stream<List<Map<String, dynamic>>> _profileStream;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    final userId = _client.auth.currentUser?.id;
    _profileStream = userId == null
        ? Stream.value(<Map<String, dynamic>>[])
        : _client
            .from('profile')
            .stream(primaryKey: ['id'])
            .eq('user_id', userId);

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkProfileSetup());
  }

  Future<void> _checkProfileSetup() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final record = await _client
          .from('profile')
          .select('username, org_name')
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;
      final username = (record?['username'] ?? '').toString().trim();
      final organization = (record?['org_name'] ?? '').toString().trim();
      if (username.isEmpty || organization.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Add your name and organization to finish setup.'),
            action: SnackBarAction(
              label: 'Open settings',
              onPressed: _openSettings,
            ),
          ),
        );
      }
    } catch (_) {
      // The account menu remains accessible if the profile check cannot load.
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AccountSettingsPage(),
      ),
    );
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await _client.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to sign out. Please try again.'),
          backgroundColor: EasyBooksTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  void _handleAccountAction(_AccountAction action, {required bool mobile}) {
    if (mobile && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); // Close the mobile navigation drawer.
    }
    switch (action) {
      case _AccountAction.settings:
        _openSettings();
      case _AccountAction.signOut:
        _signOut();
    }
  }

  Widget _navigationItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? EasyBooksTheme.elevatedSurface
            : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: SizedBox(
            height: 42,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 19,
                    color: selected
                        ? EasyBooksTheme.accent
                        : EasyBooksTheme.muted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: selected
                            ? EasyBooksTheme.text
                            : EasyBooksTheme.muted,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sidebar({
    required bool mobile,
    required String organization,
    required String username,
    required String email,
  }) {
    final initials =
        username.trim().isEmpty ? '?' : username.trim()[0].toUpperCase();

    return Container(
      width: 248,
      decoration: const BoxDecoration(
        color: EasyBooksTheme.sidebar,
        border: Border(
          right: BorderSide(color: EasyBooksTheme.border),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 25,
                      color: EasyBooksTheme.accent,
                    ),
                    SizedBox(width: 11),
                    Text(
                      'EasyBooks',
                      style: TextStyle(
                        color: EasyBooksTheme.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Workspace',
                  style: TextStyle(
                    color: EasyBooksTheme.muted.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openSettings,
                  borderRadius: BorderRadius.circular(7),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            organization.isEmpty
                                ? 'Set up organization'
                                : organization,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: EasyBooksTheme.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: EasyBooksTheme.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 23),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Overview',
                  style: TextStyle(
                    color: EasyBooksTheme.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder(
                valueListenable: notifier_selectedPage,
                builder: (context, current, _) {
                  void select(int index) {
                    notifier_selectedPage.value = index;
                    if (mobile) Navigator.of(context).pop();
                  }

                  return Column(
                    children: [
                      _navigationItem(
                        icon: Icons.space_dashboard_outlined,
                        label: 'Dashboard',
                        selected: current == 0,
                        onTap: () => select(0),
                      ),
                      _navigationItem(
                        icon: Icons.call_received_outlined,
                        label: 'Income',
                        selected: current == 1,
                        onTap: () => select(1),
                      ),
                      _navigationItem(
                        icon: Icons.call_made_outlined,
                        label: 'Expenses',
                        selected: current == 2,
                        onTap: () => select(2),
                      ),
                      _navigationItem(
                        icon: Icons.receipt_long_outlined,
                        label: 'Tax reports',
                        selected: current == 3 ||
                            current == 4 ||
                            current == 5,
                        onTap: () => select(3),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),
              const Divider(color: EasyBooksTheme.border, height: 1),
              const SizedBox(height: 12),
              PopupMenuButton<_AccountAction>(
                tooltip: 'Open account menu',
                position: PopupMenuPosition.over,
                onSelected: (action) =>
                    _handleAccountAction(action, mobile: mobile),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _AccountAction.settings,
                    child: Row(
                      children: [
                        Icon(Icons.manage_accounts_outlined, size: 19),
                        SizedBox(width: 12),
                        Text('Account settings'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: _AccountAction.signOut,
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 19),
                        SizedBox(width: 12),
                        Text('Sign out'),
                      ],
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: EasyBooksTheme.elevatedSurface,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: EasyBooksTheme.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username.isEmpty ? 'My account' : username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: EasyBooksTheme.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: EasyBooksTheme.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.more_horiz,
                        size: 20,
                        color: EasyBooksTheme.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectedContent() {
    return ValueListenableBuilder(
      valueListenable: notifier_selectedPage,
      builder: (context, selected, _) {
        final index = selected is int &&
                selected >= 0 &&
                selected < pages.length
            ? selected
            : 0;
        // Existing EasyBooks page widgets already return Expanded.
        return pages[index];
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 850;
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _profileStream,
          builder: (context, snapshot) {
            final profile = snapshot.data != null &&
                    snapshot.data!.isNotEmpty
                ? snapshot.data!.first
                : <String, dynamic>{};
            final organization =
                (profile['org_name'] ?? '').toString().trim();
            final username =
                (profile['username'] ?? '').toString().trim();
            final email = _client.auth.currentUser?.email ?? '';

            return Scaffold(
              backgroundColor: EasyBooksTheme.background,
              drawer: mobile
                  ? Drawer(
                      width: 248,
                      child: _sidebar(
                        mobile: true,
                        organization: organization,
                        username: username,
                        email: email,
                      ),
                    )
                  : null,
              appBar: mobile
                  ? AppBar(
                      title: const Text(
                        'EasyBooks',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      actions: [
                        IconButton(
                          tooltip: 'Account settings',
                          icon: const Icon(Icons.account_circle_outlined),
                          onPressed: _openSettings,
                        ),
                      ],
                    )
                  : null,
              body: mobile
                  ? Column(children: [_selectedContent()])
                  : Row(
                      children: [
                        _sidebar(
                          mobile: false,
                          organization: organization,
                          username: username,
                          email: email,
                        ),
                        _selectedContent(),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}
