import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal

void main() {
  runApp(const MigraineTrackerApp());
}

// 1. Model Data untuk menyimpan struktur data Migrain
class MigraineLog {
  final DateTime date;
  final int painScale;
  final String trigger;
  final String note;

  MigraineLog({
    required this.date,
    required this.painScale,
    required this.trigger,
    required this.note,
  });
}

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

// 2. Halaman Navigasi Utama (Bikin Tab di Bawah Aplikasi)
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Ini adalah List global untuk menampung riwayat data migrain kamu
  final List<MigraineLog> _historyLogs = [];

  @override
  Widget build(BuildContext context) {
    // Daftar halaman yang bisa diakses lewat Tab di bawah
    final List<Widget> screens = [
      MigraineLogScreen(
        onLogSaved: (newLog) {
          setState(() {
            _historyLogs.insert(0, newLog); // Log baru ditaruh di paling atas
          });
        },
      ),
      MigraineHistoryScreen(logs: _historyLogs),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.indigo,
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
            label: 'Riwayat Log',
          ),
        ],
      ),
    );
  }
}

// 3. HALAMAN INPUT (Sudah dimodifikasi agar melempar data saat di-save)
class MigraineLogScreen extends StatefulWidget {
  final Function(MigraineLog) onLogSaved;
  const MigraineLogScreen({super.key, required this.onLogSaved});

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

  void _saveLog() {
    // Membuat objek log baru berdasarkan input user
    final logBaru = MigraineLog(
      date: DateTime.now(),
      painScale: _painScale.round(),
      trigger: _selectedTrigger,
      note: _noteController.text,
    );

    // Kirim data ke List utama
    widget.onLogSaved(logBaru);

    // Reset input setelah simpan
    setState(() {
      _painScale = 5.0;
      _selectedTrigger = 'Kurang Tidur';
      _noteController.clear();
    });

    // Munculkan notifikasi sukses
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Berhasil! 🎉'),
        content: const Text('Data migrain kamu sudah disimpan ke Riwayat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Catat Migrain 🧠',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    onChanged: (value) {
                      setState(() {
                        _painScale = value;
                      });
                    },
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
              items: _triggers.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedTrigger = newValue!;
                });
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Catatan Tambahan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Belum makan siang, obat parasetamol...',
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
}

// 4. HALAMAN BARU: HALAMAN RIWAYAT UNTUK MELIHAT LOG
class MigraineHistoryScreen extends StatelessWidget {
  final List<MigraineLog> logs;
  const MigraineHistoryScreen({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Migrain 📂',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
      ),
      body: logs.isEmpty
          ? const Center(
              child: Text(
                'Belum ada riwayat.\nSilakan isi log di tab "Catat Baru".',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                // Format tanggal jadi lebih gampang dibaca (Jam:Menit - Tgl/Bln/Thn)
                final formattedDate = DateFormat(
                  'HH:mm - dd MMM yyyy',
                ).format(log.date);

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      child: Text(
                        '${log.painScale}',
                      ), // Menampilkan skala nyeri di dalam lingkaran
                    ),
                    title: Text(
                      'Pemicu: ${log.trigger}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (log.note.isNotEmpty) Text('Catatan: ${log.note}'),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
