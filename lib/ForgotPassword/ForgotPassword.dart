import 'package:flutter/material.dart';
import 'package:get_x/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:training_hub/ForgotPassword/PasswordReset_SentPage.dart';

enum ForgotPasswordValidationKey {
  empty,
  invalidFormat,
}

class ForgetPasswordMain extends StatefulWidget {
  const ForgetPasswordMain({super.key});

  @override
  State<ForgetPasswordMain> createState() => _ForgetPasswordMainState();
}

class _ForgetPasswordMainState extends State<ForgetPasswordMain> {
  // Controller for email field
  final TextEditingController _emailController = TextEditingController();

  // Loading state while sending reset email
  bool _isSendingResetEmail = false;

  // Current active validation error
  ForgotPasswordValidationKey? _activeValidationError;

  // Validation messages
  final Map<ForgotPasswordValidationKey, String> _validationMessages =
      <ForgotPasswordValidationKey, String>{
    ForgotPasswordValidationKey.empty: 'Please enter your email.',
    ForgotPasswordValidationKey.invalidFormat:
        'Please enter a valid email address.',
  };

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Shows a simple snackbar message
  void _showSimpleSnackBar({
    required String message,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // Validates email text and returns the matching validation key
  ForgotPasswordValidationKey? _validateEmail(String value) {
    final String trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return ForgotPasswordValidationKey.empty;
    }

    final RegExp emailRegex = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );

    if (!emailRegex.hasMatch(trimmedValue)) {
      return ForgotPasswordValidationKey.invalidFormat;
    }

    return null;
  }

  // Validates one field only
  void _validateSingleField() {
    setState(() {
      _activeValidationError = _validateEmail(_emailController.text);
    });
  }

  // Validates all fields
  bool _validateAllFields() {
    final ForgotPasswordValidationKey? emailError =
        _validateEmail(_emailController.text);

    setState(() {
      _activeValidationError = emailError;
    });

    return emailError == null;
  }

  // Returns true if the field has an error
  bool _hasFieldError() {
    return _activeValidationError != null;
  }

  // Returns current field error message
  String? _fieldErrorMessage() {
    if (_activeValidationError == null) {
      return null;
    }

    return _validationMessages[_activeValidationError!];
  }

  // Friendly Firebase message
  String _firebaseResetErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account was found for this email address.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'too-many-requests':
        return 'Too many requests. Please wait a moment and try again.';
      default:
        return e.message ?? 'Failed to send reset email.';
    }
  }

  // Continue button action
  Future<void> _onContinuePressed() async {
    if (_isSendingResetEmail) {
      return;
    }

    FocusScope.of(context).unfocus();

    final bool isValid = _validateAllFields();
    if (!isValid) {
      return;
    }

    final String email = _emailController.text.trim();

    setState(() {
      _isSendingResetEmail = true;
    });

    try {
      await FirebaseAuth.instance.setLanguageCode('en');

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) {
        return;
      }

      Get.off(
        () => PasswordResetSentPage(
          
        ),
        transition: Transition.fade,
        duration: const Duration(milliseconds: 200),
      );
    } on FirebaseAuthException catch (e) {
      _showSimpleSnackBar(
        message: _firebaseResetErrorMessage(e),
      );
    } catch (e) {
      _showSimpleSnackBar(
        message: 'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingResetEmail = false;
        });
      }
    }
  }

  // Checks if screen is tablet size
  bool _isTablet(double width) => width >= 600;

  // Back button action
  void _onBackPressed() {
    Get.back();
  }

  // Background color of the page
  Color get _pageBackgroundColor => Colors.white;

  // Main dark text color
  Color get _primaryTextColor => const Color(0xFF0F203D);

  // Secondary text color
  Color get _secondaryTextColor => const Color(0xFF8A8A8A);

  // Border color
  Color get _borderColor => const Color(0xFF20303D);

  // Error color
  Color get _errorColor => const Color(0xFFD93025);

  // Main button text color
  Color get _mainButtonTextColor => Colors.white;

  // Main button shadow color
  Color get _mainButtonShadowColor => const Color(0x4434D0C3);

  // Gradient for the main button
  LinearGradient get _mainButtonGradient => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0xFF5B95F0),
          Color(0xFF38D0C3),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: _pageBackgroundColor,
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double screenWidth = constraints.maxWidth;
            final double screenHeight = constraints.maxHeight;
            final bool isTablet = _isTablet(screenWidth);

            final double navBarHeight =
                isTablet ? screenHeight * 0.09 : screenHeight * 0.08;
            final double pageHorizontalPadding =
                isTablet ? screenWidth * 0.06 : screenWidth * 0.06;
            final double topContentSpacing =
                isTablet ? screenHeight * 0.06 : screenHeight * 0.04;
            final double contentBaseWidth =
                isTablet ? screenWidth * 0.72 : screenWidth;
            final double titleFontSize =
                isTablet ? screenWidth * 0.045 : screenWidth * 0.082;
            final double subtitleFontSize =
                isTablet ? screenWidth * 0.021 : screenWidth * 0.041;
            final double fieldLabelFontSize =
                isTablet ? screenWidth * 0.018 : screenWidth * 0.034;
            final double inputTextFontSize =
                isTablet ? screenWidth * 0.023 : screenWidth * 0.047;
            final double fieldErrorFontSize =
                isTablet ? screenWidth * 0.017 : screenWidth * 0.031;
            final double inputHeight = screenHeight * 0.09;
            final double inputRadius = screenWidth * 0.045;
            final double buttonHeight = screenHeight * 0.085;
            final double buttonRadius = screenWidth * 0.08;
            final double iconSize =
                isTablet ? screenWidth * 0.028 : screenWidth * 0.058;
            final double verticalSpacingSmall = screenHeight * 0.018;
            final double verticalSpacingMedium = screenHeight * 0.018;
            final double verticalSpacingLarge = screenHeight * 0.04;
            final double fieldLabelLeftInset =
                isTablet ? screenWidth * 0.10 : screenWidth * 0.12;
            final double fieldLabelHorizontalPadding =
                isTablet ? screenWidth * 0.012 : screenWidth * 0.018;
            final double fieldErrorSectionHeight = screenHeight * 0.04;
            final double suffixIconRightPadding =
                isTablet ? screenWidth * 0.02 : screenWidth * 0.03;
            final double fieldErrorLeftInset =
                isTablet ? screenWidth * 0.025 : screenWidth * 0.03;
            final double contentHorizontalPadding =
                isTablet ? screenWidth * 0.02 : screenWidth * 0.045;
            final double iconToTextSpacing =
                isTablet ? screenWidth * 0.015 : screenWidth * 0.03;

            final bool hasError = _hasFieldError();
            final String? errorMessage = _fieldErrorMessage();
            final double totalFieldHeight =
                inputHeight +
                    (fieldLabelFontSize * 0.9) +
                    fieldErrorSectionHeight;
            final Color activeBorderColor =
                hasError ? _errorColor : _borderColor;

            TextStyle titleTextStyle() {
              return TextStyle(
                color: _primaryTextColor,
                fontSize: titleFontSize,
                fontWeight: FontWeight.w800,
                height: 1.08,
              );
            }

            TextStyle subtitleTextStyle() {
              return TextStyle(
                color: _secondaryTextColor,
                fontSize: subtitleFontSize,
                fontWeight: FontWeight.w500,
                height: 1.35,
              );
            }

            TextStyle fieldLabelTextStyle() {
              return TextStyle(
                color: hasError ? _errorColor : _primaryTextColor,
                fontSize: fieldLabelFontSize,
                fontWeight: FontWeight.w500,
                height: 1,
              );
            }

            TextStyle hintTextStyle() {
              return TextStyle(
                color: hasError ? _errorColor : _secondaryTextColor,
                fontSize: inputTextFontSize,
                fontWeight: FontWeight.w400,
              );
            }

            TextStyle inputTextStyle() {
              return hintTextStyle().copyWith(
                color: hasError ? _errorColor : _primaryTextColor,
              );
            }

            TextStyle fieldErrorTextStyle() {
              return TextStyle(
                color: _errorColor,
                fontSize: fieldErrorFontSize,
                fontWeight: FontWeight.w500,
                height: 1.15,
              );
            }

            TextStyle mainButtonTextStyle() {
              return TextStyle(
                color: _mainButtonTextColor,
                fontSize: isTablet ? screenWidth * 0.026 : screenWidth * 0.053,
                fontWeight: FontWeight.w700,
              );
            }

            return SizedBox(
              width: screenWidth,
              height: screenHeight,
              child: Column(
                children: <Widget>[
                  // Top navbar
                  SizedBox(
                    width: screenWidth,
                    height: navBarHeight,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: isTablet
                              ? screenWidth * 0.02
                              : screenWidth * 0.025,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _onBackPressed,
                            borderRadius: BorderRadius.circular(
                              navBarHeight * 0.25,
                            ),
                            child: SizedBox(
                              width: isTablet
                                  ? screenWidth * 0.09
                                  : screenWidth * 0.16,
                              height: navBarHeight * 0.82,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Icon(
                                  Icons.chevron_left_rounded,
                                  color: Colors.black,
                                  size: isTablet
                                      ? screenWidth * 0.06
                                      : screenWidth * 0.11,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Main content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: pageHorizontalPadding,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: topContentSpacing,
                              bottom: screenHeight * 0.03,
                            ),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.topCenter,
                                child: SizedBox(
                                  width: contentBaseWidth,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Forgot Password',
                                        style: titleTextStyle(),
                                        textAlign: TextAlign.left,
                                      ),
                                      SizedBox(height: verticalSpacingSmall),
                                      Text(
                                        'Please enter your email to reset the password',
                                        style: subtitleTextStyle(),
                                      ),
                                      SizedBox(height: verticalSpacingLarge),

                                      // Email field
                                      SizedBox(
                                        height: totalFieldHeight,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: <Widget>[
                                            Positioned(
                                              top: fieldLabelFontSize * 0.45,
                                              left: 0,
                                              right: 0,
                                              child: SizedBox(
                                                height: inputHeight,
                                                child: TextField(
                                                  controller: _emailController,
                                                  keyboardType:
                                                      TextInputType.emailAddress,
                                                  textInputAction:
                                                      TextInputAction.done,
                                                  onChanged: (String value) {
                                                    _validateSingleField();
                                                  },
                                                  onSubmitted: (_) {
                                                    _onContinuePressed();
                                                  },
                                                  style: inputTextStyle(),
                                                  decoration: InputDecoration(
                                                    hintText: 'Email',
                                                    hintStyle: hintTextStyle(),
                                                    filled: true,
                                                    fillColor: Colors.white,
                                                    isDense: true,
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                    prefixIcon: Padding(
                                                      padding: EdgeInsets.only(
                                                        left:
                                                            contentHorizontalPadding,
                                                        right: iconToTextSpacing,
                                                      ),
                                                      child: Icon(
                                                        Icons.email_outlined,
                                                        color: hasError
                                                            ? _errorColor
                                                            : Colors.black87,
                                                        size: iconSize,
                                                      ),
                                                    ),
                                                    suffixIcon: hasError
                                                        ? Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                              right:
                                                                  suffixIconRightPadding,
                                                            ),
                                                            child: Icon(
                                                              Icons.close_rounded,
                                                              color: _errorColor,
                                                              size: iconSize,
                                                            ),
                                                          )
                                                        : null,
                                                    suffixIconConstraints:
                                                        BoxConstraints(
                                                      minWidth: isTablet
                                                          ? screenWidth * 0.08
                                                          : screenWidth * 0.14,
                                                      minHeight: inputHeight,
                                                    ),
                                                    prefixIconConstraints:
                                                        BoxConstraints(
                                                      minWidth: isTablet
                                                          ? screenWidth * 0.09
                                                          : screenWidth * 0.16,
                                                      minHeight: inputHeight,
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        inputRadius,
                                                      ),
                                                      borderSide: BorderSide(
                                                        color: activeBorderColor,
                                                        width:
                                                            screenWidth * 0.0035,
                                                      ),
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        inputRadius,
                                                      ),
                                                      borderSide: BorderSide(
                                                        color: activeBorderColor,
                                                        width:
                                                            screenWidth * 0.004,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // Floating label
                                            Positioned(
                                              left: fieldLabelLeftInset,
                                              top: 0,
                                              child: Container(
                                                color: Colors.white,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      fieldLabelHorizontalPadding,
                                                ),
                                                child: Text(
                                                  'Email',
                                                  style: fieldLabelTextStyle(),
                                                ),
                                              ),
                                            ),

                                            // Error message
                                            if (hasError && errorMessage != null)
                                              Positioned(
                                                left: fieldErrorLeftInset,
                                                right: 0,
                                                top: fieldLabelFontSize * 0.45 +
                                                    inputHeight +
                                                    (screenHeight * 0.01),
                                                child: Text(
                                                  errorMessage,
                                                  style: fieldErrorTextStyle(),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: verticalSpacingMedium),

                                      // Continue button
                                      SizedBox(
                                        width: double.infinity,
                                        height: buttonHeight,
                                        child: DecoratedBox(
                                          //Shadow start
                                          decoration: BoxDecoration(
                                            gradient: _mainButtonGradient,
                                            borderRadius: BorderRadius.circular(
                                              buttonRadius,
                                            ),
                                            boxShadow: <BoxShadow>[
                                              BoxShadow(
                                                color: _mainButtonShadowColor,
                                                blurRadius: screenWidth * 0.06,
                                                offset: Offset(
                                                  0,
                                                  screenHeight * 0.016,
                                                ),
                                              ),
                                            ],
                                          ),
                                          //Shadow end
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: _isSendingResetEmail
                                                  ? null
                                                  : _onContinuePressed,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                buttonRadius,
                                              ),
                                              child: Center(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                    child: _isSendingResetEmail
                                                        ? SizedBox(
                                                            width:
                                                                mainButtonTextStyle()
                                                                    .fontSize,
                                                            height:
                                                                mainButtonTextStyle()
                                                                    .fontSize,
                                                            child:
                                                                const CircularProgressIndicator(
                                                              strokeWidth: 2.2,
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<Color>(
                                                                Colors.white,
                                                              ),
                                                            ),
                                                          )
                                                        : Text(
                                                            'Continue',
                                                            style:
                                                                mainButtonTextStyle(),
                                                          ),
                                                  ),
                                                ),
                                              ),
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
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}