import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/pin_service.dart';

class SetupPinScreen extends StatefulWidget {
  const SetupPinScreen({super.key});

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  String _firstPin = '';
  String _currentPin = '';
  bool _isReEntering = false;

  void _onNumberTap(String number) async {
    if (_currentPin.length < AppConstants.pinLength) {
      setState(() {
        _currentPin += number;
      });

      if (_currentPin.length == AppConstants.pinLength) {
        if (!_isReEntering) {
          // Move to confirm PIN phase
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _firstPin = _currentPin;
                _currentPin = '';
                _isReEntering = true;
              });
            }
          });
        } else {
          // Confirm PIN
          if (_currentPin == _firstPin) {
            final saved = await PinService.setPin(_firstPin);
            if (!saved || !mounted) return;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Security PIN set successfully!'),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 2),
                ),
              );
            }
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                Navigator.of(context).pushNamed(AppRoutes.addAccount);
              }
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PINs do not match. Please try again.'),
                backgroundColor: AppColors.error,
              ),
            );
            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted) {
                setState(() {
                  _currentPin = '';
                });
              }
            });
          }
        }
      }
    }
  }

  void _onDeleteTap() {
    if (_currentPin.isNotEmpty) {
      setState(() {
        _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_isReEntering) {
              setState(() {
                _isReEntering = false;
                _currentPin = '';
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),

            // Title
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _isReEntering
                    ? 'Ok. Re-enter your 6-digit PIN.'
                    : 'Let’s set up your 6-digit PIN',
                key: ValueKey<bool>(_isReEntering),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 48),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(AppConstants.pinLength, (index) {
                final isFilled = index < _currentPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 3,
                    ),
                    color: isFilled ? Colors.white : Colors.transparent,
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
                      // Delete / Backspace button
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
                      // PIN is saved automatically after its confirmation.
                      _buildKeypadButton(
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 32,
                        ),
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
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
