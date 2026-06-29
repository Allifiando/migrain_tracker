import 'dart:convert'; // NEW: Untuk mengubah data ke teks (JSON)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // NEW: Untuk simpan permanen

void main() {
  runApp(const MigraineTrackerApp());
}

// =========================================================================
// MODEL DATA (Ditambah fungsi toMap & fromMap untuk simpan ke HP)
// =========================================================================
abstract class BaseLog {
  final DateTime date;
  final String type; // 'migraine' atau 'medication'
  BaseLog({required this.date, required this.type});

  Map<String, dynamic> toMap();
}

class MigraineLog extends BaseLog {
  final int painScale;
  final String trigger;
  final String note;

  MigraineLog({
    required super.date,
    required this.painScale,
    required this.trigger,
    required this.note,
  }) : super(type: 'migraine');

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'date': date.toIso8601String(),
      'painScale': painScale,
      'trigger': trigger,
      'note': note,
    };
  }

  factory MigraineLog.fromMap(Map<String, dynamic> map) {
    return MigraineLog(
      date: DateTime.parse(map['date']),
      painScale: map['painScale'],
      trigger: map['trigger'],
      note: map['note'],
    );
  }
}

class MedicationActionLog extends BaseLog {
  final String medicineName;
  final String effectiveness;

  MedicationActionLog({
    required super.date,
    required this.medicineName,
    required this.effectiveness,
  }) : super(type: 'medication');

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'date': date.toIso8601String(),
      'medicineName': medicineName,
      'effectiveness': effectiveness,
    };
  }

  factory MedicationActionLog.fromMap(Map<String, dynamic> map) {
    return MedicationActionLog(
      date: DateTime.parse(map['date']),
      medicineName: map['medicineName'],
      effectiveness: map['effectiveness'],
    );
  }
}

// =========================================================================
// APLIKASI UTAMA & NAVIGASI
// =========================================================================
class MigraineTrackerApp extends StatelessWidget {
  const MigraineTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<BaseLog> _unifiedHistoryLogs = [];

  @override
  void initState() {
    super.initState();
    _loadDataFromStorage(); // NEW: Ambil data lama pas aplikasi pertama kali dibuka
  }

  // 💾 NEW: Fungsi mengambil data dari memori HP
  Future<void> _loadDataFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('migraine_logs');

    if (encodedData != null) {
      final List<dynamic> decodedList = jsonDecode(encodedData);
      setState(() {
        _unifiedHistoryLogs.clear();
        for (var item in decodedList) {
          if (item['type'] == 'migraine') {
            _unifiedHistoryLogs.add(MigraineLog.fromMap(item));
          } else if (item['type'] == 'medication') {
            _unifiedHistoryLogs.add(MedicationActionLog.fromMap(item));
          }
        }
        _unifiedHistoryLogs.sort((a, b) => b.date.compareTo(a.date));
      });
    }
  }

  // 💾 NEW: Fungsi menyimpan data ke memori HP
  Future<void> _saveDataToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> mapList = _unifiedHistoryLogs
        .map((log) => log.toMap())
        .toList();
    await prefs.setString('migraine_logs', jsonEncode(mapList));
  }

  void _addNewLog(BaseLog newLog) {
    setState(() {
      _unifiedHistoryLogs.add(newLog);
      _unifiedHistoryLogs.sort((a, b) => b.date.compareTo(a.date));
    });
    _saveDataToStorage(); // Simpan setiap ada data baru
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      MigraineLogScreen(onLogSaved: _addNewLog, onMedicationSaved: _addNewLog),
      UnifiedHistoryScreen(logs: _unifiedHistoryLogs),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note),
            label: 'Catat Baru',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat Urut',
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// HALAMAN INPUT (Sakit & Obat)
// =========================================================================
class MigraineLogScreen extends StatefulWidget {
  final Function(MigraineLog) onLogSaved;
  final Function(MedicationActionLog) onMedicationSaved;

  const MigraineLogScreen({
    super.key,
    required this.onLogSaved,
    required this.onMedicationSaved,
  });

  @override
  State<MigraineLogScreen> createState() => _MigraineLogScreenState();
}

class _MigraineLogScreenState extends State<MigraineLogScreen> {
  double _painScale = 5.0;
  String _selectedTrigger = 'Kurang Tidur';
  final TextEditingController _noteController = TextEditingController();

  final List<String> _triggers = [
    'Kurang Tidur',
    'Kafein/Kopi',
    'Stres',
    'Cuaca Panas',
    'Makanan/MSG',
    'Asam Lambung',
    'Hormonal/Haid',
  ];

  final _formKey = GlobalKey<FormState>();
  String _selectedMedicine = 'Paracetamol';
  String _effectiveness = 'Manjur (Sembuh Total)';
  final List<String> _medicines = [
    'Paracetamol',
    'Ibuprofen',
    'Bodrex Migrain',
    'Promag',
    'Lagesil',
    'Asam Mefenamat',
    'Lainnya',
  ];
  final List<String> _efficacyOptions = [
    'Manjur (Sembuh Total)',
    'Lumayan (Mendingan)',
    'Tidak Ngefek',
  ];

  void _saveLog() {
    final logBaru = MigraineLog(
      date: DateTime.now(),
      painScale: _painScale.round(),
      trigger: _selectedTrigger,
      note: _noteController.text,
    );
    widget.onLogSaved(logBaru);
    setState(() {
      _painScale = 5.0;
      _selectedTrigger = 'Kurang Tidur';
      _noteController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log migrain berhasil disimpan! 🧠')),
    );
  }

  void _submitMedication() {
    if (_formKey.currentState!.validate()) {
      final obatBaru = MedicationActionLog(
        date: DateTime.now(),
        medicineName: _selectedMedicine,
        effectiveness: _effectiveness,
      );
      widget.onMedicationSaved(obatBaru);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aksi minum obat berhasil disimpan! 💊')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Catat Tracker Istri 🧠',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        actions: [
          TextButton.icon(
            onPressed: () => _openAddActionForm(context),
            icon: const Icon(Icons.medication, color: Colors.white),
            label: const Text(
              'Minum Obat',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.indigo.shade50,
              child: ListTile(
                leading: const Icon(
                  Icons.medication,
                  color: Colors.indigo,
                  size: 32,
                ),
                title: const Text(
                  'Baru saja minum obat?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Klik di sini untuk mencatat efektivitas obat.',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _openAddActionForm(context),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tingkat Keparahan (Skala 1-10)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                const Text('1'),
                Expanded(
                  child: Slider(
                    value: _painScale,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _painScale.round().toString(),
                    onChanged: (value) => setState(() => _painScale = value),
                  ),
                ),
                const Text('10'),
              ],
            ),
            Text(
              'Skala Nyeri: ${_painScale.round()}',
              style: const TextStyle(
                color: Colors.indigo,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pemicu Yang Dicurigai',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _selectedTrigger,
              isExpanded: true,
              items: _triggers
                  .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                  .toList(),
              onChanged: (newValue) =>
                  setState(() => _selectedTrigger = newValue!),
            ),
            const SizedBox(height: 24),
            const Text(
              'Catatan Tambahan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Belum makan siang, kunang-kunang...',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                onPressed: _saveLog,
                child: const Text(
                  'Simpan Log Migrain',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddActionForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Catat Minum Obat 💊',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedMedicine,
                decoration: const InputDecoration(labelText: 'Nama Obat'),
                items: _medicines
                    .map(
                      (med) => DropdownMenuItem(value: med, child: Text(med)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedMedicine = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _effectiveness,
                decoration: const InputDecoration(labelText: 'Kemanjuran Obat'),
                items: _efficacyOptions
                    .map(
                      (eff) => DropdownMenuItem(value: eff, child: Text(eff)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _effectiveness = val!),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                  ),
                  onPressed: _submitMedication,
                  child: const Text(
                    'Simpan Catatan Obat',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// HALAMAN RIWAYAT SATU LINIMASA
// =========================================================================
class UnifiedHistoryScreen extends StatelessWidget {
  final List<BaseLog> logs;
  const UnifiedHistoryScreen({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat & Linimasa 📂',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
      ),
      body: logs.isEmpty
          ? const Center(
              child: Text(
                'Belum ada riwayat apa pun.\nSilakan isi log migrain atau catat minum obat.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final currentLog = logs[index];
                final formattedDate = DateFormat(
                  'HH:mm - dd MMM yyyy',
                ).format(currentLog.date);

                if (currentLog is MigraineLog) {
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        child: Text('${currentLog.painScale}'),
                      ),
                      title: Text(
                        'Sakit Kepala (Skala ${currentLog.painScale})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pemicu: ${currentLog.trigger}'),
                          if (currentLog.note.isNotEmpty)
                            Text('Catatan: ${currentLog.note}'),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (currentLog is MedicationActionLog) {
                  Color statusColor = Colors.grey;
                  if (currentLog.effectiveness == 'Manjur (Sembuh Total)')
                    statusColor = Colors.green.shade600;
                  if (currentLog.effectiveness == 'Lumayan (Mendingan)')
                    statusColor = Colors.orange.shade600;
                  if (currentLog.effectiveness == 'Tidak Ngefek')
                    statusColor = Colors.red.shade600;

                  return Card(
                    color: Colors.green.shade50,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.medication,
                        color: statusColor,
                        size: 36,
                      ),
                      title: Text(
                        'Minum: ${currentLog.medicineName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Efek: ${currentLog.effectiveness}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
    );
  }
}
