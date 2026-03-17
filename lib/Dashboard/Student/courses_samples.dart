import 'package:training_hub/Dashboard/Dashboard.dart';

// Sample courses list kept in a separate file for demo/example purposes.
// Later, this can be replaced with API data, database data, or admin-added courses.
final List<DashboardCourseData> dashboardCoursesSamples =
    <DashboardCourseData>[
  const DashboardCourseData(
    imagePath: 'Pictures/WorkShops/UnitWorkShop_Basic.png',
    courseName: 'Unity Basics Workshop',
    shortDescription:
        'Learn the core Unity tools, interface, scenes, and beginner game workflow.',
    instructorName: 'Ahmad Khaled',
    availableSeatsText: '3/30',
    isRegistered: false,
    progressValue: 0,
    attendanceValue: 0.15,
    isOpen: true,
    courseId: "1",
  ),
  const DashboardCourseData(
    imagePath: 'Pictures/WorkShops/UnitWorkShop_Intermediate.png',
    courseName: 'Unity Intermediate Workshop',
    shortDescription:
        'Build stronger gameplay systems, UI flow, prefabs, and project structure skills.',
    instructorName: 'Lina Samir',
    availableSeatsText: '12/30',
    isRegistered: true,
    progressValue: 0.42,
    attendanceValue: 0.15,
    isOpen: true,
    courseId: "2",
  ),
  const DashboardCourseData(
    imagePath: 'Pictures/WorkShops/UnityWorkShop_Advanced.png',
    courseName: 'Unity Advanced Workshop',
    shortDescription:
        'Go deeper into optimization, architecture, advanced mechanics, and polish.',
    instructorName: 'IOmar Nasser',
    availableSeatsText: '8/25',
    isRegistered: true,
    progressValue: 0.78,
    attendanceValue: 0.15,
    isOpen: true,
    courseId: "3",
  ),
];