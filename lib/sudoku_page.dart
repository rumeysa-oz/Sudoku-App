import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive_listener/hive_listener.dart';
import 'package:wakelock/wakelock.dart';

import 'language.dart';
import 'sudoku_1000.dart';

final Map<String, int> sudokuLevels = {
  language["level1"]: 62,
  language["level2"]: 53,
  language["level3"]: 44,
  language["level4"]: 35,
  language["level5"]: 26,
  language["level6"]: 17,
};

class SudokuPage extends StatefulWidget {
  const SudokuPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SudokuPageState createState() => _SudokuPageState();
}

class _SudokuPageState extends State<SudokuPage> {
  final List exampleSudoku = List.generate(9, (i) => List.generate(9, (j) => j + 1));
  final Box _sudokuBox = Hive.box('sudokuApp');

  late Timer _counter;

  // ignore: prefer_final_fields
  List _sudoku = [], _sudokuHistory = [];

  late String _sudokuString;

  bool _note = false;

  void _getSudoku() {
    int seenElementNumber = sudokuLevels[_sudokuBox.get(
      'level',
      defaultValue: language["level2"],
    )]!;

    _sudokuString = sudoku1000s[Random().nextInt(sudoku1000s.length)];

    _sudokuBox.put('sudokuString', _sudokuString);

    _sudoku = List.generate(
      9,
      (i) => List.generate(
        9,
        // ignore: prefer_interpolation_to_compose_strings
        (j) => 'e' + _sudokuString.substring(i * 9, (i + 1) * 9).split('')[j],
      ),
    );

    int i = 0;
    while (i < (81 - seenElementNumber)) {
      int x = Random().nextInt(9);
      int y = Random().nextInt(9);

      if (_sudoku[x][y] != '0') {
        debugPrint(_sudoku[x][y]);
        _sudoku[x][y] = '0';
        i++;
      }
    }

    _sudokuBox.put('sudokuRows', _sudoku);
    _sudokuBox.put('xy', '99');
    _sudokuBox.put('hint', 3);
    _sudokuBox.put('time', 0);

    debugPrint(seenElementNumber as String?);
    debugPrint(_sudokuString);
  }

  void _stepSave() {
    String sudokuLastState = _sudokuBox.get('sudokuRows').toString();
    if (sudokuLastState.contains('0')) {
      Map historyItem = {
        'sudokuRows': _sudokuBox.get('sudokuRows'),
        'xy': _sudokuBox.get('xy'),
        'hint': _sudokuBox.get('hint'),
      };

      _sudokuHistory.add(jsonEncode(historyItem));

      _sudokuBox.put('sudokuHistory', _sudokuHistory);
    } else {
      _sudokuString = _sudokuBox.get('sudokuString');
      debugPrint('Sudoku first state: $_sudokuString');

      String control = sudokuLastState.replaceAll(RegExp(r'[e, \][]'), '');

      String message = 'Try again! Sudoku has errors.';

      if (control == _sudokuString) {
        message = 'Congratulations!\nYou have successfully solved Sudoku.';
        Box completedBox = Hive.box('completed_sudoku');
        Map completedSudoku = {
          'date': DateTime.now(),
          'solved': _sudokuBox.get('sudokuRows'),
          'time': _sudokuBox.get('time'),
          'sudokuHistory': _sudokuBox.get('sudokuHistory'),
        };
        completedBox.add(completedSudoku);
        _sudokuBox.put('sudokuRows', null);

        Navigator.pop(context);
      }

      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 3,
      );

      debugPrint('Sudoku last state: $control');
    }
  }

  @override
  void initState() {
    super.initState();
    // The following line will enable the Android and iOS wakelock.
    Wakelock.enable();

    if (_sudokuBox.get('sudokuRows') == null) {
      _getSudoku();
    } else {
      _sudoku = _sudokuBox.get('sudokuRows');
    }

    _counter = Timer.periodic(const Duration(seconds: 1), (timer) {
      int time = _sudokuBox.get('time');
      _sudokuBox.put('time', ++time);
    });
  }

  @override
  void dispose() {
    // if (_counter !=null && _counter.isActive) or
    if (_counter.isActive) _counter.cancel();

    // The next line disables the wakelock again.
    Wakelock.disable();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(language["sudoku_page_title"]),
        backgroundColor: Colors.red[900],
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: HiveListener(
                box: _sudokuBox,
                keys: const ['time'],
                builder: (box) {
                  String time = Duration(seconds: box.get('time')).toString();
                  return Text(time.split('.').first);
                },
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              _sudokuBox.get('level', defaultValue: language["level2"]),
            ),
            const SizedBox(
              height: 5,
            ),
            AspectRatio(
              aspectRatio: 1,
              child: ValueListenableBuilder<Box>(
                  valueListenable: _sudokuBox.listenable(
                    keys: ['xy', 'sudokuRows'],
                  ),
                  builder: (context, box, widget) {
                    String xy = box.get('xy');
                    int xC = int.parse(xy.substring(0, 1));
                    int yC = int.parse(xy.substring(1));
                    List sudokuRows = box.get('sudokuRows');

                    return Container(
                      color: Colors.white24,
                      padding: const EdgeInsets.all(2),
                      margin: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          for (int x = 0; x < 9; x++)
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        for (int y = 0; y < 9; y++)
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    margin: const EdgeInsets.all(1),
                                                    color: xC == x && yC == y
                                                        ? Colors.lightBlue[100]!.withOpacity(0.7)
                                                        : Colors.lightBlue[800]!
                                                            .withOpacity(xC == x || yC == y ? 0.7 : 1),
                                                    child: '${sudokuRows[x][y]}'.startsWith('e')
                                                        ? Text(
                                                            '${sudokuRows[x][y]}'.substring(1),
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.w900,
                                                              fontSize: 20,
                                                            ),
                                                          )
                                                        : InkWell(
                                                            onTap: () {
                                                              debugPrint('$x$y');
                                                              _sudokuBox.put('xy', '$x$y');
                                                            },
                                                            child: Center(
                                                              child: "${sudokuRows[x][y]}".length > 8
                                                                  ? Column(
                                                                      children: [
                                                                        for (int i = 0; i < 9; i += 3)
                                                                          Expanded(
                                                                            child: Row(
                                                                              children: [
                                                                                for (int j = 0; j < 3; j++)
                                                                                  Expanded(
                                                                                    child: Center(
                                                                                      child: Text(
                                                                                        "${sudokuRows[x][y]}"
                                                                                                    .split('')[i + j] ==
                                                                                                '0'
                                                                                            ? ''
                                                                                            : "${sudokuRows[x][y]}"
                                                                                                .split('')[i + j],
                                                                                        style: const TextStyle(
                                                                                            fontSize: 12),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                      ],
                                                                    )
                                                                  : Text(
                                                                      sudokuRows[x][y] != '0' ? sudokuRows[x][y] : '',
                                                                      style: const TextStyle(
                                                                        fontSize: 22,
                                                                      ),
                                                                    ),
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                                if (y == 2 || y == 5)
                                                  const SizedBox(
                                                    width: 2,
                                                  ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (x == 2 || x == 5)
                                    const SizedBox(
                                      height: 2,
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
            ),
            const SizedBox(
              height: 10,
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Card(
                                  color: Colors.yellow[400],
                                  margin: const EdgeInsets.all(8),
                                  child: InkWell(
                                    onTap: () {
                                      String xy = _sudokuBox.get('xy');
                                      if (xy != '99') {
                                        int xC = int.parse(xy.substring(0, 1));
                                        int yC = int.parse(xy.substring(1));
                                        _sudoku[xC][yC] = '0';
                                        _sudokuBox.put(
                                          'sudokuRows',
                                          _sudoku,
                                        );
                                        _stepSave();
                                      }
                                    },
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          size: 30,
                                          color: Colors.black,
                                        ),
                                        Text(
                                          'Delete',
                                          style: TextStyle(fontSize: 18, color: Colors.black),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ValueListenableBuilder<Box>(
                                  valueListenable: _sudokuBox.listenable(keys: ['hint']),
                                  builder: (context, box, widget) {
                                    return Card(
                                      color: Colors.yellow[400],
                                      margin: const EdgeInsets.all(8),
                                      child: InkWell(
                                        onTap: () {
                                          String xy = box.get('xy');

                                          if (xy != '99' && box.get('hint') > 0) {
                                            int xC = int.parse(xy.substring(0, 1));
                                            int yC = int.parse(xy.substring(1));

                                            String solutionString = box.get(
                                              'sudokuString',
                                            );

                                            List solutionSudoku = List.generate(
                                              9,
                                              (i) => List.generate(
                                                9,
                                                (j) => solutionString.substring(i * 9, (i + 1) * 9).split('')[j],
                                              ),
                                            );

                                            if (_sudoku[xC][yC] != solutionSudoku[xC][yC]) {
                                              _sudoku[xC][yC] = solutionSudoku[xC][yC];
                                              box.put(
                                                'sudokuRows',
                                                _sudoku,
                                              );
                                              box.put('hint', box.get('hint') - 1);
                                              _stepSave();
                                            }
                                          }
                                        },
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.lightbulb_outline,
                                                  size: 30,
                                                  color: Colors.black,
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '${box.get('hint')} Hint',
                                              style: const TextStyle(fontSize: 18, color: Colors.black),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Card(
                                  color: _note ? Colors.yellow[400]!.withOpacity(0.6) : Colors.yellow[400],
                                  margin: const EdgeInsets.all(8),
                                  child: InkWell(
                                    onTap: () => setState(() => _note = !_note),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.border_color,
                                          size: 30,
                                          color: Colors.black,
                                        ),
                                        Text(
                                          'Take Note',
                                          style: TextStyle(fontSize: 18, color: Colors.black),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Card(
                                  color: _note ? Colors.yellow[400]!.withOpacity(0.6) : Colors.yellow[400],
                                  margin: const EdgeInsets.all(8),
                                  child: InkWell(
                                    onTap: () {
                                      if (_sudokuHistory.length > 1) {
                                        _sudokuHistory.removeLast();

                                        Map before = jsonDecode(_sudokuHistory.last);

                                        _sudokuBox.put('sudokuRows', before['sudokuRows']);
                                        _sudokuBox.put('xy', before['xy']);
                                        _sudokuBox.put('hint', before['hint']);

                                        _sudokuBox.put('sudokuHistory', _sudokuHistory);
                                      }
                                      // ignore: avoid_print
                                      print(_sudokuHistory.length);
                                    },
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.undo,
                                          size: 30,
                                          color: Colors.black,
                                        ),
                                        ValueListenableBuilder<Box>(
                                          valueListenable: _sudokuBox.listenable(keys: ['sudokuHistory']),
                                          builder: (context, box, _) {
                                            return Text(
                                              'Undo: ${box.get('sudokuHistory', defaultValue: []).length}',
                                              style: const TextStyle(fontSize: 18, color: Colors.black),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        for (int i = 1; i < 10; i += 3)
                          Expanded(
                            child: Row(
                              children: [
                                for (int j = 0; j < 3; j++)
                                  Expanded(
                                    child: Card(
                                      color: Colors.yellow[400],
                                      margin: const EdgeInsets.all(3),
                                      shape: const CircleBorder(),
                                      child: InkWell(
                                        onTap: () {
                                          String xy = _sudokuBox.get('xy');
                                          if (xy != '99') {
                                            int xC = int.parse(xy.substring(0, 1));
                                            int yC = int.parse(xy.substring(1));
                                            if (!_note) {
                                              _sudoku[xC][yC] = '${i + j}';
                                            } else {
                                              if ('${_sudoku[xC][yC]}'.length < 8) _sudoku[xC][yC] = '000000000';

                                              _sudoku[xC][yC] = '${_sudoku[xC][yC]}'.replaceRange(
                                                i + j - 1,
                                                i + j,
                                                '${_sudoku[xC][yC]}'.substring(i + j - 1, i + j) == '${i + j}'
                                                    ? '0'
                                                    : '${i + j}',
                                              );
                                            }

                                            _sudokuBox.put('sudokuRows', _sudoku);
                                            _stepSave();
                                            // ignore: avoid_print
                                            print('${i + j}');
                                          }
                                        },
                                        child: Container(
                                          alignment: Alignment.center,
                                          margin: const EdgeInsets.all(3),
                                          child: Text(
                                            '${i + j}',
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 15,
            ),
          ],
        ),
      ),
    );
  }
}
