import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final String caption, title;

  HomeHeader({this.caption, this.title});

  @override
  Widget build(BuildContext context) {
    return this.caption != null && this.title != null
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption,
                  style: Theme.of(context)
                      .textTheme
                      .caption
                      .copyWith(fontSize: 18),
                ),
                Text(
                  title,
                  overflow: TextOverflow.fade,
                  softWrap: true,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                )
              ],
            ),
          )
        : SizedBox();
  }
}
