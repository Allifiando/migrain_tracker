import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MigraineTrackerApp());
}

// =========================================================================
// MODEL DATA (Dibuat saling mewarisi agar bisa masuk ke dalam 1 List yang sama)
// =========================================================================

abstract class BaseLog {
  final DateTime date;
  BaseLog({required this.date});
}

// Model Data untuk mencatat serangan Migrain
class MigraineLog extends BaseLog {
  final int painScale;
  final String trigger;
  final String note;

  MigraineLog({
    required super.date,
    required this.painScale,
    required this.trigger,
    required this.note,
  });
}

// Model Data untuk mencatat Aksi Minum Obat
class MedicationActionLog extends BaseLog {
  final String medicineName;
  final String effectiveness;

  MedicationActionLog({
    required super.date,
    required this.medicineName,
    required this.effectiveness,
  });
}

// =========================================================================
// APLIKASI UTAMA
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

// =========================================================================
// 2. NAVIGASI UTAMA (Kembali ke 2 Tab, tapi Fitur Obat dilempar via Pop-up)
// =========================================================================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // SATU LIST UNTUK SEMUA: Menampung riwayat sakit DAN riwayat obat sekaligus
  final List<BaseLog> _unifiedHistoryLogs = [];

  void _addNewLog(BaseLog newLog) {
    setState(() {
      _unifiedHistoryLogs.add(newLog);
      // Diurutkan berdasarkan tanggal terbaru di paling atas
      _unifiedHistoryLogs.sort((a, b) => b.date.compareTo(a.date));
    });
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
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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
// 3. HALAMAN CATAT BARU (Bisa Catat Sakit ATAU Klik Tombol Obat)
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
    'Hormonal/Haid',
  ];

  // Data untuk Form Obat
  final _formKey = GlobalKey<FormState>();
  String _selectedMedicine = 'Paracetamol';
  String _effectiveness = 'Manjur (Sembuh Total)';
  final List<String> _medicines = [
    'Paracetamol',
    'Ibuprofen',
    'Sumatriptan',
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
        const SnackBar(
          content: Text('Aksi minum obat berhasil disisipkan ke riwayat! 💊'),
        ),
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
          // Tombol cepat di pojok kanan atas untuk catat obat kapan saja
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
            // Tombol shortcut besar biar istri gampang klik kalau darurat habis minum obat
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
                  'Klik di sini untuk langsung mencatat efektivitas obat.',
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
// 4. HALAMAN RIWAYAT SATU LINIMASA (TERURUT BERDASARKAN WAKTU)
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

                // JIKA LOG ADALAH CATATAN SAKIT MIGRAIN
                if (currentLog is MigraineLog) {
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    borderOnForeground: true,
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

                // JIKA LOG ADALAH CATATAN MINUM OBAT
                if (currentLog is MedicationActionLog) {
                  Color statusColor = Colors.grey;
                  if (currentLog.effectiveness == 'Manjur (Sembuh Total)')
                    statusColor = Colors.green.shade600;
                  if (currentLog.effectiveness == 'Lumayan (Mendingan)')
                    statusColor = Colors.orange.shade600;
                  if (currentLog.effectiveness == 'Tidak Ngefek')
                    statusColor = Colors.red.shade600;

                  return Card(
                    color: Colors
                        .green
                        .shade50, // Dibikin beda warna background biar eye-catching
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
