import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

// Camera
import 'package:camera/camera.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PeriodCalendar extends StatelessWidget {
  // Example data: days with periods
  final List<int> periodDays = [5, 12, 19, 26];

  @override
  Widget build(BuildContext context) {
    // Assuming a fixed number of days for simplicity
    int daysInMonth = 30;

    // Create a grid of days
    List<Widget> dayWidgets = List.generate(daysInMonth, (index) {
      int day = index + 1;
      bool isPeriodDay = periodDays.contains(day);

      return Container(
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
}


class StatsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Placeholder widgets for mock graphs
    return Scaffold(
      appBar: AppBar(
        title: Text('Stats'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Text('ML per Day'),
            Container(
              height: 200,
              color: Colors.grey[200], // Placeholder for graph
            ),
            Text('Calendar with Period Days'),
            Container(
              height: 300, // Give a specific height to the calendar
              child: PeriodCalendar(), // Add the PeriodCalendar widget here
            ),
            Text('Questionnaire Performance'),
            Container(
              height: 200,
              color: Colors.grey[400], // Placeholder for graph
            ),
          ],
        ),
      ),
    );
  }
}

class CameraWidget extends StatefulWidget {
  final Function(String) onCapture;

  CameraWidget({required this.onCapture});

  @override
  _CameraWidgetState createState() => _CameraWidgetState();
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
        CameraPreview(_controller),
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
    // Implement your image processing logic here
    final uri = Uri.parse('https://your_server_endpoint');

    // Create a multipart request
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', imagePath));

    try {
      // Send the request
      final streamedResponse = await request.send();

      // Get the response from the server
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Process the response body
        return response.body;
      } else {
        // Handle server error
        return 'Error: Server returned status code ${response.statusCode}';
      }
    } catch (e) {
      // Handle any exceptions
      return 'Error: Failed to send image - $e';
    }

    return "Processed text from the image";
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
      StatsScreen(), // Add the new stats screen
      DracuNewsScreen(),
      DracuChatScreen(
        onMessagesUpdated: _refreshChat,
      ),
      DracuQuizScreen(survey: survey), // Provide the survey object here
      DracuVisionScreen(),
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
              icon: Icon(Icons.bar_chart),
              label: 'Stats',
            ),
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

// class DracuVisionScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Text('Vision Screen'),
//     );
//   }
// }

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
  final String apiUrl = 'https://bitsxmarato.onrender.com/api/chat/';

  TextEditingController _messageController = TextEditingController();
  List<String> _messages = [];

  Future<Map<String, dynamic>> fetchData() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _updateMessages(data);
      return data;
    } else {
      throw Exception('Failed to load data from API');
    }
  }

  void _updateMessages(Map<String, dynamic> data) {
    _messages.clear();
    for (var i = 0; i < data['messages_dict'].length; i++) {
      var message = data['messages_dict'][i.toString()];
      _messages.add(message);
    }
    widget.onMessagesUpdated();
  }

  void _sendMessage(String message) async {
    print('Message sent: $message');

    Map<String, String> body = {'message': message};
    String apiUrl = 'https://10.0.2.2:8000/api/chat/';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: json.encode(body),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print('Message sent successfully');
        final data = json.decode(response.body);
        setState(() {
          _updateMessages(data);
        });
      } else {
        print('Failed to send message. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
    }

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DracuChat'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
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
  final String apiUrl = 'https://bitsxmarato.onrender.com/api/news';

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
                  title: newsData['title'],
                  link: newsData['link'],
                  img: newsData['img']));
            }
            return ListView(
                children: newsList.map((news) {
              return Card(
                child: ListTile(
                  leading: Image.network(news.img, width: 100, height: 100), // Display the image
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
