import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import '../../data/auth_config.dart';
import '../widgets/app_version_footer.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  static Widget _buildMiniCard(BuildContext context, String rank, Color color, {bool isGold = false}) {
    return Container(
      width: 36,
      height: 54,
      decoration: BoxDecoration(
        color: isGold ? const Color(0xFFFFCA53) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          rank,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isGold ? const Color(0xFF765600) : color,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SignInScreen(
        headerMaxExtent: 200,
        providers: buildAppAuthProviders(),
        headerBuilder: (context, constraints, shrinkOffset) {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A00694B),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 58,
                      width: 90,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: 6,
                            child: Transform.rotate(
                              angle: -0.15,
                              child: _buildMiniCard(context, '5', Colors.red),
                            ),
                          ),
                          Positioned(
                            right: 6,
                            child: Transform.rotate(
                              angle: 0.15,
                              child: _buildMiniCard(context, 'J', Colors.red),
                            ),
                          ),
                          Positioned(
                            child: Transform.rotate(
                              angle: 0.0,
                              child: _buildMiniCard(context, 'A', Colors.black, isGold: true),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pedro',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                    ),
                    Text(
                      'Social Card Play',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        subtitleBuilder: (context, action) {
          return const Padding(
            padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: Text(
              'Welcome to the Veranda. Sign in to join the tables.',
              style: TextStyle(fontSize: 14),
            ),
          );
        },
        footerBuilder: (context, action) {
          return const Padding(
            padding: EdgeInsets.only(top: 16.0, bottom: 24.0),
            child: AppVersionFooter(),
          );
        },
        actions: [
          AuthStateChangeAction<UserCreated>((context, state) {
            Navigator.pushNamed(context, '/profile');
          }),
          AuthStateChangeAction<SignedIn>((context, state) {
            if (!state.user!.emailVerified && !state.user!.isAnonymous) {
              // Navigator.pushNamed(context, '/verify-email');
            }
          }),
          ForgotPasswordAction((context, email) {
            Navigator.pushNamed(
              context,
              '/forgot-password',
              arguments: {'email': email},
            );
          }),
        ],
      ),
    );
  }
}
