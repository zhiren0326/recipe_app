// lib/utils/responsive_controller.dart
import 'package:flutter/material.dart';

/// Main Responsive Controller for the entire app
class ResponsiveController {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double safeAreaHorizontal;
  static late double safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;
  static late double textMultiplier;
  static late double imageSizeMultiplier;
  static late double heightMultiplier;
  static late double widthMultiplier;
  static late bool isPortrait;
  static late bool isLandscape;
  static late DeviceType deviceType;

  /// Initialize the ResponsiveController with context
  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    final double safeAreaPaddingHorizontal =
        _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    final double safeAreaPaddingVertical =
        _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;

    safeAreaHorizontal = screenWidth - safeAreaPaddingHorizontal;
    safeAreaVertical = screenHeight - safeAreaPaddingVertical;
    safeBlockHorizontal = safeAreaHorizontal / 100;
    safeBlockVertical = safeAreaVertical / 100;

    // Text and size multipliers
    textMultiplier = blockSizeVertical;
    imageSizeMultiplier = blockSizeHorizontal;
    heightMultiplier = blockSizeVertical;
    widthMultiplier = blockSizeHorizontal;

    // Orientation
    isPortrait = _mediaQueryData.orientation == Orientation.portrait;
    isLandscape = _mediaQueryData.orientation == Orientation.landscape;

    // Device Type
    deviceType = _getDeviceType();
  }

  /// Get device type based on screen size
  static DeviceType _getDeviceType() {
    double shortestSide = _mediaQueryData.size.shortestSide;

    if (shortestSide < 300) return DeviceType.smallPhone;
    if (shortestSide < 600) return DeviceType.phone;
    if (shortestSide < 900) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Check if current device is mobile
  static bool get isMobile =>
      deviceType == DeviceType.phone || deviceType == DeviceType.smallPhone;

  /// Check if current device is tablet
  static bool get isTablet => deviceType == DeviceType.tablet;

  /// Check if current device is desktop
  static bool get isDesktop => deviceType == DeviceType.desktop;

  /// Check if current device is small phone
  static bool get isSmallPhone => deviceType == DeviceType.smallPhone;

  /// Get responsive font size
  static double fontSize(double size) {
    if (isDesktop) return size * 1.3;
    if (isTablet) {
      return isPortrait ? size * 1.15 : size * 1.1;
    }
    if (isSmallPhone) return size * 0.9;
    return size;
  }

  /// Get responsive icon size
  static double iconSize(double size) {
    if (isDesktop) return size * 1.4;
    if (isTablet) return size * 1.2;
    if (isSmallPhone) return size * 0.85;
    return size;
  }

  /// Get responsive padding
  static EdgeInsets padding({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) {
    double multiplier = isDesktop ? 1.5 : isTablet ? 1.2 : 1.0;

    if (all != null) {
      return EdgeInsets.all(all * multiplier);
    }

    return EdgeInsets.only(
      left: (left ?? horizontal ?? 0) * multiplier,
      right: (right ?? horizontal ?? 0) * multiplier,
      top: (top ?? vertical ?? 0) * multiplier,
      bottom: (bottom ?? vertical ?? 0) * multiplier,
    );
  }

  /// Get responsive spacing (SizedBox)
  static double spacing(double size) {
    if (isDesktop) return size * 1.5;
    if (isTablet) return size * 1.2;
    if (isSmallPhone) return size * 0.8;
    return size;
  }

  /// Get responsive container width with max constraints
  static double? containerWidth({
    double? maxWidth,
    double percentageOfScreen = 1.0,
  }) {
    double calculatedWidth = screenWidth * percentageOfScreen;

    if (maxWidth != null && calculatedWidth > maxWidth) {
      return maxWidth;
    }

    if (isDesktop && maxWidth == null) {
      // Default max width for desktop if not specified
      return calculatedWidth > 1200 ? 1200 : calculatedWidth;
    }

    return calculatedWidth;
  }

  /// Get responsive height based on screen percentage
  static double height(double percentage) {
    return screenHeight * (percentage / 100);
  }

  /// Get responsive width based on screen percentage
  static double width(double percentage) {
    return screenWidth * (percentage / 100);
  }

  /// Get number of grid columns based on device
  static int gridColumns({
    int mobile = 2,
    int? tablet,
    int? desktop,
  }) {
    if (isDesktop) return desktop ?? tablet ?? mobile;
    if (isTablet) {
      return isLandscape
          ? (desktop ?? tablet ?? mobile)
          : (tablet ?? mobile);
    }
    return isLandscape ? (tablet ?? mobile) : mobile;
  }

  /// Get responsive button height
  static double buttonHeight({
    double mobile = 48,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop) return desktop ?? 56;
    if (isTablet) return tablet ?? 52;
    if (isSmallPhone) return 44;
    return mobile;
  }

  /// Get responsive border radius
  static double borderRadius(double radius) {
    if (isDesktop) return radius * 1.2;
    if (isTablet) return radius * 1.1;
    return radius;
  }

  /// Get responsive image size
  static double imageSize(double size) {
    if (isDesktop) return size * 1.4;
    if (isTablet) {
      return isPortrait ? size * 1.2 : size * 1.1;
    }
    if (isSmallPhone) return size * 0.8;
    return size;
  }

  /// Determine if should show element based on device/orientation
  static bool shouldShow({
    bool showOnMobile = true,
    bool showOnTablet = true,
    bool showOnDesktop = true,
    bool showInPortrait = true,
    bool showInLandscape = true,
  }) {
    bool deviceCheck = (isMobile && showOnMobile) ||
        (isTablet && showOnTablet) ||
        (isDesktop && showOnDesktop);

    bool orientationCheck = (isPortrait && showInPortrait) ||
        (isLandscape && showInLandscape);

    return deviceCheck && orientationCheck;
  }
}

/// Device type enum
enum DeviceType {
  smallPhone,  // < 300px
  phone,       // 300-600px
  tablet,      // 600-900px
  desktop,     // > 900px
}

/// Responsive Widget Wrapper
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(
      BuildContext context,
      DeviceType deviceType,
      Orientation orientation,
      ) builder;

  const ResponsiveBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ResponsiveController.init(context);
    return builder(
      context,
      ResponsiveController.deviceType,
      ResponsiveController.isPortrait ? Orientation.portrait : Orientation.landscape,
    );
  }
}

/// Responsive Layout Widget - Shows different layouts based on device
class ResponsiveLayout extends StatelessWidget {
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    Key? key,
    this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ResponsiveController.init(context);

    if (ResponsiveController.isDesktop && desktop != null) {
      return desktop!;
    }
    if (ResponsiveController.isTablet && tablet != null) {
      return tablet!;
    }
    if (ResponsiveController.isMobile && mobile != null) {
      return mobile!;
    }

    // Fallback to first available
    return mobile ?? tablet ?? desktop ?? Container();
  }
}

/// Responsive Text Widget
class ResponsiveText extends StatelessWidget {
  final String text;
  final double baseSize;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final FontWeight? fontWeight;
  final Color? color;

  const ResponsiveText(
      this.text, {
        Key? key,
        this.baseSize = 14,
        this.style,
        this.textAlign,
        this.maxLines,
        this.overflow,
        this.fontWeight,
        this.color,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ResponsiveController.init(context);

    return Text(
      text,
      style: (style ?? TextStyle()).copyWith(
        fontSize: ResponsiveController.fontSize(baseSize),
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Responsive Container Widget
class ResponsiveContainer extends StatelessWidget {
  final Widget? child;
  final double? widthPercentage;
  final double? heightPercentage;
  final double? maxWidth;
  final double? maxHeight;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BoxDecoration? decoration;
  final AlignmentGeometry? alignment;

  const ResponsiveContainer({
    Key? key,
    this.child,
    this.widthPercentage,
    this.heightPercentage,
    this.maxWidth,
    this.maxHeight,
    this.padding,
    this.margin,
    this.decoration,
    this.alignment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ResponsiveController.init(context);

    return Container(
      width: widthPercentage != null
          ? ResponsiveController.width(widthPercentage!)
          : null,
      height: heightPercentage != null
          ? ResponsiveController.height(heightPercentage!)
          : null,
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? double.infinity,
        maxHeight: maxHeight ?? double.infinity,
      ),
      padding: padding,
      margin: margin,
      decoration: decoration,
      alignment: alignment,
      child: child,
    );
  }
}

/// Responsive Spacing Widget (replacement for SizedBox)
class ResponsiveSpacing extends StatelessWidget {
  final double? height;
  final double? width;

  const ResponsiveSpacing({
    Key? key,
    this.height,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ResponsiveController.init(context);

    return SizedBox(
      height: height != null ? ResponsiveController.spacing(height!) : null,
      width: width != null ? ResponsiveController.spacing(width!) : null,
    );
  }
}

/// Responsive Icon Widget
class ResponsiveIcon extends StatelessWidget {
  final IconData icon;
  final double baseSize;
  final Color? color;

  const ResponsiveIcon(
      this.icon, {
        Key? key,
        this.baseSize = 24,
        this.color,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ResponsiveController.init(context);

    return Icon(
      icon,
      size: ResponsiveController.iconSize(baseSize),
      color: color,
    );
  }
}

/// Responsive Visibility Widget - Show/hide based on device
class ResponsiveVisibility extends StatelessWidget {
  final Widget child;
  final bool showOnMobile;
  final bool showOnTablet;
  final bool showOnDesktop;
  final bool showInPortrait;
  final bool showInLandscape;

  const ResponsiveVisibility({
    Key? key,
    required this.child,
    this.showOnMobile = true,
    this.showOnTablet = true,
    this.showOnDesktop = true,
    this.showInPortrait = true,
    this.showInLandscape = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ResponsiveController.init(context);

    bool shouldShow = ResponsiveController.shouldShow(
      showOnMobile: showOnMobile,
      showOnTablet: showOnTablet,
      showOnDesktop: showOnDesktop,
      showInPortrait: showInPortrait,
      showInLandscape: showInLandscape,
    );

    return shouldShow ? child : SizedBox.shrink();
  }
}