import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mobile_frontend/app/buttons.dart';
import 'package:mobile_frontend/features/auth/authscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  PageController _controller = PageController();
  int _currentPage = 0;

  final List<Widget> pages = [
    OnboardingSlide(
      imagePath: "assets/splash1.png",
      titleSpans: [
        TextSpan(
          text: "Capture ",
          style: TextStyle(
            color: Color(0xFFFF7A33),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: "moments, Connect with creatives",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
      description: "Book professional photographers anytime, anywhere.",
    ),
    OnboardingSlide(
      imagePath: "assets/splash2.png",
      titleSpans: [
        TextSpan(
          text: "Find talents ",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: "nearby",
          style: TextStyle(
            color: Color(0xFFFF7A33),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
      description: "Photographers are near you!",
    ),
    OnboardingSlide(
      imagePath: "assets/splash3.png",
      titleSpans: [
        TextSpan(
          text: "Book ",
          style: TextStyle(
            color: Color(0xFFFF7A33),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: "in Minutes!",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
      description:
          "Select your date, pick a package, and get instant confirmation.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: pages.length,
              itemBuilder: (context, index) => pages[index],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pages.length,
              (index) => Container(
                margin: const EdgeInsets.all(4),
                width: _currentPage == index ? 12 : 8,
                height: _currentPage == index ? 12 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index ? Colors.blue : Colors.grey,
                ),
              ),
            ),
          ),
          Row(
            children: [
              if (_currentPage != pages.length - 3)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_circle_left_outlined,
                      color: Color(0xFFFF7A33),
                    ),
                    onPressed: () async {
                      _controller.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    },
                  ),
                ),

              SizedBox(width: 56),

              Spacer(),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_circle_right_outlined,
                    color: Color(0xFFFF7A33),
                  ),
                  onPressed: () async {
                    if (_currentPage == pages.length - 1) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('seenOnboarding', true);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => ReadyPage()),
                      );
                    } else {
                      _controller.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OnboardingSlide extends StatelessWidget {
  final String imagePath;
  final List<TextSpan> titleSpans; // instead of just "title"
  final String description;

  const OnboardingSlide({
    required this.imagePath,
    required this.titleSpans,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Image.asset(imagePath, fit: BoxFit.contain)),
          const SizedBox(height: 30),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(children: titleSpans),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class ReadyPage extends StatelessWidget {
  const ReadyPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeigth = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: SvgPicture.asset('assets/bro.svg', fit: BoxFit.contain, height: screenHeigth * 0.4,)),
              const SizedBox(height: 30),
              Text('Ready! Set!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              CustomButton(text: 'Click', width: screenWidth * 0.3, onPressed: (){
                Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginPage()),
                      );
              })
            ],
          ),
        ),
      ),
    );
  }
}
