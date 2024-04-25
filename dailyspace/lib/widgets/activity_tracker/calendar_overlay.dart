import 'package:dailyspace/services/google_services.dart';
import 'package:dailyspace/services/google_sign_in_manager.dart';
import 'package:dailyspace/screens/acitivity_tracker.dart';
import 'package:dailyspace/widgets/activity_tracker/add_calendar.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class CalendarOverlayDialog extends StatefulWidget {
  final List<String> availableCalendars;
  final Set<String> selectedCalendars;

  const CalendarOverlayDialog({
    super.key,
    required this.availableCalendars,
    required this.selectedCalendars,
  });

  @override
  _CalendarOverlayDialogState createState() => _CalendarOverlayDialogState();
}

class _CalendarOverlayDialogState extends State<CalendarOverlayDialog> {
  Set<String>? _newSelectedCalendars;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 0.8;
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Select Calendar(s)',
            style:
                TextStyle(fontSize: width * 0.06, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              _fetchCalendars();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _openAddCalendarOverlay();
            },
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          itemCount: widget.availableCalendars.length,
          itemBuilder: (context, index) {
            final calendarKey = widget.availableCalendars[index];
            return CheckboxListTile(
              title: Text(calendarKey),
              value: widget.selectedCalendars.contains(calendarKey),
              onChanged: (bool? value) {
                setState(() {
                  if (value != null) {
                    if (value) {
                      widget.selectedCalendars.add(calendarKey);
                    } else {
                      widget.selectedCalendars.remove(calendarKey);
                    }
                  }
                });
              },
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () async {
            _newSelectedCalendars = widget.selectedCalendars;
            await firebaseManager.saveSelectedCalendars(_newSelectedCalendars!);
            Navigator.of(context).pop(_newSelectedCalendars);
          },
          child: const Text('OK'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_newSelectedCalendars);
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _openAddCalendarOverlay() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddCalendarOverlay();
      },
    );
  }

  Future<void> _fetchCalendars() async {
    GoogleSignInAccount? account = GoogleSignInManager.instance.currentUser;
    try {
      // Fetch new calendars
      final calendars = await GoogleServices.fetchCalendars(account);
      setState(() {
        // Update available calendars
        widget.availableCalendars.clear();
        calendars.forEach((title, value) {
          widget.availableCalendars.add(title);
        });
      });
    } catch (e) {
      // Handle potential errors from the fetch call
      print("Error fetching calendars: $e");
    }
  }

  @override
  void dispose() {
    _newSelectedCalendars = widget.selectedCalendars;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _newSelectedCalendars = widget.selectedCalendars;
  }

  @override
  void didUpdateWidget(CalendarOverlayDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    _newSelectedCalendars = widget.selectedCalendars;
  }

  @override
  void setState(VoidCallback fn) {
    _newSelectedCalendars = widget.selectedCalendars;
    super.setState(fn);
  }
}
