import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Public product page, based on the user's four-page SaaS reference.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  static const ink = Color(0xFF172321);
  static const muted = Color(0xFF64716E);
  static const green = Color(0xFF087F64);
  static const line = Color(0xFFE5EAE8);
  static const white = Color(0xFFFFFFFF);
  static const light = Color(0xFFF7F9F8);

  final scroll = ScrollController();
  final features = GlobalKey();
  final steps = GlobalKey();
  final faq = GlobalKey();
  final preview =
      'https://raw.githubusercontent.com/Technix19/apostol-portfolio/main/public/easybooks-dashboard-2026.webp';

  bool get signedIn =>
      Supabase.instance.client.auth.currentSession != null;

  void openApp({bool createAccount = false}) {
    Navigator.of(context).pushNamed(signedIn
        ? '/dashboard'
        : (createAccount ? '/signup' : '/login'));
  }

  void jumpTo(GlobalKey key) {
    final target = key.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.02,
      );
    }
  }

  void top() {
    scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  Widget brand() => InkWell(
        onTap: top,
        borderRadius: BorderRadius.circular(7),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 26, color: green),
              SizedBox(width: 9),
              Text(
                'EasyBooks',
                style: TextStyle(
                  color: ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
            ],
          ),
        ),
      );

  Widget link(String title, VoidCallback action) => TextButton(
        onPressed: action,
        style: TextButton.styleFrom(
          foregroundColor: muted,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        ),
        child: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );

  Widget primary(
    String title,
    VoidCallback action, {
    bool inverted = false,
    bool small = false,
  }) =>
      FilledButton(
        onPressed: action,
        style: FilledButton.styleFrom(
          backgroundColor: inverted ? white : ink,
          foregroundColor: inverted ? ink : white,
          shape: const StadiumBorder(),
          minimumSize: Size(0, small ? 40 : 49),
          padding: EdgeInsets.symmetric(
            horizontal: small ? 18 : 24,
            vertical: small ? 10 : 14,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: small ? 12 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget header(double width) {
    final narrow = width < 860;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: white,
        border: Border(bottom: BorderSide(color: line)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: narrow ? 20 : 32,
              vertical: 13,
            ),
            child: Row(
              children: [
                brand(),
                const Spacer(),
                if (!narrow) ...[
                  link('Features', () => jumpTo(features)),
                  link('How it works', () => jumpTo(steps)),
                  link('FAQ', () => jumpTo(faq)),
                  const SizedBox(width: 15),
                  link(signedIn ? 'My account' : 'Log in', () => openApp()),
                  const SizedBox(width: 7),
                  primary(
                    signedIn ? 'Open dashboard' : 'Get started',
                    () => openApp(createAccount: true),
                    small: true,
                  ),
                ] else ...[
                  if (width > 430)
                    primary(
                      signedIn ? 'Dashboard' : 'Get started',
                      () => openApp(createAccount: true),
                      small: true,
                    ),
                  PopupMenuButton<int>(
                    tooltip: 'Navigation menu',
                    icon: const Icon(Icons.menu, color: ink),
                    onSelected: (choice) {
                      if (choice == 0) jumpTo(features);
                      if (choice == 1) jumpTo(steps);
                      if (choice == 2) jumpTo(faq);
                      if (choice == 3) openApp();
                      if (choice == 4) openApp(createAccount: true);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 0, child: Text('Features')),
                      const PopupMenuItem(
                          value: 1, child: Text('How it works')),
                      const PopupMenuItem(value: 2, child: Text('FAQ')),
                      PopupMenuItem(
                          value: 3,
                          child: Text(signedIn ? 'Dashboard' : 'Log in')),
                      if (width <= 430)
                        const PopupMenuItem(
                            value: 4, child: Text('Get started')),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget sectionHeading(String title, String description) => Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ink,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.1,
              height: 1.14,
              fontSize: 34,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 630),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: muted, fontSize: 15, height: 1.65),
            ),
          ),
        ],
      );

  Widget hero(double width) {
    final mobile = width < 700;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 20 : 32,
        mobile ? 66 : 102,
        mobile ? 20 : 32,
        mobile ? 68 : 99,
      ),
      child: Column(
        children: [
          const Text(
            'A simpler way to keep your books in order',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: green,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 21),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 940),
            child: Text(
              'Know where your\nbusiness money goes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ink,
                fontWeight: FontWeight.w800,
                height: 1.07,
                fontSize: mobile ? 40 : (width < 1090 ? 57 : 69),
                letterSpacing: mobile ? -1.4 : -2.7,
              ),
            ),
          ),
          const SizedBox(height: 23),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 605),
            child: Text(
              'Record income and expenses, follow gross profit, and prepare tax reports from one straightforward dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: muted,
                fontSize: mobile ? 15 : 17,
                height: 1.65,
              ),
            ),
          ),
          const SizedBox(height: 29),
          Wrap(
            alignment: WrapAlignment.center,
            runSpacing: 12,
            spacing: 12,
            children: [
              primary(
                signedIn ? 'Open dashboard' : 'Start bookkeeping',
                () => openApp(createAccount: true),
              ),
              OutlinedButton(
                onPressed: () => jumpTo(features),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ink,
                  side: const BorderSide(color: line),
                  minimumSize: const Size(0, 49),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Explore features',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: mobile ? 54 : 75),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1110),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: white,
                    border: Border.all(color: line),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0B172321),
                        offset: Offset(0, 13),
                        blurRadius: 29,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 2047 / 1111,
                      child: Image.network(
                        preview,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                        semanticLabel:
                            'EasyBooks dashboard showing income, expenses, gross profit, and daily charts',
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: ink,
                          child: Center(
                            child: Text(
                              'EasyBooks dashboard preview',
                              style: TextStyle(color: white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                const Text(
                  'A look inside the EasyBooks dashboard',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(height: mobile ? 55 : 82),
          const Divider(color: line),
          const SizedBox(height: 26),
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 38,
            runSpacing: 16,
            children: [
              _SmallLabel('Income records'),
              _SmallLabel('Expense tracking'),
              _SmallLabel('Gross profit'),
              _SmallLabel('Tax reports'),
              _SmallLabel('CSV export'),
            ],
          ),
        ],
      ),
    );
  }

  Widget featuresSection(double width) {
    const items = [
      _Feature(Icons.call_received_outlined, 'Record your income',
          'Keep a clear record of sales, quantities, and amounts in one place.'),
      _Feature(Icons.call_made_outlined, 'Track expenses',
          'Document your business spending and keep cost records organized.'),
      _Feature(Icons.account_balance_wallet_outlined, 'See gross profit',
          'Understand how your recorded sales compare with your expenses.'),
      _Feature(Icons.show_chart, 'Follow daily trends',
          'Use date ranges and charts to review income and expense changes.'),
      _Feature(Icons.receipt_long_outlined, 'Prepare tax reports',
          'Work with reporting views for VAT-registered and non-VAT businesses.'),
      _Feature(Icons.download_outlined, 'Export your records',
          'Download income and expense data as CSV files for further review.'),
    ];
    return Container(
      key: features,
      color: light,
      padding: EdgeInsets.symmetric(
        horizontal: width < 700 ? 20 : 32,
        vertical: width < 700 ? 70 : 104,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1090),
          child: Column(
            children: [
              sectionHeading(
                'Your daily numbers, in one place.',
                'EasyBooks gives you the essentials for keeping track of business activity without getting lost in spreadsheets.',
              ),
              const SizedBox(height: 50),
              LayoutBuilder(
                builder: (context, constraints) {
                  final count = constraints.maxWidth >= 900
                      ? 3
                      : (constraints.maxWidth >= 540 ? 2 : 1);
                  const gap = 14.0;
                  final itemWidth =
                      (constraints.maxWidth - (count - 1) * gap) / count;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final item in items)
                        SizedBox(
                          width: itemWidth,
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 188),
                            padding: const EdgeInsets.all(26),
                            decoration: BoxDecoration(
                              color: white,
                              border: Border.all(color: line),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(item.icon, size: 23, color: green),
                                const SizedBox(height: 21),
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: ink,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.description,
                                  style: const TextStyle(
                                    color: muted,
                                    height: 1.6,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget stepsSection(double width) {
    const entries = [
      _Step('Create your workspace',
          'Set up an account and enter your organization name.'),
      _Step('Keep your records current',
          'Add sales and expenses as your business operates.'),
      _Step('Review and report',
          'Check trends, prepare reports, or export your data.'),
    ];
    return Container(
      key: steps,
      padding: EdgeInsets.symmetric(
        horizontal: width < 700 ? 20 : 32,
        vertical: width < 700 ? 76 : 110,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1090),
          child: Column(
            children: [
              sectionHeading(
                'From daily entries to a clearer picture.',
                'Get started with the basics, then turn your records into useful reports.',
              ),
              const SizedBox(height: 54),
              LayoutBuilder(
                builder: (context, constraints) {
                  final count = constraints.maxWidth >= 720 ? 3 : 1;
                  const gap = 24.0;
                  final itemWidth =
                      (constraints.maxWidth - (count - 1) * gap) / count;
                  return Wrap(
                    spacing: gap,
                    runSpacing: 30,
                    children: [
                      for (var index = 0; index < entries.length; index++)
                        SizedBox(
                          width: itemWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '0' + (index + 1).toString(),
                                style: const TextStyle(
                                  color: green,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 15),
                              const Divider(color: line),
                              const SizedBox(height: 15),
                              Text(
                                entries[index].title,
                                style: const TextStyle(
                                  color: ink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                entries[index].description,
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 14,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget faqSection(double width) {
    const entries = [
      _Answer('What can I track in EasyBooks?',
          'You can record income and expenses, review gross profit and daily charts, and use the tax reporting tools.'),
      _Answer('Can I review a specific date range?',
          'Yes. Use the date-range selectors to review income, expenses, and dashboard trends.'),
      _Answer('Can I download my records?',
          'Yes. The Income and Expenses pages include CSV export options.'),
      _Answer('Does EasyBooks handle VAT reporting?',
          'EasyBooks includes reporting paths for VAT-registered and non-VAT businesses. Always review the output against your current tax obligations before filing.'),
      _Answer('Do I need an email link to log in?',
          'No. Regular logins use your email address and password. Account confirmation or password recovery may require a one-time email.'),
    ];
    return Container(
      key: faq,
      color: light,
      padding: EdgeInsets.symmetric(
        horizontal: width < 700 ? 20 : 32,
        vertical: width < 700 ? 72 : 104,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              sectionHeading(
                'Frequently asked questions',
                'A few useful things to know before you start.',
              ),
              const SizedBox(height: 44),
              for (final entry in entries) ...[
                Theme(
                  data: ThemeData.light(useMaterial3: true)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 7,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(5, 0, 28, 22),
                    iconColor: green,
                    collapsedIconColor: muted,
                    title: Text(
                      entry.question,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          entry.answer,
                          style: const TextStyle(
                            color: muted,
                            height: 1.65,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: line, height: 1),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget bottomCta(double width) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: width < 700 ? 20 : 32,
          vertical: width < 700 ? 76 : 110,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1090),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: width < 700 ? 24 : 52,
                vertical: width < 700 ? 55 : 76,
              ),
              decoration: BoxDecoration(
                color: ink,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    'Make sense of your business numbers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: white,
                      fontWeight: FontWeight.w800,
                      fontSize: width < 700 ? 31 : 39,
                      height: 1.15,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'One place to record activity, follow your finances, and prepare reports.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFD0DBD7),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  primary(
                    signedIn ? 'Open dashboard' : 'Get started',
                    () => openApp(createAccount: true),
                    inverted: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget footer(double width) => Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: line)),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: width < 700 ? 20 : 32,
          vertical: 35,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 50,
                  runSpacing: 18,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        brand(),
                        const Text(
                          'A straightforward bookkeeping workspace.',
                          style: TextStyle(color: muted, fontSize: 13),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 4,
                      children: [
                        link('Features', () => jumpTo(features)),
                        link('How it works', () => jumpTo(steps)),
                        link('FAQ', () => jumpTo(faq)),
                        link(signedIn ? 'Dashboard' : 'Log in',
                            () => openApp()),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 35),
                const Divider(color: line),
                const SizedBox(height: 19),
                const Text(
                  '© 2026 EasyBooks. Built for practical bookkeeping.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          brightness: Brightness.light,
          surface: white,
        ),
      ),
      child: Scaffold(
        backgroundColor: white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              children: [
                header(constraints.maxWidth),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scroll,
                    child: Column(
                      children: [
                        hero(constraints.maxWidth),
                        featuresSection(constraints.maxWidth),
                        stepsSection(constraints.maxWidth),
                        faqSection(constraints.maxWidth),
                        bottomCta(constraints.maxWidth),
                        footer(constraints.maxWidth),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Feature {
  const _Feature(this.icon, this.title, this.description);
  final IconData icon;
  final String title;
  final String description;
}

class _Step {
  const _Step(this.title, this.description);
  final String title;
  final String description;
}

class _Answer {
  const _Answer(this.question, this.answer);
  final String question;
  final String answer;
}

class _SmallLabel extends StatelessWidget {
  const _SmallLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          color: Color(0xFF687773),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
}
