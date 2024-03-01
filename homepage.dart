import 'package:auto_notes_booklet/notespage.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // All data
  List<Map<String, dynamic>> myData = [];
  final formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  // This function is used to fetch all data from the database
  void _refreshData() async {
    final data = await DatabaseHelper.getCars();
    setState(() {
      myData = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshData(); // Loading the data when the app starts
  }

  final TextEditingController _carController = TextEditingController();
  // final TextEditingController _descriptionController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item
  void showMyForm(int? id) async {
    // id == null -> create new item
    // id != null -> update an existing item
    if (id != null) {
      final existingData = myData.firstWhere((element) => element['id'] == id);
      _carController.text = existingData['car'];
      // _descriptionController.text = existingData['description'];
    } else {
      _carController.text = "";
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
                        controller: _carController,
                        validator: formValidator,
                        decoration: const InputDecoration(
                            hintText: 'Vehicle name/Όνομα Οχήματος'),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      // TextFormField(
                      //   validator: formValidator,
                      //   controller: _descriptionController,
                      //   decoration: const InputDecoration(hintText: 'Description'),
                      // ),
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
                                  _carController.text = '';
                                  // _descriptionController.text = '';
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
    await DatabaseHelper.createCar(_carController.text);
    _refreshData();
  }

  // Update an existing data
  Future<void> updateItem(int id) async {
    await DatabaseHelper.updateItem(id, _carController.text);
    _refreshData();
  }

  // Delete an item
  void deleteItem(int id) async {
    await DatabaseHelper.deleteItem(id);
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
      content: const Text(
          "Delete all vehicle's services also/Διαγραφή οχήματος και όλων των εργασιών του ?"),
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
        title: const Text('Vehicles/Οχήματα'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : myData.isEmpty
              ? const Center(child: Text("Add a Vehicle/Προσθέστε ένα Όχημα"))
              : ListView.builder(
                  itemCount: myData.length,
                  itemBuilder: (context, index) => Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(80)),
                    //set border radius more than 50% of height and width to make circle
                    color: index % 2 == 0 ? Colors.blue[300] : Colors.blue[300],
                    margin: const EdgeInsets.all(30),
                    child: ListTile(
                        leading: const Icon(Icons.directions_car_outlined),

                        // onTap: () => NotesPage(carID: myData[index]['id']),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => NotesPage(
                                      carName: myData[index]['car'],
                                      carID: myData[index]['id'])));
                        },
                        title: Text(myData[index]['car']),
                        // subtitle: Text(myData[index]['description']),
                        trailing: SizedBox(
                          width: 100,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    showMyForm(myData[index]['id']),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    //deleteItem(myData[index]['id']),
                                    showAlertDialog(
                                        context, myData[index]['id']),
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
