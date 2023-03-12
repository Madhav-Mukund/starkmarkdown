import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MarkdownParser extends StatelessWidget {
  final String data;

  MarkdownParser({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: parser(data),
    );
  }

  Widget parser(String data) {
    return SingleChildScrollView(
      child: Container(
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: blocks(data),
        ),
      ),
    );
  }

  List<Widget> blocks(String data) {
    final List<String> blocks = data.split('\n\n');
    final List<Widget> widgets = [];

    for (final block in blocks) {
      if (block.startsWith('#')) {
        widgets.add(heading(block));
      } else if (block.startsWith('- ')) {
        widgets.add(lists(block));
      } else if (block.startsWith('```')) {
        widgets.add(codeblock(block));
      } else if (block.startsWith('![')) {
        widgets.add(image(block));
      } else {
        widgets.add(paragraph(block));
      }
    }

    return widgets;
  }

  Widget heading(String data) {
    int level = 0;

    for (int i = 0; i < data.length; i++) {
      if (data[i] == '#') {
        level++;
      } else {
        break;
      }
    }
    final String text = data.substring(level + 1);

    final TextStyle style = GoogleFonts.lato(
        fontSize: 24 - (2 * level.toDouble()), fontWeight: FontWeight.bold);

    return Text(
      text,
      style: style,
      textAlign: TextAlign.justify,
    );
  }

  Widget lists(String data) {
    final List<String> items = data.split('\n');
    final List<Widget> widgets = [];

    for (final item in items) {
      if (item.startsWith('- ')) {
        final String text = item.substring(2);
        widgets.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '\u2022',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              const SizedBox(
                width: 8.0,
              ),
              Flexible(child: paragraph(text)),
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

  Widget codeblock(String data) {
    final String code = data.substring(3, data.length - 3);
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(8.0),
      child: Text(
        code,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14.0,
        ),
      ),
    );
  }

  Widget image(String data) {
    final String alt = data.substring(data.indexOf('[') + 1, data.indexOf(']'));
    final String url = data.substring(data.indexOf('(') + 1, data.indexOf(')'));

    return Image.network(url, semanticLabel: alt);
  }

  Widget paragraph(String data) {
    final List<TextSpan> textSpans = [];

    final RegExp bold = RegExp(r'\*\*(.*?)\*\*');
    final RegExp italic = RegExp(r'\*(.*?)\*');
    final RegExp under = RegExp(r'_([^_]+)_');
    final RegExp strike = RegExp(r'~~(.*?)~~');

    List<String> splitData = data.split(bold);
    for (int i = 0; i < splitData.length; i++) {
      String text = splitData[i];
      if (i % 2 == 1) {
        textSpans.add(TextSpan(
          text: text,
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ));
      } else {
        List<String> splititalic = text.split(italic);
        for (int j = 0; j < splititalic.length; j++) {
          String italic = splititalic[j];
          if (j % 2 == 1) {
            textSpans.add(TextSpan(
              text: italic,
              style: GoogleFonts.lato(fontStyle: FontStyle.italic),
            ));
          } else {
            List<String> splitunder = italic.split(under);
            for (int k = 0; k < splitunder.length; k++) {
              String under = splitunder[k];
              if (k % 2 == 1) {
                textSpans.add(TextSpan(
                  text: under,
                  style: GoogleFonts.lato(decoration: TextDecoration.underline),
                ));
              } else {
                List<String> splitstrike = under.split(strike);
                for (int l = 0; l < splitstrike.length; l++) {
                  String strike = splitstrike[l];
                  if (l % 2 == 1) {
                    textSpans.add(TextSpan(
                      text: strike,
                      style: GoogleFonts.lato(
                          decoration: TextDecoration.lineThrough),
                    ));
                  } else {
                    textSpans.add(TextSpan(text: strike));
                  }
                }
              }
            }
          }
        }
      }
    }

    return Text.rich(
      TextSpan(children: textSpans),
      maxLines: null,
      textAlign: TextAlign.justify,
      style: GoogleFonts.lato(fontSize: 16),
    );
  }
}
