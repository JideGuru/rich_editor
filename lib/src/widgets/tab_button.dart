import 'package:flutter/material.dart';

class TabButton extends StatelessWidget {
  final IconData icon;

  TabButton({this.icon = Icons.format_bold});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
      child: Container(
        height: 45.0,
        width: 45.0,
        decoration: BoxDecoration(
          // color: Color(0xff212121),
          borderRadius: BorderRadius.all(
            Radius.circular(5.0),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.all(Radius.circular(5.0)),
            onTap: () {},
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Icon(
                  icon,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
