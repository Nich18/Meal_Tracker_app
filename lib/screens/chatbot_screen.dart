import 'package:flutter/material.dart';
import '/utils/chatbot_service.dart';
import '/db/database_helper.dart';

class ChatbotScreen extends StatefulWidget {
  final int userId;

  const ChatbotScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  // Charger les messages depuis la base de données
  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  

void _scrollToBottom() {
  if (_scrollController.hasClients) {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}

  void _loadMessages() async {
    final db = DatabaseHelper();
    final messages = await db.getMessages(widget.userId);
    setState(() {
      _messages.clear();
      _messages.addAll(messages.map((e) => {
        'sender': e['isUser'] == 1 ? 'user' : 'chatbot',
        'message': e['message']
      }));
    });
  }

  void _sendMessage() async {
  final message = _controller.text;
  if (message.isEmpty) return;

  setState(() {
    _messages.add({'sender': 'user', 'message': message});
  });

  _controller.clear(); // Réinitialiser le champ de texte

  // Enregistrer le message utilisateur localement
  final db = DatabaseHelper();
  await db.insertMessage(widget.userId, message, true);

  // Ajouter un indicateur de chargement pour la réponse du bot
  setState(() {
    _messages.add({'sender': 'chatbot', 'message': 'En train de répondre...'});
    _scrollToBottom();
  });

  // Obtenir la réponse du chatbot
  try {
    final chatbotResponse = await ChatbotService().getBotResponse(message);

    // Mettre à jour l'interface avec la réponse
    setState(() {
      _messages.removeLast(); // Retirer l'indicateur de chargement
      _messages.add({'sender': 'chatbot', 'message': chatbotResponse});
      _scrollToBottom();
    });

    // Enregistrer la réponse du bot localement
    await db.insertMessage(widget.userId, chatbotResponse, false);
  } catch (e) {
    setState(() {
      _messages.removeLast();
      _messages.add({'sender': 'chatbot', 'message': 'Erreur lors de la connexion au chatbot.'});
      _scrollToBottom();
    });
    
    print('Erreur lors de l\'envoi : $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUserMessage = message['sender'] == 'user';

                  return Align(
                    alignment: isUserMessage
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isUserMessage ? Colors.blueAccent : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        message['message']!,
                        style: TextStyle(
                          color: isUserMessage ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Posez votre question...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ElevatedButton(
                onPressed: _sendMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Envoyer', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
