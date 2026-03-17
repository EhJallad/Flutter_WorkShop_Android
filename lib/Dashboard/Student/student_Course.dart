import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:training_hub/navbar_general.dart';
import 'package:training_hub/Dashboard/Dashboard.dart';
import 'package:training_hub/database_management.dart';

class StudentCourse extends StatefulWidget {
  const StudentCourse({
    super.key,
    required this.courseData,
  });

  final DashboardCourseData courseData;

  @override
  State<StudentCourse> createState() => _StudentCourseState();
}

class _StudentCourseState extends State<StudentCourse> {
  final DatabaseManagement _databaseManagement = DatabaseManagement();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late bool _isRegistered;
  late int _availableSeatsCount;

  bool _isRegisterActionLoading = false;

  double _calculatedAttendanceValue = 1;
  bool _isAttendanceLoading = true;

  double _calculatedProgressValue = 0;
  bool _isProgressLoading = true;

  @override
  void initState() {
    super.initState();
    _isRegistered = widget.courseData.isRegistered;
    _availableSeatsCount =
        int.tryParse(widget.courseData.availableSeatsText.trim()) ?? 0;

    _loadAttendanceValue();
    _loadProgressValue();
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

  Future<void> _loadAttendanceValue() async {
    final User? currentUser = _firebaseAuth.currentUser;

    if (currentUser == null || widget.courseData.courseId.trim().isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _calculatedAttendanceValue = 1;
        _isAttendanceLoading = false;
      });
      return;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> courseDocument =
          await _firestore
              .collection('courses')
              .doc(widget.courseData.courseId)
              .get();

      final Map<String, dynamic>? courseData = courseDocument.data();

      final List<dynamic> milestones =
          (courseData?['milestones'] as List<dynamic>?) ?? <dynamic>[];

      final int totalClasses = milestones.length;

      if (totalClasses <= 0) {
        if (!mounted) {
          return;
        }

        setState(() {
          _calculatedAttendanceValue = 1;
          _isAttendanceLoading = false;
        });
        return;
      }

      final DocumentSnapshot<Map<String, dynamic>> attendanceDocument =
          await _firestore
              .collection('courses')
              .doc(widget.courseData.courseId)
              .collection('studentAttendance')
              .doc(currentUser.uid)
              .get();

      final Map<String, dynamic>? attendanceData = attendanceDocument.data();

      final Map<String, dynamic> milestoneStatuses =
          (attendanceData?['milestoneStatuses'] as Map<String, dynamic>?) ??
              <String, dynamic>{};

      int attendedClassesCount = 0;

      for (final dynamic milestone in milestones) {
        final Map<String, dynamic> milestoneMap =
            Map<String, dynamic>.from(milestone as Map<String, dynamic>);

        final String milestoneId =
            (milestoneMap['milestoneId'] as String?)?.trim() ?? '';

        final String selectedStatus =
            (milestoneStatuses[milestoneId] as String?)?.trim() ?? 'None';

        if (selectedStatus == 'Did not attend') {
          continue;
        }

        attendedClassesCount++;
      }

      final double attendanceValue = attendedClassesCount / totalClasses;

      if (!mounted) {
        return;
      }

      setState(() {
        _calculatedAttendanceValue = attendanceValue.clamp(0, 1);
        _isAttendanceLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _calculatedAttendanceValue = 1;
        _isAttendanceLoading = false;
      });
    }
  }

  Future<void> _loadProgressValue() async {
    if (widget.courseData.courseId.trim().isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _calculatedProgressValue = 0;
        _isProgressLoading = false;
      });
      return;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> courseDocument =
          await _firestore
              .collection('courses')
              .doc(widget.courseData.courseId)
              .get();

      final Map<String, dynamic>? courseData = courseDocument.data();

      final List<dynamic> milestones =
          (courseData?['milestones'] as List<dynamic>?) ?? <dynamic>[];

      final int totalMilestones = milestones.length;

      if (totalMilestones <= 0) {
        if (!mounted) {
          return;
        }

        setState(() {
          _calculatedProgressValue = 0;
          _isProgressLoading = false;
        });
        return;
      }

      int completedMilestonesCount = 0;

      for (final dynamic milestone in milestones) {
        final Map<String, dynamic> milestoneMap =
            Map<String, dynamic>.from(milestone as Map<String, dynamic>);

        final bool isCompleted =
            (milestoneMap['isCompleted'] as bool?) ?? false;

        if (isCompleted) {
          completedMilestonesCount++;
        }
      }

      final double progressValue = completedMilestonesCount / totalMilestones;

      if (!mounted) {
        return;
      }

      setState(() {
        _calculatedProgressValue = progressValue.clamp(0, 1);
        _isProgressLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _calculatedProgressValue = 0;
        _isProgressLoading = false;
      });
    }
  }

  // Toggle register / unregister status
  Future<void> _onRegisterTogglePressed() async {
    if (_isRegisterActionLoading) {
      return;
    }

    if (!widget.courseData.isOpen && !_isRegistered) {
      return;
    }

    final User? currentUser = _firebaseAuth.currentUser;

    if (currentUser == null) {
      _showSimpleSnackBar(
        message: 'You must be logged in first.',
      );
      return;
    }

    if (widget.courseData.courseId.trim().isEmpty) {
      _showSimpleSnackBar(
        message: 'This course is missing its database id.',
      );
      return;
    }

    setState(() {
      _isRegisterActionLoading = true;
    });

    try {
      if (_isRegistered) {
        await _databaseManagement.unregisterStudentFromCourse(
          courseId: widget.courseData.courseId,
          studentId: currentUser.uid,
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _isRegistered = false;
          _availableSeatsCount = _availableSeatsCount + 1;
        });

        _showSimpleSnackBar(
          message: 'You have been unregistered from this course.',
        );
      } else {
        if (_availableSeatsCount <= 0) {
          if (!mounted) {
            return;
          }

          _showSimpleSnackBar(
            message: 'No seats are available for this course.',
          );
          return;
        }

        await _databaseManagement.registerStudentInCourse(
          courseId: widget.courseData.courseId,
          studentId: currentUser.uid,
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _isRegistered = true;
          _availableSeatsCount =
              _availableSeatsCount > 0 ? _availableSeatsCount - 1 : 0;
        });

        _showSimpleSnackBar(
          message: 'You have been registered successfully.',
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showSimpleSnackBar(
        message: 'Something went wrong. Please try again.',
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isRegisterActionLoading = false;
      });
    }
  }

  // Checks if screen is tablet size
  bool _isTablet(double width) => width >= 600;

  bool _isRegisterButtonDisabled() {
    return !_isRegistered && _availableSeatsCount <= 0;
  }

  // Horizontal page padding
  double _pageHorizontalPadding(double width) {
    return _isTablet(width) ? width * 0.045 : width * 0.05;
  }

  // Vertical page padding
  double _pageTopPadding(double height) {
    return height * 0.02;
  }

  double _pageBottomPadding(double height) {
    return height * 0.03;
  }

  // Spacing
  double _sectionSpacingLarge(double height) {
    return height * 0.024;
  }

  double _sectionSpacingMedium(double height) {
    return height * 0.018;
  }

  double _sectionSpacingSmall(double height) {
    return height * 0.01;
  }

  // Card sizes
  double _cardRadius(double width) {
    return width * 0.05;
  }

  double _cardInnerHorizontalPadding(double width) {
    return _isTablet(width) ? width * 0.035 : width * 0.045;
  }

  double _cardInnerVerticalPadding(double height) {
    return height * 0.022;
  }

  // Top image size
  double _courseImageHeight(double height) {
    return _isTablet(MediaQuery.of(context).size.width)
        ? height * 0.24
        : height * 0.22;
  }

  // Text sizes
  double _titleFontSize(double width) {
    return _isTablet(width) ? width * 0.032 : width * 0.055;
  }

  double _descriptionFontSize(double width) {
    return _isTablet(width) ? width * 0.018 : width * 0.033;
  }

  double _labelFontSize(double width) {
    return _isTablet(width) ? width * 0.018 : width * 0.032;
  }

  double _valueFontSize(double width) {
    return _isTablet(width) ? width * 0.019 : width * 0.033;
  }

  double _buttonTextFontSize(double width) {
    return _isTablet(width) ? width * 0.021 : width * 0.038;
  }

  double _statusTextFontSize(double width) {
    return _isTablet(width) ? width * 0.016 : width * 0.03;
  }

  double _attendanceTitleFontSize(double width) {
    return _isTablet(width) ? width * 0.021 : width * 0.038;
  }

  double _attendancePercentFontSize(double width) {
    return _isTablet(width) ? width * 0.032 : width * 0.06;
  }

  double _progressPercentFontSize(double width) {
    return _isTablet(width) ? width * 0.017 : width * 0.031;
  }

  // Button sizes
  double _mainButtonHeight(double height) {
    return height * 0.07;
  }

  double _mainButtonRadius(double width) {
    return width * 0.04;
  }

  // Status chip sizes
  double _statusChipHeight(double height) {
    return height * 0.048;
  }

  double _statusChipRadius(double width) {
    return width * 0.03;
  }

  // Attendance circular sizes
  double _attendanceCircleSize(double width) {
    return _isTablet(width) ? width * 0.22 : width * 0.34;
  }

  double _attendanceStrokeWidth(double width) {
    return _isTablet(width) ? width * 0.012 : width * 0.018;
  }

  // Progress bar sizes
  double _progressBarHeight(double height) {
    return height * 0.018;
  }

  double _progressBarRadius(double width) {
    return width * 0.03;
  }

  // Colors
  Color get _pageBackgroundColor => Colors.white;
  Color get _cardBackgroundColor => Colors.white;
  Color get _cardBorderColor => const Color(0xFFE9EDF2);
  Color get _cardShadowColor => const Color(0x12000000);
  Color get _primaryTextColor => const Color(0xFF0F203D);
  Color get _secondaryTextColor => const Color(0xFF8A8A8A);
  Color get _redColor => const Color(0xFFE95B5B);
  Color get _redDarkTextColor => const Color(0xFFB13D3D);
  Color get _greenColor => const Color(0xFF33B679);
  Color get _greenDarkTextColor => const Color(0xFF1E7D52);
  Color get _chipBackgroundColor => const Color(0xFFF4F7FB);
  Color get _chipBorderColor => const Color(0xFFD8E1EB);
  Color get _progressBackgroundColor => const Color(0xFFF0D7D7);
  Color get _progressFillColor => const Color(0xFFE95B5B);
  Color get _attendanceBackgroundColor => const Color(0xFFE9EDF2);
  Color get _disabledButtonColor => const Color(0xFFBFC5CE);
  Color get _disabledButtonShadowColor => const Color(0x22000000);

  // Main button gradient
  LinearGradient get _registerButtonGradient => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0xFF34C759),
          Color(0xFF2FAE4F),
        ],
      );

  LinearGradient get _unregisterButtonGradient => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0xFFE95B5B),
          Color(0xFFD64545),
        ],
      );

  Color get _registerButtonShadowColor => const Color(0x4434C759);
  Color get _unregisterButtonShadowColor => const Color(0x44E95B5B);

  // Text styles
  TextStyle _titleTextStyle(double width) {
    return TextStyle(
      color: _primaryTextColor,
      fontSize: _titleFontSize(width),
      fontWeight: FontWeight.w800,
      height: 1.15,
    );
  }

  TextStyle _descriptionTextStyle(double width) {
    return TextStyle(
      color: _secondaryTextColor,
      fontSize: _descriptionFontSize(width),
      fontWeight: FontWeight.w500,
      height: 1.45,
    );
  }

  TextStyle _labelTextStyle(double width) {
    return TextStyle(
      color: _secondaryTextColor,
      fontSize: _labelFontSize(width),
      fontWeight: FontWeight.w600,
    );
  }

  TextStyle _valueTextStyle(double width) {
    return TextStyle(
      color: _primaryTextColor,
      fontSize: _valueFontSize(width),
      fontWeight: FontWeight.w700,
      height: 1.25,
    );
  }

  TextStyle _buttonTextStyle(double width) {
    return TextStyle(
      color: Colors.white,
      fontSize: _buttonTextFontSize(width),
      fontWeight: FontWeight.w700,
    );
  }

  TextStyle _statusTextStyle({
    required double width,
    required bool isOpen,
  }) {
    return TextStyle(
      color: isOpen ? _greenDarkTextColor : _redDarkTextColor,
      fontSize: _statusTextFontSize(width),
      fontWeight: FontWeight.w700,
    );
  }

  TextStyle _sectionCardTitleTextStyle(double width) {
    return TextStyle(
      color: _primaryTextColor,
      fontSize: _attendanceTitleFontSize(width),
      fontWeight: FontWeight.w800,
    );
  }

  TextStyle _attendancePercentTextStyle(double width) {
    return TextStyle(
      color: _primaryTextColor,
      fontSize: _attendancePercentFontSize(width),
      fontWeight: FontWeight.w800,
    );
  }

  TextStyle _progressPercentTextStyle(double width) {
    return TextStyle(
      color: _redDarkTextColor,
      fontSize: _progressPercentFontSize(width),
      fontWeight: FontWeight.w700,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackgroundColor,
      body: Column(
        children: <Widget>[
          NavBarGeneral(
            title: widget.courseData.courseName,
            showBackButton: true,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double screenWidth = constraints.maxWidth;
                final double screenHeight = constraints.maxHeight;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    _pageHorizontalPadding(screenWidth),
                    _pageTopPadding(screenHeight),
                    _pageHorizontalPadding(screenWidth),
                    _pageBottomPadding(screenHeight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _courseImageSection(
                        width: screenWidth,
                        height: screenHeight,
                      ),
                      SizedBox(height: _sectionSpacingLarge(screenHeight)),
                      _courseTitle(width: screenWidth),
                      SizedBox(height: _sectionSpacingMedium(screenHeight)),
                      _courseDescription(width: screenWidth),
                      SizedBox(height: _sectionSpacingLarge(screenHeight)),
                      _infoLine(
                        width: screenWidth,
                        label: 'Instructor',
                        value: widget.courseData.instructorName,
                      ),
                      SizedBox(height: _sectionSpacingMedium(screenHeight)),
                      _seatsAndStatusSection(
                        width: screenWidth,
                        height: screenHeight,
                      ),
                      SizedBox(height: _sectionSpacingLarge(screenHeight)),
                      _registerButton(
                        width: screenWidth,
                        height: screenHeight,
                      ),
                      SizedBox(height: _sectionSpacingLarge(screenHeight)),
                      _attendanceContainer(
                        width: screenWidth,
                        height: screenHeight,
                      ),
                      SizedBox(height: _sectionSpacingLarge(screenHeight)),
                      _progressTrackContainer(
                        width: screenWidth,
                        height: screenHeight,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Top course image
  Widget _courseImageSection({
    required double width,
    required double height,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_cardRadius(width)),
      child: Image.asset(
        widget.courseData.imagePath,
        width: double.infinity,
        height: _courseImageHeight(height),
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          return Container(
            width: double.infinity,
            height: _courseImageHeight(height),
            color: const Color(0xFFE9EDF2),
            alignment: Alignment.center,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: const Color(0xFF8A8A8A),
              size: _isTablet(width) ? width * 0.08 : width * 0.12,
            ),
          );
        },
      ),
    );
  }

  // Course title
  Widget _courseTitle({
    required double width,
  }) {
    return Text(
      widget.courseData.courseName,
      style: _titleTextStyle(width),
    );
  }

  // Course description
  Widget _courseDescription({
    required double width,
  }) {
    return Text(
      widget.courseData.shortDescription,
      style: _descriptionTextStyle(width),
    );
  }

  // Shared info line
  Widget _infoLine({
    required double width,
    required String label,
    required String value,
  }) {
    return RichText(
      text: TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: '$label: ',
            style: _labelTextStyle(width),
          ),
          TextSpan(
            text: value,
            style: _valueTextStyle(width),
          ),
        ],
      ),
    );
  }

  // Seats + open/closed section
  Widget _seatsAndStatusSection({
    required double width,
    required double height,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: RichText(
            text: TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: 'Seats available now: ',
                  style: _labelTextStyle(width),
                ),
                TextSpan(
                  text: _availableSeatsCount.toString(),
                  style: _valueTextStyle(width),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: width * 0.03),
        _statusChip(
          width: width,
          height: height,
        ),
      ],
    );
  }

  // Open / closed chip
  Widget _statusChip({
    required double width,
    required double height,
  }) {
    final bool isOpen = _availableSeatsCount > 0;

    return Container(
      height: _statusChipHeight(height),
      padding: EdgeInsets.symmetric(
        horizontal: _isTablet(width) ? width * 0.02 : width * 0.03,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isOpen
            ? _greenColor.withOpacity(0.14)
            : _redColor.withOpacity(0.14),
        borderRadius: BorderRadius.circular(_statusChipRadius(width)),
        border: Border.all(
          color: isOpen ? _greenColor : _redColor,
          width: width * 0.0025,
        ),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: _statusTextStyle(
          width: width,
          isOpen: isOpen,
        ),
      ),
    );
  }

  // Register / unregister button
  Widget _registerButton({
    required double width,
    required double height,
  }) {
    final bool isDisabled = _isRegisterButtonDisabled();

    final String buttonText = _isRegisterActionLoading
        ? (_isRegistered ? 'Unregistering...' : 'Registering...')
        : (_isRegistered ? 'Unregister' : 'Register');

    final LinearGradient activeGradient =
        _isRegistered ? _unregisterButtonGradient : _registerButtonGradient;

    final Color activeShadowColor = _isRegistered
        ? _unregisterButtonShadowColor
        : _registerButtonShadowColor;

    return SizedBox(
      width: double.infinity,
      height: _mainButtonHeight(height),
      child: DecoratedBox(
        //Shadow start
        decoration: BoxDecoration(
          color: isDisabled ? _disabledButtonColor : null,
          gradient: isDisabled ? null : activeGradient,
          borderRadius: BorderRadius.circular(_mainButtonRadius(width)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: isDisabled ? _disabledButtonShadowColor : activeShadowColor,
              blurRadius: width * 0.06,
              offset: Offset(0, height * 0.016),
            ),
          ],
        ),
        //Shadow end
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (_isRegisterActionLoading || isDisabled)
                ? null
                : _onRegisterTogglePressed,
            borderRadius: BorderRadius.circular(_mainButtonRadius(width)),
            child: Center(
              child: Text(
                buttonText,
                style: _buttonTextStyle(width),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Attendance container
  Widget _attendanceContainer({
    required double width,
    required double height,
  }) {
    final int attendancePercent =
        (_calculatedAttendanceValue.clamp(0, 1) * 100).round();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: _cardInnerHorizontalPadding(width),
        vertical: _cardInnerVerticalPadding(height),
      ),
      decoration: BoxDecoration(
        color: _cardBackgroundColor,
        borderRadius: BorderRadius.circular(_cardRadius(width)),
        border: Border.all(
          color: _cardBorderColor,
          width: width * 0.0025,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _cardShadowColor,
            blurRadius: width * 0.05,
            offset: Offset(0, height * 0.012),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Attendance',
              style: _sectionCardTitleTextStyle(width),
            ),
          ),
          SizedBox(height: _sectionSpacingLarge(height)),
          SizedBox(
            width: _attendanceCircleSize(width),
            height: _attendanceCircleSize(width),
            child: _isAttendanceLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: _attendanceCircleSize(width),
                        height: _attendanceCircleSize(width),
                        child: CircularProgressIndicator(
                          value: _calculatedAttendanceValue.clamp(0, 1),
                          strokeWidth: _attendanceStrokeWidth(width),
                          backgroundColor: _attendanceBackgroundColor,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_progressFillColor),
                        ),
                      ),
                      Text(
                        '$attendancePercent%',
                        style: _attendancePercentTextStyle(width),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // Progress track container
  Widget _progressTrackContainer({
    required double width,
    required double height,
  }) {
    final int progressPercent =
        (_calculatedProgressValue.clamp(0, 1) * 100).round();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: _cardInnerHorizontalPadding(width),
        vertical: _cardInnerVerticalPadding(height),
      ),
      decoration: BoxDecoration(
        color: _cardBackgroundColor,
        borderRadius: BorderRadius.circular(_cardRadius(width)),
        border: Border.all(
          color: _cardBorderColor,
          width: width * 0.0025,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _cardShadowColor,
            blurRadius: width * 0.05,
            offset: Offset(0, height * 0.012),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Progress track',
                  style: _sectionCardTitleTextStyle(width),
                ),
              ),
              _isProgressLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      '$progressPercent%',
                      style: _progressPercentTextStyle(width),
                    ),
            ],
          ),
          SizedBox(height: _sectionSpacingMedium(height)),
          ClipRRect(
            borderRadius: BorderRadius.circular(_progressBarRadius(width)),
            child: LinearProgressIndicator(
              value: _isProgressLoading
                  ? 0
                  : _calculatedProgressValue.clamp(0, 1),
              minHeight: _progressBarHeight(height),
              backgroundColor: _progressBackgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(_progressFillColor),
            ),
          ),
        ],
      ),
    );
  }
}