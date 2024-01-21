import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auth Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SignInScreen(),
    );
  }
}

class User {
  final String id;
  final String email;
  final String password;

  User({required this.id, required this.email, required this.password});
}

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isServiceProvider = false;

  List<User> users = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Connexion / Inscription')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
            SwitchListTile(
              title: Text('Prestataire de service'),
              value: isServiceProvider,
              onChanged: (bool value) {
                setState(() {
                  isServiceProvider = value;
                });
              },
            ),
            ElevatedButton(
              child: Text('Inscription'),
              onPressed: () {
                signUp(emailController.text, passwordController.text, isServiceProvider);
              },
            ),
            ElevatedButton(
              child: Text('Connexion'),
              onPressed: () {
                OptionalUser? result = signIn(emailController.text, passwordController.text);
                if (result != null && result.user != null) {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ServiceSelectionScreen()));
                } else if (result != null && result.errorMessage != null) {
                  setState(() {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Erreur d\'authentification'),
                          content: Text(result.errorMessage!),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  OptionalUser? getUserByEmail(String email) {
    try {
      final user = users.firstWhere((user) => user.email == email);
      return OptionalUser(user: user);
    } on StateError {
      return OptionalUser(errorMessage: 'Aucun utilisateur trouvé avec cet e-mail');
    }
  }

  OptionalUser? signIn(String email, String password) {
    final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');

    if (!emailRegExp.hasMatch(email)) {
      return OptionalUser(errorMessage: 'L\'adresse e-mail doit être de la forme "nom@gmail.com"');
    }

    OptionalUser? user = getUserByEmail(email);

    if (user == null || user.user == null) {
      return OptionalUser(errorMessage: 'Aucun utilisateur avec cet e-mail n\'a été trouvé');
    }

    bool passwordMatches = _hashPassword(password) == user.user!.password;

    if (passwordMatches) {
      return OptionalUser(user: user.user);
    } else {
      return OptionalUser(errorMessage: 'Authentification échouée');
    }
  }

  void signUp(String email, String password, bool isServiceProvider) {
    final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');

    if (!emailRegExp.hasMatch(email)) {
      setState(() {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Erreur d\'inscription'),
              content: Text('L\'adresse e-mail doit être de la forme "nom@gmail.com"'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      });
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Erreur d\'inscription'),
              content: Text('Veuillez remplir tous les champs d\'inscription'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      });
      return;
    }

    OptionalUser? user = getUserByEmail(email);

    if (user != null && user.user != null) {
      setState(() {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Erreur d\'inscription'),
              content: Text('Un utilisateur avec cet e-mail existe déjà'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      });
      return;
    }

    String hashedPassword = _hashPassword(password);

    User newUser = User(id: UniqueKey().toString(), email: email, password: hashedPassword);
    users.add(newUser);

    if (isServiceProvider) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ServiceSelectionScreen()));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
    }
  }

  String _hashPassword(String password) {
    final salt = 'your_salt_here';
    final codec = Utf8Codec();
    final key = codec.encode(salt + password);
    final bytes = sha256.convert(key);
    return bytes.toString();
  }
}

class ServiceSelectionScreen extends StatelessWidget {
  final List<String> services = [
    'Mécanicien',
    'Couturier',
    'Électricien',
    'Plombier',
    'Jardinier',
    'Maçon',
    'Plafonnier',
    'Menuisier',
    'Femme de ménage',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sélectionnez un service'),
      ),
      body: ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return ListTile(
            title: Text(service, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            onTap: () {
              // Ajoutez ici la logique pour rediriger l'utilisateur vers la page du service sélectionné
            },
          );
        },
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Espace Utilisateur'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SignInScreen()));
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Liste des services disponibles',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class OptionalUser {
  final User? user;
  final String? errorMessage;

  OptionalUser({this.user, this.errorMessage});
}
