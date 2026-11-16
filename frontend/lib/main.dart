import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/injection/init_dependencies.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const MyApp());
}
