import 'package:flutter/material.dart';
import 'package:get_x/get.dart';
import 'package:training_hub/Register/Register_type.dart';

// Enum for the type of input field
enum RegisterInputFieldType {
  fullName,
  email,
  password,
  confirmPassword,
  phone,
}

// Enum for validation message keys
enum RegisterInputValidationKey {
  empty,
  invalidFormat,
  tooShort,
  passwordsDoNotMatch,
  invalidPhone,
}

// Main register page widget
class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

// State for the main register page
class _RegisterState extends State<Register> {
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

            // Height of the bottom register section
            final double bottomPartHeight = screenHeight - navBarHeight;

            // Main full-page layout
            return SizedBox(
              width: screenWidth,
              height: screenHeight,
              child: Column(
                children: <Widget>[
                  // Top navbar section
                  RegisterTopNavBar(
                    width: screenWidth,
                    height: navBarHeight,
                  ),

                  // Bottom register form section
                  RegisterBottomPart(
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

// Top navbar widget
class RegisterTopNavBar extends StatelessWidget {
  const RegisterTopNavBar({
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

// Bottom register form widget
class RegisterBottomPart extends StatefulWidget {
  const RegisterBottomPart({
    super.key,
    required this.width,
    required this.height,
  });

  // Section width
  final double width;

  // Section height
  final double height;

  @override
  State<RegisterBottomPart> createState() => _RegisterBottomPartState();
}

// State for the bottom register form
class _RegisterBottomPartState extends State<RegisterBottomPart> {
  // Controller for full name field
  final TextEditingController _fullNameController = TextEditingController();

  // Controller for email field
  final TextEditingController _emailController = TextEditingController();

  // Controller for password field
  final TextEditingController _passwordController = TextEditingController();

  // Controller for confirm password field
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Controller for phone field
  final TextEditingController _phoneController = TextEditingController();

  // Fixed Jordan prefix shown inside the field
  final String _jordanPrefix = '+962';

  // Single data structure for validation messages
  final Map<RegisterInputFieldType, Map<RegisterInputValidationKey, String>>
      _validationMessages =
      <RegisterInputFieldType, Map<RegisterInputValidationKey, String>>{
    RegisterInputFieldType.fullName: <RegisterInputValidationKey, String>{
      RegisterInputValidationKey.empty: 'Please enter your full name.',
      RegisterInputValidationKey.tooShort:
          'Full name must be at least 3 characters.',
    },
    RegisterInputFieldType.email: <RegisterInputValidationKey, String>{
      RegisterInputValidationKey.empty: 'Please enter your email.',
      RegisterInputValidationKey.invalidFormat:
          'Please enter a valid email address.',
    },
    RegisterInputFieldType.password: <RegisterInputValidationKey, String>{
      RegisterInputValidationKey.empty: 'Please enter your password.',
      RegisterInputValidationKey.tooShort:
          'Password must be at least 6 characters.',
    },
    RegisterInputFieldType.confirmPassword:
        <RegisterInputValidationKey, String>{
      RegisterInputValidationKey.empty: 'Please confirm your password.',
      RegisterInputValidationKey.passwordsDoNotMatch:
          'Passwords do not match.',
    },
    RegisterInputFieldType.phone: <RegisterInputValidationKey, String>{
      RegisterInputValidationKey.empty:
          'Please enter your Jordan phone number.',
      RegisterInputValidationKey.invalidPhone:
          'Enter a valid Jordan mobile number after +962, like 7XXXXXXXX.',
    },
  };

  // Stores the current active validation error for each field
  final Map<RegisterInputFieldType, RegisterInputValidationKey?>
      _activeValidationErrors =
      <RegisterInputFieldType, RegisterInputValidationKey?>{
    RegisterInputFieldType.fullName: null,
    RegisterInputFieldType.email: null,
    RegisterInputFieldType.password: null,
    RegisterInputFieldType.confirmPassword: null,
    RegisterInputFieldType.phone: null,
  };

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Validates full name text and returns the matching validation key
  RegisterInputValidationKey? _validateFullName(String value) {
    final String trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return RegisterInputValidationKey.empty;
    }

    if (trimmedValue.length < 3) {
      return RegisterInputValidationKey.tooShort;
    }

    return null;
  }

  // Validates email text and returns the matching validation key
  RegisterInputValidationKey? _validateEmail(String value) {
    final String trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return RegisterInputValidationKey.empty;
    }

    final RegExp emailRegex = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );

    if (!emailRegex.hasMatch(trimmedValue)) {
      return RegisterInputValidationKey.invalidFormat;
    }

    return null;
  }

  // Validates password text and returns the matching validation key
  RegisterInputValidationKey? _validatePassword(String value) {
    final String trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return RegisterInputValidationKey.empty;
    }

    if (trimmedValue.length < 6) {
      return RegisterInputValidationKey.tooShort;
    }

    return null;
  }

  // Validates confirm password text and returns the matching validation key
  RegisterInputValidationKey? _validateConfirmPassword(String value) {
    final String trimmedValue = value.trim();
    final String password = _passwordController.text.trim();

    if (trimmedValue.isEmpty) {
      return RegisterInputValidationKey.empty;
    }

    if (trimmedValue != password) {
      return RegisterInputValidationKey.passwordsDoNotMatch;
    }

    return null;
  }

  // Validates Jordan phone text and returns the matching validation key
  // User types only the local part after the fixed +962 prefix
  RegisterInputValidationKey? _validatePhone(String value) {
    final String trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return RegisterInputValidationKey.empty;
    }

    final String digitsOnly = trimmedValue.replaceAll(RegExp(r'\D'), '');

    if (!RegExp(r'^7\d{8}$').hasMatch(digitsOnly)) {
      return RegisterInputValidationKey.invalidPhone;
    }

    return null;
  }

  // Full Jordan phone number for next page usage
  String _fullJordanPhoneNumber() {
    final String digitsOnly =
        _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    return '$_jordanPrefix$digitsOnly';
  }

  // Validates only one field
  void _validateSingleField(RegisterInputFieldType fieldType) {
    RegisterInputValidationKey? errorKey;

    if (fieldType == RegisterInputFieldType.fullName) {
      errorKey = _validateFullName(_fullNameController.text);
    } else if (fieldType == RegisterInputFieldType.email) {
      errorKey = _validateEmail(_emailController.text);
    } else if (fieldType == RegisterInputFieldType.password) {
      errorKey = _validatePassword(_passwordController.text);
    } else if (fieldType == RegisterInputFieldType.confirmPassword) {
      errorKey = _validateConfirmPassword(_confirmPasswordController.text);
    } else if (fieldType == RegisterInputFieldType.phone) {
      errorKey = _validatePhone(_phoneController.text);
    }

    setState(() {
      _activeValidationErrors[fieldType] = errorKey;

      // If password changes, confirm password may also become invalid
      if (fieldType == RegisterInputFieldType.password) {
        _activeValidationErrors[RegisterInputFieldType.confirmPassword] =
            _validateConfirmPassword(_confirmPasswordController.text);
      }
    });
  }

  // Validates all fields before continuing
  bool _validateAllFields() {
    final RegisterInputValidationKey? fullNameError =
        _validateFullName(_fullNameController.text);
    final RegisterInputValidationKey? emailError =
        _validateEmail(_emailController.text);
    final RegisterInputValidationKey? passwordError =
        _validatePassword(_passwordController.text);
    final RegisterInputValidationKey? confirmPasswordError =
        _validateConfirmPassword(_confirmPasswordController.text);
    final RegisterInputValidationKey? phoneError =
        _validatePhone(_phoneController.text);

    setState(() {
      _activeValidationErrors[RegisterInputFieldType.fullName] = fullNameError;
      _activeValidationErrors[RegisterInputFieldType.email] = emailError;
      _activeValidationErrors[RegisterInputFieldType.password] = passwordError;
      _activeValidationErrors[RegisterInputFieldType.confirmPassword] =
          confirmPasswordError;
      _activeValidationErrors[RegisterInputFieldType.phone] = phoneError;
    });

    return fullNameError == null &&
        emailError == null &&
        passwordError == null &&
        confirmPasswordError == null &&
        phoneError == null;
  }

  // Returns true if the field currently has an error
  bool _hasFieldError(RegisterInputFieldType fieldType) {
    return _activeValidationErrors[fieldType] != null;
  }

  // Returns the current error message for a field
  String? _fieldErrorMessage(RegisterInputFieldType fieldType) {
    final RegisterInputValidationKey? errorKey =
        _activeValidationErrors[fieldType];

    if (errorKey == null) {
      return null;
    }

    return _validationMessages[fieldType]?[errorKey];
  }

  // Action for continue button
  void _onContinuePressed() {
    final bool isValid = _validateAllFields();

    if (!isValid) {
      return;
    }

    final String fullName = _fullNameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String fullPhoneNumber = _fullJordanPhoneNumber();

    Get.to(
      () => RegisterTypePage(
        fullName: fullName,
        email: email,
        password: password,
        phoneNumber: fullPhoneNumber,
      ),
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
    return widget.height * 0.015;
  }

  // Font size for the main title
  double _titleFontSize() {
    return _isTablet() ? widget.width * 0.037 : widget.width * 0.062;
  }

  // Font size for field labels
  double _fieldLabelFontSize() {
    return _isTablet() ? widget.width * 0.018 : widget.width * 0.034;
  }

  // Font size inside input fields
  double _inputTextFontSize() {
    return _isTablet() ? widget.width * 0.021 : widget.width * 0.043;
  }

  // Font size for button text
  double _buttonTextFontSize() {
    return _isTablet() ? widget.width * 0.024 : widget.width * 0.05;
  }

  // Font size for field error text
  double _fieldErrorFontSize() {
    return _isTablet() ? widget.width * 0.017 : widget.width * 0.031;
  }

  // Height of input fields
  double _inputHeight() {
    return widget.height * 0.1;
  }

  // Height of the main button
  double _mainButtonHeight() {
    return widget.height * 0.105;
  }

  // Icon size inside fields
  double _iconSize() {
    return _isTablet() ? widget.width * 0.027 : widget.width * 0.055;
  }

  // Small vertical spacing
  double _verticalSpacingSmall() {
    return widget.height * 0.014;
  }

  // Large vertical spacing
  double _verticalSpacingLarge() {
    return widget.height * 0.00;
  }

  // Space between the title and first input
  double _spaceBelowTitle() {
    return _isTablet() ? widget.height * 0.058 : widget.height * 0.12;
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

  // Prefix text gap inside phone field
  double _phonePrefixGap() {
    return _isTablet() ? widget.width * 0.012 : widget.width * 0.02;
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

  // Main button text color
  Color get _mainButtonTextColor => Colors.white;

  // Card shadow color
  Color get _cardShadowColor => const Color(0x11000000);

  // Main button shadow color
  Color get _mainButtonShadowColor => const Color(0x4434D0C3);

  // Error color for invalid fields
  Color get _errorColor => const Color(0xFFD93025);

  // Gradient for the main continue button
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

  // Text style for the fixed +962 prefix inside phone field
  TextStyle _phonePrefixTextStyle({
    required bool hasError,
  }) {
    return TextStyle(
      color: hasError ? _errorColor : _primaryTextColor,
      fontSize: _inputTextFontSize(),
      fontWeight: FontWeight.w800,
    );
  }

  double _prefixIconAreaWidth({
    required bool isPhoneField,
  }) {
    if (isPhoneField) {
      return _isTablet() ? widget.width * 0.1 : widget.width * 0.22;
    }

    return _isTablet() ? widget.width * 0.09 : widget.width * 0.16;
  }

  @override
  Widget build(BuildContext context) {
    // Radius for the top corners of the bottom section
    final double cardRadius = _cardBorderRadius();

    return RepaintBoundary(
      child: Container(
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
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: _contentBaseWidth(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              SizedBox(height: _spaceBelowTitle()),
                              _fullNameField(),
                              SizedBox(height: _verticalSpacingSmall()),
                              _emailField(),
                              SizedBox(height: _verticalSpacingSmall()),
                              _passwordField(),
                              SizedBox(height: _verticalSpacingSmall()),
                              _confirmPasswordField(),
                              SizedBox(height: _verticalSpacingSmall()),
                              _phoneField(),
                              SizedBox(height: _verticalSpacingLarge()),
                              _continueButton(),
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
      ),
    );
  }

  // Top title widget
  Widget _title() {
    return Text(
      'Create your unity workshop account',
      style: _titleTextStyle(),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Full name field widget
  Widget _fullNameField() {
    return _inputField(
      fieldType: RegisterInputFieldType.fullName,
      label: 'Full Name',
      hint: 'Full Name',
      controller: _fullNameController,
      icon: Icons.person_outline_rounded,
      obscureText: false,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
    );
  }

  // Email field widget
  Widget _emailField() {
    return _inputField(
      fieldType: RegisterInputFieldType.email,
      label: 'Email',
      hint: 'Email',
      controller: _emailController,
      icon: Icons.email_outlined,
      obscureText: false,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
    );
  }

  // Password field widget
  Widget _passwordField() {
    return _inputField(
      fieldType: RegisterInputFieldType.password,
      label: 'Password',
      hint: 'Password',
      controller: _passwordController,
      icon: Icons.lock_outline_rounded,
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.next,
    );
  }

  // Confirm password field widget
  Widget _confirmPasswordField() {
    return _inputField(
      fieldType: RegisterInputFieldType.confirmPassword,
      label: 'Confirm Password',
      hint: 'Confirm Password',
      controller: _confirmPasswordController,
      icon: Icons.lock_outline_rounded,
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.next,
    );
  }

  // Phone field widget
  Widget _phoneField() {
    return _inputField(
      fieldType: RegisterInputFieldType.phone,
      label: 'Phone',
      hint: '7XXXXXXXX',
      controller: _phoneController,
      icon: Icons.phone_outlined,
      obscureText: false,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
    );
  }

  // Shared input field widget
  Widget _inputField({
    required RegisterInputFieldType fieldType,
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required bool obscureText,
    required TextInputType keyboardType,
    required TextInputAction textInputAction,
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

    // Whether this is the phone field
    final bool isPhoneField = fieldType == RegisterInputFieldType.phone;

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
                textInputAction: textInputAction,
                onChanged: (String value) {
                  _validateSingleField(fieldType);
                },
                onSubmitted: (_) {
                  if (textInputAction == TextInputAction.done) {
                    _onContinuePressed();
                  }
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
                  prefixIcon: isPhoneField
                      ? Padding(
                          padding: EdgeInsets.only(
                            left: contentHorizontalPadding,
                            right: _phonePrefixGap(),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                icon,
                                color: hasError ? _errorColor : Colors.black87,
                                size: iconSize,
                              ),
                              SizedBox(width: iconToTextSpacing),
                              Text(
                                _jordanPrefix,
                                style: _phonePrefixTextStyle(
                                  hasError: hasError,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Padding(
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
                    minWidth: _prefixIconAreaWidth(
                      isPhoneField: isPhoneField,
                    ),
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
              top: _fieldLabelFontSize() * 0.45 +
                  inputHeight +
                  (widget.height * 0.01),
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

  // Main continue button widget
  Widget _continueButton() {
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
            onTap: _onContinuePressed,
            borderRadius: BorderRadius.circular(buttonRadius),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.width * 0.03,
                  ),
                  child: Text(
                    'Continue',
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