import 'package:flutter/material.dart';
import '../utils/date_utils.dart';
import '../User/models/user_model.dart';
import '../User/models/goal_model.dart';
import '../User/models/notification_model.dart';
import '../widgets/date_input_widget.dart';

/// Example showing how to use the new MM/DD/YYYY date format throughout the system
class DateUsageExample extends StatefulWidget {
  const DateUsageExample({Key? key}) : super(key: key);

  @override
  _DateUsageExampleState createState() => _DateUsageExampleState();
}

class _DateUsageExampleState extends State<DateUsageExample> {
  DateTime? selectedDate;
  final UserModel? sampleUser = UserModel(
    id: 1,
    email: 'john@example.com',
    password: 'password',
    fname: 'John',
    mname: 'Michael',
    lname: 'Doe',
    bday: DateTime(1990, 5, 15), // May 15, 1990
    createdAt: DateTime.now(),
    isPremium: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Date Format Examples'),
        backgroundColor: const Color(0xFF4ECDC4),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Utility Examples
            _buildSection('Date Utility Functions', [
              _buildExample('Current Date (Display)', CnergyDateUtils.getCurrentDisplayDate()),
              _buildExample('Current Date (API)', CnergyDateUtils.getCurrentApiDate()),
              _buildExample('Current DateTime (API)', CnergyDateUtils.getCurrentApiDateTime()),
              _buildExample('Parse Display Date', 
                CnergyDateUtils.parseDisplayDate('05/15/1990')?.toString() ?? 'Invalid'),
              _buildExample('Parse API Date', 
                CnergyDateUtils.parseApiDate('1990-05-15')?.toString() ?? 'Invalid'),
            ]),

            const SizedBox(height: 20),

            // User Model Examples
            if (sampleUser != null) ...[
              _buildSection('User Model Date Formatting', [
                _buildExample('Birthdate (Display)', sampleUser!.formattedBirthdate),
                _buildExample('Birthdate (API)', CnergyDateUtils.toApiDate(sampleUser!.bday)),
                _buildExample('Age', '${sampleUser!.age} years old'),
                _buildExample('Created At (Display)', sampleUser!.formattedCreatedAt),
                _buildExample('Created At (API)', CnergyDateUtils.toApiDateTime(sampleUser!.createdAt!)),
              ]),
              const SizedBox(height: 20),
            ],

            // Goal Model Examples
            _buildSection('Goal Model Date Formatting', [
              _buildExample('Goal Target Date', 
                GoalModel(
                  userId: 1,
                  goal: 'Lose 10 pounds',
                  targetDate: DateTime.now().add(const Duration(days: 30)),
                  createdAt: DateTime.now(),
                ).formattedTargetDate),
              _buildExample('Goal Relative Date', 
                GoalModel(
                  userId: 1,
                  goal: 'Lose 10 pounds',
                  targetDate: DateTime.now().add(const Duration(days: 30)),
                  createdAt: DateTime.now(),
                ).relativeTargetDate),
            ]),

            const SizedBox(height: 20),

            // Notification Model Examples
            _buildSection('Notification Model Date Formatting', [
              _buildExample('Notification Time', 
                NotificationModel(
                  id: 1,
                  message: 'Welcome to CNERGY!',
                  timestamp: DateTime.now().toIso8601String(),
                  statusName: 'unread',
                  typeName: 'info',
                  isUnread: true,
                ).getFormattedTime()),
              _buildExample('Notification Date', 
                NotificationModel(
                  id: 1,
                  message: 'Welcome to CNERGY!',
                  timestamp: DateTime.now().toIso8601String(),
                  statusName: 'unread',
                  typeName: 'info',
                  isUnread: true,
                ).getFormattedDate()),
            ]),

            const SizedBox(height: 20),

            // Date Input Widget Example
            _buildSection('Date Input Widget', [
              DateInputWidget(
                label: 'Select Birthdate',
                initialDate: selectedDate,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                onChanged: (date) {
                  setState(() {
                    selectedDate = date;
                  });
                },
                validator: (date) {
                  if (date == null) return 'Please select a date';
                  if (date.isAfter(DateTime.now())) return 'Date cannot be in the future';
                  return null;
                },
              ),
              if (selectedDate != null) ...[
                const SizedBox(height: 16),
                Text('Selected Date: ${CnergyDateUtils.toDisplayDate(selectedDate!)}'),
                Text('API Format: ${CnergyDateUtils.toApiDate(selectedDate!)}'),
                Text('Age: ${CnergyDateUtils.calculateAge(selectedDate!)} years old'),
              ],
            ]),

            const SizedBox(height: 20),

            // Date Comparison Examples
            _buildSection('Date Comparison Examples', [
              _buildExample('Is Today', CnergyDateUtils.isToday(DateTime.now()).toString()),
              _buildExample('Is Past', CnergyDateUtils.isPast(DateTime(2020, 1, 1)).toString()),
              _buildExample('Is Future', CnergyDateUtils.isFuture(DateTime(2030, 1, 1)).toString()),
              _buildExample('Relative Date (Yesterday)', 
                CnergyDateUtils.getRelativeDate(DateTime.now().subtract(const Duration(days: 1)))),
              _buildExample('Relative Date (Tomorrow)', 
                CnergyDateUtils.getRelativeDate(DateTime.now().add(const Duration(days: 1)))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4ECDC4),
          ),
        ),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildExample(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
