// Copyright 2021 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'icons_list.dart';

class IconsScreen extends StatefulWidget {
  const IconsScreen({super.key});

  @override
  State<IconsScreen> createState() => _IconsScreenState();
}

class _IconsScreenState extends State<IconsScreen> {
  final _searchKeywords = <String>[];

  @override
  Widget build(BuildContext context) {
    final icons = _getFilteredIconDescriptors();

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final searchFieldWidth = constraints.maxWidth > 800
              ? constraints.maxWidth / 3.0
              : null;
          final numFormatter = NumberFormat();
          return Column(
            children: [
              SizedBox(height: 10),
              SizedBox(
                width: searchFieldWidth,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                  child: _SearchField(
                    onSearch: _doSearch,
                  ),
                ),
              ),
              SizedBox(height: 10),
              if (_searchKeywords.isEmpty)
                Text(
                  'Showing all ${numFormatter.format(IconsList.length)} icons.',
                ),
              if (_searchKeywords.isNotEmpty && icons.isNotEmpty)
                Text(
                  'Showing ${numFormatter.format(icons.length)} out of ${numFormatter.format(IconsList.length)} icons.',
                ),
              SizedBox(height: 10),
              Expanded(
                child: _IconGridView(
                  onTap: (index) => _showIconSheet(context, icons[index]),
                  icons: icons,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _doSearch(Iterable<String> keywords) {
    setState(() {
      _searchKeywords.clear();
      _searchKeywords.addAll(keywords);
    });
  }

  List<IconDescriptor> _getFilteredIconDescriptors() {
    final descriptors = IconsList.descriptors;

    if (_searchKeywords.isEmpty) {
      return descriptors;
    }

    return descriptors.where((descriptor) {
      bool isMatch = true;

      for (final keyword in _searchKeywords) {
        isMatch = isMatch && descriptor.name.contains(keyword);
      }

      return isMatch;
    }).toList();
  }

  void _showIconSheet(BuildContext context, IconDescriptor icon) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);

        return SizedBox(
          height: 400,
          child: Container(
            color: theme.colorScheme.surfaceContainerLow,
            child: Column(
              children: [
                Icon(icon.icon, size: 300),
                _LabeledText(
                  onCopyText: (text) => _copyToClipboard(context, text),
                  label: 'Property name',
                  text: icon.name,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await Clipboard.setData(ClipboardData(text: text));
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: const Text('Copied icon property name to clipboard')),
    );
  }
}

class _LabeledText extends StatelessWidget {
  final String label;
  final String text;
  final void Function(String)? onCopyText;

  const _LabeledText({
    required this.label,
    required this.text,
    this.onCopyText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 10),
        Expanded(
          child: InputDecorator(
            decoration: InputDecoration(
              label: Text(label),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
            child: Text(text),
          ),
        ),
        IconButton(
          onPressed: () => onCopyText?.call(text),
          icon: Icon(Icons.copy),
        ),
        SizedBox(width: 10),
      ],
    );
  }
}

class _IconGridView extends StatelessWidget {
  final List<IconDescriptor> icons;
  final void Function(int)? onTap;

  const _IconGridView({
    required this.icons,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final numberOfGridColumns = math.max(
        1,
        (constraints.maxWidth / 100.0).floor(),
      );
      return icons.isEmpty
          ? Center(child: const Text('No matching icons found.'))
          : GridView.builder(
              itemCount: icons.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: numberOfGridColumns,
              ),
              itemBuilder: (context, index) => _IconView(
                onTap: () => onTap?.call(index),
                icons[index],
              ),
            );
    },
  );
}

class _SearchField extends StatefulWidget {
  final int mininumKeywordsLength;
  final void Function(Iterable<String>) onSearch;
  final Duration debounceDuration;

  const _SearchField({
    super.key,
    required this.onSearch,
    this.mininumKeywordsLength = 3,
    this.debounceDuration = const Duration(seconds: 1),
  });

  @override
  State<StatefulWidget> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  Timer? _timer;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        suffixIcon: _ClearButton(onTap: _clear),
        hintText: 'Search',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0)),
      ),
      onChanged: (_) => _resetTimer(),
      onSubmitted: (_) => _executeSearch(),
    );
  }

  void _resetTimer() {
    final searchTextLength = _controller.text.trim().length;
    _timer?.cancel();

    if (searchTextLength == 0) {
      _executeSearch();
    } else if (searchTextLength >= widget.mininumKeywordsLength) {
      _timer = Timer(widget.debounceDuration, _executeSearch);
    }
  }

  void _clear() {
    _controller.text = '';
    _executeSearch();
  }

  void _executeSearch() {
    final keywords = _controller.text
        .trim()
        .split(' ')
        .where((keyword) => keyword.isNotEmpty);
    _timer?.cancel();
    widget.onSearch(keywords);
  }
}

class _IconView extends StatefulWidget {
  final IconDescriptor icon;
  final void Function()? onTap;

  const _IconView(this.icon, {this.onTap});

  @override
  State<_IconView> createState() => _IconViewState();
}

class _IconViewState extends State<_IconView> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _isFocused ? theme.colorScheme.primary : null;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MouseRegion(
        onEnter: (_) => _focus(),
        onExit: (_) => _unfocus(),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Icon(widget.icon.icon, size: 50, color: color),
        ),
      ),
    );
  }

  void _focus() => setState(() => _isFocused = true);

  void _unfocus() => setState(() => _isFocused = false);
}

class _ClearButton extends StatefulWidget {
  final void Function() onTap;

  const _ClearButton({required this.onTap});

  @override
  State<StatefulWidget> createState() => _ClearButtonState();
}

class _ClearButtonState extends State<_ClearButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _isFocused ? theme.colorScheme.primary : null;

    return MouseRegion(
      onEnter: (_) => _focus(),
      onExit: (_) => _unfocus(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Icon(Icons.clear, color: color),
      ),
    );
  }

  void _focus() => setState(() => _isFocused = true);

  void _unfocus() => setState(() => _isFocused = false);
}
