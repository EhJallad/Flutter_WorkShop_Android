import 'package:flutter/material.dart';
import 'package:training_hub/Dashboard/Dashboard.dart';
import 'package:get_x/get.dart';
import 'package:training_hub/auth_service.dart';
import 'package:training_hub/Register/register.dart';
import 'package:training_hub/ForgotPassword/ForgotPassword.dart';

import 'package:firebase_auth/firebase_auth.dart';

// Enum for the type of input field
enum InputFieldType {
  email,
  password,
}

// Enum for validation message keys
enum InputValidationKey {
  empty,
  invalidFormat,
  tooShort,
}

// Main login page widget
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// State for the main login page
class _LoginPageState extends State<LoginPage> {
  //
  // Tracks if the login image was already precached
  bool _didPrecacheLoginImage = false;

  // Path for the top login image
  String get _loginImagePath => 'Pictures/Login.jpg';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Preload the image one time
    if (!_didPrecacheLoginImage) {
      precacheImage(AssetImage(_loginImagePath), context);
      _didPrecacheLoginImage = true;
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

            // Height of the top image section
            final double topPartHeight = screenHeight * 0.31;

            // Height of the bottom login section
            final double bottomPartHeight = screenHeight - topPartHeight;

            // Main full-page layout
            return SizedBox(
              width: screenWidth,
              height: screenHeight,
              child: Column(
                children: <Widget>[
                  // Top image section
                  LoginTopPart(
                    imagePath: _loginImagePath,
                    width: screenWidth,
                    height: topPartHeight,
                  ),

                  // Bottom login form section
                  LoginBottomPart(
                    width: screenWidth,
                    height: bottomPartHeight,
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

// Top image section widget
class LoginTopPart extends StatelessWidget {
  const LoginTopPart({
    super.key,
    required this.imagePath,
    required this.width,
    required this.height,
  });

  // Image path
  final String imagePath;

  // Section width
  final double width;

  // Section height
  final double height;

  // Controls the bottom curve depth of the image
  double _curveDepth() {
    final double value = height * 0.12;
    if (value < 18) {
      return 18;
    }
    if (value > 42) {
      return 42;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    // Current curve depth value
    final double curveDepth = _curveDepth();

    // Curved top image container
    return SizedBox(
      width: width,
      height: height,
      child: ClipPath(
        clipper: _LoginTopCurveClipper(curveDepth: curveDepth),
        child: Image.asset(
          imagePath,
          width: width,
          height: height,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          filterQuality: FilterQuality.high,
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            // Fallback if image is missing
            return Container(
              color: const Color(0xFFE9EDF2),
              alignment: Alignment.center,
              child: Text(
                'Login image not found',
                style: TextStyle(
                  color: const Color(0xFF0F203D),
                  fontSize: width * 0.045,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Bottom login form widget
class LoginBottomPart extends StatefulWidget {
  const LoginBottomPart({
    super.key,
    required this.width,
    required this.height,
  });

  // Section width
  final double width;

  // Section height
  final double height;

  @override
  State<LoginBottomPart> createState() => _LoginBottomPartState();
}

// State for the bottom login form
class _LoginBottomPartState extends State<LoginBottomPart> {
  //Authentication
  //firebase authenticaton
  final Auth _auth = Auth();

  //
  // Controller for email field
  final TextEditingController _emailController = TextEditingController();

  // Controller for password field
  final TextEditingController _passwordController = TextEditingController();

  // Single data structure for validation messages
  final Map<InputFieldType, Map<InputValidationKey, String>>
      _validationMessages = <InputFieldType, Map<InputValidationKey, String>>{
    InputFieldType.email: <InputValidationKey, String>{
      InputValidationKey.empty: 'Please enter your email.',
      InputValidationKey.invalidFormat:
          'Please enter a valid email address.',
    },
    InputFieldType.password: <InputValidationKey, String>{
      InputValidationKey.empty: 'Please enter your password.',
      InputValidationKey.tooShort:
          'Password must be at least 6 characters.',
    },
  };

  // Stores the current active validation error for each field
  final Map<InputFieldType, InputValidationKey?>
      _activeValidationErrors = <InputFieldType, InputValidationKey?>{
    InputFieldType.email: null,
    InputFieldType.password: null,
  };

  @override
  void dispose() {
    // Dispose email controller
    _emailController.dispose();

    // Dispose password controller
    _passwordController.dispose();

    super.dispose();
  }

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

  // Action for forgot password
  void _onForgotPasswordPressed() {
      Get.to(
        () => const ForgetPasswordMain(),
        transition: Transition.fade,
        duration: const Duration(milliseconds: 200),
      );
  }

  // Validates email text and returns the matching validation key
  InputValidationKey? _validateEmail(String value) {
    final String trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return InputValidationKey.empty;
    }

    final RegExp emailRegex = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );

    if (!emailRegex.hasMatch(trimmedValue)) {
      return InputValidationKey.invalidFormat;
    }

    return null;
  }

  // Validates password text and returns the matching validation key
  InputValidationKey? _validatePassword(String value) {
    final String trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return InputValidationKey.empty;
    }

    if (trimmedValue.length < 6) {
      return InputValidationKey.tooShort;
    }

    return null;
  }

  // Validates only one field
  void _validateSingleField(InputFieldType fieldType) {
    InputValidationKey? errorKey;

    if (fieldType == InputFieldType.email) {
      errorKey = _validateEmail(_emailController.text);
    } else if (fieldType == InputFieldType.password) {
      errorKey = _validatePassword(_passwordController.text);
    }

    setState(() {
      _activeValidationErrors[fieldType] = errorKey;
    });
  }

  // Validates all fields before login
  bool _validateAllFields() {
    final InputValidationKey? emailError =
        _validateEmail(_emailController.text);
    final InputValidationKey? passwordError =
        _validatePassword(_passwordController.text);

    setState(() {
      _activeValidationErrors[InputFieldType.email] = emailError;
      _activeValidationErrors[InputFieldType.password] = passwordError;
    });

    return emailError == null && passwordError == null;
  }

  // Returns true if the field currently has an error
  bool _hasFieldError(InputFieldType fieldType) {
    return _activeValidationErrors[fieldType] != null;
  }

  // Returns the current error message for a field
  String? _fieldErrorMessage(InputFieldType fieldType) {
    final InputValidationKey? errorKey = _activeValidationErrors[fieldType];

    if (errorKey == null) {
      return null;
    }

    return _validationMessages[fieldType]?[errorKey];
  }

  // Action for login button
  Future<void> _onLogInToWorkshopPressed() async {
    final bool isValid = _validateAllFields();

    if (!isValid) {
      return;
    }

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      // Firebase authentication happens here through the custom Auth service.
      // This calls signInWithEmailAndPassword from Firebase Auth using email/password.
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) {
        return;
      }

      Get.off(
        () => const Dashboard(),
        transition: Transition.fade,
        duration: const Duration(milliseconds: 200),
      );
    } on FirebaseAuthException catch (e) {
      _showSimpleSnackBar(
        
        message: e.message ?? 'Authentication failed.',
      );
    } catch (e) {
      _showSimpleSnackBar(
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  // Action for register button
  Future<void> _onRegisterForNewAccountPressed() async {
    Get.to(
      () =>  Register(),
      transition: Transition.fade,
      duration: const Duration(milliseconds: 200),
    );
  }

  // Checks if screen is tablet size
  bool _isTablet() => widget.width >= 600;

  // Radius for the main card
  double _cardBorderRadius() {
    return widget.width * 0.055;
  }

  // Radius for input fields
  double _inputBorderRadius() {
    return widget.width * 0.045;
  }

  // Radius for buttons
  double _buttonBorderRadius() {
    return widget.width * 0.08;
  }

  // Horizontal padding inside the card
  double _cardInnerHorizontalPadding() {
    return _isTablet() ? widget.width * 0.05 : widget.width * 0.06;
  }

  // Vertical padding inside the card
  double _cardInnerVerticalPadding() {
    return widget.height * 0.045;
  }

  // Font size for the main title
  double _titleFontSize() {
    return _isTablet() ? widget.width * 0.048 : widget.width * 0.082;
  }

  // Font size for field labels
  double _fieldLabelFontSize() {
    return _isTablet() ? widget.width * 0.018 : widget.width * 0.034;
  }

  // Font size inside input fields
  double _inputTextFontSize() {
    return _isTablet() ? widget.width * 0.023 : widget.width * 0.047;
  }

  // Font size for button text
  double _buttonTextFontSize() {
    return _isTablet() ? widget.width * 0.026 : widget.width * 0.053;
  }

  // Font size for OR text
  double _orTextFontSize() {
    return _isTablet() ? widget.width * 0.022 : widget.width * 0.043;
  }

  // Font size for forgot password text
  double _forgotPasswordFontSize() {
    return _isTablet() ? widget.width * 0.023 : widget.width * 0.046;
  }

  // Font size for field error text
  double _fieldErrorFontSize() {
    return _isTablet() ? widget.width * 0.017 : widget.width * 0.031;
  }

  // Height of input fields
  double _inputHeight() {
    return widget.height * 0.115;
  }

  // Height of the main login button
  double _mainButtonHeight() {
    return widget.height * 0.12;
  }

  // Height of the register button
  double _secondaryButtonHeight() {
    return widget.height * 0.12;
  }

  // Icon size inside fields
  double _iconSize() {
    return _isTablet() ? widget.width * 0.028 : widget.width * 0.058;
  }

  // Medium vertical spacing
  double _verticalSpacingMedium() {
    return widget.height * 0.025;
  }

  // Large vertical spacing
  double _verticalSpacingLarge() {
    return widget.height * 0.036;
  }

  // Divider thickness for the OR line
  double _dividerThickness() {
    return widget.width * 0.0035;
  }

  // Blur for main button shadow
  double _mainButtonShadowBlur() {
    return widget.width * 0.06;
  }

  // Y offset for main button shadow
  double _mainButtonShadowOffset() {
    return widget.height * 0.016;
  }

  // Blur for card shadow
  double _cardShadowBlur() {
    return widget.width * 0.08;
  }

  // Y offset for card shadow
  double _cardShadowOffset() {
    return widget.height * 0.02;
  }

  // Base width for centered content
  double _contentBaseWidth() {
    return _isTablet() ? widget.width * 0.72 : widget.width;
  }

  // Left position for the floating field label
  double _fieldLabelLeftInset() {
    return _isTablet() ? widget.width * 0.10 : widget.width * 0.12;
  }

  // Horizontal padding around the floating field label
  double _fieldLabelHorizontalPadding() {
    return _isTablet() ? widget.width * 0.012 : widget.width * 0.018;
  }

  // Extra vertical space reserved for field error message
  double _fieldErrorSectionHeight() {
    return widget.height * 0.04;
  }

  // Right padding for the error X icon
  double _suffixIconRightPadding() {
    return _isTablet() ? widget.width * 0.02 : widget.width * 0.03;
  }

  // Horizontal position for error text under the field
  double _fieldErrorLeftInset() {
    return _isTablet() ? widget.width * 0.025 : widget.width * 0.03;
  }

  // Background color of the page
  Color get _pageBackgroundColor => Colors.white;

  // Background color of the card
  Color get _cardBackgroundColor => Colors.white;

  // Main dark text color
  Color get _primaryTextColor => const Color(0xFF0F203D);

  // Secondary text color
  Color get _secondaryTextColor => const Color(0xFF8A8A8A);

  // Border color
  Color get _borderColor => const Color(0xFF20303D);

  // Forgot password text color
  Color get _forgotPasswordColor => const Color(0xFF2CB5A8);

  // Main button text color
  Color get _mainButtonTextColor => Colors.white;

  // Secondary button text color
  Color get _secondaryButtonTextColor => const Color(0xFF13233E);

  // Divider color
  Color get _dividerColor => const Color(0xFFB3B6BB);

  // Card shadow color
  Color get _cardShadowColor => const Color(0x11000000);

  // Main button shadow color
  Color get _mainButtonShadowColor => const Color(0x4434D0C3);

  // Error color for invalid fields
  Color get _errorColor => const Color(0xFFD93025);

  // Gradient for the main login button
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
      height: 1.05,
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

  // Text style for forgot password
  TextStyle _forgotPasswordTextStyle() {
    return TextStyle(
      color: _forgotPasswordColor,
      fontSize: _forgotPasswordFontSize(),
      fontWeight: FontWeight.w600,
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

  // Text style for secondary button
  TextStyle _secondaryButtonTextStyle() {
    return TextStyle(
      color: _secondaryButtonTextColor,
      fontSize: _buttonTextFontSize(),
      fontWeight: FontWeight.w700,
    );
  }

  // Text style for OR text
  TextStyle _orTextStyle() {
    return TextStyle(
      color: _primaryTextColor.withOpacity(0.85),
      fontSize: _orTextFontSize(),
      fontWeight: FontWeight.w500,
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

    // Bottom section layout
    return Container(
      width: widget.width,
      height: widget.height,
      color: _pageBackgroundColor,
      child: Center(
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
                    width: widget.width,
                    child: _title(),
                  ),
                ),

                // Main form content in the center
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: _contentBaseWidth(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(height: _titleFontSize() * 2.2),
                          _emailField(),
                          SizedBox(height: _verticalSpacingMedium()),
                          _passwordField(),
                          SizedBox(height: _verticalSpacingLarge()),
                          _forgotPasswordButton(),
                          SizedBox(height: _verticalSpacingLarge()),
                          _mainLoginButton(),
                          SizedBox(height: _verticalSpacingMedium()),
                          _orDivider(),
                          SizedBox(height: _verticalSpacingMedium()),
                          _registerButton(),
                        ],
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
      'Sign In to Unity Workshop',
      style: _titleTextStyle(),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Email field widget
  Widget _emailField() {
    return _inputField(
      fieldType: InputFieldType.email,
      label: 'Email',
      hint: 'Email',
      controller: _emailController,
      icon: Icons.person_outline_rounded,
      obscureText: false,
      keyboardType: TextInputType.emailAddress,
    );
  }

  // Password field widget
  Widget _passwordField() {
    return _inputField(
      fieldType: InputFieldType.password,
      label: 'Password',
      hint: 'Password',
      controller: _passwordController,
      icon: Icons.lock_outline_rounded,
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
    );
  }

  // Shared input field widget
  Widget _inputField({
    required InputFieldType fieldType,
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required bool obscureText,
    required TextInputType keyboardType,
  }) {
    // Height of the field
    final double inputHeight = _inputHeight();

    // Radius of the field border
    final double inputRadius = _inputBorderRadius();

    // Icon size
    final double iconSize = _iconSize();

    // Left position of the floating label
    final double labelLeftInset = _fieldLabelLeftInset();

    // Horizontal padding for floating label
    final double labelHorizontalPadding = _fieldLabelHorizontalPadding();

    // Left and right padding around icon
    final double contentHorizontalPadding =
        _isTablet() ? widget.width * 0.02 : widget.width * 0.045;

    // Gap between icon and text
    final double iconToTextSpacing =
        _isTablet() ? widget.width * 0.015 : widget.width * 0.03;

    // Current error state
    final bool hasError = _hasFieldError(fieldType);

    // Current error message
    final String? errorMessage = _fieldErrorMessage(fieldType);

    // Total reserved height for field + label + error text
    final double totalFieldHeight =
        inputHeight + (_fieldLabelFontSize() * 0.9) + _fieldErrorSectionHeight();

    // Active border color
    final Color activeBorderColor = hasError ? _errorColor : _borderColor;

    // Field with label attached to the border
    return SizedBox(
      height: totalFieldHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          // Main text field
          Positioned(
            top: _fieldLabelFontSize() * 0.45,
            left: 0,
            right: 0,
            child: SizedBox(
              height: inputHeight,
              child: TextField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                onChanged: (String value) {
                  _validateSingleField(fieldType);
                },
                style: _hintTextStyle(
                  hasError: hasError,
                ).copyWith(
                  color: hasError ? _errorColor : _primaryTextColor,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: _hintTextStyle(
                    hasError: hasError,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(
                      left: contentHorizontalPadding,
                      right: iconToTextSpacing,
                    ),
                    child: Icon(
                      icon,
                      color: hasError ? _errorColor : Colors.black87,
                      size: iconSize,
                    ),
                  ),
                  suffixIcon: hasError
                      ? Padding(
                          padding: EdgeInsets.only(
                            right: _suffixIconRightPadding(),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: _errorColor,
                            size: iconSize,
                          ),
                        )
                      : null,
                  suffixIconConstraints: BoxConstraints(
                    minWidth:
                        _isTablet() ? widget.width * 0.08 : widget.width * 0.14,
                    minHeight: inputHeight,
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth:
                        _isTablet() ? widget.width * 0.09 : widget.width * 0.16,
                    minHeight: inputHeight,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(inputRadius),
                    borderSide: BorderSide(
                      color: activeBorderColor,
                      width: widget.width * 0.0035,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(inputRadius),
                    borderSide: BorderSide(
                      color: activeBorderColor,
                      width: widget.width * 0.004,
                    ),
                  ),
                ),
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
                label,
                style: _fieldLabelTextStyle(
                  hasError: hasError,
                ),
              ),
            ),
          ),

          // Error message under the field
          if (hasError && errorMessage != null)
            Positioned(
              left: _fieldErrorLeftInset(),
              right: 0,
              top: _fieldLabelFontSize() * 0.45 + inputHeight + (widget.height * 0.01),
              child: Text(
                errorMessage,
                style: _fieldErrorTextStyle(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  // Forgot password widget
  Widget _forgotPasswordButton() {
    return Center(
      child: GestureDetector(
        onTap: _onForgotPasswordPressed,
        behavior: HitTestBehavior.opaque,
        child: Text(
          'Forgot Password?',
          style: _forgotPasswordTextStyle(),
        ),
      ),
    );
  }

  // Main login button widget
  Widget _mainLoginButton() {
    // Height of the button
    final double buttonHeight = _mainButtonHeight();

    // Radius of the button
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
            onTap: _onLogInToWorkshopPressed,
            borderRadius: BorderRadius.circular(buttonRadius),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Log In to Workshop',
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

  // OR divider widget
  Widget _orDivider() {
    // Gap around the OR text
    final double sideGap = widget.width * 0.04;

    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            height: _dividerThickness(),
            color: _dividerColor,
          ),
        ),
        SizedBox(width: sideGap),
        Text(
          'OR',
          style: _orTextStyle(),
        ),
        SizedBox(width: sideGap),
        Expanded(
          child: Container(
            height: _dividerThickness(),
            color: _dividerColor,
          ),
        ),
      ],
    );
  }

  // Register button widget
  Widget _registerButton() {
    // Height of the button
    final double buttonHeight = _secondaryButtonHeight();

    // Radius of the button
    final double buttonRadius = _buttonBorderRadius();

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: OutlinedButton(
        onPressed: _onRegisterForNewAccountPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _secondaryButtonTextColor,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: _borderColor,
            width: widget.width * 0.0035,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          padding: EdgeInsets.zero,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Register for New Account',
              style: _secondaryButtonTextStyle(),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom clipper for the curved image bottom
class _LoginTopCurveClipper extends CustomClipper<Path> {
  _LoginTopCurveClipper({
    required this.curveDepth,
  });

  // Depth of the curve
  final double curveDepth;

  @override
  Path getClip(Size size) {
    // Creates the custom curved path
    final Path path = Path();

    path.lineTo(0, size.height - curveDepth);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height + curveDepth,
      size.width,
      size.height - curveDepth,
    );
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant _LoginTopCurveClipper oldClipper) {
    // Reclip only if curve depth changes
    return oldClipper.curveDepth != curveDepth;
  }
}