import 'package:flutter/material.dart';
import 'package:get_x/get.dart';

class PasswordResetSentPage extends StatefulWidget {
  const PasswordResetSentPage({super.key});

  @override
  State<PasswordResetSentPage> createState() =>
      _PasswordResetSentPageState();
}

class _PasswordResetSentPageState extends State<PasswordResetSentPage> {
  // Checks if screen is tablet size
  bool _isTablet(double width) => width >= 600;

  // Back button action
  void _onBackPressed() {
    Get.back();
  }

  // Done button action
  void _onDonePressed() {
    Get.back();
  }

  // Background color of the page
  Color get _pageBackgroundColor => Colors.white;

  // Main dark text color
  Color get _primaryTextColor => const Color(0xFF0F203D);

  // Secondary text color
  Color get _secondaryTextColor => const Color(0xFF8A8A8A);

  // Success circle color
  Color get _successCircleColor => const Color(0xFFA8E3AF);

  // Check icon color
  Color get _checkIconColor => Colors.white;

  // Main button text color
  Color get _mainButtonTextColor => Colors.white;

  // Main button shadow color
  Color get _mainButtonShadowColor => const Color(0x4434D0C3);

  // Gradient for the main button
  LinearGradient get _mainButtonGradient => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0xFF5B95F0),
          Color(0xFF38D0C3),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: _pageBackgroundColor,
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double screenWidth = constraints.maxWidth;
            final double screenHeight = constraints.maxHeight;
            final bool isTablet = _isTablet(screenWidth);

            final double navBarHeight =
                isTablet ? screenHeight * 0.09 : screenHeight * 0.08;
            final double pageHorizontalPadding =
                isTablet ? screenWidth * 0.06 : screenWidth * 0.06;
            final double topContentSpacing =
                isTablet ? screenHeight * 0.05 : screenHeight * 0.035;
            final double contentBaseWidth =
                isTablet ? screenWidth * 0.72 : screenWidth;
            final double titleFontSize =
                isTablet ? screenWidth * 0.043 : screenWidth * 0.080;
            final double subtitleFontSize =
                isTablet ? screenWidth * 0.023 : screenWidth * 0.043;
            final double buttonFontSize =
                isTablet ? screenWidth * 0.026 : screenWidth * 0.053;
            final double buttonHeight =
                isTablet ? screenHeight * 0.085 : screenHeight * 0.082;
            final double buttonRadius = screenWidth * 0.08;
            final double successCircleSize =
                isTablet ? screenWidth * 0.18 : screenWidth * 0.28;
            final double checkIconSize =
                isTablet ? screenWidth * 0.08 : screenWidth * 0.13;
            final double spaceAfterCircle =
                isTablet ? screenHeight * 0.05 : screenHeight * 0.04;
            final double spaceAfterTitle =
                isTablet ? screenHeight * 0.02 : screenHeight * 0.018;
            final double spaceBeforeButton =
                isTablet ? screenHeight * 0.075 : screenHeight * 0.065;
            final double contentTopSpacer =
                isTablet ? screenHeight * 0.11 : screenHeight * 0.12;
            final double subtitleMaxWidth =
                isTablet ? contentBaseWidth * 0.80 : contentBaseWidth * 0.92;

            TextStyle titleTextStyle() {
              return TextStyle(
                color: _primaryTextColor,
                fontSize: titleFontSize,
                fontWeight: FontWeight.w800,
                height: 1.12,
              );
            }

            TextStyle subtitleTextStyle() {
              return TextStyle(
                color: _secondaryTextColor,
                fontSize: subtitleFontSize,
                fontWeight: FontWeight.w500,
                height: 1.42,
              );
            }

            TextStyle mainButtonTextStyle() {
              return TextStyle(
                color: _mainButtonTextColor,
                fontSize: buttonFontSize,
                fontWeight: FontWeight.w700,
              );
            }

            return SizedBox(
              width: screenWidth,
              height: screenHeight,
              child: Column(
                children: <Widget>[
                  // Top navbar
                  SizedBox(
                    width: screenWidth,
                    height: navBarHeight,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: isTablet
                              ? screenWidth * 0.02
                              : screenWidth * 0.025,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _onBackPressed,
                            borderRadius: BorderRadius.circular(
                              navBarHeight * 0.25,
                            ),
                            child: SizedBox(
                              width: isTablet
                                  ? screenWidth * 0.09
                                  : screenWidth * 0.16,
                              height: navBarHeight * 0.82,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Icon(
                                  Icons.chevron_left_rounded,
                                  color: Colors.black,
                                  size: isTablet
                                      ? screenWidth * 0.06
                                      : screenWidth * 0.11,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Main content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: pageHorizontalPadding,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: topContentSpacing,
                              bottom: screenHeight * 0.04,
                            ),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.topCenter,
                                child: SizedBox(
                                  width: contentBaseWidth,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      SizedBox(height: contentTopSpacer),

                                      // Success icon
                                      Container(
                                        width: successCircleSize,
                                        height: successCircleSize,
                                        decoration: BoxDecoration(
                                          color: _successCircleColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.check_rounded,
                                            color: _checkIconColor,
                                            size: checkIconSize,
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: spaceAfterCircle),

                                      // Title
                                      Text(
                                        'Password reset email sent',
                                        style: titleTextStyle(),
                                        textAlign: TextAlign.center,
                                      ),

                                      SizedBox(height: spaceAfterTitle),

                                      // Subtitle
                                      SizedBox(
                                        width: subtitleMaxWidth,
                                        child: Text(
                                          'We have sent a password reset link to your email.',
                                          style: subtitleTextStyle(),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),

                                      SizedBox(height: spaceBeforeButton),

                                      // Done button
                                      SizedBox(
                                        width: double.infinity,
                                        height: buttonHeight,
                                        child: DecoratedBox(
                                          //Shadow start
                                          decoration: BoxDecoration(
                                            gradient: _mainButtonGradient,
                                            borderRadius: BorderRadius.circular(
                                              buttonRadius,
                                            ),
                                            boxShadow: <BoxShadow>[
                                              BoxShadow(
                                                color: _mainButtonShadowColor,
                                                blurRadius: screenWidth * 0.06,
                                                offset: Offset(
                                                  0,
                                                  screenHeight * 0.016,
                                                ),
                                              ),
                                            ],
                                          ),
                                          //Shadow end
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: _onDonePressed,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                buttonRadius,
                                              ),
                                              child: Center(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                    child: Text(
                                                      'Done',
                                                      style:
                                                          mainButtonTextStyle(),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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