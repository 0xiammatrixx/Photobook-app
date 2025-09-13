import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MailSent extends StatelessWidget {
  const MailSent({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.3,),
            SvgPicture.asset('assets/mailsent.svg', height: 106, width: 171,),
            SizedBox(height: 20,),
            Text('Check your Mail', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
            SizedBox(height: 4,),
            Text('We have sent a reset link to your mail', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),),
          ],
        ),
      ),
    );
  }
}