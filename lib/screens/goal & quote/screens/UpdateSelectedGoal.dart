import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emindmatterssystem/screens/goal%20&%20quote/screens/DisplayAllGoals.dart';
import 'package:emindmatterssystem/utils/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model data/GoalModel.dart';

class UpdateSelectedGoalPage extends StatefulWidget {
  final String goalId; // Add a field to receive the goalId
  final Function refreshGoalsCallback;

  UpdateSelectedGoalPage({Key? key, required this.goalId, required this.refreshGoalsCallback}) : super(key: key);

  @override
  _UpdateSelectedGoalPageState createState() => _UpdateSelectedGoalPageState();
}

class _UpdateSelectedGoalPageState extends State<UpdateSelectedGoalPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedStartDate = DateTime.now();
  DateTime? _selectedDueDate;
  GoalStatus? _selectedStatus;
  GoalPriority? _selectedPriority;
  Color _getPriorityColor() {
    return _selectedPriority != null ? GoalModel(priority: _selectedPriority!, title: '', userId: '', status: GoalStatus.active).getPriorityColor() : backgroundColors;
  }
  double _progress = 0.0;
  AnimationController? _animationController;
  Animation<double>? _opacityAnimation;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  GoalModel? _currentGoal;

  @override
  void initState() {
    super.initState();
    _loadGoalData();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController!);
    _animationController!.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _loadGoalData() async {
    try {
      DocumentSnapshot goalSnapshot = await _db.collection('goals').doc(widget.goalId).get();
      if (goalSnapshot.exists) {
        Map<String, dynamic> goalData = goalSnapshot.data() as Map<String, dynamic>;
        _currentGoal = GoalModel.fromMap(goalData, widget.goalId);
        // Set the UI fields with the data from the loaded goal
        _titleController.text = _currentGoal!.title;
        _notesController.text = _currentGoal!.notes ?? '';
        _selectedStartDate = _currentGoal!.startDate ?? DateTime.now();
        _selectedDueDate = _currentGoal!.dueDate;
        _selectedStatus = _currentGoal!.status;
        _selectedPriority = _currentGoal!.priority;
        _progress = _currentGoal!.progress / 100; // Convert progress back to a fraction
        setState(() {}); // Call setState to refresh the UI with the loaded data
      }
    } catch (e) {
      _showErrorMessage('Failed to load goal: $e');
    }
  }

  // Save goal data to Firestore with optimization
  Future<void> _saveGoal() async {
    if (_titleController.text.isEmpty) {
      _showErrorMessage('Goal title cannot be empty.');
      return;
    }

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.uid.isEmpty) {
        _showErrorMessage('User is not authenticated.');
        return;
      }

      if (_currentGoal == null) {
        _showErrorMessage('Goal data is not initialized.');
        return;
      }

      String userId = _currentGoal!.userId.isNotEmpty ? _currentGoal!.userId : currentUser.uid;

      // Update the current goal's data
      _currentGoal = GoalModel(
        goalId: _currentGoal!.goalId, // Preserve the original goalId
        title: _titleController.text,
        notes: _notesController.text,
        startDate: _selectedStartDate, // Start date is not editable
        dueDate: _selectedDueDate,
        userId: userId,
        status: _progress == 1.0 ? GoalStatus.completed : _selectedStatus!,
        priority: _selectedPriority!,
        progress: _progress * 100,
      );

      await _db.collection('goals').doc(_currentGoal!.goalId).update(_currentGoal!.toMap());
      widget.refreshGoalsCallback();

      int tabIndex;
      if (_currentGoal!.status == GoalStatus.completed) {
        tabIndex = 1; // Index for Completed Goals tab
      } else {
        tabIndex = 0; // Index for Uncompleted Goals tab
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => DisplayAllGoalsPage(initialTabIndex: tabIndex)),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      _showErrorMessage('Failed to save goal: $e');
    }
  }

  void _showErrorMessage(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: pShadeColor4,
        title: const Text(
          "Update Goal",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DisplayAllGoalsPage()),
            );
          },
          icon: Icon(Icons.close, color: Colors.white,),
        ),
      ),
      // Update the Scaffold background color based on the selected priority
      backgroundColor: _getPriorityColor(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: FadeTransition(
          opacity: _opacityAnimation!,
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                _buildTextField(_titleController, 'Title'),
                SizedBox(height: 20),
                _buildTextField(_notesController, 'Notes', maxLines: 3),
                SizedBox(height: 20),
                _buildNonEditableStartDate(),
                SizedBox(height: 20),
                _buildDatePicker1('Due Date', (date) => setState(() => _selectedDueDate = date)),
                SizedBox(height: 20),
                _buildDropdown<GoalStatus>(
                  'Status',
                  GoalStatus.values,
                  _selectedStatus,
                      (GoalStatus? newValue) => setState(() => _selectedStatus = newValue),
                ),
                SizedBox(height: 20),
                _buildDropdown<GoalPriority>(
                  'Priority',
                  GoalPriority.values,
                  _selectedPriority,
                      (GoalPriority? newValue) => setState(() => _selectedPriority = newValue),
                ),
                SizedBox(height: 20),
                _buildProgressSlider(),
                SizedBox(height: 30),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: pShadeColor9), // Custom border color
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: pShadeColor4), // Custom border color for enabled state
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter some text';
        }
        return null;
      },
    );
  }

  Widget _buildNonEditableStartDate() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: pShadeColor4),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: ListTile(
        title: Text(
          DateFormat('dd/MM/yyyy').format(_selectedStartDate),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              color: pShadeColor9,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildDatePicker1(String label, ValueChanged<DateTime> onDateChanged) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: pShadeColor4), // Custom border color
        borderRadius: BorderRadius.circular(8), // Border radius
        color: Colors.white, // Background color
      ),
      child: ListTile(
        title: Text(_selectedDueDate == null ? label : DateFormat('dd/MM/yyyy').format(_selectedDueDate!)),
        trailing: Icon(Icons.calendar_today, color: pShadeColor9),
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: _selectedDueDate ?? _selectedStartDate, // Default to start date if due date isn't set
            firstDate: _selectedStartDate, // Set the minimum date to the start date
            lastDate: DateTime(2025),
          );
          if (picked != null && picked != _selectedDueDate) {
            onDateChanged(picked);
            setState(() {
              _selectedDueDate = picked; // Update the selected due date
            });
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }


  Widget _buildDropdown<T>(String label, List<T> items, T? currentValue, ValueChanged<T?> onChanged) {
    return DropdownButtonFormField<T>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // Rounded border
          borderSide: BorderSide(color: pShadeColor4), // Custom border color
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: pShadeColor4), // Custom border color for enabled state
        ),
        filled: true,
        fillColor: Colors.white, // Background color inside the dropdown
      ),
      style: TextStyle( // Custom text style for dropdown items
        color: Colors.black,
        fontSize: 16,
      ),
      dropdownColor: Colors.white, // Background color of dropdown items
      icon: Icon(Icons.arrow_drop_down, color: pShadeColor9), // Custom icon
      items: items.map<DropdownMenuItem<T>>((T value) {
        return DropdownMenuItem<T>(
          value: value,
          child: Text(
            value.toString().split('.').last,
            style: TextStyle(color: Colors.black), // Style for each item in dropdown
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }


  Widget _buildProgressSlider() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: pShadeColor4), // Custom border color
        borderRadius: BorderRadius.circular(8), // Border radius
        color: Colors.white, // Background color
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Initial Progress: ${(_progress * 100).toInt()}%'),
          Slider(
            value: _progress,
            onChanged: (newProgress) {
              setState(() {
                _progress = newProgress;
                // Update the current goal's progress, if it exists
                if (_currentGoal != null) {
                  _currentGoal!.progress = newProgress * 100; // Convert to percentage
                  _currentGoal!.status = newProgress == 1.0 ? GoalStatus.completed : GoalStatus.active;
                }
              });
            },
            min: 0.0,
            max: 1.0,
            divisions: 100,
            label: '${(_progress * 100).toInt()}%',
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _saveGoal,
      child: Text(
        'Submit',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: pShadeColor4,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
    );
  }

}