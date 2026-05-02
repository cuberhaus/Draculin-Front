import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

// Camera
import 'package:camera/camera.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// ── obs-experiment-embrace ──────────────────────────────────────────
// Embrace's Flutter SDK MUST be initialised before runApp so that
// Dart-side uncaught exceptions, the first auto-instrumented HTTP
// request, and the cold-start timing measurement all land in the
// same session payload. The SDK degrades to a no-op on Flutter Web
// (no embrace_web platform package exists) so the iframe Dockerfile
// build path is unaffected.
import 'package:embrace/embrace.dart';

// `DracuHttpClient` wraps the SDK's own `EmbraceHttpClient`
// (auto-recording every request as a network event) and adds the
// `X-Embrace-Session-Id` header injection on top — so the
// recorded payload + the backend BOTH see the session header.
import 'observability/embrace_http_client.dart';

// `DracuObs` is the thin facade over `package:embrace`. Every
// breadcrumb / log / span / persona call goes through it so we
// have a single chokepoint if we ever swap RUM vendors.
import 'observability/embrace.dart';

// Debug-only crash/ANR harness — adds a hidden 6th nav tab in
// `kDebugMode` builds for the Maestro flows under
// `observability/load-test/` to drive. Compiled away in release.
import 'debug/crash_button.dart';

const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'https://bits-draculin.onrender.com');

// Singleton HTTP client shared by every screen. Lazily instantiated
// on first use, which is guaranteed to happen AFTER main()'s
// `Embrace.instance.start()` because the screens themselves only
// fire requests inside `initState` / button callbacks. If Embrace
// hasn't started yet, `DracuHttpClient` degrades the
// session-header injection to a no-op (and the SDK's inner
// EmbraceHttpClient quietly drops the recording), so the wrapper
// stays safe even on the cold-start race.
final http.Client httpClient = DracuHttpClient();

class CameraWidget extends StatefulWidget {
  final Function(String) onCapture;

  CameraWidget({required this.onCapture});

  @override
  _CameraWidgetState createState() => _CameraWidgetState();
}


class BloodVolumePerWeekDayGraph extends StatelessWidget {
  final Map<String, int> bloodVolumeData = {
    'Mon': 5,
    'Tue': 10,
    'Wed': 7,
    'Thu': 15,
    'Fri': 8,
    'Sat': 4,
    'Sun': 6,
  };

  BloodVolumePerWeekDayGraph({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> plotPoints = [];
    List<int> values = bloodVolumeData.values.toList();

    for (int i = 0; i < values.length; i++) {
      String day = bloodVolumeData.keys.elementAt(i);
      int value = values[i];
      plotPoints.add(
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Tooltip(
                message: '$value',
                child: GestureDetector(
                  onTap: () {
                    final snackBar = SnackBar(
                      content: Text('$value'),
                      duration: Duration(seconds: 2),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    // You can perform any action on tap, for example, show a dialog or a snackbar
                  },
                  child: Container(
                    height: value.toDouble() *
                        5, // Scale factor for visual representation
                    width: 10,
                    color: Colors.blue,
                  ),
                ),
              ),
              Text(day),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: plotPoints,
      ),
    );
  }
}





class QuestionnairePerformanceGraph extends StatelessWidget {
  // Sample data for the bar chart
  final Map<String, int> questionnaireResults = {
    'Impacte lleu': 10, // Number of users with light impact
    'Impacte moderat': 5, // Number of users with moderate impact
    'Impacte sever': 3, // Number of users with severe impact
  };

  QuestionnairePerformanceGraph({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: questionnaireResults.entries.map((entry) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              InkWell(
                onTap: () => _showDialog(context, entry.key, entry.value),
                child: Container(
                  height:
                      (entry.value * 10).toDouble(), // Example scaling factor
                  width: 40,
                  color: _getColorForCategory(entry.key),
                ),
              ),
              Text(entry.key),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showDialog(BuildContext context, String category, int value) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(category),
          content: Text('Number of users: $value'),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'Impacte lleu':
        return Colors.green;
      case 'Impacte moderat':
        return Colors.orange;
      case 'Impacte sever':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}



class PeriodCalendar extends StatefulWidget {
  @override
  _PeriodCalendarState createState() => _PeriodCalendarState();
}

class _PeriodCalendarState extends State<PeriodCalendar> {
  // Example data: days with periods
  List<int> periodDays = [2, 3, 4, 5, 28, 29, 30];

  @override
  Widget build(BuildContext context) {
    // Assuming a fixed number of days for simplicity
    int daysInMonth = 30;

    // Create a grid of days
    List<Widget> dayWidgets = List.generate(daysInMonth, (index) {
      int day = index + 1;
      bool isPeriodDay = periodDays.contains(day);

      return InkWell(
        onTap: () => _handleTap(day),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF616161)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(day.toString()),
              if (isPeriodDay)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Period Calendar'),
      ),
      body: GridView.count(
        crossAxisCount: 7, // 7 days in a week
        children: dayWidgets,
      ),
    );
  }

  void _handleTap(int day) {
    setState(() {
      if (periodDays.contains(day)) {
        periodDays.remove(day);
      } else {
        periodDays.add(day);
      }
    });
  }
}



class StatsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Placeholder widgets for mock graphs
    return Scaffold(
      appBar: AppBar(
        title: Text('DracuStats'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Text('ML per Day'),
            Container(
              height: 200,
              child: BloodVolumePerWeekDayGraph(),
            ),
            Text('Calendar with Period Days'),
            Container(
              height: 300, // Give a specific height to the calendar
              child: PeriodCalendar(), // Add the PeriodCalendar widget here
            ),
            Text('Questionnaire Performance'),
            Container(
              height: 200,
              child: QuestionnairePerformanceGraph(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraWidgetState extends State<CameraWidget> {
  late CameraController _controller;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.max);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    try {
      final image = await _controller.takePicture();
      widget.onCapture(image.path);
    } catch (e) {
      print(e);
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        Center(
          // This centers the CameraPreview
          child: CameraPreview(_controller),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: FloatingActionButton(
            onPressed: _captureImage,
            child: Icon(Icons.camera),
          ),
        )
      ],
    );
  }
}

class DracuVisionScreen extends StatefulWidget {
  @override
  _DracuVisionScreenState createState() => _DracuVisionScreenState();
}

class _DracuVisionScreenState extends State<DracuVisionScreen> {
  String _resultText = '';

  void onImageCaptured(String imagePath) async {
    // Process the image here
    // For example, you could send the image to a server for processing
    // and then display the result
    String processedText = await processImage(imagePath);
    setState(() {
      _resultText = processedText;
    });
  }

Future<String> processImage(String imagePath) async {
  // ── Phase 4 — custom Performance Trace ────────────────────────────
  // The "camera_capture" trace is the slowest user-perceived flow
  // in the app (file IO → multipart upload → server-side ML
  // inference → text response). Wrapping it in a parent span with
  // three children gives Embrace's Performance dashboard a
  // breakdown that's actually useful for diagnosing tail-latency
  // regressions, not just a single black-box "processImage was
  // slow" signal.
  final parent = await DracuObs.startSpan('camera_capture');
  final imageBytes = await File(imagePath).length().catchError((_) => 0);
  try {
    final uri = Uri.parse('$baseUrl/api/camera/');

    // Phase 1 — read the image file off disk + attach to the
    // multipart envelope. Renamed `compress` per the plan for
    // forward-compat (a future Phase will probably introduce
    // client-side JPEG compression here).
    final request = await DracuObs.recordSpan<http.MultipartRequest>(
      'compress',
      parent: parent,
      attributes: {'image.bytes': imageBytes.toString()},
      code: () async {
        return http.MultipartRequest('POST', uri)
          ..files.add(await http.MultipartFile.fromPath('image', imagePath));
      },
    );

    // Phase 2 — send via the wrapped client so the multipart
    // upload gets X-Embrace-Session-Id and is recorded as its own
    // network event in addition to this span.
    final uploadStart = DateTime.now();
    final response = await DracuObs.recordSpan<http.StreamedResponse>(
      'upload',
      parent: parent,
      attributes: {'image.bytes': imageBytes.toString()},
      code: () async => httpClient.send(request),
    );
    final networkDurationMs =
        DateTime.now().difference(uploadStart).inMilliseconds;

    // Phase 3 — drain the streamed response into a String the UI
    // can render. Captures parse/decode time which is occasionally
    // non-trivial on slow devices for large server payloads.
    final body = await DracuObs.recordSpan<String>(
      'parse_response',
      parent: parent,
      attributes: {
        'response.status': response.statusCode.toString(),
        'network.duration_ms': networkDurationMs.toString(),
      },
      code: () async {
        if (response.statusCode == 200) {
          return await http.Response.fromStream(response)
              .then((value) => value.body);
        } else {
          return 'Error: Server returned status code ${response.statusCode}';
        }
      },
    );
    await parent?.stop();
    return body;
  } catch (e, stack) {
    // Mark the parent span as a failure so the dashboard's
    // span-error rate goes up. logHandledDartError keeps this off
    // the crash-free-session metric (it was caught) but still
    // surfaces a stack trace in the logs panel.
    await parent?.stop(errorCode: ErrorCode.failure);
    DracuObs.recordHandledError(e, stack);
    return 'Error: Failed to send image - $e';
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DracuVision'),
      ),
      body: Column(
        children: [
          Expanded(
            child: CameraWidget(
              onCapture: onImageCaptured,
            ),
          ),
          if (_resultText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_resultText),
            ),
        ],
      ),
    );
  }
}

Future<void> main() async {
  // `ensureInitialized()` is required because `Embrace.instance.start`
  // touches platform channels (Method/Event channels) before runApp,
  // and those channels need the binary messenger from
  // `WidgetsFlutterBinding` to be ready.
  WidgetsFlutterBinding.ensureInitialized();
  // Boot the SDK first (sets up the native bridge, reads
  // embrace-config.json / Embrace-Info.plist). Synchronously
  // await — runApp must wait so the very first session captures
  // the cold-start spans cleanly.
  await Embrace.instance.start();
  // Then install the global Dart error handlers and run the app
  // inside the guarded zone so uncaught zone errors flow through
  // the SDK's crash handler. We use the explicit
  // `installErrorHandlers` API rather than `start(action: ...)` so
  // the intent of "wrap runApp in runZonedGuarded" is obvious at
  // the call site (and so the code keeps working across SDK
  // versions where `start`'s `action` param has wandered between
  // positional and named).
  await Embrace.instance.installErrorHandlers(() async {
    runApp(MyApp());
  });
  // Fire-and-forget: bump the persisted launch counter and tag
  // the session with a persona. Doesn't block runApp because (a)
  // it's disk IO and (b) Embrace's persona model applies to the
  // CURRENT session — if it lands one frame late the dashboard's
  // session-level segmentation still works.
  unawaited(_recordLaunchAndSetPersona());
}

/// Persisted launch counter → user persona for Embrace's
/// "Personas" filter. The counter lives in the app docs dir
/// (path_provider) as a one-line int file. Keeps no other state,
/// so wiping the app's data resets the persona to first-time-user.
///
/// Buckets:
///   1     → first-time-user   (no tag — Embrace shows the default)
///   2-5   → returning
///   6+    → power-user
///
/// We don't try to handle migration / corruption — if the file
/// can't be read, we treat it as launch #1 and overwrite.
Future<void> _recordLaunchAndSetPersona() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/.embrace_launch_count');
    int count = 0;
    if (await file.exists()) {
      try {
        count = int.parse((await file.readAsString()).trim());
      } catch (_) {
        count = 0;
      }
    }
    count += 1;
    await file.writeAsString(count.toString());

    if (count >= 6) {
      DracuObs.addPersona('power-user');
    } else if (count >= 2) {
      DracuObs.addPersona('returning');
    }
    // count == 1 → no persona, intentional. Embrace's default
    // segment "no persona set" already groups first-time users.

    // Surface the count as a session property too — searchable in
    // the Sessions tab, useful when triaging "did this user
    // actually use the app before crashing?".
    DracuObs.info('launch', properties: {'count': count.toString()});
  } catch (e, stack) {
    DracuObs.recordHandledError(e, stack);
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;
  late MenstrualHealthSurvey survey; // Use the late keyword
  late List<Widget> _pages;

  void _refreshChat() {
    setState(() 
    {});
  }

  @override
  void initState() {
    super.initState();

    // Initialize the survey here
    survey = MenstrualHealthSurvey([
      // Add your questions here
      Question(
          'El teu sagnat menstrual és més freqüent que cada 21 dies?', 2, 0),
      Question('El teu sagnat menstrual dura més de 7 dies?', 2, 0),
      Question(
          'Consideres que el teu sagnat menstrual és excessivament abundant?',
          3,
          0),
      Question(
          'Pateixes dolors forts durant el teu període menstrual que interfereixen amb les teves activitats diàries?',
          3,
          0),
      Question(
          'Experimentes símptomes addicionals (com ara nàusees, mal de cap intens, mareigs) durant el teu període?',
          2,
          0),
      Question(
          'El teu període menstrual té un impacte negatiu en la teva vida social o emocional?',
          2,
          0)
    ]);

    // Initialize the pages list in initState
    _pages = [
      DracuNewsScreen(),
      DracuChatScreen(
        onMessagesUpdated: _refreshChat,
      ),
      DracuQuizScreen(survey: survey), // Provide the survey object here
      DracuVisionScreen(),
      StatsScreen(), // Add the new stats screen
      ...debugCrashTabPages(),
    ];
  }

  // final List<Widget> _pages = [
  //   // Aquí puedes colocar tus diferentes pantallas o secciones
  //   // Por ahora, estoy usando contenedores con colores diferentes como ejemplo
  //   DracuNewsScreen(),
  //   DracuChatScreen(),
  //   DracuQuizScreen(),
  //   DracuVisionScreen(),
  // ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Draculin',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        cardTheme: const CardTheme(
          color: Color(0xFF1A1A2E),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Draculin'),
        ),
        body: _pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            // Phase 4 — breadcrumb on every nav change. Embrace's
            // crash UX shows the breadcrumb timeline of the last
            // ~30 s before any error, so this is the single most
            // valuable telemetry to add: if a user crashed on
            // DracuVision, the trail tells you they came from
            // DracuChat, not DracuNews.
            const labels = [
              'DracuNews',
              'DracuChat',
              'DracuQuiz',
              'DracuVision',
              'DracuStats',
              'Debug',
            ];
            final label = (index >= 0 && index < labels.length) ? labels[index] : 'unknown';
            DracuObs.breadcrumb('nav: $label');
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: Colors.pinkAccent,
          unselectedItemColor: Colors.pink[200],
          backgroundColor: const Color(0xFF1A1A2E),
          iconSize: 36.0,
          selectedFontSize: 16.0,
          unselectedFontSize: 14.0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.language),
              label: 'DracuNews',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.question_answer),
              label: 'DracuChat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_alt),
              label: 'DracuQuiz',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.photo_camera),
              label: 'DracuVision',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'DracuStats',
            ),
            ...debugCrashTabItems(),
          ],
        ),
      ),
    );
  }
}

class DracuNewsScreen extends StatefulWidget {
  @override
  _APINewsScreenState createState() => _APINewsScreenState();
}

class DracuChatScreen extends StatefulWidget {
  final void Function() onMessagesUpdated;

  DracuChatScreen({Key? key, required this.onMessagesUpdated})
      : super(key: key);

  @override
  _APIChatsScreenState createState() => _APIChatsScreenState();
}

class DracuQuizScreen extends StatefulWidget {
  final MenstrualHealthSurvey survey;

  DracuQuizScreen({Key? key, required this.survey}) : super(key: key);

  @override
  _DracuQuizScreenState createState() => _DracuQuizScreenState();
}

class Question {
  String text;
  int scoreYes;
  int scoreNo;

  Question(this.text, this.scoreYes, this.scoreNo);
}

class MenstrualHealthSurvey {
  List<Question> questions;
  int totalScore = 0;

  MenstrualHealthSurvey(this.questions);

  void answerQuestion(int questionIndex, bool answerYes) {
    Question question = questions[questionIndex];
    totalScore += answerYes ? question.scoreYes : question.scoreNo;
  }

  String getResult() {
    if (totalScore <= 3) return 'Impacte lleu o cap impacte.';
    if (totalScore <= 7)
      return 'Impacte moderat, pot requerir una revisió mèdica.';
    return 'Impacte sever, és aconsellable buscar ajuda mèdica. Truca al 112 per a assistència d\'emergència.';
  }
}

class _DracuQuizScreenState extends State<DracuQuizScreen> {
  int _currentQuestionIndex = 0;
  bool _isQuizCompleted = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _isQuizCompleted ? _buildResult() : _buildQuestion(),
    );
  }

  Widget _buildQuestion() {
    Question currentQuestion = widget.survey.questions[_currentQuestionIndex];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            currentQuestion.text,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _answerQuestion(true),
            child: Text(
              'Sí',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _answerQuestion(false),
            child: Text(
              'No',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _answerQuestion(bool answerYes) {
    widget.survey.answerQuestion(_currentQuestionIndex, answerYes);

    if (_currentQuestionIndex < widget.survey.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      setState(() {
        _isQuizCompleted = true;
      });
    }
  }

  Widget _buildResult() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Resultat del Test:',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            widget.survey.getResult(),
            style: TextStyle(fontSize: 18, color: Colors.blue),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _restartQuiz,
            child: Text('Restart Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _isQuizCompleted = false;
      widget.survey.totalScore = 0;
    });
  }
}

class News {
  final String title;
  final String link;
  final String img;

  News({required this.title, required this.link, required this.img});
}


class _APIChatsScreenState extends State<DracuChatScreen> {
  final String apiUrlInit = "$baseUrl/api/chat/";
  final String apiUrlMess = "$baseUrl/api/messages/";
  bool _hasFetchedData = false; 
  TextEditingController _messageController = TextEditingController();
  List<String> _messages = [];

  Future<Map<String, dynamic>> fetchAndInitData() async {
    final response = await httpClient.get(Uri.parse(apiUrlInit));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _updateMessages(data);
      return data;
    } else {
      throw Exception('Failed to load data from API');
    }
  }

  Future<Map<String, dynamic>> fetchData() async {
    final response = await httpClient.get(Uri.parse(apiUrlMess));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _updateMessages(data);
      return data;
    } else {
      throw Exception('Failed to load data from API');
    }
  }

  void _updateMessages(Map<String, dynamic> data) {
    print("MESSAGES UPDATING____________________________________________");
    _messages.clear();

    if (data != null && data['messages_dict'] != null) {
      for (var i = 0; i < data['messages_dict'].length; i++) {
        var message = data['messages_dict'][i.toString()];
        _messages.add(message);
      }
    }

    widget.onMessagesUpdated();
  }
  void _sendMessage(String message) async {
    print('Message sent: $message');
    DracuObs.breadcrumb('chat: send (len=${message.length})');

    Map<String, String> body = {'message': message};
    String apiUrl = "$baseUrl/api/chat/";
    try {
      final response = await httpClient.post(
        Uri.parse(apiUrl),
        body: json.encode(body),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print('Message sent successfully');
        await fetchData();
      } else {
        print('Failed to send message. Status code: ${response.statusCode}');
        // Non-2xx is a server-side problem worth surfacing in the
        // dashboard's Logs tab — Embrace's network event already
        // captured the status, this log gives the dashboard a
        // searchable string-typed property.
        DracuObs.warn(
          'chat: server returned non-2xx',
          properties: {'status': response.statusCode.toString()},
        );
      }
    } catch (e, stack) {
      print('Error sending message: $e');
      // ERROR-level breadcrumb so the timeline shows a clear
      // anomaly marker if a crash happens later in the same session
      // (Embrace renders ERROR breadcrumbs with a red icon).
      DracuObs.breadcrumb('chat: send failed (${e.runtimeType})');
      DracuObs.recordHandledError(e, stack);
    }

    _messageController.clear();
  }

  @override
  void initState() {
    super.initState();
    // Llama a fetchAndInitData solo cuando se inicia el widget
    fetchAndInitData().then((data) {
      setState(() {
        _hasFetchedData = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Elimina la llamada a fetchData de aquí
    return Scaffold(
      appBar: AppBar(
        title: Text('DracuChats'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Column(
              children: <Widget>[
                Flexible(
                  child: ListView.builder(
                    padding: EdgeInsets.all(8.0),
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (_, int index) => Text(_messages[index]),
                  ),
                ),
                Divider(height: 1.0),
                _buildMessageInput(),
              ],
            );
          }
        },
      ),
    );
  }
  Widget _buildMessageInput() {
    return Container(
      margin: EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              if (_messageController.text.isNotEmpty) {
                _sendMessage(_messageController.text);
              }
            },
          ),
        ],
      ),
    );
  }
}


class _APINewsScreenState extends State<DracuNewsScreen> {
  final String apiUrl = '$baseUrl/api/news';

  Future<Map<String, dynamic>> fetchData() async {
    final response = await httpClient.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data from API');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DracuNews'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            // Utiliza los datos de la API aquí
            final data = snapshot.data!;
            List<News> newsList = [];

            for (var i = 0; i < data['news'].length; i++) {
              var newsData = data['news'][i.toString()];
              newsList.add(News(
                  title: newsData['title'] ?? 'Title not found',
                  link: newsData['link'] ?? '#',
                  img: newsData['img'] ?? 'url not found'));
            }
            return ListView(
                children: newsList.map((news) {
              return Card(
                child: ListTile(
                  leading: Image.network(news.img, width: 100, height: 100),
                  title: Text(news.title),
                  onTap: () {
                    _launchURL(news.link);
                  },
                ),
              );
            }).toList());
          }
        },
      ),
    );
  }

  _launchURL(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'No se pudo abrir la URL: $url';
    }
  }
}
