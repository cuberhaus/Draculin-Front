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

  final List<Widget> _pages = [
    // Aquí puedes colocar tus diferentes pantallas o secciones
    // Por ahora, estoy usando contenedores con colores diferentes como ejemplo
    DracuNewsScreen(),
    DracuChatScreen(),
    DracuQuizScreen(),
    DracuVisionScreen(),
  ];

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

class DracuQuizScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Quiz Screen'),
    );
  }
}

class DracuVisionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Vision Screen'),
    );
  }
}
