import 'package:flutter/material.dart';
import 'package:get_x/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:training_hub/database_management.dart';

// Enum for the type of input field
enum CourseAddInputFieldType {
  courseName,
  courseDescription,
  maxSeats,
}

// Enum for validation message keys
enum CourseAddInputValidationKey {
  empty,
  invalidFormat,
  tooShort,
  invalidNumber,
  mustBeGreaterThanZero,
}

// Main course add page widget
class CourseAdd extends StatefulWidget {
  const CourseAdd({super.key});

  @override
  State<CourseAdd> createState() => _CourseAddState();
}

// State for the main course add page
class _CourseAddState extends State<CourseAdd> {
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

            // Height of the bottom content section
            final double bottomPartHeight = screenHeight - navBarHeight;

            // Main full-page layout
            return SizedBox(
              width: screenWidth,
              height: screenHeight,
              child: Column(
                children: <Widget>[
                  // Top navbar section
                  CourseAddTopNavBar(
                    width: screenWidth,
                    height: navBarHeight,
                  ),

                  // Bottom form section
                  CourseAddBottomPart(
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
class CourseAddTopNavBar extends StatelessWidget {
  const CourseAddTopNavBar({
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
    return Container(
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
    );
  }
}

// Bottom course add form widget
class CourseAddBottomPart extends StatefulWidget {
  const CourseAddBottomPart({
    super.key,
    required this.width,
    required this.height,
  });

  // Section width
  final double width;

  // Section height
  final double height;

  @override
  State<CourseAddBottomPart> createState() => _CourseAddBottomPartState();
}

// State for the bottom course add form
class _CourseAddBottomPartState extends State<CourseAddBottomPart> {
  // Database helper
  final DatabaseManagement _databaseManagement = DatabaseManagement();

  // Firebase auth instance
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Default image path
  final String _defaultCourseImagePath = 'Pictures/WorkShops/defaults.png';

  // Loading state for add course
  bool _isAddingCourse = false;

  // Controller for course name field
  final TextEditingController _courseNameController = TextEditingController();

  // Controller for course description field
  final TextEditingController _courseDescriptionController =
      TextEditingController();

  // Controller for max seats field
  final TextEditingController _maxSeatsController = TextEditingController();

  // Controllers for milestones
  final List<TextEditingController> _milestoneControllers =
      <TextEditingController>[];

  // Stores milestone row errors
  final List<String?> _milestoneErrors = <String?>[];

  // Single data structure for validation messages
  final Map<CourseAddInputFieldType, Map<CourseAddInputValidationKey, String>>
      _validationMessages =
      <CourseAddInputFieldType, Map<CourseAddInputValidationKey, String>>{
    CourseAddInputFieldType.courseName:
        <CourseAddInputValidationKey, String>{
      CourseAddInputValidationKey.empty: 'Please enter the course name.',
      CourseAddInputValidationKey.tooShort:
          'Course name must be at least 3 characters.',
    },
    CourseAddInputFieldType.courseDescription:
        <CourseAddInputValidationKey, String>{
      CourseAddInputValidationKey.empty:
          'Please enter the course description.',
      CourseAddInputValidationKey.tooShort:
          'Course description must be at least 10 characters.',
    },
    CourseAddInputFieldType.maxSeats:
        <CourseAddInputValidationKey, String>{
      CourseAddInputValidationKey.empty:
          'Please enter the maximum number of seats.',
      CourseAddInputValidationKey.invalidNumber:
          'Please enter a valid whole number.',
      CourseAddInputValidationKey.mustBeGreaterThanZero:
          'Max seats must be greater than 0.',
    },
  };

  // Stores the current active validation error for each field
  final Map<CourseAddInputFieldType, CourseAddInputValidationKey?>
      _activeValidationErrors =
      <CourseAddInputFieldType, CourseAddInputValidationKey?>{
    CourseAddInputFieldType.courseName: null,
    CourseAddInputFieldType.courseDescription: null,
    CourseAddInputFieldType.maxSeats: null,
  };

  @override
  void initState() {
    super.initState();

    // Start with one milestone field
    _addMilestoneField();
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseDescriptionController.dispose();
    _maxSeatsController.dispose();

    for (final TextEditingController controller in _milestoneControllers) {
      controller.dispose();
    }

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

  // Adds one milestone field
  void _addMilestoneField() {
    setState(() {
      _milestoneControllers.add(TextEditingController());
      _milestoneErrors.add(null);
    });
  }

  // Removes one milestone field
  void _removeMilestoneField(int index) {
    if (_milestoneControllers.length == 1) {
      return;
    }

    setState(() {
      _milestoneControllers[index].dispose();
      _milestoneControllers.removeAt(index);
      _milestoneErrors.removeAt(index);
    });
  }

  // Validates course name text and returns the matching validation key
  CourseAddInputValidationKey? _validateCourseName(String value) {
    final String trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return CourseAddInputValidationKey.empty;
    }

    if (trimmedValue.length < 3) {
      return CourseAddInputValidationKey.tooShort;
    }

    return null;
  }

  // Validates course description text and returns the matching validation key
  CourseAddInputValidationKey? _validateCourseDescription(String value) {
    final String trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return CourseAddInputValidationKey.empty;
    }

    if (trimmedValue.length < 10) {
      return CourseAddInputValidationKey.tooShort;
    }

    return null;
  }

  // Validates max seats text and returns the matching validation key
  CourseAddInputValidationKey? _validateMaxSeats(String value) {
    final String trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return CourseAddInputValidationKey.empty;
    }

    final int? parsedValue = int.tryParse(trimmedValue);

    if (parsedValue == null) {
      return CourseAddInputValidationKey.invalidNumber;
    }

    if (parsedValue <= 0) {
      return CourseAddInputValidationKey.mustBeGreaterThanZero;
    }

    return null;
  }

  // Validates one milestone name and returns string message if invalid
  String? _validateMilestoneName(String value) {
    final String trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return 'Please enter the milestone name.';
    }

    if (trimmedValue.length < 2) {
      return 'Milestone name must be at least 2 characters.';
    }

    return null;
  }

  // Builds milestone list for Firestore
  List<Map<String, dynamic>> _buildMilestonesForFirestore() {
    final List<Map<String, dynamic>> milestones = <Map<String, dynamic>>[];

    for (int i = 0; i < _milestoneControllers.length; i++) {
      milestones.add(
        <String, dynamic>{
          'milestoneId': 'milestone_${i + 1}',
          'milestoneName': _milestoneControllers[i].text.trim(),
          'order': i + 1,
          'isCompleted': false,
        },
      );
    }

    return milestones;
  }

  // Validates only one field
  void _validateSingleField(CourseAddInputFieldType fieldType) {
    CourseAddInputValidationKey? errorKey;

    if (fieldType == CourseAddInputFieldType.courseName) {
      errorKey = _validateCourseName(_courseNameController.text);
    } else if (fieldType == CourseAddInputFieldType.courseDescription) {
      errorKey =
          _validateCourseDescription(_courseDescriptionController.text);
    } else if (fieldType == CourseAddInputFieldType.maxSeats) {
      errorKey = _validateMaxSeats(_maxSeatsController.text);
    }

    setState(() {
      _activeValidationErrors[fieldType] = errorKey;
    });
  }

  // Validates only one milestone field
  void _validateSingleMilestoneField(int index) {
    setState(() {
      _milestoneErrors[index] =
          _validateMilestoneName(_milestoneControllers[index].text);
    });
  }

  // Validates all fields before adding course
  bool _validateAllFields() {
    final CourseAddInputValidationKey? courseNameError =
        _validateCourseName(_courseNameController.text);
    final CourseAddInputValidationKey? courseDescriptionError =
        _validateCourseDescription(_courseDescriptionController.text);
    final CourseAddInputValidationKey? maxSeatsError =
        _validateMaxSeats(_maxSeatsController.text);

    bool areMilestonesValid = true;
    final List<String?> updatedMilestoneErrors = <String?>[];

    for (final TextEditingController controller in _milestoneControllers) {
      final String? error = _validateMilestoneName(controller.text);
      updatedMilestoneErrors.add(error);

      if (error != null) {
        areMilestonesValid = false;
      }
    }

    setState(() {
      _activeValidationErrors[CourseAddInputFieldType.courseName] =
          courseNameError;
      _activeValidationErrors[CourseAddInputFieldType.courseDescription] =
          courseDescriptionError;
      _activeValidationErrors[CourseAddInputFieldType.maxSeats] =
          maxSeatsError;

      for (int i = 0; i < _milestoneErrors.length; i++) {
        _milestoneErrors[i] = updatedMilestoneErrors[i];
      }
    });

    return courseNameError == null &&
        courseDescriptionError == null &&
        maxSeatsError == null &&
        areMilestonesValid;
  }

  // Returns true if the field currently has an error
  bool _hasFieldError(CourseAddInputFieldType fieldType) {
    return _activeValidationErrors[fieldType] != null;
  }

  // Returns the current error message for a field
  String? _fieldErrorMessage(CourseAddInputFieldType fieldType) {
    final CourseAddInputValidationKey? errorKey =
        _activeValidationErrors[fieldType];

    if (errorKey == null) {
      return null;
    }

    return _validationMessages[fieldType]?[errorKey];
  }

  // Action for add course button
  Future<void> _onAddCoursePressed() async {
    final bool isValid = _validateAllFields();

    if (!isValid) {
      return;
    }

    if (_isAddingCourse) {
      return;
    }

    final User? currentUser = _firebaseAuth.currentUser;

    if (currentUser == null) {
      _showSimpleSnackBar(
        message: 'You must be logged in before adding a course.',
      );
      return;
    }

    final String courseName = _courseNameController.text.trim();
    final String courseDescription = _courseDescriptionController.text.trim();
    final int maxSeats = int.parse(_maxSeatsController.text.trim());
    final List<Map<String, dynamic>> milestones =
        _buildMilestonesForFirestore();
    final String courseImagePath = _defaultCourseImagePath;

    setState(() {
      _isAddingCourse = true;
    });

    try {
      final userDocument = await _databaseManagement.getUserData(
        uid: currentUser.uid,
      );

      final Map<String, dynamic>? userData = userDocument.data();
      final String instructorName =
          (userData?['fullName'] as String?)?.trim() ?? 'Unknown Instructor';
      final String instructorEmail =
          (userData?['email'] as String?)?.trim().toLowerCase() ??
              (currentUser.email?.trim().toLowerCase() ?? '');

      await _databaseManagement.createCourseData(
        instructorId: currentUser.uid,
        instructorName: instructorName,
        instructorEmail: instructorEmail,
        title: courseName,
        description: courseDescription,
        courseTitle: courseName,
        courseDescription: courseDescription,
        maxStudentsAllowed: maxSeats,
        courseImagePath: courseImagePath,
        milestones: milestones,
      );

      if (!mounted) {
        return;
      }

      _showSimpleSnackBar(
        message: 'Course added successfully.',
      );

      _courseNameController.clear();
      _courseDescriptionController.clear();
      _maxSeatsController.clear();

      for (final TextEditingController controller in _milestoneControllers) {
        controller.dispose();
      }

      setState(() {
        _activeValidationErrors[CourseAddInputFieldType.courseName] = null;
        _activeValidationErrors[CourseAddInputFieldType.courseDescription] =
            null;
        _activeValidationErrors[CourseAddInputFieldType.maxSeats] = null;

        _milestoneControllers.clear();
        _milestoneErrors.clear();
      });

      _addMilestoneField();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showSimpleSnackBar(
        message: 'Failed to add course. Please try again.',
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isAddingCourse = false;
      });
    }
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

  // Radius for small action buttons
  double _smallButtonBorderRadius() {
    return widget.width * 0.045;
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

  // Font size for small button text
  double _smallButtonTextFontSize() {
    return _isTablet() ? widget.width * 0.018 : widget.width * 0.034;
  }

  // Font size for section title
  double _sectionTitleFontSize() {
    return _isTablet() ? widget.width * 0.024 : widget.width * 0.045;
  }

  // Font size for field error text
  double _fieldErrorFontSize() {
    return _isTablet() ? widget.width * 0.017 : widget.width * 0.031;
  }

  // Height of input fields
  double _inputHeight() {
    return widget.height * 0.1;
  }

  // Height of multiline description field
  double _descriptionFieldHeight() {
    return widget.height * 0.16;
  }

  // Height of image preview
  double _imagePreviewHeight() {
    return _isTablet() ? widget.height * 0.22 : widget.height * 0.18;
  }

  // Height of the main button
  double _mainButtonHeight() {
    return widget.height * 0.105;
  }

  // Height of small outlined buttons
  double _smallButtonHeight() {
    return widget.height * 0.07;
  }

  // Icon size inside fields
  double _iconSize() {
    return _isTablet() ? widget.width * 0.027 : widget.width * 0.055;
  }

  // Small icon size
  double _smallIconSize() {
    return _isTablet() ? widget.width * 0.02 : widget.width * 0.045;
  }

  // Small vertical spacing
  double _verticalSpacingSmall() {
    return widget.height * 0.014;
  }

  // Medium vertical spacing
  double _verticalSpacingMedium() {
    return widget.height * 0.02;
  }

  // Large vertical spacing
  double _verticalSpacingLarge() {
    return widget.height * 0.03;
  }

  // Space between the title and first input
  double _spaceBelowTitle() {
    return _isTablet() ? widget.height * 0.058 : widget.height * 0.09;
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

  // Image preview border radius
  double _imagePreviewRadius() {
    return widget.width * 0.04;
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

  // Divider / subtle border color
  Color get _lightBorderColor => const Color(0xFFD8DDE3);

  // Card shadow color
  Color get _cardShadowColor => const Color(0x11000000);

  // Main button shadow color
  Color get _mainButtonShadowColor => const Color(0x4434D0C3);

  // Error color for invalid fields
  Color get _errorColor => const Color(0xFFD93025);

  // Positive accent color
  Color get _addColor => const Color(0xFF2CB5A8);

  // Disabled button color
  Color get _disabledButtonOverlayColor => const Color(0x88FFFFFF);

  // Image placeholder color
  Color get _imagePlaceholderColor => const Color(0xFFF4F7FB);

  // Gradient for the main add button
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

  // Text style for section titles
  TextStyle _sectionTitleTextStyle() {
    return TextStyle(
      color: _primaryTextColor,
      fontSize: _sectionTitleFontSize(),
      fontWeight: FontWeight.w700,
      height: 1.1,
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

  // Text style for small buttons
  TextStyle _smallButtonTextStyle({
    required Color color,
  }) {
    return TextStyle(
      color: color,
      fontSize: _smallButtonTextFontSize(),
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
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: _contentBaseWidth(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(height: _spaceBelowTitle()),
                          _courseNameField(),
                          SizedBox(height: _verticalSpacingSmall()),
                          _courseDescriptionField(),
                          SizedBox(height: _verticalSpacingSmall()),
                          _maxSeatsField(),
                          SizedBox(height: _verticalSpacingLarge()),
                          _courseImageSection(),
                          SizedBox(height: _verticalSpacingLarge()),
                          _milestonesSection(),
                          SizedBox(height: _verticalSpacingLarge()),
                          _addCourseButton(),
                          SizedBox(height: _verticalSpacingMedium()),
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
      'Add New Course',
      style: _titleTextStyle(),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Course name field widget
  Widget _courseNameField() {
    return _inputField(
      fieldType: CourseAddInputFieldType.courseName,
      label: 'Course Name',
      hint: 'Course Name',
      controller: _courseNameController,
      icon: Icons.menu_book_outlined,
      obscureText: false,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
    );
  }

  // Course description field widget
  Widget _courseDescriptionField() {
    return _inputField(
      fieldType: CourseAddInputFieldType.courseDescription,
      label: 'Course Description',
      hint: 'Course Description',
      controller: _courseDescriptionController,
      icon: Icons.description_outlined,
      obscureText: false,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      isMultiline: true,
    );
  }

  // Max seats field widget
  Widget _maxSeatsField() {
    return _inputField(
      fieldType: CourseAddInputFieldType.maxSeats,
      label: 'Max Number of Seats',
      hint: 'Max Number of Seats',
      controller: _maxSeatsController,
      icon: Icons.event_seat_outlined,
      obscureText: false,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
    );
  }

  // Course image section widget
  Widget _courseImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Course Image',
          style: _sectionTitleTextStyle(),
        ),
        SizedBox(height: _verticalSpacingMedium()),
        _courseImagePreview(),
      ],
    );
  }

  // Course image preview widget
  Widget _courseImagePreview() {
    return Container(
      width: double.infinity,
      height: _imagePreviewHeight(),
      decoration: BoxDecoration(
        color: _imagePlaceholderColor,
        borderRadius: BorderRadius.circular(_imagePreviewRadius()),
        border: Border.all(
          color: _lightBorderColor,
          width: widget.width * 0.003,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        _defaultCourseImagePath,
        fit: BoxFit.cover,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          return _defaultImagePreviewContent();
        },
      ),
    );
  }

  // Default image preview content
  Widget _defaultImagePreviewContent() {
    return Container(
      color: _imagePlaceholderColor,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.image_outlined,
            size: _isTablet() ? widget.width * 0.06 : widget.width * 0.1,
            color: _secondaryTextColor,
          ),
          SizedBox(height: widget.height * 0.01),
          Text(
            'No image selected',
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize:
                  _isTablet() ? widget.width * 0.018 : widget.width * 0.033,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Shared input field widget
  Widget _inputField({
    required CourseAddInputFieldType fieldType,
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required bool obscureText,
    required TextInputType keyboardType,
    required TextInputAction textInputAction,
    bool isMultiline = false,
  }) {
    // Height of the field
    final double inputHeight =
        isMultiline ? _descriptionFieldHeight() : _inputHeight();

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
                minLines: isMultiline ? 5 : 1,
                maxLines: isMultiline ? null : 1,
                onChanged: (String value) {
                  _validateSingleField(fieldType);
                },
                onSubmitted: (_) {
                  if (textInputAction == TextInputAction.done) {
                    _onAddCoursePressed();
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
                  alignLabelWithHint: isMultiline,
                  contentPadding: isMultiline
                      ? EdgeInsets.only(
                          top: widget.height * 0.026,
                          bottom: widget.height * 0.02,
                          right: contentHorizontalPadding,
                        )
                      : EdgeInsets.zero,
                  prefixIcon: isMultiline
                      ? Padding(
                          padding: EdgeInsets.only(
                            left: contentHorizontalPadding,
                            right: iconToTextSpacing,
                            top: widget.height * 0.022,
                            bottom: widget.height * 0.08,
                          ),
                          child: Icon(
                            icon,
                            color: hasError ? _errorColor : Colors.black87,
                            size: iconSize,
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
                    minHeight: isMultiline ? widget.height * 0.08 : inputHeight,
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth:
                        _isTablet() ? widget.width * 0.09 : widget.width * 0.16,
                    minHeight: isMultiline ? widget.height * 0.08 : inputHeight,
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

  // Milestones section widget
  Widget _milestonesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Milestones to Add',
          style: _sectionTitleTextStyle(),
        ),
        SizedBox(height: _verticalSpacingMedium()),
        ...List<Widget>.generate(
          _milestoneControllers.length,
          (int index) => Padding(
            padding: EdgeInsets.only(bottom: _verticalSpacingSmall()),
            child: _milestoneField(index),
          ),
        ),
        SizedBox(height: _verticalSpacingSmall()),
        _addMilestoneButton(),
      ],
    );
  }

  // Single milestone field
  Widget _milestoneField(int index) {
    final bool hasError = _milestoneErrors[index] != null;
    final String? errorMessage = _milestoneErrors[index];

    final double inputHeight = _inputHeight();
    final double inputRadius = _inputBorderRadius();
    final double iconSize = _iconSize();
    final double totalFieldHeight =
        inputHeight + (_fieldLabelFontSize() * 0.9) + _fieldErrorSectionHeight();
    final double contentHorizontalPadding =
        _isTablet() ? widget.width * 0.02 : widget.width * 0.045;
    final double iconToTextSpacing =
        _isTablet() ? widget.width * 0.015 : widget.width * 0.03;
    final double labelLeftInset = _fieldLabelLeftInset();
    final double labelHorizontalPadding = _fieldLabelHorizontalPadding();
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
              child: TextField(
                controller: _milestoneControllers[index],
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.name,
                onChanged: (String value) {
                  _validateSingleMilestoneField(index);
                },
                onSubmitted: (_) {
                  _onAddCoursePressed();
                },
                style: _hintTextStyle(
                  hasError: hasError,
                ).copyWith(
                  color: hasError ? _errorColor : _primaryTextColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Milestone ${index + 1}',
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
                      Icons.flag_outlined,
                      color: hasError ? _errorColor : Colors.black87,
                      size: iconSize,
                    ),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (hasError)
                        Padding(
                          padding: EdgeInsets.only(
                            right: widget.width * 0.005,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: _errorColor,
                            size: iconSize,
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.only(
                          right: _suffixIconRightPadding(),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            _removeMilestoneField(index);
                          },
                          child: Icon(
                            Icons.remove_circle_outline_rounded,
                            color: _milestoneControllers.length == 1
                                ? _lightBorderColor
                                : _errorColor,
                            size: iconSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                  suffixIconConstraints: BoxConstraints(
                    minWidth:
                        _isTablet() ? widget.width * 0.12 : widget.width * 0.24,
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
          Positioned(
            left: labelLeftInset,
            top: 0,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: labelHorizontalPadding,
              ),
              child: Text(
                'Milestone ${index + 1}',
                style: _fieldLabelTextStyle(
                  hasError: hasError,
                ),
              ),
            ),
          ),
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

  // Add milestone button
  Widget _addMilestoneButton() {
    final double buttonHeight = _smallButtonHeight();
    final double buttonRadius = _smallButtonBorderRadius();

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: OutlinedButton.icon(
        onPressed: _isAddingCourse ? null : _addMilestoneField,
        icon: Icon(
          Icons.add_rounded,
          size: _smallIconSize(),
          color: _addColor,
        ),
        label: Text(
          'Add Milestone',
          style: _smallButtonTextStyle(
            color: _addColor,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _addColor,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: _addColor,
            width: widget.width * 0.0035,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
    );
  }

  // Main add course button widget
  Widget _addCourseButton() {
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
            onTap: _isAddingCourse ? null : _onAddCoursePressed,
            borderRadius: BorderRadius.circular(buttonRadius),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.width * 0.03,
                      ),
                      child: Text(
                        _isAddingCourse ? 'Adding Course...' : 'Add Course',
                        style: _mainButtonTextStyle(),
                      ),
                    ),
                  ),
                ),
                if (_isAddingCourse)
                  Container(
                    decoration: BoxDecoration(
                      color: _disabledButtonOverlayColor,
                      borderRadius: BorderRadius.circular(buttonRadius),
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