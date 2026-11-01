import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../services/auth/auth_service.dart';

class VerificationScreen extends StatefulWidget {
  final String? email;

  const VerificationScreen({super.key, this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  late Timer _timer;
  int _secondsRemaining = 299; // 04:59
  bool _canResend = false;
  bool _isVerifying = false;
  String _currentOtp = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 299;
    _canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer.cancel();
      }
    });
  }

  void _onResendCode() async {
    if (!_canResend) return;
    final displayEmail = widget.email ?? 'your email';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sending new verification code...')),
    );
    final result = await AuthService.resendSignupOtp(displayEmail);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? AppColors.primary : AppColors.error,
        ),
      );
      if (result.success) {
        _startTimer();
      }
    }
  }

  String get _formattedTime {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _onVerify() async {
    if (_isVerifying) return;
    final displayEmail = widget.email ?? 'your email';

    if (_currentOtp.length == 6) {
      setState(() => _isVerifying = true);
      final result = await AuthService.verifySignupOtp(
        email: displayEmail,
        token: _currentOtp,
      );
      if (!mounted) return;
      setState(() => _isVerifying = false);

      if (mounted) {
        if (result.success) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.signUpSuccess);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit code'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayEmail = widget.email ?? 'your email';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Verification',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 28),
                      Text(
                        'Enter your\nVerification Code',
                        style: GoogleFonts.inter(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // PIN Code Fields
                      PinCodeTextField(
                        appContext: context,
                        length: 6,
                        controller: _otpController,
                        obscureText: false,
                        animationType: AnimationType.fade,
                        keyboardType: TextInputType.number,
                        textStyle: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.circle,
                          fieldHeight: 48,
                          fieldWidth: 48,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.border,
                          selectedColor: AppColors.primary,
                          activeFillColor: Colors.transparent,
                          inactiveFillColor: Colors.transparent,
                          selectedFillColor: Colors.transparent,
                          borderWidth: 2,
                        ),
                        animationDuration: const Duration(milliseconds: 200),
                        enableActiveFill: false,
                        onChanged: (value) {
                          setState(() {
                            _currentOtp = value;
                          });
                        },
                        onCompleted: (value) {
                          _onVerify();
                        },
                      ),

                      const SizedBox(height: 16),

                      // Timer
                      Text(
                        _formattedTime,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Info text
                      RichText(
                        text: TextSpan(
                          text: 'We sent a verification code to your email ',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(
                              text: '$displayEmail. ',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const TextSpan(
                              text: 'Please check your Inbox and Spam folder.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Change Email Button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Entered wrong email? Change'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Resend link
                      GestureDetector(
                        onTap: _canResend ? _onResendCode : null,
                        child: Text(
                          'I didn’t receive the code? Send again',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: _canResend
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Note: If custom email server is unconfigured, test code 123456 can be used.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),

                      const Spacer(),
                      const SizedBox(height: 24),

                      // Verify button
                      ElevatedButton(
                        onPressed: _isVerifying ? null : _onVerify,
                        child: _isVerifying
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text('Verify'),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
