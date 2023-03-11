import 'package:flutter/material.dart';

class MarkdownParser extends StatelessWidget {
  final String data;

  MarkdownParser({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: _parseMarkdown(data),
    );
  }

  Widget _parseMarkdown(String data) {
    return Container(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _parseBlocks(data),
        ),
      ),
    );
  }

  List<Widget> _parseBlocks(String data) {
    final List<String> blocks = data.split('\n\n');
    final List<Widget> widgets = [];

    for (final block in blocks) {
      if (block.startsWith('#')) {
        widgets.add(_parseHeader(block));
      } else if (block.startsWith('- ')) {
        widgets.add(_parseList(block));
      } else if (block.startsWith('```')) {
        widgets.add(_parseCodeBlock(block));
      } else if (block.startsWith('![')) {
        widgets.add(_parseImage(block));
      } else {
        widgets.add(_parseParagraph(block));
      }
    }

    return widgets;
  }

  Widget _parseHeader(String data) {
    int level = 0;
    for (int i = 0; i < data.length; i++) {
      if (data[i] == '#') {
        level++;
      } else {
        break;
      }
    }
    final String text = data.substring(level + 1);
    final TextStyle style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 24.0 - (level * 2),
    );

    return Text(
      text,
      style: style,
      textAlign: TextAlign.left,
    );
  }

  Widget _parseList(String data) {
    final List<String> items = data.split('\n');
    final List<Widget> widgets = [];

    for (final item in items) {
      if (item.startsWith('- ')) {
        final String text = item.substring(2);
        widgets.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\u2022',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              SizedBox(
                width: 8.0,
              ),
              _parseParagraph(text),
            ],
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _parseCodeBlock(String data) {
    final String code = data.substring(3, data.length - 3);
    return Container(
      color: Colors.grey[200],
      padding: EdgeInsets.all(8.0),
      child: Text(
        code,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14.0,
        ),
      ),
    );
  }

  Widget _parseImage(String data) {
    final String altText =
        data.substring(data.indexOf('[') + 1, data.indexOf(']'));
    final String imageUrl =
        data.substring(data.indexOf('(') + 1, data.indexOf(')'));

    return Image.network(imageUrl, semanticLabel: altText);
  }

  Widget _parseParagraph(String data) {
    return Text(
      data,
      style: TextStyle(
        fontSize: 16.0,
      ),
    );
  }
}
