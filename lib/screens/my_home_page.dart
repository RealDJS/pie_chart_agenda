import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pie_agenda/display/point.dart';
import 'package:pie_agenda/pie/slice.dart';
import 'package:pie_agenda/pie/task.dart';
import 'package:pie_agenda/display/dragbutton.dart';
import 'package:pie_agenda/pie/pie.dart';
import 'package:pie_agenda/display/piepainter.dart';
import 'package:pie_agenda/display/clock.dart';

/// These will be re-instantiated as soon as we get the width of the screen
Pie pie = Pie(350);
PiePainter painter = PiePainter(pie: pie);
Slice selectedSlice = Slice();

const Color mainBackground = Color.fromRGBO(219, 220, 255, 1); //(219,220,255)
const Color menuBackground = Color.fromRGBO(212, 255, 234, 1); //(212,255,234)
const Color topBackground = Color.fromRGBO(238, 203, 255, 1); //(238,203,255)

/// Home Page Widget
class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

/// App Home Page
class MyHomePageState extends State<MyHomePage> {
  Timer? _timer;
  final GlobalKey _gestureKey = GlobalKey();
  double? widgetHeight;
  double? widgetWidth;

  void _getWidgetSize() {
    final RenderBox renderBox =
        _gestureKey.currentContext!.findRenderObject() as RenderBox;
    setState(() {
      widgetHeight = renderBox.size.height;
      widgetWidth = renderBox.size.width;
    });
  }

  @override
  void initState() {
    super.initState();
    // Get the dimensions of the app ASAP here
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getWidgetSize();
      // Find the smallest of the two dimensions
      double smallestDimension = min(widgetHeight!, widgetWidth!);
      // Use the dimensions here
      pie = Pie(smallestDimension * .9);
      painter = PiePainter(pie: pie);
    });
    startTimer();
  }

  /// Creates labeled text fields for user input
  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
    );
  }

  /// Builds the display for the Home Page.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: mainBackground,
        appBar: AppBar(
            backgroundColor: topBackground,
            title: Text(widget.title),
            bottom: const PreferredSize(
                preferredSize: Size.fromHeight(30.0),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                        padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
                        child: Clock())))),
        body: GestureDetector(
          key: _gestureKey,
          onTapDown: (details) {
            _getWidgetSize();
            // We need to get the rotation from the center that a tapped point is at
            // convert it to a double time
            // print("$widgetWidth and height: $widgetHeight");

            double tapTime = DragButton.getTimeFromPoint(Point.parameterized(
                x: details.localPosition.dx -
                    (widgetWidth! / 2) +
                    (pie.width / 2),
                y: details.localPosition.dy -
                    (widgetHeight! / 2) +
                    (pie.width / 2)));
            // Need to start from the corner of the pie, not the corner of the whole window
            // search through the slices for one whose endpoints are before and after this time
            int i = 0;
            bool found = false;
            for (Slice slice in pie.slices) {
              if (slice.getStartTime() - .2 < tapTime) {
                if (slice.getEndTime() + .2 > tapTime) {
                  //.2 accounts for dragbutton :O
                  selectedSlice = slice;
                  pie.setSelectedSliceIndex(i);
                  found = true;
                  break;
                }
              }
              i++;
            }
            if (!found) {
              pie.setSelectedSliceIndex(-1);
              // if one was not selected, deselect what we do have
            }
            updateScreen();
          },
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: _buildPie(),
            ),
          ),
        ),
        floatingActionButton: _buildFloatingActionButtons());
  }

  Widget _buildFloatingActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        FloatingActionButton(
          onPressed: _showAddSliceDialog,
          tooltip: 'Add Slice',
          child: const Icon(Icons.add),
        ),
        if (isEditing()) const SizedBox(width: 10),
        if (isEditing())
          FloatingActionButton(
            onPressed: _removeSelectedSlice,
            tooltip: 'Delete Slice',
            child: const Icon(Icons.delete_forever),
          ),
        const SizedBox(width: 10),
        FloatingActionButton(
          onPressed: _listSlices,
          tooltip: 'List Slices',
          child: const Icon(Icons.list),
        )
      ],
    );
  }

  /// Opens dialog to add a new slice to the pie
  void _showAddSliceDialog() {
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();
    final taskController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildAddSliceDialog(
          startTimeController,
          endTimeController,
          taskController,
        );
      },
    );
  }

  void _removeSelectedSlice() {
    // get the last slice that was selected
    // remove it from the slices
    pie.removeSlice();
  }

  /// Dialog structure for adding a new slice
  Widget _buildAddSliceDialog(
      TextEditingController startController,
      TextEditingController durationController,
      TextEditingController taskController) {
    return AlertDialog(
      backgroundColor: menuBackground,
      title: const Text('Add New Slice'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTextField(startController, 'Start Time'),
          _buildTextField(durationController, 'Duration'),
          _buildTextField(taskController, 'Task Description'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            _addUserSlice(
              startController.text,
              durationController.text,
              taskController.text,
            );
            Navigator.of(context).pop();
          },
          child: const Text('Add Slice'),
        ),
      ],
    );
  }

  /// Validates input and adds a new slice if valid.
  void _addUserSlice(String startText, String endText, String taskText) {
    final startTime = double.tryParse(startText) ?? 0;
    final duration = double.tryParse(endText) ?? 0;

    if (startTime >= 0 && duration >= 0 && taskText.isNotEmpty) {
      setState(() {
        Task task = Task.parameterized(taskText, startTime, duration);
        pie.addSlice(task);
        pie.selectedSliceIndex = pie.slices.length - 1;
        painter = PiePainter(pie: pie); // Update painter with new data
      });
    } else {
      print("Invalid input for start, end time, or empty task");
    }
  }

  Offset windowSize() {
    return Offset(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
  }

  void _listSlices() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: menuBackground,
          title: const Text('Slices'),
          content: SingleChildScrollView(
            child: ListBody(
              children: pie.slices.map((slice) {
                return ListTile(
                  title: Text(slice.getTaskName()),
                  subtitle: Text(
                      'Start: ${_formatTime(slice.getStartTime())}, End: ${_formatTime(slice.getEndTime())}'),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void updateScreen() {
    setState(() {
      painter = PiePainter(pie: pie);
    });
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      updateScreen();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Converts a slice's time to a time format.
String _formatTime(double time) {
  int hours = time.floor();
  int minutes = ((time - hours) * 60).round();
  // Handle cases where minutes might be 60 due to rounding
  if (minutes == 60) {
    hours += 1;
    minutes = 0;
  }
  // Ensure hours wrap around if exceeding 24
  hours = hours % 24;
  String timeOfDay = "$hours:$minutes";
  return timeOfDay;
}

/// Build the PiePainter and the DragButtons being used in the program.
List<Widget> _buildPie() {
  List<Widget> pieAndDragButtons = [];
  // First item is the pie painter, the rest are dragbuttons
  pieAndDragButtons.add(
    CustomPaint(
        size: Size(pie.width + buttonDiameter, pie.width + buttonDiameter),
        painter: painter),
  );
  if (isEditing()) {
    for (Slice slice in pie.slices) {
      pieAndDragButtons.add(slice.dragButtonBefore);
      pieAndDragButtons.add(slice.dragButtonAfter);
    }
  }
  print(pie.selectedSliceIndex);
  return pieAndDragButtons;
}

bool isEditing() {
  return pie.selectedSliceIndex > -1;
}
