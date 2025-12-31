// Copyright 2021 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'src/constants.dart';
import 'src/home.dart';

void main() async {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _useMaterial3 = true;
  ThemeMode _themeMode = ThemeMode.system;
  ColorSeed _colorSelected = ColorSeed.baseColor;
  Color _customColorSelected = Colors.white;
  Color _pickerColor = Colors.white;
  ColorImageProvider _imageSelected = ColorImageProvider.leaves;
  ColorScheme? _imageColorScheme = const ColorScheme.light();
  ColorSelectionMethod _colorSelectionMethod = ColorSelectionMethod.colorSeed;

  bool get _useLightMode => switch (_themeMode) {
    ThemeMode.system =>
      View.of(context).platformDispatcher.platformBrightness ==
          Brightness.light,
    ThemeMode.light => true,
    ThemeMode.dark => false,
  };

  void _handleBrightnessChange(bool useLightMode) {
    setState(() {
      _themeMode = useLightMode ? ThemeMode.light : ThemeMode.dark;
    });
  }

  void _handleMaterialVersionChange() {
    setState(() {
      _useMaterial3 = !_useMaterial3;
    });
  }

  void _handleColorSelect(BuildContext context, int value) {
    final colorSeed = ColorSeed.values[value];

    if (colorSeed == ColorSeed.custom) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _pickerColor,
              onColorChanged: _handleColorPicker,
            ),
          ),
          actions: [
            ElevatedButton(
              child: const Text('Ok'),
              onPressed: () {
                _handleCustomColorSelect();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _colorSelectionMethod = ColorSelectionMethod.colorSeed;
        _colorSelected = colorSeed;
      });
    }
  }

  void _handleImageSelect(int value) {
    final String url = ColorImageProvider.values[value].url;
    ColorScheme.fromImageProvider(provider: NetworkImage(url)).then((
      newScheme,
    ) {
      setState(() {
        _colorSelectionMethod = ColorSelectionMethod.image;
        _imageSelected = ColorImageProvider.values[value];
        _imageColorScheme = newScheme;
      });
    });
  }

  void _handleCustomColorSelect() {
    setState(() {
      _colorSelectionMethod = ColorSelectionMethod.customColor;
      _customColorSelected = _pickerColor;
    });
  }

  void _handleColorPicker(Color color) {
    setState(() {
      _pickerColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material 3',
      themeMode: _themeMode,
      theme: ThemeData(
        colorSchemeSeed:
            _colorSelectionMethod == ColorSelectionMethod.colorSeed
            ? _colorSelected.color
            : (_colorSelectionMethod == ColorSelectionMethod.customColor
                  ? _customColorSelected
                  : null),
        colorScheme: _colorSelectionMethod == ColorSelectionMethod.image
            ? _imageColorScheme
            : null,
        useMaterial3: _useMaterial3,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed:
            _colorSelectionMethod == ColorSelectionMethod.colorSeed
            ? _colorSelected.color
            : (_colorSelectionMethod == ColorSelectionMethod.customColor
                  ? _customColorSelected
                  : _imageColorScheme!.primary),
        useMaterial3: _useMaterial3,
        brightness: Brightness.dark,
      ),
      home: Home(
        useLightMode: _useLightMode,
        useMaterial3: _useMaterial3,
        colorSelected: _colorSelected,
        imageSelected: _imageSelected,
        handleBrightnessChange: _handleBrightnessChange,
        handleMaterialVersionChange: _handleMaterialVersionChange,
        handleColorSelect: _handleColorSelect,
        handleImageSelect: _handleImageSelect,
        colorSelectionMethod: _colorSelectionMethod,
      ),
    );
  }
}
