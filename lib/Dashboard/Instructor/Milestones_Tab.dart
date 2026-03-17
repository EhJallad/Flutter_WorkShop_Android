import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:training_hub/Dashboard/Dashboard.dart';

class MilestoneTab extends StatefulWidget {
  const MilestoneTab({
    super.key,
    required this.courseData,
  });

  final DashboardCourseData courseData;

  @override
  State<MilestoneTab> createState() => _MilestoneTabState();
}

class _MilestoneTabState extends State<MilestoneTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoadingPage = true;
  bool _isSavingMilestones = false;

  final List<TextEditingController> _milestoneControllers =
      <TextEditingController>[];
  final List<String?> _milestoneErrors = <String?>[];

  final List<String> _milestoneIds = <String>[];
  final List<bool> _selectedCheckboxValues = <bool>[];

  @override
  void initState() {
    super.initState();
    _loadMilestones();
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _milestoneControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMilestones() async {
    if (widget.courseData.courseId.trim().isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingPage = false;
      });
      return;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> courseDocument =
          await _firestore.collection('courses').doc(widget.courseData.courseId).get();

      final Map<String, dynamic>? courseMap = courseDocument.data();

      final List<dynamic> rawMilestones =
          (courseMap?['milestones'] as List<dynamic>?) ?? <dynamic>[];

      for (final TextEditingController controller in _milestoneControllers) {
        controller.dispose();
      }

      _milestoneControllers.clear();
      _milestoneErrors.clear();
      _milestoneIds.clear();
      _selectedCheckboxValues.clear();

      final List<Map<String, dynamic>> sortedMilestones = rawMilestones
          .map(
            (dynamic item) => Map<String, dynamic>.from(
              item as Map<String, dynamic>,
            ),
          )
          .toList()
        ..sort(
          (Map<String, dynamic> a, Map<String, dynamic> b) {
            final int firstOrder = (a['order'] as num?)?.toInt() ?? 0;
            final int secondOrder = (b['order'] as num?)?.toInt() ?? 0;
            return firstOrder.compareTo(secondOrder);
          },
        );

      for (int i = 0; i < sortedMilestones.length; i++) {
        final Map<String, dynamic> milestone = sortedMilestones[i];

        final String milestoneId =
            (milestone['milestoneId'] as String?)?.trim().isNotEmpty == true
                ? (milestone['milestoneId'] as String).trim()
                : 'milestone_${i + 1}';

        final String milestoneName =
            (milestone['milestoneName'] as String?)?.trim() ?? '';

        final bool isChecked = (milestone['isCompleted'] as bool?) ?? false;

        _milestoneIds.add(milestoneId);
        _milestoneControllers.add(
          TextEditingController(text: milestoneName),
        );
        _milestoneErrors.add(null);
        _selectedCheckboxValues.add(isChecked);
      }

      if (_milestoneControllers.isEmpty) {
        _addMilestoneField(
          shouldSetState: false,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingPage = false;
      });
    } catch (e) {
      if (_milestoneControllers.isEmpty) {
        _addMilestoneField(
          shouldSetState: false,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingPage = false;
      });

      _showSimpleSnackBar(
        message: 'Failed to load milestones.',
      );
    }
  }

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

  void _validateSingleMilestoneField(int index) {
    setState(() {
      _milestoneErrors[index] =
          _validateMilestoneName(_milestoneControllers[index].text);
    });
  }

  bool _validateAllMilestones() {
    bool isValid = true;

    for (int i = 0; i < _milestoneControllers.length; i++) {
      final String? error =
          _validateMilestoneName(_milestoneControllers[i].text);

      _milestoneErrors[i] = error;

      if (error != null) {
        isValid = false;
      }
    }

    setState(() {});

    return isValid;
  }

  void _addMilestoneField({
    bool shouldSetState = true,
  }) {
    void action() {
      final int nextIndex = _milestoneControllers.length + 1;

      _milestoneIds.add('milestone_$nextIndex');
      _milestoneControllers.add(TextEditingController());
      _milestoneErrors.add(null);
      _selectedCheckboxValues.add(false);
    }

    if (shouldSetState) {
      setState(action);
    } else {
      action();
    }
  }

  void _removeMilestoneField(int index) {
    if (_milestoneControllers.length == 1) {
      _showSimpleSnackBar(
        message: 'At least one milestone is required.',
      );
      return;
    }

    setState(() {
      _milestoneControllers[index].dispose();
      _milestoneControllers.removeAt(index);
      _milestoneErrors.removeAt(index);
      _milestoneIds.removeAt(index);
      _selectedCheckboxValues.removeAt(index);
    });
  }

  List<Map<String, dynamic>> _buildMilestonesForFirestore() {
    final List<Map<String, dynamic>> milestones = <Map<String, dynamic>>[];

    for (int i = 0; i < _milestoneControllers.length; i++) {
      final String originalId = _milestoneIds[i].trim();

      milestones.add(
        <String, dynamic>{
          'milestoneId': originalId.isNotEmpty ? originalId : 'milestone_${i + 1}',
          'milestoneName': _milestoneControllers[i].text.trim(),
          'order': i + 1,
          'isCompleted': _selectedCheckboxValues[i],
        },
      );
    }

    return milestones;
  }

  Future<void> _saveMilestones() async {
    if (_isSavingMilestones) {
      return;
    }

    if (widget.courseData.courseId.trim().isEmpty) {
      _showSimpleSnackBar(
        message: 'This course is missing its database id.',
      );
      return;
    }

    final bool isValid = _validateAllMilestones();

    if (!isValid) {
      return;
    }

    setState(() {
      _isSavingMilestones = true;
    });

    try {
      final List<Map<String, dynamic>> milestones =
          _buildMilestonesForFirestore();

      await _firestore.collection('courses').doc(widget.courseData.courseId).update(
        <String, dynamic>{
          'milestones': milestones,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      if (!mounted) {
        return;
      }

      _showSimpleSnackBar(
        message: 'Milestones updated successfully.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showSimpleSnackBar(
        message: 'Failed to update milestones.',
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingMilestones = false;
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

  double _fieldLabelFontSize(double width) {
    return _isTablet(width) ? width * 0.017 : width * 0.031;
  }

  double _inputTextFontSize(double width) {
    return _isTablet(width) ? width * 0.017 : width * 0.03;
  }

  double _sectionTitleFontSize(double width) {
    return _isTablet(width) ? width * 0.021 : width * 0.038;
  }

  double _buttonTextFontSize(double width) {
    return _isTablet(width) ? width * 0.021 : width * 0.038;
  }

  double _smallButtonTextFontSize(double width) {
    return _isTablet(width) ? width * 0.016 : width * 0.029;
  }

  double _fieldErrorFontSize(double width) {
    return _isTablet(width) ? width * 0.016 : width * 0.029;
  }

  double _inputHeight(double height) {
    return height * 0.074;
  }

  double _mainButtonHeight(double height) {
    return height * 0.07;
  }

  double _smallButtonHeight(double height) {
    return height * 0.06;
  }

  double _buttonBorderRadius(double width) {
    return width * 0.04;
  }

  double _smallButtonBorderRadius(double width) {
    return width * 0.04;
  }

  double _fieldLabelLeftInset(double width) {
    return _isTablet(width) ? width * 0.08 : width * 0.1;
  }

  double _fieldLabelHorizontalPadding(double width) {
    return _isTablet(width) ? width * 0.012 : width * 0.018;
  }

  double _fieldErrorLeftInset(double width) {
    return _isTablet(width) ? width * 0.025 : width * 0.03;
  }

  double _fieldErrorSectionHeight(double height) {
    return height * 0.04;
  }

  double _suffixIconRightPadding(double width) {
    return _isTablet(width) ? width * 0.018 : width * 0.028;
  }

  double _iconSize(double width) {
    return _isTablet(width) ? width * 0.025 : width * 0.05;
  }

  double _checkboxScale(double width) {
    return _isTablet(width) ? 1.1 : 1.0;
  }

  Color get _pageBackgroundColor => Colors.white;
  Color get _cardBackgroundColor => Colors.white;
  Color get _cardBorderColor => const Color(0xFFE9EDF2);
  Color get _cardShadowColor => const Color(0x12000000);
  Color get _primaryTextColor => const Color(0xFF0F203D);
  Color get _secondaryTextColor => const Color(0xFF8A8A8A);
  Color get _borderColor => const Color(0xFF20303D);
  Color get _lightBorderColor => const Color(0xFFD8E1EB);
  Color get _greenColor => const Color(0xFF33B679);
  Color get _greenDarkTextColor => const Color(0xFF1E7D52);
  Color get _addColor => const Color(0xFF2CB5A8);
  Color get _errorColor => const Color(0xFFD93025);
  Color get _mainButtonShadowColor => const Color(0x4434D0C3);

  LinearGradient get _mainButtonGradient => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0xFF5B95F0),
          Color(0xFF38D0C3),
        ],
      );

  TextStyle _sectionCardTitleTextStyle(double width) {
    return TextStyle(
      color: _primaryTextColor,
      fontSize: _sectionTitleFontSize(width),
      fontWeight: FontWeight.w800,
    );
  }

  TextStyle _subtitleTextStyle(double width) {
    return TextStyle(
      color: _secondaryTextColor,
      fontSize: _fieldLabelFontSize(width),
      fontWeight: FontWeight.w500,
      height: 1.35,
    );
  }

  TextStyle _fieldLabelTextStyle({
    required double width,
    required bool hasError,
  }) {
    return TextStyle(
      color: hasError ? _errorColor : _primaryTextColor,
      fontSize: _fieldLabelFontSize(width),
      fontWeight: FontWeight.w500,
      height: 1,
    );
  }

  TextStyle _hintTextStyle({
    required double width,
    required bool hasError,
  }) {
    return TextStyle(
      color: hasError ? _errorColor : _secondaryTextColor,
      fontSize: _inputTextFontSize(width),
      fontWeight: FontWeight.w400,
    );
  }

  TextStyle _fieldErrorTextStyle(double width) {
    return TextStyle(
      color: _errorColor,
      fontSize: _fieldErrorFontSize(width),
      fontWeight: FontWeight.w500,
      height: 1.15,
    );
  }

  TextStyle _mainButtonTextStyle(double width) {
    return TextStyle(
      color: Colors.white,
      fontSize: _buttonTextFontSize(width),
      fontWeight: FontWeight.w700,
    );
  }

  TextStyle _smallButtonTextStyle({
    required double width,
    required Color color,
  }) {
    return TextStyle(
      color: color,
      fontSize: _smallButtonTextFontSize(width),
      fontWeight: FontWeight.w700,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBackgroundColor,
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
                _milestonesContainer(
                  width: screenWidth,
                  height: screenHeight,
                ),
                SizedBox(height: _sectionSpacingLarge(screenHeight)),
                _addMilestoneButton(
                  width: screenWidth,
                  height: screenHeight,
                ),
                SizedBox(height: _sectionSpacingLarge(screenHeight)),
                _saveMilestonesButton(
                  width: screenWidth,
                  height: screenHeight,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _milestonesContainer({
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
        //Shadow start
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _cardShadowColor,
            blurRadius: width * 0.05,
            offset: Offset(0, height * 0.012),
          ),
        ],
        //Shadow end
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Milestones',
            style: _sectionCardTitleTextStyle(width),
          ),
          SizedBox(height: _sectionSpacingSmall(height)),
          Text(
            'Edit previous milestones, delete them, add new ones, and mark them with the checkbox.',
            style: _subtitleTextStyle(width),
          ),
          SizedBox(height: _sectionSpacingLarge(height)),
          ...List<Widget>.generate(
            _milestoneControllers.length,
            (int index) => Padding(
              padding: EdgeInsets.only(
                bottom: index == _milestoneControllers.length - 1
                    ? 0
                    : _sectionSpacingMedium(height),
              ),
              child: _milestoneRow(
                width: width,
                height: height,
                index: index,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _milestoneRow({
    required double width,
    required double height,
    required int index,
  }) {
    final bool hasError = _milestoneErrors[index] != null;
    final String? errorMessage = _milestoneErrors[index];

    final double inputHeight = _inputHeight(height);
    final double inputRadius = _buttonBorderRadius(width);
    final double iconSize = _iconSize(width);
    final double labelLeftInset = _fieldLabelLeftInset(width);
    final double labelHorizontalPadding = _fieldLabelHorizontalPadding(width);
    final double totalFieldHeight =
        inputHeight + (_fieldLabelFontSize(width) * 0.9) + _fieldErrorSectionHeight(height);

    final double contentHorizontalPadding =
        _isTablet(width) ? width * 0.02 : width * 0.04;

    final double iconToTextSpacing =
        _isTablet(width) ? width * 0.012 : width * 0.025;

    final Color activeBorderColor = hasError ? _errorColor : _borderColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: totalFieldHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                top: _fieldLabelFontSize(width) * 0.45,
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
                    style: _hintTextStyle(
                      width: width,
                      hasError: hasError,
                    ).copyWith(
                      color: hasError ? _errorColor : _primaryTextColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Milestone ${index + 1}',
                      hintStyle: _hintTextStyle(
                        width: width,
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
                      suffixIcon: Padding(
                        padding: EdgeInsets.only(
                          right: _suffixIconRightPadding(width),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (hasError)
                              Padding(
                                padding: EdgeInsets.only(
                                  right: width * 0.006,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: _errorColor,
                                  size: iconSize,
                                ),
                              ),
                            GestureDetector(
                              onTap: () {
                                _removeMilestoneField(index);
                              },
                              child: Icon(
                                Icons.delete_outline_rounded,
                                color: _milestoneControllers.length == 1
                                    ? _lightBorderColor
                                    : _errorColor,
                                size: iconSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                      suffixIconConstraints: BoxConstraints(
                        minWidth: _isTablet(width) ? width * 0.12 : width * 0.22,
                        minHeight: inputHeight,
                      ),
                      prefixIconConstraints: BoxConstraints(
                        minWidth: _isTablet(width) ? width * 0.09 : width * 0.15,
                        minHeight: inputHeight,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(inputRadius),
                        borderSide: BorderSide(
                          color: activeBorderColor,
                          width: width * 0.0035,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(inputRadius),
                        borderSide: BorderSide(
                          color: activeBorderColor,
                          width: width * 0.004,
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
                      width: width,
                      hasError: hasError,
                    ),
                  ),
                ),
              ),
              if (hasError && errorMessage != null)
                Positioned(
                  left: _fieldErrorLeftInset(width),
                  right: 0,
                  top: _fieldLabelFontSize(width) * 0.45 +
                      inputHeight +
                      (height * 0.01),
                  child: Text(
                    errorMessage,
                    style: _fieldErrorTextStyle(width),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: _sectionSpacingSmall(height)),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            height: _smallButtonHeight(height),
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.02,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(width * 0.035),
              border: Border.all(
                color: _lightBorderColor,
                width: width * 0.0025,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Transform.scale(
                  scale: _checkboxScale(width),
                  child: Checkbox(
                    value: _selectedCheckboxValues[index],
                    activeColor: _greenColor,
                    checkColor: Colors.white,
                    side: BorderSide(
                      color: _lightBorderColor,
                      width: width * 0.0025,
                    ),
                    onChanged: (bool? value) {
                      setState(() {
                        _selectedCheckboxValues[index] = value ?? false;
                      });
                    },
                  ),
                ),
                Text(
                  'Done',
                  style: _smallButtonTextStyle(
                    width: width,
                    color: _greenDarkTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _addMilestoneButton({
    required double width,
    required double height,
  }) {
    return SizedBox(
      width: double.infinity,
      height: _smallButtonHeight(height),
      child: OutlinedButton.icon(
        onPressed: _isSavingMilestones
            ? null
            : () {
                _addMilestoneField();
              },
        icon: Icon(
          Icons.add_rounded,
          size: _iconSize(width),
          color: _addColor,
        ),
        label: Text(
          'Add Milestone',
          style: _smallButtonTextStyle(
            width: width,
            color: _addColor,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _addColor,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: _addColor,
            width: width * 0.0035,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              _smallButtonBorderRadius(width),
            ),
          ),
        ),
      ),
    );
  }

  Widget _saveMilestonesButton({
    required double width,
    required double height,
  }) {
    return SizedBox(
      width: double.infinity,
      height: _mainButtonHeight(height),
      child: DecoratedBox(
        //Shadow start
        decoration: BoxDecoration(
          gradient: _mainButtonGradient,
          borderRadius: BorderRadius.circular(_buttonBorderRadius(width)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: _mainButtonShadowColor,
              blurRadius: width * 0.06,
              offset: Offset(0, height * 0.016),
            ),
          ],
        ),
        //Shadow end
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isSavingMilestones ? null : _saveMilestones,
            borderRadius: BorderRadius.circular(_buttonBorderRadius(width)),
            child: Center(
              child: Text(
                _isSavingMilestones ? 'Saving Milestones...' : 'Save Milestones',
                style: _mainButtonTextStyle(width),
              ),
            ),
          ),
        ),
      ),
    );
  }
}