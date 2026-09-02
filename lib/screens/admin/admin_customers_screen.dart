import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  final AdminService _adminService = AdminService();

  String? _role;
  bool _checkingRole = true;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _accounts = <Map<String, dynamic>>[];
  String _query = '';
  String _roleFilter = 'all';
  final Set<String> _busyEmails = <String>{};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final String? r = await _adminService.getCurrentUserRole();
    if (!mounted) return;
    setState(() {
      _role = r;
      _checkingRole = false;
    });
    if (r != null && AdminService.adminRoles.contains(r.toLowerCase())) {
      await _loadAccounts();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<Map<String, dynamic>> data = await _adminService.getAccounts();
      if (!mounted) return;
      setState(() {
        _accounts = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool get _isAdmin {
    final String r = (_role ?? '').toLowerCase();
    return AdminService.adminRoles.contains(r);
  }

  bool get _isSuperAdmin => (_role ?? '').toLowerCase() == 'superadmin';

  List<Map<String, dynamic>> get _filtered {
    final String q = _query.trim().toLowerCase();
    return _accounts.where((a) {
      final bool roleOk = _roleFilter == 'all' || a['role'] == _roleFilter;
      if (!roleOk) return false;
      if (q.isEmpty) return true;
      return a['name'].toString().toLowerCase().contains(q) ||
          a['email'].toString().toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _changeRole(String email, String newRole) async {
    if (!_isSuperAdmin) {
      showAppSnackBar(context, 'Only superadmin can change roles.');
      return;
    }
    setState(() => _busyEmails.add(email));
    try {
      await _adminService.updateAccountRole(email: email, newRole: newRole);
      await _loadAccounts();
      if (!mounted) return;
      showAppSnackBar(context, 'Role updated for $email → $newRole');
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Role update failed: $e');
      setState(() => _busyEmails.remove(email));
    } finally {
      if (mounted) setState(() => _busyEmails.remove(email));
    }
  }

  Future<void> _toggleStatus(String email, String currentStatus) async {
    final String next = currentStatus == 'suspended' ? 'active' : 'suspended';
    setState(() => _busyEmails.add(email));
    try {
      await _adminService.toggleAccountStatus(email: email, newStatus: next);
      await _loadAccounts();
      if (!mounted) return;
      showAppSnackBar(context, '$email ${next == 'suspended' ? 'suspended' : 'activated'}.');
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Status update failed: $e');
      setState(() => _busyEmails.remove(email));
    } finally {
      if (mounted) setState(() => _busyEmails.remove(email));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingRole) {
      return const MobileScaffold(
        appBar: ScreenTitleBar(title: 'Customers / Accounts'),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_isAdmin) {
      return MobileScaffold(
        appBar: const ScreenTitleBar(title: 'Customers / Accounts'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, size: 48, color: AppColors.danger),
                const SizedBox(height: 12),
                const Text('Admin access required', style: TextStyle(fontWeight: FontWeight.w900)),
                Text('Role: ${_role ?? 'unknown'}', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Go back')),
              ],
            ),
          ),
        ),
      );
    }

    return MobileScaffold(
      appBar: ScreenTitleBar(
        title: 'Customers / Accounts',
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loading ? null : _loadAccounts),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Search name or email…',
                    prefixIcon: Icon(Icons.search_rounded),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _roleFilter,
                        decoration: const InputDecoration(
                          labelText: 'Role filter',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All roles')),
                          DropdownMenuItem(value: 'customer', child: Text('Customer')),
                          DropdownMenuItem(value: 'staff', child: Text('Staff')),
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                          DropdownMenuItem(value: 'superadmin', child: Text('Super Admin')),
                        ],
                        onChanged: (v) => setState(() => _roleFilter = v ?? 'all'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (!_isSuperAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Read-only',
                            style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w800)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Superadmin',
                            style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _loading ? 'Loading…' : '${_filtered.length} of ${_accounts.length} accounts',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (!_isSuperAdmin)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Only superadmin (super@smilehub.ph) can change roles. All admins can suspend/activate.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange.shade700, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                              const SizedBox(height: 12),
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              FilledButton(onPressed: _loadAccounts, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : _filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _accounts.isEmpty ? 'No accounts found.' : 'No matching accounts.',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final Map<String, dynamic> a = _filtered[index];
                              final String email = a['email'].toString();
                              final String name = a['name'].toString();
                              final String role = a['role'].toString().toLowerCase();
                              final String status = a['status'].toString().toLowerCase();
                              final bool busy = _busyEmails.contains(email);
                              final Color roleColor = role == 'superadmin'
                                  ? Colors.purple
                                  : role == 'admin'
                                      ? AppColors.teal
                                      : role == 'staff'
                                          ? Colors.orange
                                          : Colors.grey;
                              final Color statusColor = status == 'suspended' ? AppColors.danger : AppColors.success;

                              return AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                          child: Text(
                                            name.isEmpty ? '?' : name[0].toUpperCase(),
                                            style: TextStyle(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.w900),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontWeight: FontWeight.w800)),
                                              Text(email,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: Theme.of(context).textTheme.bodySmall),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            status == 'suspended' ? 'Suspended' : 'Active',
                                            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _isSuperAdmin
                                              ? DropdownButtonFormField<String>(
                                                  value: <String>['customer', 'staff', 'admin', 'superadmin'].contains(role)
                                                      ? role
                                                      : 'customer',
                                                  decoration: const InputDecoration(
                                                    labelText: 'Role',
                                                    isDense: true,
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                  ),
                                                  isExpanded: true,
                                                  items: const [
                                                    DropdownMenuItem(value: 'customer', child: Text('Customer')),
                                                    DropdownMenuItem(value: 'staff', child: Text('Staff')),
                                                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                                    DropdownMenuItem(value: 'superadmin', child: Text('Super Admin')),
                                                  ],
                                                  onChanged: busy
                                                      ? null
                                                      : (v) {
                                                          if (v != null && v != role) _changeRole(email, v);
                                                        },
                                                )
                                              : Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                  decoration: BoxDecoration(
                                                    color: roleColor.withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(color: roleColor.withOpacity(0.2)),
                                                  ),
                                                  child: Text(
                                                    role == 'superadmin'
                                                        ? 'Super Admin'
                                                        : role[0].toUpperCase() + role.substring(1),
                                                    style: TextStyle(color: roleColor, fontWeight: FontWeight.w800, fontSize: 12),
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          height: 42,
                                          child: busy
                                              ? const SizedBox(
                                                  width: 42,
                                                  child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                                                )
                                              : FilledButton.tonal(
                                                  onPressed: () => _toggleStatus(email, status),
                                                  child: Text(status == 'suspended' ? 'Activate' : 'Suspend',
                                                      style: const TextStyle(fontSize: 12)),
                                                ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
