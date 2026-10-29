import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/pin_service.dart';

class EnterPinScreen extends StatefulWidget {
  const EnterPinScreen({super.key});

  @override
  State<EnterPinScreen> createState() => _EnterPinScreenState();
}

class _EnterPinScreenState extends State<EnterPinScreen> {
  String _enteredPin = '';
  bool _isError = false;

  void _onNumberTap(String number) async {
    if (await PinService.isLocked()) {
      final remaining = await PinService.lockoutRemaining();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Too many attempts. Try again in ${remaining?.inMinutes ?? 1} minute(s).',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    if (_enteredPin.length < AppConstants.pinLength) {
      setState(() {
        _isError = false;
        _enteredPin += number;
      });

      if (_enteredPin.length == AppConstants.pinLength) {
        final isValid = await PinService.verifyPin(_enteredPin);
        if (isValid) {
          if (mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
          }
        } else {
          setState(() {
            _isError = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Incorrect PIN. Please try again.'),
                backgroundColor: AppColors.error,
                duration: Duration(seconds: 2),
              ),
            );
          }
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _enteredPin = '';
                _isError = false;
              });
            }
          });
        }
      }
    }
  }

  void _onDeleteTap() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _isError = false;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _onForgotPin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Security PIN?'),
        content: const Text(
          'To reset your PIN, you will need to re-login with your email verification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await PinService.clearAll();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reset & Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),

            // Icon / Shield
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Enter your PIN',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your 6-digit security PIN to unlock FinSight',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 40),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(AppConstants.pinLength, (index) {
                final isFilled = index < _enteredPin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isError
                          ? AppColors.error
                          : Colors.white.withValues(alpha: 0.6),
                      width: 2.5,
                    ),
                    color: isFilled
                        ? (_isError ? AppColors.error : Colors.white)
                        : Colors.transparent,
                  ),
                );
              }),
            ),

            const Spacer(flex: 2),

            // Numeric Keypad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _buildKeypadRow(['1', '2', '3']),
                  const SizedBox(height: 24),
                  _buildKeypadRow(['4', '5', '6']),
                  const SizedBox(height: 24),
                  _buildKeypadRow(['7', '8', '9']),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Delete button
                      _buildKeypadButton(
                        child: const Icon(
                          Icons.backspace_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                        onTap: _onDeleteTap,
                      ),
                      _buildKeypadButton(
                        child: Text(
                          '0',
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        onTap: () => _onNumberTap('0'),
                      ),
                      // Forgot PIN option
                      _buildKeypadButton(
                        child: const Icon(
                          Icons.help_outline,
                          color: Colors.white70,
                          size: 26,
                        ),
                        onTap: _onForgotPin,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            TextButton(
              onPressed: _onForgotPin,
              child: Text(
                'Forgot PIN?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> values) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: values.map((val) {
        return _buildKeypadButton(
          child: Text(
            val,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          onTap: () => _onNumberTap(val),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return InkResponse(
      onTap: onTap,
      radius: 40,
      splashColor: Colors.white24,
      child: SizedBox(width: 80, height: 60, child: Center(child: child)),
    );
  }
}
