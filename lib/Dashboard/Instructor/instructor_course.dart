import 'package:flutter/material.dart';
import 'package:training_hub/Dashboard/Dashboard.dart';
import 'package:training_hub/Dashboard/Instructor/Milestones_Tab.dart';
import 'package:training_hub/Dashboard/Instructor/instructor_BottomBar.dart';
import 'package:training_hub/Dashboard/Instructor/Tab_Students/students_tab.dart';
import 'package:training_hub/navbar_general.dart';

class InstructorCourse extends StatefulWidget {
  const InstructorCourse({
    super.key,
    required this.courseData,
  });

  final DashboardCourseData courseData;

  @override
  State<InstructorCourse> createState() => _InstructorCourseState();
}

class _InstructorCourseState extends State<InstructorCourse> {
  int _currentIndex = 0;

  late final List<Widget> _pages = <Widget>[
    StudentsTab(
      courseData: widget.courseData,
    ),
   MilestoneTab(
      courseData: widget.courseData,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const NavBarGeneral(
            title: 'Training Dashboard',
          ),
          Expanded(child: _pages[_currentIndex]),
        ],
      ),
      bottomNavigationBar: BottomBarInstructor(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

