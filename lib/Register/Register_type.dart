import 'package:flutter/material.dart';
import 'package:training_hub/Dashboard/Dashboard.dart';
import 'package:get_x/get.dart';
import 'package:training_hub/auth_service.dart';
import 'package:training_hub/database_management.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:training_hub/login.dart';

// Account type values for the dropdown
enum RegisterAccountType {
  instructor,
  student,
}

// Register type page
class RegisterTypePage extends StatefulWidget {
  const RegisterTypePage({
    super.key,
    required this.fullName,
    required this.email,
    required this.password,
    required this.phoneNumber,
  });

  final String fullName;
  final String email;
  final String password;
  final String phoneNumber;

  @override
  State<RegisterTypePage> createState() => _RegisterTypePageState();
}

class _RegisterTypePageState extends State<RegisterTypePage> {
  // Firebase authentication service
  final Auth _auth = Auth();

  // Firestore database service
  final DatabaseManagement _databaseManagement = DatabaseManagement();

  // Current selected account type
  RegisterAccountType? _selectedAccountType;

  // Tracks whether the page is currently creating an account
  bool _isCreatingAccount = false;

  // Whether to show account type validation
  bool _showAccountTypeError = false;

  // Shows a simple snackbar message
  void _showSimpleSnackBar({
    required String message,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // Returns a friendly Firebase auth message
  String _firebaseRegisterErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please log in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled in Firebase.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      default:
        return e.message ?? 'Account creation failed.';
    }
  }

  // Selected account type label for UI/debug usage
  String _selectedAccountTypeLabel() {
    if (_selectedAccountType == RegisterAccountType.instructor) {
      return 'Instructor';
    }

    return 'Student';
  }

  // Account type value for Firestore storage
  String _accountTypeDatabaseValue() {
    if (_selectedAccountType == RegisterAccountType.instructor) {
      return 'instructor';
    }

    return 'student';
  }

  // Sign up action
  Future<void> _onSignUpPressed() async {
    // Prevent double taps while request is running
    if (_isCreatingAccount) {
      return;
    }

    if (_selectedAccountType == null) {
      setState(() {
        _showAccountTypeError = true;
      });
      return;
    }

    setState(() {
      _showAccountTypeError = false;
      _isCreatingAccount = true;
    });

    try {
      // Firebase Auth account creation
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      final User? createdUser = userCredential.user;

      if (createdUser == null) {
        throw Exception('Account was created but user data is missing.');
      }

      // Firestore user profile creation
      await _databaseManagement.createUserData(
        uid: createdUser.uid,
        fullName: widget.fullName,
        email: widget.email,
        phoneNumber: widget.phoneNumber,
        accountType: _accountTypeDatabaseValue(),
      );

      debugPrint('Full name: ${widget.fullName}');
      debugPrint('Jordan phone number: ${widget.phoneNumber}');
      debugPrint('Account type: ${_selectedAccountTypeLabel()}');

      if (!mounted) {
        return;
      }

      Get.offAll(
        () => const Dashboard(),
        transition: Transition.fade,
        duration: const Duration(milliseconds: 200),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      _showSimpleSnackBar(
        message: _firebaseRegisterErrorMessage(e),
      );

      if (e.code == 'email-already-in-use') {
        Future<void>.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) {
            return;
          }

          Get.to(
            () => const LoginPage(),
            transition: Transition.fade,
            duration: const Duration(milliseconds: 200),
          );
        });
      }
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      _showSimpleSnackBar(
        message: e.message ?? 'Failed to save user data.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showSimpleSnackBar(
        message: 'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingAccount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the page inside safe areas
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            // Screen width
            final double screenWidth = constraints.maxWidth;

            // Screen height
            final double screenHeight = constraints.maxHeight;

            // Height of the top navbar
            final double navBarHeight = screenHeight * 0.075;

            // Height of the bottom section
            final double bottomPartHeight = screenHeight - navBarHeight;

            // Main full-page layout
            return SizedBox(
              width: screenWidth,
              height: screenHeight,
              child: Column(
                children: <Widget>[
                  RegisterTypeTopNavBar(
                    width: screenWidth,
                    height: navBarHeight,
                  ),
                  RegisterTypeBottomPart(
                    width: screenWidth,
                    height: bottomPartHeight,
                    selectedAccountType: _selectedAccountType,
                    showAccountTypeError: _showAccountTypeError,
                    isCreatingAccount: _isCreatingAccount,
                    onAccountTypeChanged: (RegisterAccountType? value) {
                      setState(() {
                        _selectedAccountType = value;
                        _showAccountTypeError = value == null;
                      });
                    },
                    onSignUpPressed: _onSignUpPressed,
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

// Top navbar widget
class RegisterTypeTopNavBar extends StatelessWidget {
  const RegisterTypeTopNavBar({
    super.key,
    required this.width,
    required this.height,
  });

  // Full screen width
  final double width;

  // Navbar height
  final double height;

  // Checks if screen is tablet size
  bool _isTablet() => width >= 600;

  // Left padding for the icon
  double _leftPadding() {
    return _isTablet() ? width * 0.02 : width * 0.025;
  }

  // Icon size
  double _iconSize() {
    return _isTablet() ? width * 0.06 : width * 0.11;
  }

  // Tap area width
  double _tapAreaWidth() {
    return _isTablet() ? width * 0.09 : width * 0.16;
  }

  // Tap area height
  double _tapAreaHeight() {
    return height * 0.82;
  }

  // Icon color
  Color get _iconColor => Colors.black;

  void _onBackPressed() {
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(left: _leftPadding()),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _onBackPressed,
              borderRadius: BorderRadius.circular(_tapAreaHeight() * 0.25),
              child: SizedBox(
                width: _tapAreaWidth(),
                height: _tapAreaHeight(),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: _iconColor,
                    size: _iconSize(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Bottom register type widget
class RegisterTypeBottomPart extends StatelessWidget {
  const RegisterTypeBottomPart({
    super.key,
    required this.width,
    required this.height,
    required this.selectedAccountType,
    required this.showAccountTypeError,
    required this.isCreatingAccount,
    required this.onAccountTypeChanged,
    required this.onSignUpPressed,
  });

  final double width;
  final double height;
  final RegisterAccountType? selectedAccountType;
  final bool showAccountTypeError;
  final bool isCreatingAccount;
  final ValueChanged<RegisterAccountType?> onAccountTypeChanged;
  final VoidCallback onSignUpPressed;

  // Checks if screen is tablet size
  bool _isTablet() => width >= 600;

  // Radius for the main card
  double _cardBorderRadius() {
    return width * 0.055;
  }

  // Radius for input fields
  double _inputBorderRadius() {
    return width * 0.045;
  }

  // Radius for buttons
  double _buttonBorderRadius() {
    return width * 0.08;
  }

  // Horizontal padding inside the card
  double _cardInnerHorizontalPadding() {
    return _isTablet() ? width * 0.05 : width * 0.06;
  }

  // Vertical padding inside the card
  double _cardInnerVerticalPadding() {
    return height * 0.015;
  }

  // Font size for the main title
  double _titleFontSize() {
    return _isTablet() ? width * 0.037 : width * 0.062;
  }

  // Font size for field labels
  double _fieldLabelFontSize() {
    return _isTablet() ? width * 0.018 : width * 0.034;
  }

  // Font size inside dropdown
  double _inputTextFontSize() {
    return _isTablet() ? width * 0.021 : width * 0.043;
  }

  // Font size for button text
  double _buttonTextFontSize() {
    return _isTablet() ? width * 0.024 : width * 0.05;
  }

  // Font size for field error text
  double _fieldErrorFontSize() {
    return _isTablet() ? width * 0.017 : width * 0.031;
  }

  // Height of dropdown field
  double _inputHeight() {
    return height * 0.1;
  }

  // Height of the main button
  double _mainButtonHeight() {
    return height * 0.105;
  }

  // Icon size
  double _iconSize() {
    return _isTablet() ? width * 0.027 : width * 0.055;
  }

  // Small vertical spacing
  double _verticalSpacingSmall() {
    return height * 0.02;
  }

  // Space between the title and dropdown
  double _spaceBelowTitle() {
    return _isTablet() ? height * 0.08 : height * 0.16;
  }

  // Blur for main button shadow
  double _mainButtonShadowBlur() {
    return width * 0.06;
  }

  // Y offset for main button shadow
  double _mainButtonShadowOffset() {
    return height * 0.016;
  }

  // Blur for card shadow
  double _cardShadowBlur() {
    return width * 0.08;
  }

  // Y offset for card shadow
  double _cardShadowOffset() {
    return height * 0.02;
  }

  // Base width for content
  double _contentBaseWidth() {
    return _isTablet() ? width * 0.72 : width;
  }

  // Left position for the floating field label
  double _fieldLabelLeftInset() {
    return _isTablet() ? width * 0.10 : width * 0.12;
  }

  // Horizontal padding around the floating field label
  double _fieldLabelHorizontalPadding() {
    return _isTablet() ? width * 0.012 : width * 0.018;
  }

  // Extra vertical space reserved for field error message
  double _fieldErrorSectionHeight() {
    return height * 0.04;
  }

  // Horizontal position for error text under the field
  double _fieldErrorLeftInset() {
    return _isTablet() ? width * 0.025 : width * 0.03;
  }

  // Page background color
  Color get _pageBackgroundColor => Colors.white;

  // Card background color
  Color get _cardBackgroundColor => Colors.white;

  // Main dark text color
  Color get _primaryTextColor => const Color(0xFF0F203D);

  // Secondary text color
  Color get _secondaryTextColor => const Color(0xFF8A8A8A);

  // Border color
  Color get _borderColor => const Color(0xFF20303D);

  // Main button text color
  Color get _mainButtonTextColor => Colors.white;

  // Card shadow color
  Color get _cardShadowColor => const Color(0x11000000);

  // Main button shadow color
  Color get _mainButtonShadowColor => const Color(0x4434D0C3);

  // Error color
  Color get _errorColor => const Color(0xFFD93025);

  // Gradient for the main sign up button
  LinearGradient get _mainButtonGradient => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0xFF5B95F0),
          Color(0xFF38D0C3),
        ],
      );

  // Text style for the top title
  TextStyle _titleTextStyle() {
    return TextStyle(
      color: _primaryTextColor,
      fontSize: _titleFontSize(),
      fontWeight: FontWeight.w800,
      height: 1.12,
    );
  }

  // Text style for the field label
  TextStyle _fieldLabelTextStyle({
    required bool hasError,
  }) {
    return TextStyle(
      color: hasError ? _errorColor : _primaryTextColor,
      fontSize: _fieldLabelFontSize(),
      fontWeight: FontWeight.w500,
      height: 1,
    );
  }

  // Text style for dropdown text
  TextStyle _dropdownTextStyle({
    required bool hasError,
  }) {
    return TextStyle(
      color: hasError ? _errorColor : _primaryTextColor,
      fontSize: _inputTextFontSize(),
      fontWeight: FontWeight.w500,
    );
  }

  // Text style for hint text
  TextStyle _hintTextStyle({
    required bool hasError,
  }) {
    return TextStyle(
      color: hasError ? _errorColor : _secondaryTextColor,
      fontSize: _inputTextFontSize(),
      fontWeight: FontWeight.w400,
    );
  }

  // Text style for main button
  TextStyle _mainButtonTextStyle() {
    return TextStyle(
      color: _mainButtonTextColor,
      fontSize: _buttonTextFontSize(),
      fontWeight: FontWeight.w700,
    );
  }

  // Text style for field error message
  TextStyle _fieldErrorTextStyle() {
    return TextStyle(
      color: _errorColor,
      fontSize: _fieldErrorFontSize(),
      fontWeight: FontWeight.w500,
      height: 1.15,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Radius for the top corners of the bottom section
    final double cardRadius = _cardBorderRadius();

    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        color: _pageBackgroundColor,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: _cardBackgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(cardRadius),
              topRight: Radius.circular(cardRadius),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: _cardShadowColor,
                blurRadius: _cardShadowBlur(),
                offset: Offset(0, _cardShadowOffset()),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _cardInnerHorizontalPadding(),
              vertical: _cardInnerVerticalPadding(),
            ),
            child: Stack(
              children: <Widget>[
                // Title at the top of the bottom section
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: width,
                    child: _title(),
                  ),
                ),

                // Main form content near the top
                Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: _spaceBelowTitle(),
                      ),
                      child: SizedBox(
                        width: _contentBaseWidth(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            _accountTypeDropdown(),
                            SizedBox(height: _verticalSpacingSmall()),
                            _signUpButton(),
                          ],
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
    );
  }

  // Top title widget
  Widget _title() {
    return Text(
      'Choose your account type',
      style: _titleTextStyle(),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Account type dropdown widget
  Widget _accountTypeDropdown() {
    final double inputHeight = _inputHeight();
    final double inputRadius = _inputBorderRadius();
    final double iconSize = _iconSize();
    final double labelLeftInset = _fieldLabelLeftInset();
    final double labelHorizontalPadding = _fieldLabelHorizontalPadding();
    final bool hasError = showAccountTypeError;
    final double totalFieldHeight =
        inputHeight + (_fieldLabelFontSize() * 0.9) + _fieldErrorSectionHeight();

    final Color activeBorderColor = hasError ? _errorColor : _borderColor;

    return SizedBox(
      height: totalFieldHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            top: _fieldLabelFontSize() * 0.45,
            left: 0,
            right: 0,
            child: SizedBox(
              height: inputHeight,
              child: DropdownButtonFormField<RegisterAccountType>(
                value: selectedAccountType,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: iconSize,
                  color: hasError ? _errorColor : _primaryTextColor,
                ),
                style: _dropdownTextStyle(
                  hasError: hasError,
                ),
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  hintText: 'Select account type',
                  hintStyle: _hintTextStyle(
                    hasError: hasError,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: _isTablet() ? width * 0.04 : width * 0.05,
                    vertical: _isTablet() ? height * 0.028 : height * 0.022,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(inputRadius),
                    borderSide: BorderSide(
                      color: activeBorderColor,
                      width: width * 0.0035,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(inputRadius),
                    borderSide: BorderSide(
                      color: activeBorderColor,
                      width: width * 0.004,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(inputRadius),
                    borderSide: BorderSide(
                      color: _errorColor,
                      width: width * 0.0035,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(inputRadius),
                    borderSide: BorderSide(
                      color: _errorColor,
                      width: width * 0.004,
                    ),
                  ),
                  errorStyle: const TextStyle(
                    height: 0,
                    fontSize: 0,
                  ),
                ),
                items: const <DropdownMenuItem<RegisterAccountType>>[
                  DropdownMenuItem<RegisterAccountType>(
                    value: RegisterAccountType.instructor,
                    child: Text('Instructor'),
                  ),
                  DropdownMenuItem<RegisterAccountType>(
                    value: RegisterAccountType.student,
                    child: Text('Student'),
                  ),
                ],
                onChanged: onAccountTypeChanged,
              ),
            ),
          ),

          // Floating label on the border
          Positioned(
            left: labelLeftInset,
            top: 0,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: labelHorizontalPadding,
              ),
              child: Text(
                'Account Type',
                style: _fieldLabelTextStyle(
                  hasError: hasError,
                ),
              ),
            ),
          ),

          // Error message under the field
          if (hasError)
            Positioned(
              left: _fieldErrorLeftInset(),
              right: 0,
              top: _fieldLabelFontSize() * 0.45 +
                  inputHeight +
                  (height * 0.01),
              child: Text(
                'Please choose an account type.',
                style: _fieldErrorTextStyle(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  // Main sign up button widget
  Widget _signUpButton() {
    final double buttonHeight = _mainButtonHeight();
    final double buttonRadius = _buttonBorderRadius();

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: DecoratedBox(
        //Shadow start
        decoration: BoxDecoration(
          gradient: _mainButtonGradient,
          borderRadius: BorderRadius.circular(buttonRadius),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: _mainButtonShadowColor,
              blurRadius: _mainButtonShadowBlur(),
              offset: Offset(0, _mainButtonShadowOffset()),
            ),
          ],
        ),
        //Shadow end
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isCreatingAccount ? null : onSignUpPressed,
            borderRadius: BorderRadius.circular(buttonRadius),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.03,
                  ),
                  child: isCreatingAccount
                      ? SizedBox(
                          width: _buttonTextFontSize(),
                          height: _buttonTextFontSize(),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Sign Up',
                          style: _mainButtonTextStyle(),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}