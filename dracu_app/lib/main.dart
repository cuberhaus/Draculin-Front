import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

// Camera
import 'package:camera/camera.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

const String baseUrl = 'https://bits-draculin.onrender.com';

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
            border: Border.all(color: Colors.grey),
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
  try {
    final uri = Uri.parse('$baseUrl/api/camera/');

    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', imagePath));

    var response = await request.send();

    if (response.statusCode == 200) {
      // Procesa el cuerpo de la respuesta
      return await http.Response.fromStream(response).then((value) => value.body);
    } else {
      // Maneja el error del servidor
      return 'Error: Server returned status code ${response.statusCode}';
    }
  } catch (e) {
    // Maneja cualquier excepción
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

void main() {
  runApp(MyApp());
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
      home: Scaffold(
        appBar: AppBar(
          title: Text('Draculin'),
        ),
        body: _pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: Colors.pink,
          unselectedItemColor: Colors.pink[100],
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
            // child: Text('Sí'),
            child: Text(
              'Sí',
              style: TextStyle(color: Colors.black), // Black text color
            ),
            style: ElevatedButton.styleFrom(
              primary: Colors.pink,
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
              style: TextStyle(color: Colors.black), // Black text color
            ),
            style: ElevatedButton.styleFrom(
              primary: Colors.grey,
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
              primary: Colors.green,
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
    final response = await http.get(Uri.parse(apiUrlInit));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _updateMessages(data);
      return data;
    } else {
      throw Exception('Failed to load data from API');
    }
  }

  Future<Map<String, dynamic>> fetchData() async {
    final response = await http.get(Uri.parse(apiUrlMess));

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

    Map<String, String> body = {'message': message};
    String apiUrl = "$baseUrl/api/chat/";
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: json.encode(body),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print('Message sent successfully');
        await fetchData(); // Recargar mensajes después de enviar el mensaje
      } else {
        print('Failed to send message. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
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
    final response = await http.get(Uri.parse(apiUrl));

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
