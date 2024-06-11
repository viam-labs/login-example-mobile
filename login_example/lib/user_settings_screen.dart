import 'package:flutter/material.dart';

import 'auth/auth_service.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  late ViamUserProfile user;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    getUser();
  }

  Future<void> getUser() async {
    user = await AuthService.currentUser;
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const CircularProgressIndicator.adaptive()
        : FractionallySizedBox(
            heightFactor: 0.9,
            child: DraggableScrollableSheet(
                initialChildSize: 1.0,
                minChildSize: 1.0,
                builder:
                    (BuildContext context, ScrollController scrollController) {
                  return Column(
                    children: [
                      AppBar(
                          elevation: 0.0,
                          backgroundColor: Colors.transparent,
                          title: Text('Account',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.primary)),
                          leading: IconButton(
                            icon: Icon(Icons.close,
                                color: Theme.of(context).colorScheme.primary),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          )),
                      Column(
                        children: [
                          const SizedBox(height: 24),
                          ListTile(
                            title: const Text('Name'),
                            trailing: Text(user.name ?? ''),
                          ),
                          ListTile(
                            title: const Text('Email'),
                            trailing: Text(user.email ?? ''),
                          ),
                          ListTile(
                            title: const Text('Log out'),
                            leading: const Icon(Icons.logout),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              showLogoutDialog(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                }),
          );
  }
}
