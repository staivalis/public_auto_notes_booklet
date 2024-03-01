import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class NotesPage extends StatefulWidget {
  final int? carID;
  final String? carName;

  const NotesPage({super.key, this.carID, this.carName});
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  // All data
  List<Map<String, dynamic>> myNotesData = [];
  final formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  int _carID = 0;
  String _carName = "";

  DateTime selectedDate = DateTime.now();
  DateTime date = DateTime.now();
  String strDate = "";

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime(1990),
        lastDate: DateTime(2101));
    if (picked != null && picked != date) {
      //print('hello $picked');
      setState(() {
        date = picked;
      });
    }
  }

  // This function is used to fetch all data from the database
  void _refreshData() async {
    final data = await DatabaseHelper.getNotes(_carID);
    setState(() {
      myNotesData = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _carID = widget.carID!;
    _carName = widget.carName!;
    _refreshData(); // Loading the data when the app starts
  }

  final TextEditingController _workController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _kmController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item
  void showMyForm(int? id) async {
    // id == null -> create new item
    // id != null -> update an existing item
    if (id != null) {
      final existingData =
          myNotesData.firstWhere((element) => element['id'] == id);
      _workController.text = existingData['work'];
      _dateController.text = existingData['date'];
      _kmController.text = existingData['km'];
      _notesController.text = existingData['notes'];
    } else {
      _workController.text = "";
      _dateController.text = "";
      _kmController.text = "";
      _notesController.text = "";
      // _descriptionController.text = "";
    }

    showModalBottomSheet(
        context: context,
        elevation: 5,
        isDismissible: false,
        isScrollControlled: true,
        builder: (_) => SingleChildScrollView(
            child: Container(
                padding: EdgeInsets.only(
                  top: 15,
                  left: 15,
                  right: 15,
                  // prevent the soft keyboard from covering the text fields
                  bottom: MediaQuery.of(context).viewInsets.bottom + 120,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextFormField(
                        controller: _workController,
                        validator: formValidator,
                        decoration:
                            const InputDecoration(hintText: 'Service/Εργασία'),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        controller: _kmController,
                        //validator: formValidator,
                        decoration:
                            const InputDecoration(hintText: 'km/Χιλιόμετρα'),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        onTap: () async {
                          // Below line stops keyboard from appearing
                          FocusScope.of(context).requestFocus(FocusNode());
                          // Show Date Picker Here
                          await _selectDate(context);
                          _dateController.text =
                              DateFormat('dd/MM/y').format(date);
                          //setState(() {});
                        },
                        //validator: formValidator,

                        onSaved: (String? val) {
                          strDate = val!;
                        },
                        controller: _dateController,
                        //controller: TextEditingController(text: date.toString()),
                        decoration: const InputDecoration(
                          hintText: 'Date/Ημερομηνία',
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        controller: _notesController,
                        //validator: formValidator,
                        decoration:
                            const InputDecoration(hintText: 'Notes/Σημειώσεις'),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text("Cancel/Ακύρωση")),
                          ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                if (id == null) {
                                  await addItem();
                                }

                                if (id != null) {
                                  await updateItem(id);
                                }

                                // Clear the text fields
                                setState(() {
                                  _workController.text = '';
                                  _dateController.text = '';
                                  _kmController.text = '';
                                  _notesController.text = '';
                                });

                                // Close the bottom sheet
                                Navigator.pop(context);
                              }
                              // Save new data
                            },
                            child: Text(id == null
                                ? 'Save/Αποθήκευση'
                                : 'Update/Ενημέρωση'),
                          ),
                        ],
                      )
                    ],
                  ),
                ))));
  }

  String? formValidator(String? value) {
    if (value!.isEmpty) return 'Field is Required/Απαιτούμενο Πεδίο';
    return null;
  }

// Insert a new data to the database
  Future<void> addItem() async {
    await DatabaseHelper.createNote(_carID, _workController.text,
        _dateController.text, _kmController.text, _notesController.text);
    _refreshData();
  }

  // Update an existing data
  Future<void> updateItem(int id) async {
    await DatabaseHelper.updateNote(id, _workController.text,
        _dateController.text, _kmController.text, _notesController.text);
    _refreshData();
  }

  // Delete an item
  void deleteItem(int id) async {
    await DatabaseHelper.deleteNote(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Successfully deleted/Επιτυχής Διαγραφή'),
        backgroundColor: Colors.green));
    _refreshData();
  }

  void showAlertDialog(BuildContext context, int id) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: const Text("Cancel/Άκυρο"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = TextButton(
      child: const Text("OK"),
      onPressed: () {
        Navigator.of(context).pop(); // dismiss dialog
        deleteItem(id);
      },
    );
    // Navigator.of(context).pop();

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Delete/Διαγραφή ?"),
      content: const Text("Delete service/Διαγραφή εργασίας ?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Services/Εργασίες  ($_carName)'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : myNotesData.isEmpty
              ? const Center(child: Text("Add a Service/Προσθέστε μια Εργασία"))
              : ListView.builder(
                  itemCount: myNotesData.length,
                  itemBuilder: (context, index) => Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    //set border radius more than 50% of height and width to make circle
                    color: index % 2 == 0 ? Colors.blue[300] : Colors.blue[300],
                    margin: const EdgeInsets.all(30),
                    child: ListTile(
                        // title: Text(myNotesData[index]['work']),
                        title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              RichText(
                                text: TextSpan(
                                  text: 'Service/Εργασία: ',
                                  style: const TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.w700,
                                      color: Color.fromARGB(255, 3, 0, 0)),
                                  children: <TextSpan>[
                                    TextSpan(
                                        text: myNotesData[index]['work'],
                                        style: const TextStyle(
                                            fontSize: 19.0,
                                            fontWeight: FontWeight.w300,
                                            color:
                                                Color.fromARGB(255, 3, 0, 0))),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              RichText(
                                text: TextSpan(
                                  text: 'km/χιλιόμετρα: ',
                                  style: const TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.w700,
                                      color: Color.fromARGB(255, 3, 0, 0)),
                                  children: <TextSpan>[
                                    TextSpan(
                                        text: myNotesData[index]['km'],
                                        style: const TextStyle(
                                            fontSize: 19.0,
                                            fontWeight: FontWeight.w300,
                                            color:
                                                Color.fromARGB(255, 3, 0, 0))),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              RichText(
                                text: TextSpan(
                                  text: 'Date/Ημερομηνία: ',
                                  style: const TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.w700,
                                      color: Color.fromARGB(255, 3, 0, 0)),
                                  children: <TextSpan>[
                                    TextSpan(
                                        text: myNotesData[index]['date'],
                                        style: const TextStyle(
                                            fontSize: 19.0,
                                            fontWeight: FontWeight.w300,
                                            color:
                                                Color.fromARGB(255, 3, 0, 0))),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              RichText(
                                text: TextSpan(
                                  text: 'Notes/Σημειώσεις: ',
                                  style: const TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.w700,
                                      color: Color.fromARGB(255, 3, 0, 0)),
                                  children: <TextSpan>[
                                    TextSpan(
                                        text: myNotesData[index]['notes'],
                                        style: const TextStyle(
                                            fontSize: 19.0,
                                            fontWeight: FontWeight.w300,
                                            color:
                                                Color.fromARGB(255, 3, 0, 0))),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                            ]),
                        subtitle: Text(_carName),
                        trailing: SizedBox(
                          width: 100,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    showMyForm(myNotesData[index]['id']),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    //deleteItem(myNotesData[index]['id']),
                                    showAlertDialog(
                                        context, myNotesData[index]['id']),
                              ),
                            ],
                          ),
                        )),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => showMyForm(null),
      ),
    );
  }
}
