import 'package:flutter/material.dart';

extension UIHelper on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  
  void push(Widget screen) {
    Navigator.of(this).push(MaterialPageRoute(builder: (_) => screen));
  }

  void pushReplacement(Widget screen) {
    Navigator.of(this).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }
}

extension Spacing on num {
  Widget get verticalSpace => SizedBox(height: toDouble());
  Widget get horizontalSpace => SizedBox(width: toDouble());
}
