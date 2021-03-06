import 'package:Biquer/constants.dart';
import 'package:flutter/material.dart';

enum MessageType { send, reply }

class MessageBubble extends StatefulWidget {
  static Text defaultMessageText(String text) {
    return Text(text, style: TextStyle(color: Colors.white));
  }

  final Widget messageChild;
  final MessageType messageType;
  final Color backcolor;

  MessageBubble(
      {@required this.messageChild,
      this.messageType = MessageType.reply,
      this.backcolor});

  static MessageBubble successMessage(String msg) {
    return MessageBubble(
      messageChild: defaultMessageText(msg),
      messageType: MessageType.reply,
      backcolor: Colors.green,
    );
  }

  static MessageBubble errorMessage(String msg) {
    return MessageBubble(
      messageChild: defaultMessageText(msg),
      messageType: MessageType.reply,
      backcolor: Colors.red,
    );
  }

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Column(
        crossAxisAlignment: widget.messageType == MessageType.send
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            child: widget.messageChild,
            padding: EdgeInsets.all(16),
            margin: widget.messageType != MessageType.send
                ? EdgeInsets.only(right: 88)
                : EdgeInsets.only(left: 88),
            decoration: BoxDecoration(
                color: widget.messageType == MessageType.reply
                    ? widget.backcolor ?? Theme.of(context).primaryColor
                    : Theme.of(context).hintColor.withOpacity(0.10),
                borderRadius: widget.messageType == MessageType.send
                    ? kUserMessageBorder
                    : kSenderMessageBorder),
          ),
        ],
      ),
    );
  }
}
