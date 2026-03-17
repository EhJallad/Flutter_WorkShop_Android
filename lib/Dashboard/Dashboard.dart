import 'package:flutter/material.dart';
import 'package:training_hub/Dashboard/Instructor/instructor_course.dart';
import 'package:training_hub/navbar_general.dart';
import 'package:training_hub/Dashboard/Student/student_Course.dart';
import 'package:training_hub/Dashboard/Student/Courses_samples.dart';

import 'package:get_x/get.dart';
import 'package:training_hub/auth_service.dart';
import 'package:training_hub/database_management.dart';
import 'package:training_hub/Dashboard/Instructor/CourseAdd.dart';

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

// Simple model for each dashboard course
class DashboardCourseData {
  const DashboardCourseData({
    required this.courseId,
    required this.imagePath,
    required this.courseName,
    required this.shortDescription,
    required this.instructorName,
    required this.availableSeatsText,
    required this.isRegistered,
    required this.progressValue,
    required this.attendanceValue,
    required this.isOpen,
  });

  final String courseId;
  final String imagePath;
  final String courseName;
  final String shortDescription;
  final String instructorName;
  final String availableSeatsText;
  final bool isRegistered;
  final double progressValue;
  final double attendanceValue;
  final bool isOpen;
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // Firebase authentication service
  final Auth _auth = Auth();

  // Firestore database service
  final DatabaseManagement _databaseManagement = DatabaseManagement();

  // Firestore instance for courses loading
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current account type loaded from Firestore
  String _accountType = 'student';

  // Tracks whether account type is still loading
  bool _isLoadingAccountType = true;

  // Tracks whether courses are still loading
  bool _isLoadingCourses = true;

  // Real courses loaded from Firestore
  List<DashboardCourseData> _realCourses = <DashboardCourseData>[];

  @override
  void initState() {
    super.initState();
    _loadAccountTypeAndCourses();
  }

  // Returns true if account type is instructor/teacher
  bool _isInstructorAccount(String accountType) {
    final String normalizedType = accountType.trim().toLowerCase();
    return normalizedType == 'instructor' || normalizedType == 'teacher';
  }

  // Loads the current user's account type and courses from Firestore
  Future<void> _loadAccountTypeAndCourses() async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          _accountType = 'student';
          _isLoadingAccountType = false;
        });

        await _loadCourses();
        return;
      }

      final userDocument = await _databaseManagement.getUserData(
        uid: currentUser.uid,
      );

      final Map<String, dynamic>? data = userDocument.data();

      final String rawAccountType =
          (data?['accountType'] as String?)?.trim().toLowerCase() ?? 'student';

      final String resolvedAccountType =
          _isInstructorAccount(rawAccountType) ? 'instructor' : 'student';

      if (!mounted) {
        return;
      }

      setState(() {
        _accountType = resolvedAccountType;
        _isLoadingAccountType = false;
      });

      await _loadCourses();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _accountType = 'student';
        _isLoadingAccountType = false;
      });

      await _loadCourses();
    }
  }

  // Loads courses from Firestore based on account type
  Future<void> _loadCourses() async {
    try {
      final currentUser = _auth.currentUser;

      Query<Map<String, dynamic>> coursesQuery =
          _firestore.collection('courses');

      if (_accountType == 'instructor' && currentUser != null) {
        coursesQuery = coursesQuery.where(
          'instructorId',
          isEqualTo: currentUser.uid,
        );
      }

      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await coursesQuery.get();

      final List<DashboardCourseData> loadedCourses = querySnapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> document) =>
                _mapFirestoreCourseToDashboardCourse(
              document.data(),
            ),
          )
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _realCourses = loadedCourses;
        _isLoadingCourses = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _realCourses = <DashboardCourseData>[];
        _isLoadingCourses = false;
      });
    }
  }

  // Maps Firestore course document to dashboard model
  DashboardCourseData _mapFirestoreCourseToDashboardCourse(
    Map<String, dynamic> data,
  ) {
    final String courseName =
        (data['courseTitle'] as String?)?.trim().isNotEmpty == true
            ? (data['courseTitle'] as String).trim()
            : ((data['title'] as String?)?.trim() ?? 'Untitled Course');

    final String courseDescription =
        (data['courseDescription'] as String?)?.trim().isNotEmpty == true
            ? (data['courseDescription'] as String).trim()
            : ((data['description'] as String?)?.trim() ??
                'No description available.');

    final String instructorName =
        (data['instructorName'] as String?)?.trim().isNotEmpty == true
            ? (data['instructorName'] as String).trim()
            : 'Unknown Instructor';

    final int maxStudentsAllowed =
        (data['maxStudentsAllowed'] as num?)?.toInt() ?? 0;

    final List<dynamic> registeredStudentIds =
        (data['registeredStudentIds'] as List<dynamic>?) ?? <dynamic>[];

    final int registeredCount = registeredStudentIds.length;
    final int availableSeats = maxStudentsAllowed - registeredCount;

    final bool isOpen = (data['isOpen'] as bool?) ?? true;

    final String courseImagePath =
        (data['courseImagePath'] as String?)?.trim().isNotEmpty == true
            ? (data['courseImagePath'] as String).trim()
            : 'Pictures/Login.jpg';

  return DashboardCourseData(
  courseId: (data['courseId'] as String?)?.trim() ?? '',
  imagePath: courseImagePath,
  courseName: courseName,
  shortDescription: courseDescription,
  instructorName: instructorName,
  availableSeatsText: availableSeats < 0
      ? '0'
      : availableSeats.toString(),
  isRegistered: _accountType == 'instructor'
      ? true
      : _isCurrentStudentRegistered(registeredStudentIds),
  progressValue: 0,
  attendanceValue: 0,
  isOpen: isOpen,
);
  }

  // Checks if current student is registered inside course
  bool _isCurrentStudentRegistered(List<dynamic> registeredStudentIds) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return false;
    }

    return registeredStudentIds.contains(currentUser.uid);
  }

  // Dashboard title based on account type
  String _dashboardSectionTitle() {
    if (_isLoadingAccountType) {
      return 'Available Workshops';
    }

    if (_accountType == 'instructor') {
      return 'Your Teaching Workshops';
    }

    return 'Available Workshops';
  }

  // Dashboard subtitle based on account type
  String _dashboardSectionSubtitle() {
    if (_isLoadingAccountType) {
      return 'Explore your courses and continue your learning progress.';
    }

    if (_accountType == 'instructor') {
      return 'Manage your workshops and follow your teaching activity.';
    }

    return 'Explore your courses and continue your learning progress.';
  }

  // Courses shown based on account type
  List<DashboardCourseData> _dashboardCourses() {
    if (_accountType == 'instructor') {
      // Teacher/instructor sees only their own real courses
      return _realCourses;
    }

    // Student sees sample courses + all real courses from any instructor
    return <DashboardCourseData>[
      ...dashboardCoursesSamples,
      ..._realCourses,
    ];
  }

  // Whether instructor floating add button should be shown
  bool _showInstructorAddButton() {
    return !_isLoadingAccountType && _accountType == 'instructor';
  }

  // Opens add course page
  void _onAddCoursePressed() async {
    await Get.to(
      () => const CourseAdd(),
      transition: Transition.fade,
      duration: const Duration(milliseconds: 200),
    );

    await _loadCourses();
  }

  @override
  Widget build(BuildContext context) {
    final List<DashboardCourseData> courses = _dashboardCourses();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: <Widget>[
          const NavBarGeneral(
            title: 'Training Dashboard',
          ),
          Expanded(
            child: DashboardBody(
              courses: courses,
              sectionTitle: _dashboardSectionTitle(),
              sectionSubtitle: _dashboardSectionSubtitle(),
              isInstructor: _accountType == 'instructor',
              isLoadingAccountType: _isLoadingAccountType,
              isLoadingCourses: _isLoadingCourses,
            ),
          ),
        ],
      ),
      floatingActionButton: _showInstructorAddButton()
          ? FloatingActionButton(
              onPressed: _onAddCoursePressed,
              backgroundColor: const Color(0xFF4D84DB),
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}

// Main body under the navbar
class DashboardBody extends StatelessWidget {
  const DashboardBody({
    super.key,
    required this.courses,
    required this.sectionTitle,
    required this.sectionSubtitle,
    required this.isInstructor,
    required this.isLoadingAccountType,
    required this.isLoadingCourses,
  });

  final List<DashboardCourseData> courses;
  final String sectionTitle;
  final String sectionSubtitle;
  final bool isInstructor;
  final bool isLoadingAccountType;
  final bool isLoadingCourses;

  // Checks if screen is tablet size
  bool _isTablet(double width) => width >= 600;

  // Horizontal page padding
  double _pageHorizontalPadding(double width) {
    return _isTablet(width) ? width * 0.045 : width * 0.05;
  }

  // Top page padding
  double _pageTopPadding(double height) {
    return height * 0.02;
  }

  // Bottom page padding
  double _pageBottomPadding(double height) {
    return height * 0.03;
  }

  // Space between course cards
  double _coursesSpacing(double height) {
    return height * 0.022;
  }

  // Small page title font size
  double _sectionTitleFontSize(double width) {
    return _isTablet(width) ? width * 0.028 : width * 0.05;
  }

  // Small page subtitle font size
  double _sectionSubtitleFontSize(double width) {
    return _isTablet(width) ? width * 0.018 : width * 0.032;
  }

  // Empty state title font size
  double _emptyStateTitleFontSize(double width) {
    return _isTablet(width) ? width * 0.022 : width * 0.04;
  }

  // Empty state subtitle font size
  double _emptyStateSubtitleFontSize(double width) {
    return _isTablet(width) ? width * 0.017 : width * 0.03;
  }

  // Primary text color
  Color get _primaryTextColor => const Color(0xFF0F203D);

  // Secondary text color
  Color get _secondaryTextColor => const Color(0xFF8A8A8A);

  Widget _emptyState(double screenWidth, double screenHeight) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.menu_book_outlined,
              size: _isTablet(screenWidth)
                  ? screenWidth * 0.07
                  : screenWidth * 0.12,
              color: _secondaryTextColor,
            ),
            SizedBox(height: screenHeight * 0.016),
            Text(
              isInstructor ? 'No courses yet' : 'No workshops available',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _primaryTextColor,
                fontSize: _emptyStateTitleFontSize(screenWidth),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: screenHeight * 0.008),
            Text(
              isInstructor
                  ? 'Tap the + button to add your first course.'
                  : 'Check back later for available workshops.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: _emptyStateSubtitleFontSize(screenWidth),
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double screenWidth = constraints.maxWidth;
        final double screenHeight = constraints.maxHeight;

        return Padding(
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
                sectionTitle,
                style: TextStyle(
                  color: _primaryTextColor,
                  fontSize: _sectionTitleFontSize(screenWidth),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: screenHeight * 0.006),
              Text(
                sectionSubtitle,
                style: TextStyle(
                  color: _secondaryTextColor,
                  fontSize: _sectionSubtitleFontSize(screenWidth),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: screenHeight * 0.024),
              Expanded(
                child: isLoadingAccountType || isLoadingCourses
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : courses.isEmpty
                        ? _emptyState(screenWidth, screenHeight)
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: courses.length,
                            separatorBuilder: (BuildContext context, int index) {
                              return SizedBox(
                                height: _coursesSpacing(screenHeight),
                              );
                            },
                            itemBuilder: (BuildContext context, int index) {
                              return Dashboard_course(
                                courseData: courses[index],
                                screenWidth: screenWidth,
                                availableHeight: screenHeight,
                                isInstructorView: isInstructor,
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Single reusable course card
class Dashboard_course extends StatelessWidget {
  const Dashboard_course({
    super.key,
    required this.courseData,
    required this.screenWidth,
    required this.availableHeight,
    required this.isInstructorView,
  });

  final DashboardCourseData courseData;
  final double screenWidth;
  final double availableHeight;
  final bool isInstructorView;

  void _openWorkShopPage(BuildContext context) {
  Get.to(
    () => isInstructorView
        ? InstructorCourse(
             courseData: courseData,
          )
        : StudentCourse(
            courseData: courseData,
          ),
    transition: Transition.fade,
    duration: const Duration(milliseconds: 200),
  );
}
  // Checks if screen is tablet size
  bool _isTablet() => screenWidth >= 600;

  // Card border radius
  double _cardBorderRadius() {
    return screenWidth * 0.05;
  }

  // Card padding
  double _cardHorizontalPadding() {
    return _isTablet() ? screenWidth * 0.028 : screenWidth * 0.04;
  }

  double _cardVerticalPadding() {
    return availableHeight * 0.02;
  }

  // Course image size
  double _imageWidth() {
    return _isTablet() ? screenWidth * 0.17 : screenWidth * 0.24;
  }

  double _imageHeight() {
    return _isTablet() ? availableHeight * 0.16 : availableHeight * 0.135;
  }

  // Card shadow values
  double _cardShadowBlur() {
    return screenWidth * 0.05;
  }

  double _cardShadowOffset() {
    return availableHeight * 0.012;
  }

  // Text sizes
  double _courseTitleFontSize() {
    return _isTablet() ? screenWidth * 0.023 : screenWidth * 0.041;
  }

  double _descriptionFontSize() {
    return _isTablet() ? screenWidth * 0.016 : screenWidth * 0.029;
  }

  double _instructorFontSize() {
    return _isTablet() ? screenWidth * 0.016 : screenWidth * 0.03;
  }

  double _seatTextFontSize() {
    return _isTablet() ? screenWidth * 0.0155 : screenWidth * 0.028;
  }

  double _registerTextFontSize() {
    return _isTablet() ? screenWidth * 0.0165 : screenWidth * 0.029;
  }

  double _progressTextFontSize() {
    return _isTablet() ? screenWidth * 0.0145 : screenWidth * 0.026;
  }

  // Inner spacing
  double _topRowSpacing() {
    return _isTablet() ? screenWidth * 0.025 : screenWidth * 0.03;
  }

  double _smallSpacing() {
    return availableHeight * 0.008;
  }

  double _mediumSpacing() {
    return availableHeight * 0.014;
  }

  // Seat container values
  double _seatContainerHeight() {
    return availableHeight * 0.045;
  }

  double _seatContainerRadius() {
    return screenWidth * 0.03;
  }

  double _seatIconSize() {
    return _isTablet() ? screenWidth * 0.024 : screenWidth * 0.042;
  }

  // Register button values
  double _registerContainerHeight() {
    return availableHeight * 0.05;
  }

  double _registerContainerWidth() {
    return _isTablet() ? screenWidth * 0.16 : screenWidth * 0.24;
  }

  double _registerContainerRadius() {
    return screenWidth * 0.033;
  }

  // Progress section values
  double _progressBarHeight() {
    return availableHeight * 0.016;
  }

  double _progressBarRadius() {
    return screenWidth * 0.03;
  }

  // Colors
  Color get _cardBackgroundColor => Colors.white;
  Color get _cardBorderColor => const Color(0xFFE9EDF2);
  Color get _cardShadowColor => const Color(0x12000000);
  Color get _primaryTextColor => const Color(0xFF0F203D);
  Color get _secondaryTextColor => const Color(0xFF8A8A8A);
  Color get _chipBackgroundColor => const Color(0xFFF4F7FB);
  Color get _chipBorderColor => const Color(0xFFD8E1EB);
  Color get _iconColor => const Color(0xFF20303D);
  Color get _registerBackgroundColor => const Color(0xFFE95B5B);
  Color get _registerTextColor => Colors.white;
  Color get _progressBackgroundColor => const Color(0xFFF0D7D7);
  Color get _progressFillColor => const Color(0xFFE95B5B);
  Color get _progressLabelColor => const Color(0xFFB13D3D);

  // Course title style
  TextStyle _courseTitleTextStyle() {
    return TextStyle(
      color: _primaryTextColor,
      fontSize: _courseTitleFontSize(),
      fontWeight: FontWeight.w800,
      height: 1.15,
    );
  }

  // Course description style
  TextStyle _descriptionTextStyle() {
    return TextStyle(
      color: _secondaryTextColor,
      fontSize: _descriptionFontSize(),
      fontWeight: FontWeight.w500,
      height: 1.35,
    );
  }

  // Instructor text style
  TextStyle _instructorTextStyle() {
    return TextStyle(
      color: _primaryTextColor.withOpacity(0.92),
      fontSize: _instructorFontSize(),
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
  }

  // Seats text style
  TextStyle _seatTextStyle() {
    return TextStyle(
      color: _primaryTextColor,
      fontSize: _seatTextFontSize(),
      fontWeight: FontWeight.w700,
    );
  }

  // Register text style
  TextStyle _registerTextStyle() {
    return TextStyle(
      color: _registerTextColor,
      fontSize: _registerTextFontSize(),
      fontWeight: FontWeight.w700,
    );
  }

  // Progress label text style
  TextStyle _progressTextStyle() {
    return TextStyle(
      color: _progressLabelColor,
      fontSize: _progressTextFontSize(),
      fontWeight: FontWeight.w700,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double cardRadius = _cardBorderRadius();

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _openWorkShopPage(context);
          },
          borderRadius: BorderRadius.circular(cardRadius),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: _cardHorizontalPadding(),
              vertical: _cardVerticalPadding(),
            ),
            decoration: BoxDecoration(
              color: _cardBackgroundColor,
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(
                color: _cardBorderColor,
                width: screenWidth * 0.0025,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: _cardShadowColor,
                  blurRadius: _cardShadowBlur(),
                  offset: Offset(0, _cardShadowOffset()),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _courseImage(),
                SizedBox(width: _topRowSpacing()),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _courseTitle(),
                      SizedBox(height: _smallSpacing()),
                      _courseDescription(),
                      SizedBox(height: _mediumSpacing()),
                      _instructorName(),
                      SizedBox(height: _mediumSpacing()),
                      _bottomInfoSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Course image widget
Widget _courseImage() {
  final String imagePath = courseData.imagePath.trim();

  Widget imageWidget;

  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    imageWidget = Image.network(
      imagePath,
      width: _imageWidth(),
      height: _imageHeight(),
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) {
        return _imageFallback();
      },
    );
  } else if (imagePath.startsWith('/')) {
    imageWidget = Image.file(
      File(imagePath),
      width: _imageWidth(),
      height: _imageHeight(),
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) {
        return _imageFallback();
      },
    );
  } else {
    imageWidget = Image.asset(
      imagePath,
      width: _imageWidth(),
      height: _imageHeight(),
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) {
        return _imageFallback();
      },
    );
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(_cardBorderRadius() * 0.7),
    child: imageWidget,
  );
}

Widget _imageFallback() {
  return Container(
    width: _imageWidth(),
    height: _imageHeight(),
    color: const Color(0xFFE9EDF2),
    alignment: Alignment.center,
    child: Icon(
      Icons.image_not_supported_outlined,
      color: const Color(0xFF8A8A8A),
      size: _isTablet() ? screenWidth * 0.04 : screenWidth * 0.07,
    ),
  );
}



  // Course title widget
  Widget _courseTitle() {
    return Text(
      courseData.courseName,
      style: _courseTitleTextStyle(),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Course description widget
  Widget _courseDescription() {
    return Text(
      courseData.shortDescription,
      style: _descriptionTextStyle(),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Instructor name widget
Widget _instructorName() {
  return Text(
    'Instructor: ${courseData.instructorName}',
    style: _instructorTextStyle(),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

  // Bottom section that contains seats + register state
  Widget _bottomInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _seatsContainer(),
        SizedBox(height: _mediumSpacing()),
        isInstructorView
            ? _progressSection()
            : (courseData.isRegistered
                ? _progressSection()
                : _registerContainer()),
      ],
    );
  }

  // Seats container widget
  Widget _seatsContainer() {
    return Container(
      height: _seatContainerHeight(),
      padding: EdgeInsets.symmetric(
        horizontal: _isTablet() ? screenWidth * 0.018 : screenWidth * 0.03,
      ),
      decoration: BoxDecoration(
        color: _chipBackgroundColor,
        borderRadius: BorderRadius.circular(_seatContainerRadius()),
        border: Border.all(
          color: _chipBorderColor,
          width: screenWidth * 0.0022,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.event_seat_outlined,
            color: _iconColor,
            size: _seatIconSize(),
          ),
          SizedBox(width: screenWidth * 0.015),
          Text(
            "${courseData.availableSeatsText} seats",
            style: _seatTextStyle(),
          ),
        ],
      ),
    );
  }

  // Register widget when user is not registered
  Widget _registerContainer() {
    return Container(
      width: _registerContainerWidth(),
      height: _registerContainerHeight(),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _registerBackgroundColor,
        borderRadius: BorderRadius.circular(_registerContainerRadius()),
      ),
      child: Text(
        'Register',
        style: _registerTextStyle(),
      ),
    );
  }

  // Progress widget when user is already registered
  Widget _progressSection() {
    final int progressPercent = (courseData.progressValue * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          isInstructorView
              ? 'Course progress • $progressPercent% completed'
              : 'Registered • $progressPercent% completed',
          style: _progressTextStyle(),
        ),
        SizedBox(height: _smallSpacing()),
        ClipRRect(
          borderRadius: BorderRadius.circular(_progressBarRadius()),
          child: LinearProgressIndicator(
            value: courseData.progressValue.clamp(0, 1),
            minHeight: _progressBarHeight(),
            backgroundColor: _progressBackgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(_progressFillColor),
          ),
        ),
      ],
    );
  }
}