import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:schedule_generator/service/services.dart';

class GeminiPage extends StatefulWidget {
  const GeminiPage({super.key});

  @override
  State<GeminiPage> createState() => _GeminiPageState();
}

class _GeminiPageState extends State<GeminiPage> {
  final _controllerName = TextEditingController();
  final _controllerDuration = TextEditingController();
  String _selectedPriority = "High";
  DateTime? _fromDate;
  DateTime? _untilDate;
  String _result = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    dotenv.load();
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _untilDate = picked;
        }
      });
    }
  }

  Future<void> generateSchedule() async {
    if (_controllerName.text.isEmpty ||
        _controllerDuration.text.isEmpty ||
        _fromDate == null ||
        _untilDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select dates.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = ""; // Clear previous result
    });

    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    String fromDate = formatter.format(_fromDate!);
    String untilDate = formatter.format(_untilDate!);

    try {
      final result = await GeminiServices.generateSchedule(
        _controllerName.text,
        _controllerDuration.text,
        _selectedPriority,
        fromDate,
        untilDate,
      );

      setState(() {
        _result = result;
      });
    } catch (e) {
      log('Error generating schedule: $e');
      setState(() {
        _result = 'Failed to generate schedule. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Schedule Generator")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _textField("Text", _controllerName),
            const SizedBox(height: 10),
            _textField("Duration", _controllerDuration, isNumber: true),
            const SizedBox(height: 10),
            _dropDown(),
            const SizedBox(height: 10),
            _datePicker(
              "From Date",
              _fromDate,
              () => _selectDate(context, true),
            ),
            const SizedBox(height: 10),
            _datePicker(
              "Until Date",
              _untilDate,
              () => _selectDate(context, false),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : generateSchedule,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Text('Generate Text'),
            ),
            const SizedBox(height: 20),
            if (_result.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(_result),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    );
  }

  Widget _dropDown() {
    return DropdownButtonFormField<String>(
      value: _selectedPriority,
      items: ["High", "Medium", "Low"]
          .map(
            (elemen) => DropdownMenuItem(value: elemen, child: Text(elemen)),
          )
          .toList(),
      onChanged: (String? value) {
        if (value != null) {
          setState(() {
            _selectedPriority = value;
          });
        }
      },
      decoration: const InputDecoration(labelText: "Priority"),
    );
  }

  Widget _datePicker(String label, DateTime? date, VoidCallback onTap) {
    return ListTile(
      title: Text(
        date == null
            ? "$label (Select Date)"
            : "$label: ${DateFormat('yyyy-MM-dd').format(date)}",
      ),
      onTap: onTap,
    );
  }
}