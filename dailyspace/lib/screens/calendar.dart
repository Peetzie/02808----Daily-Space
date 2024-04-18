import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class Calendar extends StatefulWidget {
  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  DateTime selectedDate = DateTime.now();
  bool isCalendarVisible = false;

  void _showCalendarDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: Color.fromARGB(255, 255, 255, 255),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: selectedDate,
                onDateTimeChanged: (DateTime newDateTime) {
                  setState(() {
                    selectedDate = newDateTime;
                  });
                },
                use24hFormat: true,
                minuteInterval: 1,
              ),
            ),
            CupertinoButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  children: [
                    Text(
                      '${selectedDate.day}-${selectedDate.month}-${selectedDate.year}',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.indigo[700]),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(isCalendarVisible
                          ? Icons.calendar_today
                          : Icons.calendar_today_outlined),
                      onPressed: () {
                        setState(() {
                          isCalendarVisible = !isCalendarVisible;
                        });
                        _showCalendarDialog();
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
