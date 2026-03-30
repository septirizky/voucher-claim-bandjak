import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voucher_claim/services/auth.dart';
import 'home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final pinController = TextEditingController();
  bool isLoading = false;
  String? errorText;

  @override
  void initState() {
    super.initState();
    pinController.addListener(() {
      setState(() {}); // rebuild untuk enable/disable button
    });
  }

  Future<void> login() async {
    if (pinController.text.length != 6) return;

    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      final agentData = await AuthService.login(pinController.text.trim());

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(agent: agentData),
        ),
      );
    } catch (e) {
      setState(() {
        errorText = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPinValid = pinController.text.length == 6;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: 380,
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(
                color: Color(0xFF2E7D32), // hijau border
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 60,
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Voucher Claim System",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Login with your 6-digit PIN",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 28),

                  /// PIN FIELD
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: const TextStyle(
                      fontSize: 20,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: "••••••",
                      counterText: "", // hilangkan counter 0/6
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2E7D32),
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (_) {
                      if (isPinValid) login();
                    },
                  ),

                  const SizedBox(height: 16),

                  if (errorText != null)
                    Text(
                      errorText!,
                      style: const TextStyle(color: Colors.red),
                    ),

                  const SizedBox(height: 20),

                  /// LOGIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: (!isPinValid || isLoading) ? null : login,
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "LOGIN",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
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
}
