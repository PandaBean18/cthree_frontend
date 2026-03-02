import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class ContentPlannerScreen extends StatefulWidget {
  const ContentPlannerScreen({super.key});

  @override
  State<ContentPlannerScreen> createState() => _ContentPlannerScreenState();
}

class _ContentPlannerScreenState extends State<ContentPlannerScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool isDraftDone = false;
  bool isVlogDone = false;
  bool isMeetingDone = true;
  var months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
  String selectedDayStr = "";
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              
              // --- Optimized Calendar ---
              _buildTableCalendar(),

              const SizedBox(height: 40),
              _buildScheduleHeader(),
              const SizedBox(height: 24),

              // Tasks (These will eventually map to your Rails API data)
              _buildTaskCard(time: "10:00 AM", title: "Nike Campaign Draft", status: isDraftDone ? "COMPLETED" : "DRAFTING PHASE", accent: const Color(0xFF45A2FF), isDone: isDraftDone, onTap: () {setState(() {
                isDraftDone = !isDraftDone;
              });}),
              _buildTaskCard(time: "02:30 PM", title: "Vlog Editing Sesh", status: isVlogDone ? "COMPLETED" : "READY TO START", accent: const Color(0xFFE157A4), isDone: isVlogDone, onTap: () {setState(() {
                isVlogDone = !isVlogDone;
              });}),
              _buildTaskCard(time: "05:00 PM", title: "Brand Meeting", status: isMeetingDone ? "COMPLETED" : "SCHEDULED",accent: const Color(0xFF45A2FF), isDone: true, onTap: () {setState(() {
                isMeetingDone = !isMeetingDone;
              });}),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildBottomActions(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );

    
  }

  Widget _buildTableCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12151C), // Background
        borderRadius: BorderRadius.circular(16),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        startingDayOfWeek: StartingDayOfWeek.sunday,
        
        // --- Styling to match your UI ---
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
          leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFF6F7685)),
          rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFF6F7685)),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Color(0xFF6F7685), fontSize: 12),
          weekendStyle: TextStyle(color: Color(0xFF6F7685), fontSize: 12),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: const TextStyle(color: Color(0xFF6F7685)),
          weekendTextStyle: const TextStyle(color: Color(0xFF6F7685)),
          
          // Selection Styling
          selectedDecoration: const BoxDecoration(
            color: Color(0xFFE157A4), // Your Secondary Pink
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          
          // Today Styling
          todayDecoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF45A2FF), width: 1), // Primary Blue outline
            shape: BoxShape.rectangle,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          
          // Grid lines effect
          outsideDaysVisible: false,
          rowDecoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF1E222A), width: 0.5)),
          ),
        ),

        // --- Logic ---
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            HashMap<int, String> months = new HashMap();
            months[1] = 'JAN';
            months[2] = 'FEB';
            months[3] = 'MAR';
            months[4] = 'APR';
            months[5] = 'MAY';
            months[6] = 'JUN';
            months[7] = 'JUL';
            months[8] = 'AUG';
            months[9] = 'SEP';
            months[10] = 'OCT';
            months[11] = 'NOV';
            months[12] = 'DEC';

            String monthStr = months[selectedDay.month]!;
            int monthDate = selectedDay.day;
            selectedDayStr = "$monthStr $monthDate";
            selectedYear = selectedDay.year;
            selectedMonth = selectedDay.month;

            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
      ),
    );
  }

 Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "CONTENT",
              style: TextStyle(
                color: Colors.white, 
                fontSize: 32, 
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "PLANNER",
              style: TextStyle(
                color: const Color(0xFF45A2FF).withOpacity(0.8), // Primary Blue
                fontSize: 32, 
                fontWeight: FontWeight.bold, 
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
             Text(
              "${months[selectedMonth-1]} ${selectedYear}", 
              style: TextStyle(color: Color(0xFF6F7685), fontSize: 14),
            ),
          ],
        ),
        Row(
          children: [
            _buildHeaderCircle(Icons.list),
            const SizedBox(width: 12),
            _buildHeaderCircle(Icons.more_horiz),
          ],
        )
      ],
    );
  }

  // The "DAILY SCHEDULE" sub-header with the date chip
  Widget _buildScheduleHeader() {
    return Row(
      children: [
        const Text(
          "DAILY ", 
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Text(
          "SCHEDULE", 
          style: TextStyle(
            color: Color(0xFFE157A4), // Secondary Pink
            fontSize: 24, 
            fontWeight: FontWeight.bold, 
            fontStyle: FontStyle.italic,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E222A), // Surface
            borderRadius: BorderRadius.circular(12),
          ),
          child:  Text(
            (selectedDayStr == '' ? '${months[DateTime.now().month-1]} ${DateTime.now().day}' : selectedDayStr), 
            style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }

  // Helper for the circular buttons in the top right
  Widget _buildHeaderCircle(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E222A), // Surface
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildTaskCard({
    required String time,
    required String title,
    required String status,
    required Color accent,
    required bool isDone,
    required VoidCallback onTap, // New callback parameter
  }) {
    return GestureDetector(
      onTap: onTap, // Entire card is now clickable for better UX
      child: Opacity(
        opacity: isDone ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E222A), 
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(time, style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      title, 
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(isDone ? Icons.check_circle : Icons.circle, color: accent, size: 12),
                        const SizedBox(width: 8),
                        Text(status, style: const TextStyle(color: Color(0xFF6F7685), fontSize: 10, letterSpacing: 1)),
                      ],
                    ),
                  ],
                ),
              ),
              
              // The Interactive Tick Box
              AnimatedContainer(
                duration: const Duration(milliseconds: 200), // Smooth transition
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDone ? Colors.transparent : const Color(0xFF6F7685),
                  ),
                  color: isDone ? const Color(0xFF45A2FF) : Colors.transparent,
                ),
                child: isDone ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FloatingActionButton(
            heroTag: "chat",
            backgroundColor: const Color(0xFF1E222A),
            onPressed: () {},
            child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          ),
          FloatingActionButton.extended(
            heroTag: "add",
            backgroundColor: const Color(0xFF45A2FF),
            onPressed: () {},
            label: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  // ... (Keep the _buildHeader, _buildScheduleHeader, _buildTaskCard, and _buildBottomActions from the previous response)
}