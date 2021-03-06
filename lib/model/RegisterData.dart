import 'dart:async';
import 'dart:io';

import 'package:Biquer/components/MessageBubble.dart';
import 'package:cpf_cnpj_validator/cnpj_validator.dart';
import 'package:cpf_cnpj_validator/cpf_validator.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'address/Address.dart';
import 'address/AddressData.dart';
import 'address/CepData.dart';
import 'document/Document.dart';
import 'document/DocumentData.dart';
import 'user/User.dart';
import 'user/UserData.dart';

enum RegisterStage { user, address, document, photo, saving, complete }

class RegisterData extends ChangeNotifier {
  List<MessageBubble> messages = [];

  FirebaseUser user;
  RegisterStage stage = RegisterStage.user;
  AddressStage addressStage = AddressStage.cep;
  UserStage userStage = UserStage.email;
  DocumentStage documentStage = DocumentStage.selectype;
  Address _userAddress;
  User _myUser;
  Document _userDocument;
  String userEmail, userPassword, userName;

  RegisterData() {
    userAddress = Address();
    _myUser = User();
    _userDocument = Document();
  }

  Address get userAddress => _userAddress;

  User get myUser => _myUser;

  set userAddress(Address value) {
    _userAddress = value;
    print('Address updated');
    notifyListeners();
  }

  void initializeRegister() async {
    var udata = UserData();
    List<MessageBubble> registerMessages = await udata
        .loadRegisterMessages('Debora Profil', (FirebaseUser firebaseuser) {
      updateUser(firebaseuser);
    });
    if (registerMessages == null || registerMessages.isEmpty) {
      sendReply('Ocorreu um erro ao iniciar o chat');
    } else {
      addBubbles(registerMessages);
    }
  }

  void updateUser(FirebaseUser firebaseuser) {
    print('user logged $firebaseuser');
    if (firebaseuser != null) {
      user = firebaseuser;
      sendSuccessMessage(
          'Seus dados foram validados ${user.displayName} vamos prosseguir com o cadastro');
      this.user = firebaseuser;
      _myUser.uid = user.uid;
      stage = RegisterStage.address;
      initializeAddress();
    } else {
      sendReply('Ops parece que algo deu errado durante seu login');
    }
  }

  void initializeAddress() {
    var addressMessages = AddressData().loadAddressMessages();
    addBubbles(addressMessages);
  }

  Future addBubbles(List<MessageBubble> messageBubbles) async {
    if (messageBubbles.length == 0) {
      sendReply('Só um momento...');
    }
    for (MessageBubble message in messageBubbles) {
      messages.add(message);
      notifyListeners();
      await Future.delayed(Duration(seconds: 4), () {
        print('can add another bubble now');
      });
    }
    print('added ${messages.length} bubbles');
  }

  void updateMessages(Widget child, MessageType messageType) {
    addBubbles([MessageBubble(messageType: messageType, messageChild: child)]);
  }

  void createMessage(MessageBubble bubble) {
    messages.add(bubble);
  }

  void sendData(dynamic msg) {
    handleData(msg);
  }

  void handleData(dynamic data) {
    switch (stage) {
      case RegisterStage.address:
        handleAddress(data);
        break;
      case RegisterStage.user:
        handleUser(data);
        break;
      case RegisterStage.document:
        handleDocument(data);
        break;
      case RegisterStage.photo:
        updateUserPic(data);
        break;
      case RegisterStage.complete:
        sendSuccessMessage('Seu cadastro foi concluído com sucesso!');
        break;
      case RegisterStage.saving:
        loadMessage();
        break;
    }
  }

  void handleAddress(String data) {
    switch (addressStage) {
      case AddressStage.cep:
        getCepData(data);
        break;
      case AddressStage.number:
        updateAddressNumber(data);
        break;
      case AddressStage.proof:
        updateAddressURL(data);
        break;
    }
  }

  void handleUser(String data) async {
    switch (userStage) {
      case UserStage.email:
        updateUserEmail(data);
        break;
      case UserStage.password:
        await updateUserPass(data);
        break;
      case UserStage.name:
        updateUsername(data);
        break;
    }
  }

  Future updateUserPass(String data) async {
    userPassword = data;
    loadMessage();
    user =
        await UserData().registerWithEmailAndPassword(userEmail, userPassword);
    messages.removeLast();
    if (user != null) {
      sendSuccessMessage(
          'Seu email foi validado com sucesso ${user.displayName} vamos continuar com o cadastro');
      stage = RegisterStage.address;
      initializeAddress();
    } else {
      sendErrorMessage(
          'Ocorreu um erro ao processar seu cadastro, vamos tentar de novo');
      sendReply('Envie seu email');
      userStage = UserStage.email;
    }
    notifyListeners();
  }

  void sendSuccessMessage(String msg) {
    addBubbles([MessageBubble.successMessage(msg)]);
  }

  void sendErrorMessage(String msg) {
    addBubbles([MessageBubble.errorMessage(msg)]);
  }

  void updateUserEmail(String data) {
    sendMessage(Text(data));
    if (!EmailValidator.validate(data)) {
      sendReply('Não foi possível validar seu email, envie novamente',
          backcolor: Colors.red);
      return;
    }
    userEmail = data;
    userStage = UserStage.password;
    sendReply('Ok agora digite sua senha');
    notifyListeners();
  }

  void updateUsername(String data) {
    sendData(Text(data));
    userName = data;
    sendReply('Que nome lindo! agora envie seu email por gentileza');
    userStage = UserStage.email;
  }

  void handleDocument(dynamic data) {
    switch (documentStage) {
      case DocumentStage.selectype:
        updateUserType(data);
        break;
      case DocumentStage.docid:
        updateDocID(data);
        break;
      case DocumentStage.docUrl:
        updateDocURL(data);
        break;
    }
  }

  void updateUserType(data) {
    _myUser.type = data;
    documentStage = DocumentStage.docid;
    String type = _myUser.type == UserType.individual ? 'CPF' : 'CNPJ';
    sendReply('Ok agora insira seu $type');
  }

  void getCepData(String cepInput) async {
    sendMessage(Text(cepInput));
    loadMessage();
    var cepHelper = CepHelper(cepInput);
    var cepData = await cepHelper.getCepInfo();
    print('cep updated $cepData');
    var error = cepData == null;
    if (!error) {
      messages.removeLast();
      sendSuccessMessage(
          'Endereço validado com sucesso veja a seguir se as informações estão corretas');
      updateAddressCEP(cepData.cep);
      await addBubbles(cepData.cepMessages());
      sendReply('Ok agora envie o número da residência');
      addressStage = AddressStage.number;
    } else {
      messages.removeLast();
      sendReply(
          'Opss, não consegui encontrar seu CEP, poderia digitar novamente?');
      notifyListeners();
    }
  }

  void sendReply(String msg, {Color backcolor}) {
    updateMessages(
        Text(
          msg,
          style: TextStyle(color: Colors.white),
        ),
        MessageType.reply);
  }

  void sendMessage(Widget child) {
    addBubbles([
      MessageBubble(
        messageChild: child,
        messageType: MessageType.send,
      )
    ]);
  }

  void loadMessage() {
    messages.add(MessageBubble(
        messageChild: FadeInImage(
            width: 100,
            height: 100,
            placeholder: AssetImage('images/chick.png'),
            image: AssetImage('images/debtyping.png')),
        messageType: MessageType.reply,
        backcolor: Colors.transparent));
    notifyListeners();
  }

  set userDocument(Document value) {
    _userDocument = value;
    print('document updated on provider');
    notifyListeners();
  }

  void updateAddressNumber(String number) {
    userAddress.number = number;
    sendMessage(Text(number));
    sendReply('Muito bem agora envie um comprovante de endereço');
    addressStage = AddressStage.proof;
  }

  void updateDocID(String id) {
    if (_myUser.type == UserType.individual) {
      if (!CPFValidator.isValid(id)) {
        sendErrorMessage('CPF inválido tente novamente');
      }
    } else if (_myUser.type == UserType.company) {
      if (!CNPJValidator.isValid(id)) {
        sendErrorMessage('CNPJ inválido tente novamente');
      }
    }

    _userDocument.id = id;
    sendMessage(Text(id));
    sendReply(
        'Perfeito agora envie a foto de seu documento para comprovar sua identidade');
    documentStage = DocumentStage.docUrl;

    print('updated docID $id on provider');
  }

  void updateAddressURL(String url) async {
    print('Getting file $url');
    _userAddress.urlComprovAddress = url;
    updateMessages(
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: FadeInImage(
              width: 200,
              fit: BoxFit.cover,
              height: 200,
              placeholder: AssetImage('images/chick.png'),
              image: FileImage(
                File(url),
              )),
        ),
        MessageType.send);
    sendReply('Perfeito vamos prosseguir com o cadastro');
    stage = RegisterStage.document;
    addBubbles(await DocumentData().docMessages((usertype) {
      _myUser.type = usertype;
      if (usertype == UserType.individual) {
        sendReply('Ok agora insira o seu CPF');
      } else {
        sendReply('Ok agora insira seu cnpj');
      }
      documentStage = DocumentStage.docid;
    }));
    documentStage = DocumentStage.selectype;
    notifyListeners();
  }

  void updateDocURL(String url) {
    _userDocument.docURL = url;
    updateMessages(
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: FadeInImage(
              width: 200,
              height: 200,
              placeholder: AssetImage('images/chick.png'),
              image: FileImage(
                File(url),
              )),
        ),
        MessageType.send);
    sendReply('Perfeito hora da última etapa');

    sendReply(
        'Para finalizar você precisa enviar uma foto de rosto com seu documento em mãos');
    stage = RegisterStage.photo;
    notifyListeners();
  }

  void updateUserPic(String url) async {
    _myUser.safetyPic = url;
    notifyListeners();
    updateMessages(
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: FadeInImage(
              width: 200,
              height: 200,
              placeholder: AssetImage('images/chick.png'),
              image: FileImage(
                File(url),
              )),
        ),
        MessageType.send);
    sendReply('Ok isso é tudo vou processar seu cadastro');
    loadMessage();
    bool saved = await saveUserInfo();
    if (saved) {
      sendSuccessMessage(
          'Seu cadastro foi concluído com sucesso, você já está pronto para usar a bico!');
      stage = RegisterStage.complete;
    } else {
      sendReply(
          'Ocorreu um erro ao processar seu cadastro já estou verificando isso');
      sendData(url);
    }
  }

  void updateAddressCEP(String cep) {
    userAddress.cep = cep;
    notifyListeners();
    print('cep $cep updated on provider');
  }

  bool userLogged() {
    print('user logged?  ${user != null}');
    return user != null;
  }

  Future<bool> saveUserInfo() async {
    _myUser.document = _userDocument;
    _myUser.address = _userAddress;
    stage = RegisterStage.saving;
    notifyListeners();
    return await UserData()
        .saveUserInfo(_myUser, user.displayName.trim(), this);
  }
}
