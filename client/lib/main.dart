import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'api.dart';
import 'google_auth_service.dart';
import 'google_button.dart';

void main() => runApp(const ScrapMarketApp());

class RotatingLoader extends StatefulWidget {
  const RotatingLoader({super.key, this.size = 24});

  final double size;

  @override
  State<RotatingLoader> createState() => _RotatingLoaderState();
}

class _RotatingLoaderState extends State<RotatingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox.square(
      dimension: widget.size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: RotationTransition(
          turns: CurvedAnimation(parent: controller, curve: Curves.linear),
          child: Icon(
            Icons.recycling_rounded,
            color: color,
            size: widget.size * 0.7,
          ),
        ),
      ),
    );
  }
}

Future<ImageSource?> chooseImageSource(BuildContext context) =>
    showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add a photo',
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.pop(sheetContext, ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13),
                  child: Text('Take photo with camera'),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pop(sheetContext, ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13),
                  child: Text('Upload from gallery'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

class ScrapMarketApp extends StatelessWidget {
  const ScrapMarketApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ScrapMarket',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff176b52),
        primary: const Color(0xff176b52),
        secondary: const Color(0xfff1a43c),
      ),
      scaffoldBackgroundColor: const Color(0xfff4f7f3),
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide.none,
        ),
      ),
    ),
    home: const MarketplaceShell(),
  );
}

class PasswordAccessPage extends StatefulWidget {
  const PasswordAccessPage({super.key, this.registrationMode = false});

  final bool registrationMode;

  @override
  State<PasswordAccessPage> createState() => _PasswordAccessPageState();
}

class _PasswordAccessPageState extends State<PasswordAccessPage> {
  final name = TextEditingController();
  final phone = TextEditingController(text: '+9665');
  final email = TextEditingController();
  final password = TextEditingController();
  final storeNumber = TextEditingController();
  bool loading = false;
  bool obscurePassword = true;
  bool googleReady = false;
  StreamSubscription<String>? googleSubscription;

  bool get registering => widget.registrationMode;

  @override
  void initState() {
    super.initState();
    if (!registering) _initializeGoogle();
  }

  Future<void> _initializeGoogle() async {
    try {
      final ready = await GoogleAuthService.instance.initialize();
      googleSubscription = GoogleAuthService.instance.idTokens.listen(
        _loginWithGoogle,
        onError: (_) => _showGoogleError(),
      );
      if (mounted) setState(() => googleReady = ready);
    } catch (_) {
      if (mounted) setState(() => googleReady = false);
    }
  }

  Future<void> _loginWithGoogle(String idToken) async {
    if (loading) return;
    setState(() => loading = true);
    try {
      await ApiService.instance.loginWithGoogle(idToken);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showGoogleError() {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in was not completed')),
      );
  }

  @override
  void dispose() {
    googleSubscription?.cancel();
    name.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    storeNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CircleAvatar(
                      radius: 34,
                      backgroundColor: Color(0xffe1f0e9),
                      child: Icon(Icons.recycling, size: 38),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      registering ? 'Create account' : 'Login',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      registering
                          ? 'Create your marketplace account.'
                          : 'Log in with your Saudi phone number.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 26),
                    if (registering) ...[
                      TextField(
                        controller: name,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Saudi phone number',
                        hintText: '+9665XXXXXXXX',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    if (registering) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: password,
                      obscureText: obscurePassword,
                      onSubmitted: registering ? null : (_) => _enterApp(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter any password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => obscurePassword = !obscurePassword,
                          ),
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    if (registering) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: storeNumber,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Store number',
                          hintText: '0101',
                          counterText: '',
                          prefixIcon: Icon(Icons.store_outlined),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: loading ? null : _enterApp,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: loading
                            ? const RotatingLoader(size: 22)
                            : Text(registering ? 'Create account' : 'Login'),
                      ),
                    ),
                    if (!registering && googleReady) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('or'),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                      ),
                      buildGoogleSignInButton(),
                    ],
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: loading
                          ? null
                          : registering
                          ? () => Navigator.of(context).pop(false)
                          : _openRegistration,
                      child: Text(
                        registering
                            ? 'Already registered? Back to login'
                            : 'New user? Register',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _enterApp() async {
    if (!RegExp(r'^\+9665\d{8}$').hasMatch(phone.text.trim()) ||
        password.text.length < (registering ? 8 : 1) ||
        (registering &&
            (name.text.trim().length < 2 ||
                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                    .hasMatch(email.text.trim()) ||
                !RegExp(r'^\d{1,4}$').hasMatch(storeNumber.text.trim())))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Check your name, email, +9665XXXXXXXX phone, password (8+ characters), and store number (up to 4 digits)',
          ),
        ),
      );
      return;
    }
    String? verificationMethod;
    if (registering) {
      verificationMethod = await _chooseVerificationMethod();
      if (verificationMethod == null || !mounted) return;
    }
    setState(() => loading = true);
    try {
      if (registering) {
        final pending = await ApiService.instance.startRegistration(
          name: name.text.trim(),
          phone: phone.text.trim(),
          email: email.text.trim().toLowerCase(),
          password: password.text,
          storeNumber: storeNumber.text.trim(),
          verificationMethod: verificationMethod!,
        );
        if (!mounted) return;
        final code = await _askForVerificationCode(
          pending['destination'] as String? ?? '',
        );
        if (code == null) return;
        await ApiService.instance.verifyRegistration(
          verificationId: pending['verificationId'] as String,
          code: code,
        );
      } else {
        await ApiService.instance.login(
          phone: phone.text.trim(),
          password: password.text,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot connect to the server')),
        );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<String?> _chooseVerificationMethod() => showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Verify your account'),
      content: const Text(
        'Where should we send your 6-digit verification code?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(dialogContext, 'phone'),
          icon: const Icon(Icons.sms_outlined),
          label: const Text('Phone'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(dialogContext, 'email'),
          icon: const Icon(Icons.email_outlined),
          label: const Text('Email'),
        ),
      ],
    ),
  );

  Future<String?> _askForVerificationCode(String destination) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter verification code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('We sent a 6-digit code to $destination.'),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Verification code',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (RegExp(r'^\d{6}$').hasMatch(controller.text)) {
                Navigator.pop(dialogContext, controller.text);
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _openRegistration() async {
    final registered = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const RegistrationPage()));
    if (registered == true && mounted) Navigator.of(context).pop(true);
  }
}

class RegistrationPage extends StatelessWidget {
  const RegistrationPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const PasswordAccessPage(registrationMode: true);
}

class Listing {
  const Listing(
    this.title,
    this.type,
    this.price,
    this.storeNumber,
    this.description,
    this.userName,
    this.phoneNumber,
    this.postedAt,
    this.postedYear,
    this.postedMonth,
    this.postedDay,
    this.icon,
    this.color, [
    this.imageUrl,
  ]);

  final String title;
  final String type;
  final String price;
  final String storeNumber;
  final String description;
  final String userName;
  final String phoneNumber;
  final String postedAt;
  final int postedYear;
  final int postedMonth;
  final int postedDay;
  final IconData icon;
  final Color color;
  final String? imageUrl;
}

const listings = [
  Listing(
    'Construction helpers needed',
    'Need Worker',
    '\$85 / day',
    '0101',
    'Need four reliable helpers for loading materials. Work starts at 8 AM.',
    'Ahmed Khan',
    '+966 50 123 4567',
    'Today, 9:30 AM',
    2026,
    9,
    1,
    Icons.engineering,
    Color(0xffe8d8c5),
  ),
  Listing(
    'Copper wire scrap',
    'Sell Scrap',
    '\$4.20 / kg',
    '0204',
    'Clean copper wire available in one large lot. Inspection is welcome.',
    'Maria Lopez',
    '+966 53 246 8105',
    'Today, 8:15 AM',
    2026,
    9,
    1,
    Icons.cable,
    Color(0xffd8e8e4),
  ),
  Listing(
    'Buying used batteries',
    'Buy Scrap',
    'Best price',
    '0318',
    'Buying used vehicle and inverter batteries in any reasonable quantity.',
    'Rahim Traders',
    '+966 54 381 7296',
    'Yesterday, 6:40 PM',
    2026,
    8,
    31,
    Icons.battery_5_bar,
    Color(0xffe5e1d5),
  ),
  Listing(
    'Experienced warehouse loader',
    'Need Job',
    '\$100 / day',
    '0407',
    'Available for warehouse loading work. Experienced and ready to start.',
    'Sam Wilson',
    '+966 55 492 6183',
    'Yesterday, 2:10 PM',
    2026,
    8,
    31,
    Icons.inventory_2,
    Color(0xffdde4ec),
  ),
  Listing(
    'Mixed aluminium sheets',
    'Sell Scrap',
    '\$2.80 / kg',
    '0512',
    'Mixed aluminium roofing sheets, dry and ready for collection today.',
    'Noor Recycling',
    '+966 56 735 2048',
    'Aug 30, 11:25 AM',
    2026,
    8,
    30,
    Icons.layers,
    Color(0xffe4ddd7),
  ),
  Listing(
    'Experienced delivery driver available',
    'Driver',
    'Negotiable',
    '0614',
    'Saudi-licensed driver available for delivery or company driving work.',
    'Fahad Ali',
    '+966 58 614 3072',
    'Aug 30, 9:10 AM',
    2026,
    8,
    30,
    Icons.local_shipping_outlined,
    Color(0xffdce7ef),
  ),
];

class MarketplaceShell extends StatefulWidget {
  const MarketplaceShell({super.key});

  @override
  State<MarketplaceShell> createState() => _MarketplaceShellState();
}

class _MarketplaceShellState extends State<MarketplaceShell> {
  int index = 0;
  bool signedIn = false;

  @override
  void initState() {
    super.initState();
    ApiService.instance.restoreSession().then((restored) {
      if (mounted) setState(() => signedIn = restored);
    });
  }

  Future<bool> _openLogin() async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const PasswordAccessPage()));
    if (result == true && mounted) setState(() => signedIn = true);
    return result == true;
  }

  Future<void> _openPost() async {
    if (!signedIn && !await _openLogin()) return;
    if (!mounted) return;
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CreatePostPage()));
  }

  Future<void> _selectDestination(int value) async {
    const profileIndex = 3;
    if (value == profileIndex && !signedIn) {
      final loggedIn = await _openLogin();
      if (!loggedIn || !mounted) return;
    }
    if (mounted) setState(() => index = value);
  }

  Future<void> _signOut() async {
    await ApiService.instance.signOut();
    await GoogleAuthService.instance.signOut();
    if (mounted)
      setState(() {
        signedIn = false;
        index = 0;
      });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(signedIn: signedIn, onLogin: _openLogin),
      const SavedPage(),
      const MyPostsPage(),
      ProfilePage(onSignOut: _signOut),
    ];
    return Scaffold(
      body: pages[index],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPost,
        icon: const Icon(Icons.add),
        label: const Text('Post'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _selectDestination,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            label: 'My posts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.signedIn, required this.onLogin});

  final bool signedIn;
  final VoidCallback onLogin;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const bannerImages = [
    'assets/banners/scrap-yard.png',
    'assets/banners/scrap-parts.png',
    'assets/banners/scrap-sunset.png',
    'assets/banners/scrap-batteries.png',
    'assets/banners/scrap-auto-parts.png',
    'assets/banners/scrap-appliances.png',
    'assets/banners/scrap-plastics.png',
    'assets/banners/scrap-cardboard.png',
    'assets/banners/scrap-construction.png',
    'assets/banners/scrap-electronics.png',
  ];

  String filter = 'All';
  String query = '';
  int selectedMonth = DateTime.now().month;
  int? selectedDay;
  int bannerIndex = 0;
  final bannerController = PageController();
  Timer? bannerTimer;
  List<Listing> remoteListings = [];
  List<String> categories = [];
  bool loadingPosts = true;
  String? postsError;

  static const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadCategories();
    bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !bannerController.hasClients) return;
      final next = (bannerIndex + 1) % bannerImages.length;
      bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _loadCategories() async {
    try {
      final values = await ApiService.instance.fetchCategories();
      if (mounted) setState(() => categories = values);
    } catch (_) {
      // The post feed can still render while Render/Neon is waking up.
    }
  }

  Future<void> _loadPosts() async {
    try {
      final rows = await ApiService.instance.fetchPosts();
      final mapped = rows.map((row) {
        final created = DateTime.parse(row['created_at'] as String).toLocal();
        final urls = (row['image_urls'] as List? ?? const []).cast<String>();
        final category = row['category'] as String;
        final icon = switch (category) {
          'Need Job' => Icons.work_outline,
          'Need Worker' => Icons.engineering,
          'Buy Scrap' => Icons.shopping_cart_outlined,
          'Driver' => Icons.local_shipping_outlined,
          _ => Icons.recycling,
        };
        final priceValue = row['price'];
        final unitValue = row['unit'] as String?;
        return Listing(
          row['title'] as String,
          category,
          priceValue == null
              ? 'Negotiable'
              : '$priceValue${unitValue == null ? '' : ' / $unitValue'}',
          row['store_number'] as String,
          row['description'] as String,
          row['user_name'] as String,
          row['phone'] as String,
          '${created.day}/${created.month}/${created.year}',
          created.year,
          created.month,
          created.day,
          icon,
          const Color(0xffd8e8e4),
          urls.isEmpty ? null : urls.first,
        );
      }).toList();
      if (mounted)
        setState(() {
          remoteListings = mapped;
          loadingPosts = false;
          postsError = null;
          if (mapped.isNotEmpty) selectedMonth = mapped.first.postedMonth;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          loadingPosts = false;
          postsError = 'Could not load posts';
        });
    }
  }

  @override
  void dispose() {
    bannerTimer?.cancel();
    bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postDates = remoteListings
        .map(
          (item) => DateTime(item.postedYear, item.postedMonth, item.postedDay),
        )
        .toList();
    final newestPostDate = postDates.isEmpty
        ? DateTime.now()
        : postDates.reduce(
            (current, date) => date.isAfter(current) ? date : current,
          );
    final rangeStart = newestPostDate.subtract(const Duration(days: 29));
    final windowDates = List.generate(
      30,
      (index) => rangeStart.add(Duration(days: index)),
    );
    final activeListings = remoteListings.where((item) {
      final createdAt = DateTime(
        item.postedYear,
        item.postedMonth,
        item.postedDay,
      );
      return !createdAt.isBefore(rangeStart) &&
          !createdAt.isAfter(newestPostDate);
    }).toList();
    final availableMonths =
        windowDates.map((date) => date.month).toSet().toList()..sort();
    final monthToShow = availableMonths.contains(selectedMonth)
        ? selectedMonth
        : (availableMonths.isEmpty ? selectedMonth : availableMonths.last);
    final availableDays =
        windowDates
            .where((date) => date.month == monthToShow)
            .map((date) => date.day)
            .toList()
          ..sort();
    final visible = activeListings.where((item) {
      return (filter == 'All' || item.type == filter) &&
          item.postedMonth == monthToShow &&
          (selectedDay == null || item.postedDay == selectedDay) &&
          item.title.toLowerCase().contains(query.toLowerCase());
    }).toList();
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(child: Icon(Icons.recycling)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Torik-Dammam Scrap Market',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const Text(
                                  'Find everything to buy and sell in one place.',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: widget.signedIn ? null : widget.onLogin,
                            icon: Icon(
                              widget.signedIn
                                  ? Icons.check_circle_outline
                                  : Icons.login,
                            ),
                            label: Text(
                              widget.signedIn
                                  ? 'Signed in'
                                  : MediaQuery.sizeOf(context).width < 600
                                  ? 'Login'
                                  : 'Login / Sign up',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          height: 220,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              PageView.builder(
                                controller: bannerController,
                                itemCount: bannerImages.length,
                                onPageChanged: (value) =>
                                    setState(() => bannerIndex = value),
                                itemBuilder: (context, index) => Image.asset(
                                  bannerImages[index],
                                  fit: BoxFit.cover,
                                  semanticLabel:
                                      'Scrap market banner ${index + 1}',
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 12,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    bannerImages.length,
                                    (index) => AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      width: bannerIndex == index ? 22 : 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: bannerIndex == index
                                            ? Colors.white
                                            : Colors.white70,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        onChanged: (value) => setState(() => query = value),
                        decoration: const InputDecoration(
                          hintText: 'Search work, metal, batteries…',
                          prefixIcon: Icon(Icons.search),
                          suffixIcon: Icon(Icons.tune),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 8,
                          children: ['All', ...categories]
                              .map(
                                (label) => ChoiceChip(
                                  label: Text(label),
                                  selected: filter == label,
                                  onSelected: (_) =>
                                      setState(() => filter = label),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xfffff3db),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xff9a6414),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Posts show for 30 days. Older posts are automatically deleted.',
                                style: TextStyle(
                                  color: Color(0xff68430c),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: availableMonths.isEmpty
                            ? null
                            : monthToShow,
                        decoration: const InputDecoration(
                          labelText: 'Choose month',
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                        ),
                        items: availableMonths
                            .map(
                              (month) => DropdownMenuItem(
                                value: month,
                                child: Text(monthNames[month - 1]),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            selectedMonth = value;
                            selectedDay = null;
                          });
                        },
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'All dates in this 30-day window are shown. Dates without posts remain empty.',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All days'),
                            selected: selectedDay == null,
                            onSelected: (_) =>
                                setState(() => selectedDay = null),
                          ),
                          ...availableDays.map((day) {
                            return ChoiceChip(
                              label: Text('$day'),
                              selected: selectedDay == day,
                              onSelected: (_) =>
                                  setState(() => selectedDay = day),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (loadingPosts)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: RotatingLoader(size: 34),
                          ),
                        ),
                      if (postsError != null)
                        Row(
                          children: [
                            Expanded(child: Text(postsError!)),
                            TextButton(
                              onPressed: _loadPosts,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      Text(
                        '${monthNames[monthToShow - 1]} posts',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
            sliver: SliverLayoutBuilder(
              builder: (context, _) => SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisExtent: 390,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => ListingCard(listing: visible[i]),
                  childCount: visible.length,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 150,
          child: listing.imageUrl == null
              ? ColoredBox(
                  color: listing.color,
                  child: Icon(listing.icon, size: 52, color: Colors.black54),
                )
              : Image.network(
                  listing.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: listing.color,
                    child: Icon(listing.icon, size: 52),
                  ),
                ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 40,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Row(
                          key: const Key('post-time-left'),
                          children: [
                            const Icon(
                              Icons.schedule_outlined,
                              size: 15,
                              color: Colors.black45,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              listing.postedAt,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.bookmark_border, size: 21),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Chip(
                          key: const Key('post-category-right'),
                          label: Text(listing.type),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  listing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  listing.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, height: 1.35),
                ),
                const SizedBox(height: 8),
                Text(
                  listing.price,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  listing.storeNumber,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const Divider(height: 18),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      child: Icon(Icons.person_outline, size: 18),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.userName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            listing.phoneNumber,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Call ${listing.userName}',
                      onPressed: () {},
                      icon: const Icon(Icons.call_outlined),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final title = TextEditingController();
  final description = TextEditingController();
  final price = TextEditingController();
  final unit = TextEditingController();
  final storeNumber = TextEditingController();
  final images = <UploadImage>[];
  final imagePicker = ImagePicker();
  List<String> categories = [];
  bool loadingCategories = true;
  String? type;
  bool publishing = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final values = await ApiService.instance.fetchCategories();
      if (mounted)
        setState(() {
          categories = values;
          loadingCategories = false;
        });
    } catch (_) {
      if (mounted) setState(() => loadingCategories = false);
    }
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    price.dispose();
    unit.dispose();
    storeNumber.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (images.length >= 3) return;
    final source = await chooseImageSource(context);
    if (source == null || !mounted) return;
    XFile? image;
    try {
      image = await imagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1800,
      );
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera or photo access is not available'),
          ),
        );
      }
      return;
    }
    if (image == null) return;
    final selectedImage = image;
    final bytes = await selectedImage.readAsBytes();
    if (bytes.length > 8 * 1024 * 1024) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Each image must be smaller than 8 MB')),
        );
      return;
    }
    setState(() => images.add(UploadImage(selectedImage.name, bytes)));
  }

  Future<void> _publish() async {
    if (type == null ||
        title.text.trim().length < 3 ||
        description.text.trim().length < 10 ||
        !RegExp(r'^\d{1,4}$').hasMatch(storeNumber.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a category and complete all required fields'),
        ),
      );
      return;
    }
    setState(() => publishing = true);
    try {
      await ApiService.instance.createPost(
        category: type!,
        title: title.text.trim(),
        description: description.text.trim(),
        price: price.text.trim(),
        unit: unit.text.trim(),
        storeNumber: storeNumber.text.trim(),
        images: images,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Post published')));
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot connect to the server')),
        );
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create a post')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Post category '),
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Text(
                'Required to create a post',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              if (loadingCategories)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: RotatingLoader(size: 32),
                  ),
                ),
              if (!loadingCategories && categories.isEmpty)
                Row(
                  children: [
                    const Expanded(
                      child: Text('Categories could not be loaded'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => loadingCategories = true);
                        _loadCategories();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories
                    .map(
                      (category) => ChoiceChip(
                        label: Text(category),
                        selected: type == category,
                        onSelected: (selected) =>
                            setState(() => type = selected ? category : null),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 22),
              const Text(
                'Photos (maximum 3)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index < 2 ? 10 : 0),
                      child: AspectRatio(
                        aspectRatio: 1.25,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                          clipBehavior: Clip.antiAlias,
                          onPressed: publishing || index > images.length
                              ? null
                              : () {
                                  if (index < images.length) {
                                    setState(() => images.removeAt(index));
                                  } else {
                                    _pickImage();
                                  }
                                },
                          child: index < images.length
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.memory(
                                      images[index].bytes,
                                      fit: BoxFit.cover,
                                    ),
                                    const Positioned(
                                      right: 6,
                                      top: 6,
                                      child: CircleAvatar(
                                        radius: 13,
                                        backgroundColor: Colors.black54,
                                        child: Icon(
                                          Icons.close,
                                          size: 17,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_a_photo_outlined),
                                    const SizedBox(height: 5),
                                    Text('Photo ${index + 1}'),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: price,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: unit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        hintText: 'kg / day / item',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: storeNumber,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: const InputDecoration(
                  labelText: 'Store number',
                  hintText: 'Example: 0101',
                  prefixIcon: Icon(Icons.store_outlined),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: publishing ? null : _publish,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: publishing
                      ? const RotatingLoader(size: 22)
                      : const Text('Publish post'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});
  @override
  Widget build(BuildContext context) => const EmptyPage(
    icon: Icons.bookmark_outline,
    title: 'Saved posts',
    message: 'Posts you save will appear here.',
  );
}

class MyPostsPage extends StatelessWidget {
  const MyPostsPage({super.key});
  @override
  Widget build(BuildContext context) => const EmptyPage(
    icon: Icons.article_outlined,
    title: 'My posts',
    message: 'Manage your work and scrap listings here.',
  );
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final storeNumber = TextEditingController();
  String savedStoreNumber = '';
  DateTime lastStoreNumberChange = DateTime.now().subtract(
    const Duration(days: 31),
  );
  bool loadingProfile = true;
  bool savingProfile = false;
  bool uploadingProfileImage = false;
  String? profileImageUrl;
  final profileImagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final cached = ApiService.instance.currentUser;
    if (cached != null) _applyUser(cached, notify: false);
    _loadProfile();
  }

  void _applyUser(Map<String, dynamic> user, {bool notify = true}) {
    name.text = user['name'] as String? ?? '';
    phone.text = user['phone'] as String? ?? '';
    savedStoreNumber = user['storeNumber'] as String? ?? '';
    profileImageUrl = user['profileImageUrl'] as String?;
    storeNumber.text = savedStoreNumber;
    final changedAt = user['storeNumberChangedAt'] as String?;
    lastStoreNumberChange = changedAt == null
        ? DateTime.now().subtract(const Duration(days: 31))
        : DateTime.parse(changedAt).toLocal();
    loadingProfile = false;
    if (notify && mounted) setState(() {});
  }

  Future<void> _loadProfile() async {
    if (ApiService.instance.token == null) {
      if (mounted) setState(() => loadingProfile = false);
      return;
    }
    try {
      _applyUser(await ApiService.instance.fetchProfile());
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => loadingProfile = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!RegExp(r'^\d{1,4}$').hasMatch(storeNumber.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store number must contain 1 to 4 digits'),
        ),
      );
      return;
    }
    final changed = storeNumber.text.trim() != savedStoreNumber;
    if (changed && !canChangeStoreNumber) {
      storeNumber.text = savedStoreNumber;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Store number can be changed again in $daysUntilStoreChange days',
          ),
        ),
      );
      return;
    }
    setState(() => savingProfile = true);
    try {
      final user = await ApiService.instance.updateStoreNumber(
        storeNumber.text.trim(),
      );
      _applyUser(user);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              changed
                  ? 'Profile saved. Store number is locked for 30 days.'
                  : 'Profile is up to date',
            ),
          ),
        );
    } on ApiException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => savingProfile = false);
    }
  }

  Future<void> _pickProfileImage() async {
    final source = await chooseImageSource(context);
    if (source == null || !mounted) return;
    XFile? image;
    try {
      image = await profileImagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1800,
      );
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera or photo access is not available'),
          ),
        );
      }
      return;
    }
    if (image == null) return;
    final selectedImage = image;
    final bytes = await selectedImage.readAsBytes();
    if (bytes.length > 8 * 1024 * 1024) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image must be smaller than 8 MB')),
        );
      return;
    }
    setState(() => uploadingProfileImage = true);
    try {
      _applyUser(
        await ApiService.instance.uploadProfileImage(
          UploadImage(selectedImage.name, bytes),
        ),
      );
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
    } on ApiException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => uploadingProfileImage = false);
    }
  }

  bool get canChangeStoreNumber => daysUntilStoreChange == 0;

  int get daysUntilStoreChange {
    final remaining = lastStoreNumberChange
        .add(const Duration(days: 30))
        .difference(DateTime.now());
    if (remaining.isNegative || remaining == Duration.zero) return 0;
    return (remaining.inHours / 24).ceil();
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    storeNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (loadingProfile)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: RotatingLoader(size: 34),
                      ),
                    ),
                  Text(
                    'Your profile',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'These details will appear below your posts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: const Color(0xffe1f0e9),
                          backgroundImage: profileImageUrl == null
                              ? null
                              : NetworkImage(profileImageUrl!),
                          child: profileImageUrl == null
                              ? const Icon(Icons.person_outline, size: 52)
                              : null,
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: IconButton.filled(
                            tooltip: 'Add profile picture',
                            onPressed: uploadingProfileImage
                                ? null
                                : _pickProfileImage,
                            icon: uploadingProfileImage
                                ? const RotatingLoader(size: 20)
                                : const Icon(Icons.add_a_photo_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: uploadingProfileImage ? null : _pickProfileImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      profileImageUrl == null
                          ? 'Add profile picture'
                          : 'Change profile picture',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: name,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_outline),
                      suffixIcon: Icon(Icons.lock_outline),
                      helperText: 'Name cannot be changed',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phone,
                    readOnly: true,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Saudi phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      suffixIcon: Icon(Icons.lock_outline),
                      helperText:
                          'Saudi numbers only (+966); cannot be changed',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: storeNumber,
                    readOnly: !canChangeStoreNumber,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Store number',
                      hintText: 'Example: 0101',
                      prefixIcon: const Icon(Icons.store_outlined),
                      suffixIcon: Icon(
                        canChangeStoreNumber
                            ? Icons.edit_outlined
                            : Icons.lock_clock_outlined,
                      ),
                      helperText: canChangeStoreNumber
                          ? 'Store number can be changed now'
                          : 'Can be changed again in $daysUntilStoreChange days',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: loadingProfile || savingProfile
                        ? null
                        : _saveProfile,
                    icon: const Icon(Icons.check),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: savingProfile
                          ? const RotatingLoader(size: 22)
                          : const Text('Save profile'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: savingProfile ? null : widget.onSignOut,
                    icon: const Icon(Icons.logout),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Sign out'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class EmptyPage extends StatelessWidget {
  const EmptyPage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    ),
  );
}
