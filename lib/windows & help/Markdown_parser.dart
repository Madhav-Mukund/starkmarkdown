import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme.dart';

class MarkdownParser extends StatelessWidget {
  final String data;
  Color def = Colors.black;
  Color cb = Colors.grey.shade900;

  MarkdownParser({required this.data});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    if (themeProvider.isDarkModeEnabled) {
      def = Colors.white;
      cb = Colors.black;
    }
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
    final List<String> lines = data.split('\n');
    final List<Widget> widgets = [];

    String currentBlock = '';

    for (final line in lines) {
      if (line.startsWith('#')) {
        if (currentBlock.isNotEmpty) {
          widgets.add(paragraph(currentBlock, def));
          currentBlock = '';
        }
        widgets.add(heading(line));
      } else if (line.startsWith('- ')) {
        if (currentBlock.isNotEmpty) {
          widgets.add(paragraph(currentBlock, def));
          currentBlock = '';
        }
        widgets.add(lists(line));
      } else if (line.startsWith('```')) {
        if (currentBlock.isNotEmpty) {
          widgets.add(paragraph(currentBlock, def));
          currentBlock = '';
        }
        widgets.add(codeblock(line));
      } else if (line.startsWith('![')) {
        if (currentBlock.isNotEmpty) {
          widgets.add(paragraph(currentBlock, def));
          currentBlock = '';
        }
        widgets.add(image(line));
      } else if (line.startsWith('> ')) {
        if (currentBlock.isNotEmpty) {
          widgets.add(paragraph(currentBlock, def));
          currentBlock = '';
        }
        widgets.add(quote(line));
      } else {
        currentBlock += line + '\n';
      }
    }

    if (currentBlock.isNotEmpty) {
      widgets.add(paragraph(currentBlock, def));
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
              Flexible(child: paragraph(text, def)),
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
    final String url =
        data.substring(data.indexOf('(') + 1, data.lastIndexOf(')'));

    return Image.network(url, semanticLabel: alt);
  }

  Widget paragraph(String data, Color color) {
    final List<TextSpan> textSpans = [];

    final RegExp allreg = RegExp(r'(\*\*\*|\*\*|__|\*|_|\~\~)(.*?)\1');

    int i = 0;
    while (i < data.length) {
      final match = allreg.firstMatch(data.substring(i));
      if (match == null) {
        textSpans.add(TextSpan(text: data.substring(i)));
        break;
      } else {
        if (match.start > 0) {
          textSpans.add(TextSpan(text: data.substring(i, i + match.start)));
        }

        final String marker = match.group(1)!;
        final String text = match.group(2)!;
        final TextStyle style = textstyle(marker);

        textSpans.add(TextSpan(text: text, style: style));
        i += match.start + match.group(0)!.length;
      }
    }

    return Text.rich(
      TextSpan(children: textSpans),
      maxLines: null,
      textAlign: TextAlign.justify,
      style: GoogleFonts.lato(fontSize: 16, color: color),
    );
  }

  TextStyle textstyle(String marker) {
    switch (marker) {
      case '**':
      case '__':
        return GoogleFonts.lato(fontWeight: FontWeight.bold);
      case '*':
      case '_':
        return GoogleFonts.lato(fontStyle: FontStyle.italic);
      case '~~':
        return GoogleFonts.lato(decoration: TextDecoration.lineThrough);
      case '***':
        return GoogleFonts.lato(
            fontStyle: FontStyle.italic, fontWeight: FontWeight.bold);
      default:
        return TextStyle();
    }
  }

  Widget quote(String data) {
    final String text = data.substring(1);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Colors.grey.shade400,
            width: 4.0,
          ),
        ),
      ),
      padding: const EdgeInsets.only(left: 8),
      child: paragraph(text, cb),
    );
  }
}
