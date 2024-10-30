// Dennis Skoy
// ignore_for_file: no_leading_underscores_for_local_identifiers

/// And object that stores a task's main attributes:
/// * _taskName - The task's name.
/// * _duration - How long a task lasts.
/// * _startTime - When a task starts.
/// * _endTime - When a task ends.
class Task {
  // This is the data of a task/slice. This must be able to be stored in .json
  String _taskName; //
  double _duration;
  double _startTime;
  double _endTime;

  /// Task Constructor
  /// Time Syntax is as such:
  /// * 1.25 = 1:30
  /// * 0.5 = 12:30
  Task(this._taskName, this._startTime, this._endTime)
      : _duration = _endTime - _startTime;

// Getters and Setters
  /// Returns the task's name.
  String getTaskName() {
    return _taskName;
  }

  /// Returns the task's duration
  double getDuration() {
    return _duration;
  }

  /// Returns the task's startTime
  double getStartTime() {
    return _startTime;
  }

  /// Returns the task's endTime.
  double getEndTime() {
    "Get the EndTime";
    return _endTime;
  }

  /// Set the task's _taskName.
  void changeTaskName(String _taskName) {
    this._taskName = _taskName;
  }

  /// Set the tasks's _duration.
  void changeDuration(double _duration) {
    this._duration = _duration;
  }

  /// Set the task's _startTime.
  void changeStartTime(double _startTime) {
    this._startTime = _startTime;
  }

  /// Set the task's _endTime.
  void changeEndTime(double _endTime) {
    this._endTime = _endTime;
  }

  /// Convert Task object to JSON.
  /// * String jsonString = jsonEncode(task.toJson());
  Map<String, dynamic> toJson() {
    return {
      '_taskName': _taskName,
      '_duration': _duration,
      '_startTime': _startTime,
      '_endTime': _endTime,
    };
  }

  /// Convert JSON to a Task object.
  /// * Task taskFromJson = Task.fromJson(jsonDecode(jsonString));
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(json['_taskName'] as String, json['_startTime'] as double,
        json['_endTime'] as double);
  }
}
