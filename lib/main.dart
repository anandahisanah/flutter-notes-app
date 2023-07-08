import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(CatatanApp());
}

class CatatanApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kelompok 2 IFB6K Catatan',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: CatatanList(),
    );
  }
}

class CatatanList extends StatefulWidget {
  @override
  _CatatanListState createState() => _CatatanListState();
}

class _CatatanListState extends State<CatatanList> {
  List<Catatan> catatans = [];

  @override
  void initState() {
    super.initState();
    restoreCatatans();
  }

  Future<void> restoreCatatans() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? catatanListJson = prefs.getString('catatanList');
    if (catatanListJson != null) {
      List<dynamic> catatanList = jsonDecode(catatanListJson);
      setState(() {
        catatans = catatanList.map((json) => Catatan.fromMap(json)).toList();
      });
    }
  }

  Future<void> saveCatatans() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> catatanList =
        catatans.map((catatan) => catatan.toMap()).toList();
    String catatanListJson = jsonEncode(catatanList);
    await prefs.setString('catatanList', catatanListJson);
  }

  void deleteCatatan(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus Catatan'),
          content: Text('Apakah anda yakin ingin menghapus catatan ini?'),
          actions: [
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Hapus'),
              onPressed: () {
                setState(() {
                  catatans.removeAt(index);
                  saveCatatans();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void editCatatan(int index) async {
    final editedCatatan = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CatatanForm(catatan: catatans[index]),
      ),
    );
    if (editedCatatan != null) {
      setState(() {
        catatans[index] = editedCatatan;
        saveCatatans();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelompok 2 IFB6K Catatan'),
      ),
      body: ListView.builder(
        itemCount: catatans.length,
        itemBuilder: (context, index) {
          String originalDate = catatans[index].date;
          DateTime dateTime = DateTime.parse(originalDate);
          String formattedDate =
              DateFormat('dd MMM yyyy HH:mm').format(dateTime);

          return ListTile(
            title: Text(catatans[index].title),
            subtitle: Text(formattedDate),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CatatanDetail(catatan: catatans[index]),
                ),
              );
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    editCatatan(index);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    deleteCatatan(index);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final newCatatan = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CatatanForm(),
            ),
          );
          if (newCatatan != null) {
            setState(() {
              catatans.add(newCatatan);
              saveCatatans();
            });
          }
        },
      ),
    );
  }
}

class Catatan {
  String title;
  String description;
  String date;

  Catatan({
    required this.title,
    required this.description,
    required this.date,
  });

  factory Catatan.fromMap(Map<String, dynamic> map) {
    return Catatan(
      title: map['title'],
      description: map['description'],
      date: map['date'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date,
    };
  }
}

class CatatanForm extends StatefulWidget {
  final Catatan? catatan;

  CatatanForm({this.catatan});

  @override
  _CatatanFormState createState() => _CatatanFormState();
}

class _CatatanFormState extends State<CatatanForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController titleController;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.catatan?.title);
    descriptionController =
        TextEditingController(text: widget.catatan?.description);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.catatan != null ? 'Edit Catatan' : 'Tambah Catatan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Judul',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8.0),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Deskripsi tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                child: Text(widget.catatan != null
                    ? 'Simpan Catatan'
                    : 'Tambah Catatan'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final editedCatatan = Catatan(
                      title: titleController.text,
                      description: descriptionController.text,
                      date: widget.catatan?.date ?? DateTime.now().toString(),
                    );
                    Navigator.pop(context, editedCatatan);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CatatanDetail extends StatelessWidget {
  final Catatan catatan;

  CatatanDetail({required this.catatan});

  @override
  Widget build(BuildContext context) {
    String originalDate = catatan.date;
    DateTime dateTime = DateTime.parse(originalDate);
    String formattedDate = DateFormat('dd MMM yyyy HH:mm').format(dateTime);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Catatan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              catatan.title,
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            Text(catatan.description),
          ],
        ),
      ),
    );
  }
}
