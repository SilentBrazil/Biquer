import 'dart:ui';

import 'package:Biquer/components/SocialLoginButton.dart';
import 'package:Biquer/constants.dart';
import 'package:Biquer/model/user/UserData.dart';
import 'package:Biquer/screens/HomeScreen.dart';
import 'package:Biquer/screens/register/RegisterScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';

class LoginScreen extends StatefulWidget {
  static String screenRoute = '/Login';

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscureText = true;
  bool login = false;
  String email, password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FadeInImage(
                  width: 230,
                  height: 230,
                  placeholder: AssetImage(''),
                  image: NetworkImage(kLoginImage)),
              Text(
                'Bem-vindo a Bico',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 40),
              ),
              Text(
                'A sua nova maneira de trabalhar e arranjar aquela renda extra que você sempre quis em suas mãos! Afinal um bico é sempre bom né?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.subtitle1,
              ),
              SocialLoginButton('Continuar com Google', FlutterIcons.google_mco,
                  backColor: Colors.blue,
                  iconColor: Colors.white,
                  textStyle: TextStyle(color: Colors.white), onTap: () async {
                FirebaseUser user = await UserData().signInWithGoogle();
                handleUserLogin(user, context);
              }),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: SizedBox(
                      width: double.maxFinite,
                      height: 1,
                      child: Container(
                        color: Theme.of(context).secondaryHeaderColor,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Ou'),
                  ),
                  Expanded(
                    child: SizedBox(
                      width: double.maxFinite,
                      height: 1,
                      child: Container(
                        color: Theme.of(context).secondaryHeaderColor,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                child: TextField(
                  textInputAction: TextInputAction.next,
                  onSubmitted: (value) => FocusScope.of(context).nextFocus(),
                  onChanged: (newValue) {
                    setState(() {
                      email = newValue;
                    });
                  },
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                      hintText: 'Email',
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color:
                                  Theme.of(context).textTheme.bodyText1.color),
                          borderRadius: kDefaultBorder)),
                ),
              ),
              Container(
                margin: kDefaultMargin,
                child: TextField(
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: obscureText,
                  textInputAction: TextInputAction.go,
                  onChanged: (newValue) {
                    setState(() {
                      password = newValue;
                    });
                  },
                  onSubmitted: (value) async {
                    FirebaseUser user = await UserData()
                        .signInWithEmailAndPassword(email, password);
                    handleUserLogin(user, context);
                  },
                  style: TextStyle(fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                      suffixIcon: IconButton(
                          icon: Icon(
                            obscureText
                                ? FlutterIcons.md_eye_ion
                                : FlutterIcons.md_eye_off_ion,
                          ),
                          onPressed: () {
                            setState(() {
                              obscureText = !obscureText;
                            });
                          }),
                      hintText: 'Senha',
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color:
                              Theme
                                  .of(context)
                                  .textTheme
                                  .bodyText1
                                  .color),
                          borderRadius: kDefaultBorder)),
                ),
              ),
              CupertinoButton(
                child: RichText(
                    text: TextSpan(text: 'Esqueceu a senha? ', children: [
                      TextSpan(
                          text: 'Clique aqui',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.red))
                    ])),
                onPressed: () =>
                    Navigator.pushNamed(context, RegisterScreen.screenRoute),
              ),
              MaterialButton(
                minWidth: double.maxFinite,
                padding: EdgeInsets.all(16),
                color: Theme
                    .of(context)
                    .textTheme
                    .bodyText1
                    .color,
                shape: RoundedRectangleBorder(borderRadius: kDefaultBorder),
                onPressed: login
                    ? null
                    : () async {
                  handleUserLogin(
                      await UserData()
                          .signInWithEmailAndPassword(email, password),
                      context);
                },
                child: Text(
                  'Login',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme
                          .of(context)
                          .scaffoldBackgroundColor),
                ),
              ),
              CupertinoButton(
                child: RichText(
                    text: TextSpan(text: 'Não possui cadastro? ', children: [
                      TextSpan(
                          text: 'Cadastre-se hoje mesmo',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme
                                  .of(context)
                                  .primaryColor))
                    ])),
                onPressed: () =>
                    Navigator.pushNamed(context, RegisterScreen.screenRoute),
              )
            ],
          ),
        ),
      )),
    );
  }

  void handleUserLogin(FirebaseUser user, BuildContext context) {
    if (user != null) {
      showDialog(
          context: context,
          child: CupertinoAlertDialog(
            title: Text('Login realizado com sucesso!'),
            content: Text('Bem-vindo ${user.displayName} sentimos sua falta!'),
            actions: [
              CupertinoButton(
                child: Text('Ok'),
                onPressed: () => Navigator.popAndPushNamed(
                    context, HomeScreen.screenRoute,
                    arguments: user),
              )
            ],
          ));
    } else {
      showDialog(
          context: context,
          child: CupertinoAlertDialog(
            content:
                Text('Ocorreu um erro ao realizar o login, tente novamente'),
            actions: [
              CupertinoButton(
                child: Text('Ok'),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ));
    }
    setState(() {
      login = false;
    });
  }
}
