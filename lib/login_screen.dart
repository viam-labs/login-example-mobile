import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? redirectTo;
  const LoginScreen({super.key, this.redirectTo});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = true;
  bool _loggingIn = false;

  @override
  void initState() {
    super.initState();
    checkLoginState();
  }

  Future<void> checkLoginState() async {
    try {
      if (await AuthService.init()) {
        setState(() {
          _isLoading = false;
        });
        _routeToNext();
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print(e);
    }
  }

  /// routes user either to the LandingScreen or the path passed in from goRouter.
  void _routeToNext() async {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/home'),
          builder: (context) => const HomeScreen(),
        ),
      );
    }
  }

  void _login() async {
    setState(() => _loggingIn = true);
    try {
      await AuthService.loginAction();
      setState(() => _loggingIn = true);
      _routeToNext();
    } on PlatformException catch (e) {
      print(e);
    } catch (e) {
      if (mounted) {
        return showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error logging in'),
              content: Text(
                'Error: $e',
              ),
            );
          },
        );
      }
    }
    setState(() => _loggingIn = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(left: 50.0, right: 50.0),
                    child: Text('Login Example',
                        style: Theme.of(context).textTheme.displayMedium),
                  ),
                  const SizedBox(height: 80),
                  FilledButton(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(120, 56)),
                    onPressed: _loggingIn ? null : _login,
                    child: Text(
                      'Login',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
    );
  }
}
