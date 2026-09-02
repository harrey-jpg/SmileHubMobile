import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/profile_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final ProfileService _profileService = ProfileService();
  final AdminService _adminService = AdminService();

  String _fullName = 'SmileHub User';
  String _buyerType = 'Customer';
  bool _isLoadingProfile = true;
  String? _userRole;
  bool _checkingRole = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      final String? role = await _adminService.getCurrentUserRole();
      if (!mounted) return;
      setState(() {
        _userRole = role;
        _checkingRole = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _checkingRole = false);
    }
  }

  bool get _isAdmin {
    final String r = (_userRole ?? '').toLowerCase();
    return AdminService.adminRoles.contains(r);
  }

  String get _initials {
    final List<String> parts = _fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'SH';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }

  Future<void> _loadProfile() async {
    try {
      final Map<String, String> profile =
          await _profileService.loadProfile();

      if (!mounted) return;

      setState(() {
        final String loadedName =
            profile['fullName']?.trim() ?? '';

        final String loadedBuyerType =
            profile['buyerType']?.trim() ?? '';

        _fullName = loadedName.isEmpty
            ? 'SmileHub User'
            : loadedName;

        _buyerType = loadedBuyerType.isEmpty
            ? 'Customer'
            : loadedBuyerType;

        _isLoadingProfile = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingProfile = false;
      });

      debugPrint('Account profile error: $error');
    }
  }

  Future<void> _openPersonalInformation() async {
    final Object? result = await Navigator.of(context).pushNamed(
      AppRoutes.personalInformation,
    );

    if (result == true) {
      await _loadProfile();
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService().signOut();

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;

      showAppSnackBar(
        context,
        'Unable to log out.',
      );

      debugPrint('Logout error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);

    return MobileScaffold(
      appBar: const ScreenTitleBar(
        title: 'My Account',
        showBack: false,
      ),
      bottomNavigationBar: const MainBottomNavigation(
        currentIndex: 4,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          26,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF0D5F72)
                      : AppColors.teal,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: _isLoadingProfile
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _initials,
                          style: const TextStyle(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isLoadingProfile
                            ? 'Loading...'
                            : _fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLoadingProfile ? '' : _buyerType,
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: OrderService().watchMyOrders(),
            builder: (BuildContext context,
                AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
              if (snapshot.hasError) {
                return const AppCard(
                  child: Text('Unable to load your latest order.'),
                );
              }
              if (!snapshot.hasData) {
                return const AppCard(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
                  snapshot.data!.docs;
              if (docs.isEmpty) {
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Latest Order',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.orders),
                        child: Text(
                          'No orders yet. Tap here to view your orders.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              QueryDocumentSnapshot<Map<String, dynamic>> latest = docs.first;
              for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
                  in docs) {
                final DateTime? docDate =
                    (doc.data()['createdAt'] as Timestamp?)?.toDate();
                final DateTime? latestDate =
                    (latest.data()['createdAt'] as Timestamp?)?.toDate();
                if (docDate != null &&
                    (latestDate == null || docDate.isAfter(latestDate))) {
                  latest = doc;
                }
              }
              final Map<String, dynamic> data = latest.data();
              final String status =
                  data['status']?.toString() ?? 'Pending';
              final String number =
                  data['orderNumber']?.toString() ?? '—';
              final int itemCount =
                  (data['itemCount'] as num?)?.toInt() ?? 0;
              final double total = (data['total'] as num?)?.toDouble() ?? 0;

              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Latest Order',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        Chip(label: Text(status)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '#$number',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$itemCount item${itemCount == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Total',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '₱${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          if (!_checkingRole && _isAdmin) ...[
            const SizedBox(height: 18),
            Text(
              'Admin Panel',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Role: ${(_userRole ?? '').toUpperCase()} — manage store data',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.dashboard_rounded,
                    label: 'Admin Dashboard',
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminDashboard),
                  ),
                  const Divider(height: 1),
                  _SettingsRow(
                    icon: Icons.receipt_long_rounded,
                    label: 'Manage Orders',
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminOrders),
                  ),
                  const Divider(height: 1),
                  _SettingsRow(
                    icon: Icons.inventory_2_rounded,
                    label: 'Manage Products / Inventory',
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminProducts),
                  ),
                  const Divider(height: 1),
                  _SettingsRow(
                    icon: Icons.people_rounded,
                    label: 'Customers & Accounts',
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminCustomers),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          Text(
            'Account Settings',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Personal Information',
                  onTap: _openPersonalInformation,
                ),
                const Divider(height: 1),
                _SettingsRow(
                  icon: Icons.location_on_outlined,
                  label: 'Shipping Addresses',
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.addresses,
                    );
                  },
                ),
                const Divider(height: 1),
                _SettingsRow(
                  icon: Icons.credit_card_rounded,
                  label: 'Payment Methods',
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.payments,
                    );
                  },
                ),
                const Divider(height: 1),
                _SettingsRow(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.help,
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: Icon(
                    controller.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                  ),
                  title: const Text(
                    'Dark Mode',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  value: controller.isDarkMode,
                  onChanged: controller.toggleTheme,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.danger,
                  ),
                  title: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.danger,
                  ),
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
      ),
      onTap: onTap,
    );
  }
}