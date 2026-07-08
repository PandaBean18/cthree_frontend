import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cthree/core/api/calendar_repository.dart';
import 'package:cthree/core/models/calendar_entry_model.dart';
import 'package:google_fonts/google_fonts.dart';


class ContentPlannerScreen extends StatefulWidget {
  const ContentPlannerScreen({super.key});

  @override
  State<ContentPlannerScreen> createState() => _ContentPlannerScreenState();
}

class _ContentPlannerScreenState extends State<ContentPlannerScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  var months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
  String selectedDayStr = "";
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  final CalendarRepository _calendarRepository = CalendarRepository();
  CalendarModel? _calendarData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCalendar();
  }

  Future<void> _fetchCalendar() async {
    try {
      final data = await _calendarRepository.getCalendar();

      if (mounted) {
        setState(() {
          _calendarData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading 
      ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary,))
      : SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              
              _buildTableCalendar(),

              const SizedBox(height: 40),
              _buildScheduleHeader(),
              const SizedBox(height: 24),

              _buildTasksForDay(_selectedDay ?? _focusedDay),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildBottomActions(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _showAddEntryDialog(BuildContext context) async {
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _briefController = TextEditingController();
    DateTime _selectedDate = DateTime.now();
    String _selectedType = 'reel';
    bool _isCreating = false;

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(20)),
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "New Calendar Entry",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFF6F7685)),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          )
                        ],
                      ),
                      Divider(color: Theme.of(context).colorScheme.surface,),
                      const SizedBox(height: 16,),

                      _buildInputField(controller: _titleController, label: "Title", placeholder: 'e.g. Edit Jaipur Vlog'),
                      const SizedBox(height: 16,),

                      _buildInputField(controller: _briefController, label: 'Brief (Optional)', placeholder: 'e.g. Edit Jaipur vlog, full version for yt and teaser for insta', maxLines: 2),
                      const SizedBox(height: 16),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Entry Type', style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 5),
                      _buildDropdown(value: _selectedType, onChanged: (val) => setDialogState(() => _selectedType = val!)),
                      const SizedBox(height: 24,),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Select Date', style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: Theme.of(context).primaryColor,
                            surface: Theme.of(context).scaffoldBackgroundColor
                          )
                        ),
                        child: SizedBox(
                          height: 250,
                          child: CalendarDatePicker(
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                            onDateChanged: (date) => setDialogState(() => _selectedDate = date),
                          ),
                        ),
                      ),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                          onPressed: _isCreating
                            ? null
                            : () async {
                            if (_titleController.text.isNotEmpty) {
                              setDialogState(() {
                                _isCreating = true;
                              });
                              final newEntry = CalendarEntryModel(
                                title: _titleController.text,
                                brief: _briefController.text,
                                date: _selectedDate,
                                entryType: _selectedType,
                                isCompleted: false,
                              );
                              
                              final result = await _calendarRepository.createDeliverableEntry(newEntry);

                              if (result == true) {
                                Navigator.pop(context);
                                setState(() {
                                  _isLoading = true;
                                });
                                await _fetchCalendar();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Something went wrong"),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              } 
                            }
                          },
                          child: _isCreating 
                          ? CircularProgressIndicator(color: Colors.white, constraints: BoxConstraints(minHeight: 20, minWidth: 20))
                          : Text("Add To Calendar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      } 
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required String placeholder, int maxLines = 1 }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8,),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Color(0xFF6F7685), fontSize: 12),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)
          ),
        )
      ],
    );
  }

  Widget _buildDropdown({ required String value, required Function(String?) onChanged}) {
    final Map<String, Color> accents = {
      'reel': Theme.of(context).colorScheme.secondary,
      'post': Theme.of(context).primaryColor,
      'video':  Color(0xFFEE4445),
      'story': Color(0xFFF97316),
      'other': Colors.white
    };
    return DropdownButtonFormField<String>(
      value: value,
      borderRadius: BorderRadius.circular(12),
      dropdownColor: Theme.of(context).colorScheme.surface,
      isExpanded: true,
      decoration: InputDecoration(
        floatingLabelBehavior: FloatingLabelBehavior.never,
        labelStyle: const TextStyle(color: Color(0xFF6F7685)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: accents.keys.map((String type) {
        return DropdownMenuItem(
          value: type,
          child: Row(
            children: [
              Icon(Icons.circle, size: 10, color: accents[type],),
              const SizedBox(width: 10,),
              Text(type.toUpperCase(), style: TextStyle(fontSize: 12),)
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTableCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12151C), 
        borderRadius: BorderRadius.circular(16),
      ),
      child: TableCalendar(
        pageJumpingEnabled: true,
        eventLoader: (day) {
          return _calendarData?.data[day.year]?[day.month]?[day.day] ?? [];
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return const SizedBox.shrink();

            final tasks = events.cast<CalendarEntryModel>();

            final uniqueTypes = tasks.map((e) => e.entryType).toSet();

            if (_selectedDay != null && _selectedDay == date) {
              return const SizedBox.shrink();
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: uniqueTypes.map((type) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      width: (uniqueTypes.length > 3) ? 3 : 6,
                      height: (uniqueTypes.length > 3) ? 3 : 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getAccentColor(type)!,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 9,)
              ]
            );
          }
        ),
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        startingDayOfWeek: StartingDayOfWeek.sunday,
        
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

          defaultDecoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(8),
          ),
          
          selectedDecoration: const BoxDecoration(
            color: Color(0xFFE157A4), 
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          
          todayDecoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF45A2FF), width: 1), 
            shape: BoxShape.rectangle,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),

          weekendDecoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(8),
          ),
          
          outsideDaysVisible: false,
          rowDecoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF1E222A), width: 0.5)),
          ),
        ),

        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          HashMap<int, String> months = HashMap();
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
          setState(() {
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

  Color? _getAccentColor(String type) {
    final Map<String, Color> accents = {
      'reel': Theme.of(context).colorScheme.secondary,
      'post': Theme.of(context).primaryColor,
      'video':  Color(0xFFEE4445),
      'story': Color(0xFFF97316),
      'other': Colors.white
    };
    
    return accents[type];
  }

  Widget _buildHeader() {
    final double progress = _getMonthlyProgress();
    final int percentage = (progress * 100).toInt();
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
                color: const Color(0xFF45A2FF).withValues(alpha: 0.8),
                fontSize: 32, 
                fontWeight: FontWeight.bold, 
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
             Text(
              "${months[selectedMonth-1]} $selectedYear", 
              style: TextStyle(color: Color(0xFF6F7685), fontSize: 14),
            ),
          ],
        ),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: Color(0xFF6F7685),
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
                  strokeCap: StrokeCap.butt,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$percentage%",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: GoogleFonts.robotoMono().fontFamily,
                    ),
                  ),
                  Text(
                    "Done",
                    style: TextStyle(
                      color: Color(0xFF6F7685),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      fontFamily: GoogleFonts.robotoMono().fontFamily,
                    ),
                  )
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  double _getMonthlyProgress() {
    if (_calendarData == null) return 0.0;
    
    final monthData = _calendarData!.data[selectedYear]?[selectedMonth];
    if (monthData == null || monthData.isEmpty) return 0.0;

    int totalTasks = 0;
    int completedTasks = 0;

    monthData.forEach((day, tasks) {
      for (var task in tasks) {
        totalTasks++;
        if (task.isCompleted) completedTasks++;
      }
    });

    return totalTasks == 0 ? 0.0 : completedTasks / totalTasks;
  }

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
            color: Color(0xFFE157A4),
            fontSize: 24, 
            fontWeight: FontWeight.bold, 
            fontStyle: FontStyle.italic,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E222A),
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

  Widget _buildTasksForDay(DateTime day) {
    final yearData = _calendarData?.data[day.year];
    final monthData = yearData?[day.month];
    final List<CalendarEntryModel> tasks = monthData?[day.day] ?? [];

    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy, color: const Color(0xFF6F7685).withValues(alpha: 0.5), size: 48),
              const SizedBox(height: 16),
              Text(
                day.day == DateTime.now().day && day.month == DateTime.now().month
                    ? "No tasks for today"
                    : "No tasks for ${months[day.month - 1][0].toUpperCase()}${months[day.month - 1].substring(1).toLowerCase()} ${day.day}",
                style: const TextStyle(
                  color: Color(0xFF6F7685),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final entry = tasks[index];

        final Map<String, Color> accents = {
          'reel': Theme.of(context).colorScheme.secondary,
          'post': Theme.of(context).primaryColor,
          'video':  Color(0xFFEE4445),
          'story': Color(0xFFF97316),
          'other': Colors.white
        };
        
        final accent = accents[entry.entryType];

        return _buildTaskCard(
          entry: entry,
          accent: accent!,
        );
      },
    );
  }

  Widget _buildTaskCard({
    required CalendarEntryModel entry,
    required Color accent,
  }) {
    return GestureDetector(
      onTap: () {
        entry.isCompleted ? _calendarRepository.undoCompleteEntry(entry) : _calendarRepository.completeEntry(entry);
        setState(() {
          entry.isCompleted = !entry.isCompleted;
        });
      },
      child: Opacity(
        opacity: entry.isCompleted ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E222A),
            borderRadius: BorderRadius.circular(20),
            border: entry.isCompleted 
                ? null 
                : Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.entryType.toUpperCase(),
                      style: TextStyle(
                        color: accent, 
                        fontSize: 12, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    Text(
                      entry.title ?? "Untitled Task",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: entry.isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: accent,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                        (entry.brief != null && entry.brief!.isNotEmpty 
                                ? entry.brief! 
                                : (entry.isCompleted ? "Completed" : "In Progress")),
                        overflow: TextOverflow.ellipsis, 
                        style: const TextStyle(
                          color: Color(0xFF6F7685),
                          fontSize: 10,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    
                      
                  ],
                ),
              ),
              
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: entry.isCompleted ? Colors.transparent : const Color(0xFF6F7685),
                  ),
                  color: entry.isCompleted ? const Color(0xFF45A2FF) : Colors.transparent,
                ),
                child: entry.isCompleted 
                    ? const Icon(Icons.check, color: Colors.white, size: 18) 
                    : null,
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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "add",
            backgroundColor: const Color(0xFF45A2FF),
            onPressed: () {_showAddEntryDialog(context);},
            label: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }
}