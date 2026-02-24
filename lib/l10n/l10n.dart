import 'package:flutter/widgets.dart';
import 'app_strings.dart';

extension L10nX on BuildContext {
  AppStrings get s => AppStrings.of(this);
}