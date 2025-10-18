import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:repo_easybooks/auth/auth_gate.dart';
import 'package:repo_easybooks/auth/auth_service.dart';
import 'package:repo_easybooks/data/notifiers.dart';
import 'package:repo_easybooks/expenses_page.dart';
import 'package:repo_easybooks/home_page.dart';
import 'package:repo_easybooks/income_page.dart';
import 'package:repo_easybooks/select_vat_status_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ====== Simple knob to control ALL sidebar menu label font sizes ======
double sidebarMenuFontSize = 14;

// ====== Shared design tokens for dialogs and panels ======
const _sbBg = Color(0xFF121212);
const _panel = Color(0xFF1A1A1A);
const _border = Color(0xFF3A3A3A);
const _title = Color(0xFFEDEDED);
const _muted = Color(0xFFBFBFBF);
const _accent = Color(0xFF6FFF43);
const _chipBg = Color(0xFF2A2A2A);

final List<Widget> pages = const [
  HomePage(),
  IncomePage(),
  ExpensesPage(),
  SelectVatStatusPage(), // index 3
  TaxReportNotVatRegisteredPage(), // index 4
  TaxReportPage(), // index 5
];

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  final authService = AuthService();
  final supabase = Supabase.instance.client;
  final profile_stream = Supabase.instance.client
      .from('profile')
      .stream(primaryKey: ['id']);

  // Profile Info Dialog (values unchanged; styled UI)
  Future<void> _profileInfoInputDialog() async {
    String username = '';
    String org_name = '';

    final user_id = supabase.auth.currentUser!.id;
    final check_if_theres_username = await supabase
        .from('profile')
        .select('username')
        .eq('user_id', user_id)
        .maybeSingle();

    if (check_if_theres_username == null ||
        (check_if_theres_username['username'] ?? '').toString().isEmpty) {
      // ignore: use_build_context_synchronously
      return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: _sbBg,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: _border),
            ),
            title: const Text(
              "Complete your profile",
              style: TextStyle(color: _title, fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LabeledField(
                  label: 'Username',
                  hint: 'Enter your username',
                  onChanged: (v) => setState(() => username = v),
                  icon: Icons.person,
                ),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Business Name',
                  hint: 'Enter your business name',
                  onChanged: (v) => setState(() => org_name = v),
                  icon: Icons.business_outlined,
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            actions: [
              FilledButton(
                onPressed: () async {
                  try {
                    if (username.isEmpty || org_name.isEmpty) {
                      throw Exception("Please input your profile information");
                    }

                    Navigator.pop(
                      context,
                    ); //Debug Fixed: Put this above the await
                    await supabase.from('profile').insert({
                      'username': username,
                      'org_name': org_name,
                    });
                    // ignore: use_build_context_synchronously
                  } catch (e) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.red,
                        content: Text("Error: $e"),
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Submit"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _profileInfoInputDialog();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ================= LEFT SIDEBAR =================
          Container(
            width: 250,
            decoration: const BoxDecoration(
              color: _sbBg,
              border: Border(right: BorderSide(color: _border, width: 1)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    StreamBuilder(
                      stream: profile_stream,
                      builder: (context, snapshot) {
                        String orgNameLabel = 'Organization';
                        if (snapshot.hasData &&
                            (snapshot.data as List).isNotEmpty) {
                          final first = (snapshot.data as List).first;
                          final show_org_name = (first['org_name'] ?? '')
                              .toString();
                          if (show_org_name.isNotEmpty) {
                            orgNameLabel = show_org_name;
                          }
                        }
                        return _SidebarHeader(
                          title: orgNameLabel,
                          onTap: () {
                            // Profile Information dialog
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: _sbBg,
                                  surfaceTintColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(color: _border),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 500,
                                    maxWidth: 700,
                                    maxHeight:
                                        560, // <=== CHANGE HEIGHT HERE (default 560)
                                  ),
                                  insetPadding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 24,
                                  ),
                                  titlePadding: const EdgeInsets.fromLTRB(
                                    20,
                                    16,
                                    12,
                                    0,
                                  ),
                                  contentPadding: const EdgeInsets.fromLTRB(
                                    20,
                                    8,
                                    20,
                                    16,
                                  ),
                                  title: Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          "Profile Information",
                                          style: TextStyle(
                                            color: _title,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => Navigator.pop(context),
                                        icon: const Icon(
                                          Icons.close,
                                          color: _muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: StreamBuilder(
                                    stream: profile_stream,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox(
                                          height: 160,
                                          child: Center(
                                            child:
                                                CircularProgressIndicator.adaptive(),
                                          ),
                                        );
                                      }
                                      final rows = snapshot.data ?? [];
                                      if (rows.isEmpty) {
                                        return const Text(
                                          'No profile yet. Please add one.',
                                          style: TextStyle(color: _muted),
                                        );
                                      }

                                      final profile = rows.first;
                                      final username =
                                          (profile['username'] ?? '')
                                              .toString();
                                      final org_name =
                                          (profile['org_name'] ?? '')
                                              .toString();
                                      final email = authService
                                          .getCurrentUserEmail();

                                      final str_creation_date =
                                          (profile['created_at'] ?? '')
                                              .toString();
                                      final time_creation_date =
                                          str_creation_date.isNotEmpty
                                          ? DateTime.parse(
                                              str_creation_date,
                                            ).toUtc()
                                          : null;

                                      return ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minWidth: 500,
                                          maxWidth: 640,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _SectionHeader(title: 'Account'),

                                            // ====> Add Profile Picture Here <====
                                            const SizedBox(height: 10),
                                            _ProfileCard(
                                              children: [
                                                _ProfileTile(
                                                  icon: Icons.person,
                                                  label: 'Username',
                                                  value: username,
                                                  onEdit: () {
                                                    String newUsername = '';
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) {
                                                        return _EditDialog(
                                                          title:
                                                              'Update Username',
                                                          hint: 'New Username',
                                                          dialogHeight:
                                                              70, // <=== CHANGE HEIGHT HERE
                                                          onChanged: (v) =>
                                                              setState(
                                                                () =>
                                                                    newUsername =
                                                                        v,
                                                              ),
                                                          onSubmit: () async {
                                                            try {
                                                              if (newUsername
                                                                  .isEmpty) {
                                                                throw Exception(
                                                                  "Username can not be empty!",
                                                                );
                                                              }
                                                              await supabase
                                                                  .from(
                                                                    'profile',
                                                                  )
                                                                  .update({
                                                                    'username':
                                                                        newUsername,
                                                                  })
                                                                  .eq(
                                                                    'user_id',
                                                                    supabase
                                                                        .auth
                                                                        .currentUser!
                                                                        .id,
                                                                  );
                                                              // ignore: use_build_context_synchronously
                                                              Navigator.pop(
                                                                context,
                                                              );
                                                              // ignore: use_build_context_synchronously
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                const SnackBar(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .lightGreenAccent,
                                                                  content: Text(
                                                                    "Username has been updated!",
                                                                  ),
                                                                ),
                                                              );
                                                            } catch (e) {
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red,
                                                                  content: Text(
                                                                    "Error: $e",
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                          },
                                                        );
                                                      },
                                                    );
                                                  },
                                                ),
                                                const Divider(
                                                  height: 1,
                                                  color: _border,
                                                ),
                                                _ProfileTile(
                                                  icon: Icons.email_outlined,
                                                  label: 'Email',
                                                  value: email ?? '',
                                                  onEdit: null,
                                                ),
                                                const Divider(
                                                  height: 1,
                                                  color: _border,
                                                ),
                                                _ProfileTile(
                                                  icon: Icons
                                                      .calendar_month_outlined,
                                                  label: 'Created',
                                                  value:
                                                      time_creation_date == null
                                                      ? ''
                                                      : DateFormat(
                                                          'MMMM d, y',
                                                        ).format(
                                                          time_creation_date
                                                              .toLocal(),
                                                        ),
                                                  onEdit: null,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            _SectionHeader(
                                              title: 'Organization',
                                            ),
                                            const SizedBox(height: 10),
                                            _ProfileCard(
                                              children: [
                                                _ProfileTile(
                                                  icon: Icons.business_outlined,
                                                  label: 'Business Name',
                                                  value: org_name,
                                                  onEdit: () {
                                                    String newOrgName = '';
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) {
                                                        return _EditDialog(
                                                          title:
                                                              'Update Business Name',
                                                          hint:
                                                              'New Business Name',
                                                          dialogHeight:
                                                              70, // <=== CHANGE HEIGHT HERE
                                                          onChanged: (v) =>
                                                              setState(
                                                                () =>
                                                                    newOrgName =
                                                                        v,
                                                              ),
                                                          onSubmit: () async {
                                                            try {
                                                              if (newOrgName
                                                                  .isEmpty) {
                                                                throw Exception(
                                                                  "New Business Name Can't Be Empty!",
                                                                );
                                                              }
                                                              await supabase
                                                                  .from(
                                                                    'profile',
                                                                  )
                                                                  .update({
                                                                    'org_name':
                                                                        newOrgName,
                                                                  })
                                                                  .eq(
                                                                    'user_id',
                                                                    supabase
                                                                        .auth
                                                                        .currentUser!
                                                                        .id,
                                                                  );
                                                              // ignore: use_build_context_synchronously
                                                              Navigator.pop(
                                                                context,
                                                              );
                                                              // ignore: use_build_context_synchronously
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                const SnackBar(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .lightGreenAccent,
                                                                  content: Text(
                                                                    "Business Name has been updated successfully!",
                                                                  ),
                                                                ),
                                                              );
                                                            } catch (e) {
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red,
                                                                  content: Text(
                                                                    "Error: $e",
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                          },
                                                        );
                                                      },
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: OutlinedButton(
                                                onPressed: () {
                                                  authService.signOut();
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      backgroundColor: Colors
                                                          .lightGreenAccent,
                                                      content: Text(
                                                        "You have been logged out successfully!",
                                                      ),
                                                    ),
                                                  );
                                                  Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          const AuthGate(),
                                                    ),
                                                  );
                                                },
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(
                                                    color: _border,
                                                  ),
                                                  foregroundColor: _title,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                                child: const Text("Sign out"),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'DASHBOARD',
                      style: TextStyle(
                        color: _title,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Menu
                    ValueListenableBuilder(
                      valueListenable: notifier_selectedPage,
                      builder: (context, current, _) {
                        return Column(
                          children: [
                            _SidebarItem(
                              icon: Icons.grid_view_rounded,
                              label: 'Home',
                              selected: current == 0,
                              onTap: () => notifier_selectedPage.value = 0,
                              fontSize: sidebarMenuFontSize,
                            ),
                            _SidebarItem(
                              icon: Icons.lock,
                              label: 'Income',
                              selected: current == 1,
                              onTap: () => notifier_selectedPage.value = 1,
                              fontSize: sidebarMenuFontSize,
                            ),
                            _SidebarItem(
                              icon: Icons.bar_chart_rounded,
                              label: 'Expenses',
                              selected: current == 2,
                              onTap: () => notifier_selectedPage.value = 2,
                              fontSize: sidebarMenuFontSize,
                            ),
                            _SidebarItem(
                              icon: Icons.group_rounded,
                              label: 'Tax Report',
                              selected:
                                  current == 3 ||
                                  current == 4 ||
                                  current ==
                                      5, // ✅ Highlight all 3 related pages
                              onTap: () => notifier_selectedPage.value =
                                  3, // Always go to main SelectVatStatusPage when clicked
                              fontSize: sidebarMenuFontSize,
                            ),
                          ],
                        );
                      },
                    ),
                    const Spacer(),

                    // ===== Bottom brand: just the image (no text) =====
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 11),
                        child: Image.asset(
                          'assets/images/easybooks_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ================= RIGHT CONTENT =================
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: notifier_selectedPage,
              builder: (context, selectedPage, _) {
                return pages.elementAt(selectedPage);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Smaller visual widgets =====
class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: _chipBg,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _title,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final double? fontSize;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    final Color textColor = selected
        ? Colors.black
        : (enabled ? const Color(0xFFBFBFBF) : const Color(0xFF8A8A8A));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: selected ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: selected ? Colors.black : textColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize ?? 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Sections & Cards for Profile dialog
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _muted,
        fontWeight: FontWeight.w700,
        fontSize: 12,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(children: children),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onEdit,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minLeadingWidth: 0,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _chipBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _title, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: _muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: _title,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: onEdit == null
          ? null
          : TextButton.icon(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: _accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text(
                'Edit',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
    );
  }
}

// Small "Update ___" dialog (height adjustable)
class _EditDialog extends StatelessWidget {
  const _EditDialog({
    required this.title,
    required this.hint,
    required this.onChanged,
    required this.onSubmit,
    this.dialogHeight,
    this.dialogWidth,
  });

  final String title;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final double? dialogHeight;
  final double? dialogWidth;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _sbBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _border),
      ),
      title: Text(
        title,
        style: const TextStyle(color: _title, fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: dialogWidth ?? 520,
        height: dialogHeight ?? 180, // <=== CHANGE HEIGHT HERE
        child: _LabeledField(
          label: title,
          hint: hint,
          onChanged: onChanged,
          icon: Icons.edit_outlined,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: _muted),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: onSubmit,
          style: FilledButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text("Submit"),
        ),
      ],
    );
  }
}

// Reusable styled field
class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.onChanged,
    required this.icon,
  });

  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          onChanged: onChanged,
          style: const TextStyle(color: _title),
          cursorColor: _accent,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF8A8A8A)),
            prefixIcon: Icon(icon, color: _muted, size: 18),
            isDense: true,
            filled: true,
            fillColor: _panel,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _accent, width: 1.2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
