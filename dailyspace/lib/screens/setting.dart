import 'dart:developer';

import 'package:dailyspace/datastructures/calendar_manager.dart';
import 'package:dailyspace/datastructures/data_manager.dart';
import 'package:dailyspace/main.dart';
import 'package:dailyspace/widgets/activity_tracker/calendar_overlay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dailyspace/screens/login_screen.dart';
import 'package:dailyspace/services/google_sign_in_manager.dart';

class SettingsPage2 extends StatefulWidget {
  final CalendarManager calendarManager;
  final DataManager dataManager;
  const SettingsPage2(
      {Key? key, required this.calendarManager, required this.dataManager})
      : super(key: key);

  @override
  State<SettingsPage2> createState() => _SettingsPage2State();
}

class _SettingsPage2State extends State<SettingsPage2> {
  bool _isDark = false;
  late CalendarManager calendarManager;
  late DataManager dataManager;

  @override
  @override
  void initState() {
    super.initState();
    calendarManager = widget.calendarManager;
    dataManager = widget.dataManager;
  }

  void _signOut() async {
    await GoogleSignInManager.instance.signOut();
    // Navigate back to the login screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          builder: (context) => MainScreen(
                calendarManager: calendarManager,
                dataManager: dataManager,
              )),
    );
  }

  void _openCalendarOverlay() {
    log("calendars from overlay main" +
        calendarManager.availableCalendars.toString());
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CalendarOverlayDialog(
          availableCalendars: calendarManager.availableCalendars,
          selectedCalendars: calendarManager.selectedCalendars,
        );
      },
    ).then((result) {
      if (result != null) {
        setState(() {
          // selectedCalendars = result as Set<String>;
          //_fetchActivities();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Settings"),
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: ListView(
              children: [
                _SingleSection(
                  title: "General",
                  children: [
                    _CustomListTile(
                      title: "Sign out",
                      icon: Icons.exit_to_app_rounded,
                      onTap: _signOut,
                    ),
                  ],
                ),
                const Divider(),
                _SingleSection(
                  title: "Data",
                  children: [
                    _CustomListTile(
                      title: "Manage Calendars",
                      icon: Icons.calendar_today_outlined,
                      onTap: _openCalendarOverlay,
                    ),
                    _CustomListTile(
                      title: "Refresh",
                      icon: Icons.cloud_sync,
                      onTap: () async {
                        await dataManager.fetchAndStoreActivities(
                            GoogleSignInManager.instance.currentUser);
                      },
                    ),
                  ],
                ),
                const Divider(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomListTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _CustomListTile({
    required this.title,
    required this.icon,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      leading: Icon(icon),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _SingleSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _SingleSection({
    this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ...children,
      ],
    );
  }
}
