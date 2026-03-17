import 'package:flutter/material.dart';
import 'package:get_x/get.dart';
import 'package:training_hub/auth_service.dart';
import 'package:training_hub/database_management.dart';
import 'package:training_hub/login.dart';

// Reusable general navbar widget
class NavBarGeneral extends StatefulWidget {
  const NavBarGeneral({
    super.key,
    required this.title,
    this.showBackButton = false,
  });

  // Center title text
  final String title;

  // Optional back button on the left of hello text
  final bool showBackButton;

  @override
  State<NavBarGeneral> createState() => _NavBarGeneralState();
}

class _NavBarGeneralState extends State<NavBarGeneral> {
  // Firebase authentication service
  final Auth _auth = Auth();

  // Firestore database service
  final DatabaseManagement _databaseManagement = DatabaseManagement();

  // Tracks whether logout is currently running
  bool _isSigningOut = false;

  // Tracks whether user name is loading
  bool _isLoadingUserName = true;

  // User name shown in navbar
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  // Loads the current user's full name from Firestore
  Future<void> _loadUserName() async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          _userName = 'User';
          _isLoadingUserName = false;
        });
        return;
      }

      final userDocument = await _databaseManagement.getUserData(
        uid: currentUser.uid,
      );

      final Map<String, dynamic>? data = userDocument.data();

      final String fullName =
          (data?['fullName'] as String?)?.trim() ?? 'User';

      if (!mounted) {
        return;
      }

      setState(() {
        _userName = fullName.isEmpty ? 'User' : fullName;
        _isLoadingUserName = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _userName = 'User';
        _isLoadingUserName = false;
      });
    }
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

  // Action for logout button
  Future<void> _onLogoutPressed() async {
    if (_isSigningOut) {
      return;
    }

    setState(() {
      _isSigningOut = true;
    });

    try {
      // Completely signs out the currently logged in Firebase user
      await _auth.signOut();

      if (!mounted) {
        return;
      }

      // Remove all previous routes and go back to login page
      Get.offAll(
        () => const LoginPage(),
        transition: Transition.fade,
        duration: const Duration(milliseconds: 200),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showSimpleSnackBar(
        message: 'Failed to log out. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  // Action for back button
  void _onBackPressed() {
    Get.back();
  }

  // Checks if screen is tablet size
  bool _isTablet() => MediaQuery.of(context).size.width >= 600;

  // Navbar total height
  double _navBarHeight() {
    final double screenHeight = MediaQuery.of(context).size.height;
    return _isTablet() ? screenHeight * 0.145 : screenHeight * 0.15;
  }

  // First row height
  double _topRowHeight() {
    return _navBarHeight() * 0.38;
  }

  // Second row height
  double _bottomRowHeight() {
    return _navBarHeight() - _topRowHeight();
  }

  // Horizontal padding
  double _horizontalPadding() {
    final double screenWidth = MediaQuery.of(context).size.width;
    return _isTablet() ? screenWidth * 0.03 : screenWidth * 0.045;
  }

  // Top padding
  double _topPadding() {
    final double screenHeight = MediaQuery.of(context).size.height;
    return _isTablet() ? screenHeight * 0.000 : screenHeight * 0.000;
  }

  // Bottom padding
  double _bottomPadding() {
    final double screenHeight = MediaQuery.of(context).size.height;
    return _isTablet() ? screenHeight * 0.014 : screenHeight * 0.016;
  }

  // Title font size
  double _titleFontSize() {
    final double screenWidth = MediaQuery.of(context).size.width;
    return _isTablet() ? screenWidth * 0.03 : screenWidth * 0.055;
  }

  // Side text font size
  double _sideTextFontSize() {
    final double screenWidth = MediaQuery.of(context).size.width;
    return _isTablet() ? screenWidth * 0.027 : screenWidth * 0.047;
  }

  // Emoji font size
  double _emojiFontSize() {
    final double screenWidth = MediaQuery.of(context).size.width;
    return _isTablet() ? screenWidth * 0.022 : screenWidth * 0.038;
  }

  // Icon size
  double _iconSize() {
    final double screenWidth = MediaQuery.of(context).size.width;
    return _isTablet() ? screenWidth * 0.026 : screenWidth * 0.05;
  }

  // Border radius for logout button area
  double _logoutBorderRadius() {
    final double screenWidth = MediaQuery.of(context).size.width;
    return _isTablet() ? screenWidth * 0.02 : screenWidth * 0.04;
  }

  // Space between icon and logout text
  double _logoutContentSpacing() {
    final double screenWidth = MediaQuery.of(context).size.width;
    return _isTablet() ? screenWidth * 0.008 : screenWidth * 0.015;
  }

  // Space between hello text and emoji
  double _helloSpacing() {
    final double screenWidth = MediaQuery.of(context).size.width;
    return _isTablet() ? screenWidth * 0.006 : screenWidth * 0.01;
  }

  // Space between back button and hello text
  double _backButtonSpacing() {
    final double screenWidth = MediaQuery.of(context).size.width;
    return _isTablet() ? screenWidth * 0.008 : screenWidth * 0.012;
  }

  // Main navbar background color
  Color get _backgroundColor => const Color(0xFF4D84DB);

  // First row darker blue
  Color get _topRowBackgroundColor => const Color(0xFF4D84DB);

  // Second row blue
  Color get _bottomRowBackgroundColor => const Color(0xFF5B95F0);

  // Slightly darker bottom border color
  Color get _bottomBorderColor => const Color(0xFF3E73C9);

  // Main text color
  Color get _mainTextColor => Colors.white;

  // Slightly softer white for top row
  Color get _secondaryTextColor => const Color(0xFFF3F7FF);

  // Logout icon color
  Color get _logoutIconColor => const Color(0xFFDAFFF9);

  // Back icon color
  Color get _backIconColor => const Color(0xFFF3F7FF);

  // Text style for center title
  TextStyle _titleTextStyle() {
    return TextStyle(
      color: _mainTextColor,
      fontSize: _titleFontSize(),
      fontWeight: FontWeight.w800,
      height: 1.08,
    );
  }

  // Text style for side labels
  TextStyle _sideTextStyle() {
    return TextStyle(
      color: _secondaryTextColor,
      fontSize: _sideTextFontSize(),
      fontWeight: FontWeight.w600,
      height: 1,
    );
  }

  // Hello text
  String _helloText() {
    if (_isLoadingUserName) {
      return 'Hello...';
    }

    return 'Hello, $_userName';
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        color: _backgroundColor,
        child: SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            height: _navBarHeight(),
            decoration: BoxDecoration(
              color: _backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: _bottomBorderColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: <Widget>[
                // First row: hello + logout
                Container(
                  width: double.infinity,
                  height: _topRowHeight(),
                  color: _topRowBackgroundColor,
                  padding: EdgeInsets.only(
                    left: _horizontalPadding(),
                    right: _horizontalPadding(),
                    top: _topPadding(),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                if (widget.showBackButton) ...<Widget>[
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _onBackPressed,
                                      borderRadius: BorderRadius.circular(
                                        _logoutBorderRadius(),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(
                                          _navBarHeight() * 0.04,
                                        ),
                                        child: Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          color: _backIconColor,
                                          size: _iconSize() * 0.9,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: _backButtonSpacing()),
                                ],
                                Text(
                                  _helloText(),
                                  style: _sideTextStyle(),
                                ),
                                SizedBox(width: _helloSpacing()),
                                Text(
                                  '👋',
                                  style: TextStyle(
                                    fontSize: _emojiFontSize(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isSigningOut ? null : _onLogoutPressed,
                          borderRadius: BorderRadius.circular(
                            _logoutBorderRadius(),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: _horizontalPadding() * 0.2,
                              vertical: _navBarHeight() * 0.08,
                            ),
                            child: FittedBox(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  if (_isSigningOut)
                                    SizedBox(
                                      width: _iconSize() * 0.9,
                                      height: _iconSize() * 0.9,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          _mainTextColor,
                                        ),
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.logout_rounded,
                                      color: _logoutIconColor,
                                      size: _iconSize(),
                                    ),
                                  SizedBox(width: _logoutContentSpacing()),
                                  Text(
                                    'Logout',
                                    style: _sideTextStyle(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Second row: title only
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: _bottomRowBackgroundColor,
                    padding: EdgeInsets.only(
                      left: _horizontalPadding(),
                      right: _horizontalPadding(),
                      bottom: _bottomPadding(),
                    ),
                    child: Center(
                      child: Text(
                        widget.title,
                        style: _titleTextStyle(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
}