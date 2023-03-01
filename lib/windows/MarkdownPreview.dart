import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MyMarkdownScreen extends StatefulWidget {
  String markdown;
  MyMarkdownScreen({required this.markdown});

  @override
  _MyMarkdownScreenState createState() => _MyMarkdownScreenState();
}

class _MyMarkdownScreenState extends State<MyMarkdownScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.markdown);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Markdown(
              data: widget.markdown,
            ),
          ),
          Row(children: <Widget>[
            Expanded(
                child: Divider(
              thickness: 5,
            )),
            Text(
              "Enter Text Below",
              style: TextStyle(fontSize: 15),
            ),
            Expanded(
                child: Divider(
              thickness: 5,
            )),
          ]),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (value) => setState(() {
                widget.markdown = value;
              }),
              decoration: const InputDecoration(
                hintText: "Markdown content",
              ),
              keyboardType: TextInputType.multiline,
              maxLines: null,
            ),
          ),
        ],
      ),
    );
  }
}
