import 'package:flutter/material.dart';

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
      DracuChatScreen(),
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

class DracuNewsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('News Screen'),
    );
  }
}

class DracuChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Chat Screen'),
    );
  }
}

// class DracuQuizScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Text('Quiz Screen'),
//     );
//   }
// }
class DracuQuizScreen extends StatefulWidget {
  final MenstrualHealthSurvey survey;

  DracuQuizScreen({Key? key, required this.survey}) : super(key: key);

  @override
  _DracuQuizScreenState createState() => _DracuQuizScreenState();
}

class DracuVisionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Vision Screen'),
    );
  }
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
    return 'Impacte sever, és aconsellable buscar ajuda mèdica.';
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(currentQuestion.text),
        ElevatedButton(
          onPressed: () => _answerQuestion(true),
          child: Text('Sí'),
        ),
        ElevatedButton(
          onPressed: () => _answerQuestion(false),
          child: Text('No'),
        ),
      ],
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Resultat del Test:'),
        Text(widget.survey.getResult()),
        ElevatedButton(
          onPressed: _restartQuiz,
          child: Text('Restart Quiz'),
        ),
      ],
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
