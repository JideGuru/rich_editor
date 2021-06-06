import 'package:flutter/material.dart';

class TabButton extends StatelessWidget {
  final IconData? icon;
  final Function? onTap;
  final String tooltip;
  final bool selected;

  TabButton({this.icon, this.onTap, this.tooltip = '', this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
      child: Tooltip(
        message: '$tooltip',
        child: Container(
          height: 40.0,
          width: 40.0,
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).accentColor.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.all(
              Radius.circular(5.0),
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.all(Radius.circular(5.0)),
              onTap: () => onTap!(),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Icon(
                    icon,
                    color: selected
                        ? Theme.of(context).accentColor
                        : Theme.of(context).iconTheme.color,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
