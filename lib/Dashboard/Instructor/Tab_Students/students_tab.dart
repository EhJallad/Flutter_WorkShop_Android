import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:training_hub/Dashboard/Dashboard.dart';
import 'package:training_hub/Dashboard/Instructor/Tab_Students/students_tab_samples.dart';
import 'package:training_hub/Dashboard/Instructor/Tab_Students/student_info.dart';

// Students tab page for one specific course
class StudentsTab extends StatefulWidget {
  const StudentsTab({
    super.key,
    required this.courseData,
  });

  final DashboardCourseData courseData;

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Loading state
  bool _isLoadingStudents = true;

  // Loaded students
  List<CourseStudentData> _students = <CourseStudentData>[];

  @override
  void initState() {
    super.initState();
    _loadRegisteredStudents();
  }

  // Loads students registered for this specific course only
  Future<void> _loadRegisteredStudents() async {
    try {
      if (widget.courseData.courseId.trim().isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          _students = courseStudentsSamples;
          _isLoadingStudents = false;
        });
        return;
      }

      final DocumentSnapshot<Map<String, dynamic>> courseDocument =
          await _firestore
              .collection('courses')
              .doc(widget.courseData.courseId)
              .get();

      final Map<String, dynamic>? courseData = courseDocument.data();

      final List<dynamic> registeredStudentIds =
          (courseData?['registeredStudentIds'] as List<dynamic>?) ??
              <dynamic>[];

      if (registeredStudentIds.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          _students = courseStudentsSamples;
          _isLoadingStudents = false;
        });
        return;
      }

      final List<CourseStudentData> loadedStudents = <CourseStudentData>[];

      for (final dynamic studentId in registeredStudentIds) {
        final String uid = studentId.toString().trim();

        if (uid.isEmpty) {
          continue;
        }

        final DocumentSnapshot<Map<String, dynamic>> userDocument =
            await _firestore.collection('users').doc(uid).get();

        final Map<String, dynamic>? userData = userDocument.data();

        final String studentName =
            (userData?['fullName'] as String?)?.trim() ?? 'Unknown Student';

        loadedStudents.add(
          CourseStudentData(
            studentId: uid,
            studentName: studentName,
          ),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _students = <CourseStudentData>[
          ...courseStudentsSamples,
          ...loadedStudents,
        ];
        _isLoadingStudents = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _students = courseStudentsSamples;
        _isLoadingStudents = false;
      });
    }
  }

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

  // Space between student cards
  double _studentsSpacing(double height) {
    return height * 0.018;
  }

  // Section title font size
  double _sectionTitleFontSize(double width) {
    return _isTablet(width) ? width * 0.028 : width * 0.05;
  }

  // Section subtitle font size
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
              Icons.people_outline_rounded,
              size: _isTablet(screenWidth)
                  ? screenWidth * 0.07
                  : screenWidth * 0.12,
              color: _secondaryTextColor,
            ),
            SizedBox(height: screenHeight * 0.016),
            Text(
              'No students yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _primaryTextColor,
                fontSize: _emptyStateTitleFontSize(screenWidth),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: screenHeight * 0.008),
            Text(
              'Students who register for this course will appear here.',
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

        return SafeArea(
          child: Padding(
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
                  'Students',
                  style: TextStyle(
                    color: _primaryTextColor,
                    fontSize: _sectionTitleFontSize(screenWidth),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: screenHeight * 0.006),
                Text(
                  'Students registered in ${widget.courseData.courseName}.',
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: _sectionSubtitleFontSize(screenWidth),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: screenHeight * 0.024),
                Expanded(
                  child: _isLoadingStudents
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : _students.isEmpty
                          ? _emptyState(screenWidth, screenHeight)
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: _students.length,
                              separatorBuilder:
                                  (BuildContext context, int index) {
                                return SizedBox(
                                  height: _studentsSpacing(screenHeight),
                                );
                              },
                              itemBuilder: (BuildContext context, int index) {
                                return StudentCourseContainer(
                                  studentData: _students[index],
                                  courseData: widget.courseData,
                                  screenWidth: screenWidth,
                                  availableHeight: screenHeight,
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Single reusable student card
class StudentCourseContainer extends StatelessWidget {
  const StudentCourseContainer({
    super.key,
    required this.studentData,
    required this.courseData,
    required this.screenWidth,
    required this.availableHeight,
  });

  final CourseStudentData studentData;
  final DashboardCourseData courseData;
  final double screenWidth;
  final double availableHeight;

  void _openStudentInfo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => StudentInfo(
          studentData: studentData,
          courseData: courseData,
        ),
      ),
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

  // Card shadow values
  double _cardShadowBlur() {
    return screenWidth * 0.05;
  }

  double _cardShadowOffset() {
    return availableHeight * 0.012;
  }

  // Text sizes
  double _studentNameFontSize() {
    return _isTablet() ? screenWidth * 0.023 : screenWidth * 0.041;
  }

  // Icon size
  double _studentIconSize() {
    return _isTablet() ? screenWidth * 0.028 : screenWidth * 0.05;
  }

  // Spacing
  double _rowSpacing() {
    return _isTablet() ? screenWidth * 0.025 : screenWidth * 0.03;
  }

  // Colors
  Color get _cardBackgroundColor => Colors.white;
  Color get _cardBorderColor => const Color(0xFFE9EDF2);
  Color get _cardShadowColor => const Color(0x12000000);
  Color get _primaryTextColor => const Color(0xFF0F203D);
  Color get _iconBackgroundColor => const Color(0xFFF4F7FB);
  Color get _iconBorderColor => const Color(0xFFD8E1EB);
  Color get _iconColor => const Color(0xFF20303D);

  // Student name style
  TextStyle _studentNameTextStyle() {
    return TextStyle(
      color: _primaryTextColor,
      fontSize: _studentNameFontSize(),
      fontWeight: FontWeight.w700,
      height: 1.2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double cardRadius = _cardBorderRadius();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _openStudentInfo(context);
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
            children: <Widget>[
              Container(
                width: _isTablet() ? screenWidth * 0.07 : screenWidth * 0.12,
                height: _isTablet() ? screenWidth * 0.07 : screenWidth * 0.12,
                decoration: BoxDecoration(
                  color: _iconBackgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _iconBorderColor,
                    width: screenWidth * 0.0022,
                  ),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: _iconColor,
                  size: _studentIconSize(),
                ),
              ),
              SizedBox(width: _rowSpacing()),
              Expanded(
                child: Text(
                  studentData.studentName,
                  style: _studentNameTextStyle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}