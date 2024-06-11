import 'dart:async';

import 'package:flutter/material.dart';

import 'package:viam_sdk/protos/app/app.dart';

import 'auth/auth_service.dart';
import 'user_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;

  List<Organization> organizations = [];

  @override
  void initState() {
    _setup();
    super.initState();
  }

  Future<void> _setup() async {
    await _getOrgs();
  }

  Future<void> _getOrgs() async {
    final viam = await AuthService.authenticatedViam;

    try {
      organizations = await viam.appClient.listOrganizations();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(),
        actions: [
          IconButton(
              onPressed: () => showModalBottomSheet(
                    isDismissible: true,
                    isScrollControlled: true,
                    context: context,
                    builder: (BuildContext context) =>
                        const UserSettingsScreen(),
                  ),
              icon: const Icon(Icons.person))
        ],
        title: const Text('Home'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator.adaptive(),
            )
          : Column(
              children: [
                ListView(
                  children: [
                    const Text('You are logged in!'),
                    // add a ListTile for each organization the user is a member of
                    for (final organization in organizations)
                      ListTile(title: Text(organization.name)),
                  ],
                ),
              ],
            ),
    );
  }
}
