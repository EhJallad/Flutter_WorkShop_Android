import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:training_hub/navbar_general.dart';
import 'package:training_hub/Dashboard/Dashboard.dart';
import 'package:training_hub/Dashboard/Instructor/Tab_Students/students_tab_samples.dart';

class StudentInfo extends StatefulWidget {
  const StudentInfo({
    super.key,
    required this.studentData,
    required this.courseData,
  });

  final CourseStudentData studentData;
  final DashboardCourseData courseData;

  @override
  State<StudentInfo> createState() => _StudentInfoState();
}

class _StudentInfoState extends State<StudentInfo> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoadingPage = true;

  String _fullName = '';
  String _email = '';
  String _phoneNumber = '';

  List<String> _joinedCourses = <String>[];
  List<Map<String, dynamic>> _courseMilestones = <Map<String, dynamic>>[];

  final Map<String, String?> _selectedAttendanceValues = <String, String?>{};
  final Map<String, bool> _isConfirmingMilestone = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _loadStudentInfoPage();
  }

  Future<void> _loadStudentInfoPage() async {
    try {
      await _loadStudentBasicInfo();
      await _loadJoinedCourses();
      await _loadCourseMilestonesAndAttendance();

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingPage = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingPage = false;
      });
    }
  }

  Future<void> _loadStudentBasicInfo() async {
    if (widget.studentData.studentId.startsWith('sample_')) {
      setState(() {
        _fullName = widget.studentData.studentName;
        _email = 'sample@student.com';
        _phoneNumber = '+962700000000';
      });
      return;
    }

    final DocumentSnapshot<Map<String, dynamic>> userDocument =
        await _firestore.collection('users').doc(widget.studentData.studentId).get();

    final Map<String, dynamic>? userData = userDocument.data();

    setState(() {
      _fullName =
          (userData?['fullName'] as String?)?.trim() ?? widget.studentData.studentName;
      _email = (userData?['email'] as String?)?.trim() ?? 'No email found';
      _phoneNumber =
          (userData?['phoneNumber'] as String?)?.trim() ?? 'No phone number found';
    });
  }

  Future<void> _loadJoinedCourses() async {
    if (widget.studentData.studentId.startsWith('sample_')) {
      setState(() {
        _joinedCourses = <String>[
          widget.courseData.courseName,
        ];
      });
      return;
    }

    final QuerySnapshot<Map<String, dynamic>> joinedCoursesSnapshot =
        await _firestore
            .collection('courses')
            .where(
              'registeredStudentIds',
              arrayContains: widget.studentData.studentId,
            )
            .get();

    final List<String> courseTitles = joinedCoursesSnapshot.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> document) {
            final Map<String, dynamic> data = document.data();

            final String courseTitle =
                (data['courseTitle'] as String?)?.trim().isNotEmpty == true
                    ? (data['courseTitle'] as String).trim()
                    : ((data['title'] as String?)?.trim() ?? 'Untitled Course');

            return courseTitle;
          },
        )
        .toList();

    setState(() {
      _joinedCourses = courseTitles;
    });
  }

  Future<void> _loadCourseMilestonesAndAttendance() async {
    if (widget.courseData.courseId.trim().isEmpty) {
      return;
    }

    final DocumentSnapshot<Map<String, dynamic>> courseDocument =
        await _firestore.collection('courses').doc(widget.courseData.courseId).get();

    final Map<String, dynamic>? courseData = courseDocument.data();

    final List<dynamic> milestones =
        (courseData?['milestones'] as List<dynamic>?) ?? <dynamic>[];

    final DocumentSnapshot<Map<String, dynamic>> attendanceDocument =
        await _firestore
            .collection('courses')
            .doc(widget.courseData.courseId)
            .collection('studentAttendance')
            .doc(widget.studentData.studentId)
            .get();

    final Map<String, dynamic>? attendanceData = attendanceDocument.data();
    final Map<String, dynamic> milestoneStatuses =
        (attendanceData?['milestoneStatuses'] as Map<String, dynamic>?) ??
            <String, dynamic>{};

    final List<Map<String, dynamic>> loadedMilestones = milestones
        .map(
          (dynamic milestone) => Map<String, dynamic>.from(
            milestone as Map<String, dynamic>,
          ),
        )
        .toList();

    setState(() {
      _courseMilestones = loadedMilestones;

      for (final Map<String, dynamic> milestone in _courseMilestones) {
        final String milestoneId =
            (milestone['milestoneId'] as String?)?.trim() ?? '';
        final String? storedValue = milestoneStatuses[milestoneId] as String?;

        _selectedAttendanceValues[milestoneId] = storedValue ?? 'Choose';
        _isConfirmingMilestone[milestoneId] = false;
      }
    });
  }

  Future<void> _confirmAttendanceForMilestone({
    required String milestoneId,
  }) async {
    final String selectedValue =
        (_selectedAttendanceValues[milestoneId] ?? 'Choose').trim();

    if (selectedValue.isEmpty || selectedValue == 'Choose') {
      return;
    }

    if (_isConfirmingMilestone[milestoneId] == true) {
      return;
    }

    if (widget.courseData.courseId.trim().isEmpty) {
      return;
    }

    setState(() {
      _isConfirmingMilestone[milestoneId] = true;
    });

    try {
      await _firestore
          .collection('courses')
          .doc(widget.courseData.courseId)
          .collection('studentAttendance')
          .doc(widget.studentData.studentId)
          .set(
        <String, dynamic>{
          'studentId': widget.studentData.studentId,
          'studentName': widget.studentData.studentName,
          'courseId': widget.courseData.courseId,
          'courseName': widget.courseData.courseName,
          'milestoneStatuses': <String, dynamic>{
            milestoneId: selectedValue,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Attendance updated successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Failed to update attendance.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isConfirmingMilestone[milestoneId] = false;
      });
    }
  }

  bool _isTablet(double width) => width >= 600;

  double _pageHorizontalPadding(double width) {
    return _isTablet(width) ? width * 0.045 : width * 0.05;
  }

  double _pageTopPadding(double height) {
    return height * 0.02;
  }

  double _pageBottomPadding(double height) {
    return height * 0.03;
  }

  double _sectionSpacingLarge(double height) {
    return height * 0.024;
  }

  double _sectionSpacingMedium(double height) {
    return height * 0.018;
  }

  double _sectionSpacingSmall(double height) {
    return height * 0.01;
  }

  double _cardRadius(double width) {
    return width * 0.05;
  }

  double _cardInnerHorizontalPadding(double width) {
    return _isTablet(width) ? width * 0.035 : width * 0.045;
  }

  double _cardInnerVerticalPadding(double height) {
    return height * 0.022;
  }

  double _titleFontSize(double width) {
    return _isTablet(width) ? width * 0.032 : width * 0.055;
  }

  double _labelFontSize(double width) {
    return _isTablet(width) ? width * 0.018 : width * 0.032;
  }

  double _valueFontSize(double width) {
    return _isTablet(width) ? width * 0.019 : width * 0.033;
  }

  double _sectionTitleFontSize(double width) {
    return _isTablet(width) ? width * 0.021 : width * 0.038;
  }

  double _milestoneNameFontSize(double width) {
    return _isTablet(width) ? width * 0.0155 : width * 0.027;
  }

  double _dropdownTextFontSize(double width) {
    return _isTablet(width) ? width * 0.015 : width * 0.026;
  }

  double _confirmButtonHeight(double height) {
    return height * 0.05;
  }

  double _confirmButtonWidth(double width) {
    return _isTablet(width) ? width * 0.16 : width * 0.29;
  }

  double _confirmButtonRadius(double width) {
    return width * 0.03;
  }

  double _buttonTextFontSize({
    required double width,
    required double height,
  }) {
    final double fontSizeFromWidth =
        _isTablet(width) ? width * 0.0145 : width * 0.024;
    final double fontSizeFromHeight = _confirmButtonHeight(height) * 0.34;

    return fontSizeFromWidth < fontSizeFromHeight
        ? fontSizeFromWidth
        : fontSizeFromHeight;
  }

  Color get _pageBackgroundColor => Colors.white;
  Color get _cardBackgroundColor => Colors.white;
  Color get _cardBorderColor => const Color(0xFFE9EDF2);
  Color get _cardShadowColor => const Color(0x12000000);
  Color get _primaryTextColor => const Color(0xFF0F203D);
  Color get _secondaryTextColor => const Color(0xFF8A8A8A);
  Color get _greenColor => const Color(0xFF33B679);
  Color get _lightBorderColor => const Color(0xFFD8E1EB);
  Color get _disabledButtonColor => const Color(0xFFBFC5CE);

  TextStyle _titleTextStyle(double width) {
    return TextStyle(
      color: _primaryTextColor,
      fontSize: _titleFontSize(width),
      fontWeight: FontWeight.w800,
      height: 1.15,
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

  TextStyle _sectionCardTitleTextStyle(double width) {
    return TextStyle(
      color: _primaryTextColor,
      fontSize: _sectionTitleFontSize(width),
      fontWeight: FontWeight.w800,
    );
  }

  TextStyle _milestoneNameTextStyle(double width) {
    return TextStyle(
      color: _primaryTextColor,
      fontSize: _milestoneNameFontSize(width),
      fontWeight: FontWeight.w600,
      height: 1.25,
    );
  }

  TextStyle _dropdownTextStyle(double width) {
    return TextStyle(
      color: _primaryTextColor,
      fontSize: _dropdownTextFontSize(width),
      fontWeight: FontWeight.w500,
    );
  }

  TextStyle _confirmButtonTextStyle({
    required double width,
    required double height,
  }) {
    return TextStyle(
      color: Colors.white,
      fontSize: _buttonTextFontSize(
        width: width,
        height: height,
      ),
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
            title: widget.studentData.studentName,
            showBackButton: true,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double screenWidth = constraints.maxWidth;
                final double screenHeight = constraints.maxHeight;

                if (_isLoadingPage) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

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
                      Text(
                        _fullName.isEmpty ? widget.studentData.studentName : _fullName,
                        style: _titleTextStyle(screenWidth),
                      ),
                      SizedBox(height: _sectionSpacingLarge(screenHeight)),
                      _infoLine(
                        width: screenWidth,
                        label: 'Full Name',
                        value: _fullName.isEmpty ? widget.studentData.studentName : _fullName,
                      ),
                      SizedBox(height: _sectionSpacingMedium(screenHeight)),
                      _infoLine(
                        width: screenWidth,
                        label: 'Email',
                        value: _email,
                      ),
                      SizedBox(height: _sectionSpacingMedium(screenHeight)),
                      _infoLine(
                        width: screenWidth,
                        label: 'Phone number',
                        value: _phoneNumber,
                      ),
                      SizedBox(height: _sectionSpacingLarge(screenHeight)),
                      _joinedCoursesContainer(
                        width: screenWidth,
                        height: screenHeight,
                      ),
                      SizedBox(height: _sectionSpacingLarge(screenHeight)),
                      _attendanceContainer(
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

  Widget _joinedCoursesContainer({
    required double width,
    required double height,
  }) {
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
          Text(
            'All courses joined',
            style: _sectionCardTitleTextStyle(width),
          ),
          SizedBox(height: _sectionSpacingMedium(height)),
          if (_joinedCourses.isEmpty)
            Text(
              'No courses found.',
              style: _labelTextStyle(width),
            )
          else
            ...List<Widget>.generate(
              _joinedCourses.length,
              (int index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index == _joinedCourses.length - 1
                      ? 0
                      : _sectionSpacingSmall(height),
                ),
                child: Text(
                  '• ${_joinedCourses[index]}',
                  style: _valueTextStyle(width),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _attendanceContainer({
    required double width,
    required double height,
  }) {
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
          Text(
            'Attendence',
            style: _sectionCardTitleTextStyle(width),
          ),
          SizedBox(height: _sectionSpacingMedium(height)),
          if (_courseMilestones.isEmpty)
            Text(
              'No milestones found for this course.',
              style: _labelTextStyle(width),
            )
          else
            ...List<Widget>.generate(
              _courseMilestones.length,
              (int index) {
                final Map<String, dynamic> milestone = _courseMilestones[index];
                final String milestoneId =
                    (milestone['milestoneId'] as String?)?.trim() ?? '';
                final String milestoneName =
                    (milestone['milestoneName'] as String?)?.trim() ??
                        'Unnamed Milestone';

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == _courseMilestones.length - 1
                        ? 0
                        : _sectionSpacingMedium(height),
                  ),
                  child: _milestoneAttendanceRow(
                    width: width,
                    height: height,
                    milestoneId: milestoneId,
                    milestoneName: milestoneName,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _milestoneAttendanceRow({
    required double width,
    required double height,
    required String milestoneId,
    required String milestoneName,
  }) {
    final String selectedValue =
        (_selectedAttendanceValues[milestoneId] ?? 'Choose').trim();
    final bool isConfirming = _isConfirmingMilestone[milestoneId] ?? false;
    final bool isButtonEnabled = selectedValue != 'Choose';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          milestoneName,
          style: _milestoneNameTextStyle(width),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: _sectionSpacingSmall(height)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Container(
                height: _confirmButtonHeight(height),
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.03,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(width * 0.035),
                  border: Border.all(
                    color: _lightBorderColor,
                    width: width * 0.0025,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedValue,
                    isExpanded: true,
                    hint: Text(
                      'Choose',
                      style: _labelTextStyle(width).copyWith(
                        fontSize: _dropdownTextFontSize(width),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: _dropdownTextStyle(width),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: 'Choose',
                        child: Text(
                          'Choose',
                          style: _dropdownTextStyle(width),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Attended',
                        child: Text(
                          'Attended',
                          style: _dropdownTextStyle(width),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Did not attend',
                        child: Text(
                          'Did not attend',
                          style: _dropdownTextStyle(width),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: (String? value) {
                      setState(() {
                        _selectedAttendanceValues[milestoneId] = value ?? 'Choose';
                      });
                    },
                  ),
                ),
              ),
            ),
            SizedBox(width: width * 0.025),
            SizedBox(
              width: _confirmButtonWidth(width),
              height: _confirmButtonHeight(height),
              child: ElevatedButton(
                onPressed: isButtonEnabled
                    ? () {
                        _confirmAttendanceForMilestone(
                          milestoneId: milestoneId,
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isButtonEnabled ? _greenColor : _disabledButtonColor,
                  disabledBackgroundColor: _disabledButtonColor,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      _confirmButtonRadius(width),
                    ),
                  ),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.018,
                      ),
                      child: Text(
                        isConfirming ? '...' : 'Confirm',
                        style: _confirmButtonTextStyle(
                          width: width,
                          height: height,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}