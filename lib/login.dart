import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'language.dart';
import 'sudoku_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late Box _sudokuBox;
  Future<Box> _boxOpen() async {
    _sudokuBox = await Hive.openBox('sudokuApp');
    return await Hive.openBox('completed_sudoku');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Box>(
      future: _boxOpen(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: Text(language["login_title"]),
              backgroundColor: Colors.red[900],
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.settings_display),
                  onPressed: () {
                    Box box = Hive.box('settings');
                    box.put(
                      'dark_theme',
                      !box.get('dark_theme', defaultValue: false),
                    );
                  },
                ),
                if (_sudokuBox.get('sudokuRows') != null)
                  IconButton(
                    icon: const Icon(Icons.play_circle_outline),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SudokuPage()),
                      );
                    },
                  ),
                PopupMenuButton(
                  icon: const Icon(Icons.add),
                  onSelected: (value) {
                    if (_sudokuBox.isOpen) {
                      _sudokuBox.put('level', value);
                      _sudokuBox.put('sudokuRows', null);

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SudokuPage()),
                      );
                    }
                  },
                  itemBuilder: (context) => <PopupMenuEntry>[
                    PopupMenuItem(
                      value: language["select_level"],
                      // ignore: sort_child_properties_last
                      child: Text(
                        language["select_level"],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                        ),
                      ),
                      enabled: false,
                    ),
                    for (String key in sudokuLevels.keys)
                      PopupMenuItem(
                        value: key,
                        child: Text(key),
                      ),
                  ],
                ),
              ],
            ),
            body: ValueListenableBuilder<Box>(
              valueListenable: snapshot.data!.listenable(),
              builder: (context, box, _) {
                return Column(
                  children: <Widget>[
                    if (box.length == 0)
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          language["no_completed_sudoku"],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.courgette(
                            textStyle: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    for (Map element in box.values.toList().reversed.take(30))
                      ListTile(
                        onTap: () {},
                        title: Text("Date and Time: ${element['date']}"),
                        subtitle: Text("${Duration(seconds: element['time'])}".split('.').first),
                      ),
                  ],
                );
              },
            ),
          );
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
