import 'package:flutter/material.dart';

// Simple model for each registered student row
class CourseStudentData {
  const CourseStudentData({
    required this.studentId,
    required this.studentName,
  });

  final String studentId;
  final String studentName;
}

// Always-available sample students
const List<CourseStudentData> courseStudentsSamples = <CourseStudentData>[
  CourseStudentData(
    studentId: 'sample_test_one',
    studentName: 'TestOne',
  ),
  CourseStudentData(
    studentId: 'sample_test_two',
    studentName: 'TestTwo',
  ),
];