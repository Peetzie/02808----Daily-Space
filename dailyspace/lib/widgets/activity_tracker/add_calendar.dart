import 'package:dailyspace/services/google_services.dart';
import 'package:dailyspace/services/google_sign_in_manager.dart';
import 'package:dailyspace/sources/palette.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AddCalendarOverlay extends StatefulWidget {
  final Map<String, int> calendarData = {
    'Food + nutrition': 7,
    'Fitness': 4,
    'Office Work': 9,
    'Personal Time': 16,
    'Family': 24,
    'Mindfulness': 16,
    'Rest + travel': 1,
    'Digital life': 8,
  };

  AddCalendarOverlay({super.key});

  @override
  _AddCalendarOverlayState createState() => _AddCalendarOverlayState();
}

class _AddCalendarOverlayState extends State<AddCalendarOverlay> {
  final Map<String, String> _selectedColors = {};
  final Map<String, bool> _selectedCalendars = {};
  bool _isLoading = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    widget.calendarData.forEach((calendarName, colorId) {
      _selectedColors[calendarName] = 'Color $colorId';
      _selectedCalendars[calendarName] = false; // Initialize all as unselected
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Calendar'),
      content: _isLoading
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                LinearProgressIndicator(value: _progress), // Progress bar
                const SizedBox(height: 20),
                Text('${(_progress * 100).toStringAsFixed(0)}% completed'),
              ],
            )
          : buildContent(),
      actions: !_isLoading
          ? <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: createCalendars,
                child: const Text('OK'),
              ),
            ]
          : null,
    );
  }

  Widget buildContent() {
    return SizedBox(
      width: double.maxFinite,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.calendarData.length,
        itemBuilder: (BuildContext context, int index) {
          final calendarName = widget.calendarData.keys.elementAt(index);
          final selectedColor = _selectedColors[calendarName]!;
          final isSelected = _selectedCalendars[calendarName] ?? false;

          return Row(
            children: [
              DropdownButton<String>(
                value: selectedColor,
                onChanged: (newValue) {
                  setState(() {
                    _selectedColors[calendarName] = newValue!;
                  });
                },
                items: _buildColorDropdownItems(selectedColor),
              ),
              Expanded(child: Text(calendarName)),
              Checkbox(
                value: isSelected,
                onChanged: (bool? newValue) {
                  setState(() {
                    _selectedCalendars[calendarName] = newValue!;
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildColorDropdownItems(String currentColor) {
    List<String> usedColors = _selectedColors.values.toList();
    List<DropdownMenuItem<String>> items = [];

    for (int i = 1; i <= 24; i++) {
      String colorValue = 'Color $i';
      if (!usedColors.contains(colorValue) || colorValue == currentColor) {
        items.add(DropdownMenuItem(
          value: colorValue,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: getColorFromId(i.toString()),
                radius: 8,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ));
      }
    }

    return items;
  }

  Future<void> createCalendars() async {
    GoogleSignInAccount? account = GoogleSignInManager.instance.currentUser;
    setState(() => _isLoading = true);
    _progress = 0.0; // Initialize progress

    final selectedCalendarsWithColors = getSelectedCalendarsWithColors();
    final total = selectedCalendarsWithColors.length;
    var completed = 0;

    for (var entry in selectedCalendarsWithColors.entries) {
      Map<String, int> calendarInfo = {};
      calendarInfo[entry.key] = entry.value;
      await GoogleServices.createCalendar(account, calendarInfo);
      completed++;
      setState(() {
        _progress = completed / total;
      });
    }

    setState(() => _isLoading = false);
    Navigator.of(context)
        .pop(); // Optionally, close the dialog or navigate after completion
  }

  Map<String, int> getSelectedCalendarsWithColors() {
    Map<String, int> selectedCalendarsWithColors = {};
    _selectedCalendars.forEach((key, value) {
      if (value) {
        final colorId =
            int.parse(_selectedColors[key]!.replaceAll('Color ', ''));
        selectedCalendarsWithColors[key] = colorId;
      }
    });

    return selectedCalendarsWithColors;
  }
}
