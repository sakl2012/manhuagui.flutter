import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../store.dart';

enum LoginStatus { initial, pending, success, failed }

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  static String getUsername() => globals.user.username ?? '';
  static String getPassword() => globals.user.password ?? '';

  final _username = TextEditingController(text: getUsername());
  final _password = TextEditingController(text: getPassword());

  LoginStatus _status = LoginStatus.initial;
  // bool _remember = true;

  bool get anyEmtpy => _username.text.isEmpty || _password.text.isEmpty;

  @override
  void initState() {
    _username.addListener(_refresh);
    _password.addListener(_refresh);
    super.initState();
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _startLogin() async {
    setState(() {
      _status = LoginStatus.pending;
    });

    final c = await globals.user
        .login(username: _username.text, password: _password.text);
    setState(() {
      _status = c == null ? LoginStatus.failed : LoginStatus.success;
    });
    if (globals.user.isLogin) {
      globals.syncFavorites();
    }
  }

  static const REGISTER_URL = 'https://tw.manhuagui.com/user/register';

  void _register() async {
    if (await canLaunch(REGISTER_URL)) {
      await launch(REGISTER_URL, forceSafariVC: false);
    } else {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('無法打開連結'),
              content: Center(
                  child: RaisedButton(
                child: const Text('確定'),
                color: Colors.red,
                onPressed: () {
                  Navigator.pop(context);
                },
              )),
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(left: 30.0, right: 30.0),
      width: 280.0,
      height: 300.0,
      child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _status == LoginStatus.initial
              ? [
                  TextFormField(
                    controller: _username,
                    autofocus: true,
                    decoration: const InputDecoration(
                        hintText: '使用者名稱',
                        labelStyle: TextStyle(color: Colors.red)),
                  ),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: '密碼',
                    ),
                  ),
                  // SwitchListTile(
                  //   title: const Text('記住密碼',style: TextStyle(color: Colors.blue, fontSize: 18.0)),
                  //   value: _remember,
                  //   onChanged: (value) {
                  //     setState(() {
                  //       _remember = value;
                  //     });
                  //   },
                  // ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      SizedBox(
                        width: 180.0,
                        height: 48.0,
                        child: RaisedButton(
                          color: Colors.green[900],
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.open_in_browser,
                                  color: Colors.white, size: 36.0),
                              Expanded(
                                  child: Center(
                                      child: const Text('網站註冊',
                                          style: const TextStyle(
                                            fontSize: 18.0,
                                            color: Colors.white,
                                          )))),
                            ],
                          ),
                          onPressed: _register,
                        ),
                      ),
                      SizedBox(
                        width: 120.0,
                        height: 40.0,
                        child: RaisedButton(
                          color: Colors.red[900],
                          textColor: Colors.white,
                          child: const Text('取消',
                              style: const TextStyle(fontSize: 18.0)),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 48.0,
                    child: RaisedButton(
                      color: Colors.lightBlue[800],
                      textColor: Colors.white,
                      child: Center(
                          child: const Text('登 入',
                              style: const TextStyle(fontSize: 21.0))),
                      onPressed: anyEmtpy ? null : _startLogin,
                    ),
                  ),
                ]
              : _status == LoginStatus.pending
                  ? [
                      SizedBox(
                        width: 100.0,
                        height: 100.0,
                        child: CircularProgressIndicator(),
                      ),
                      const Text('登入中...',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 20.0,
                          )),
                    ]
                  : _status == LoginStatus.success
                      ? [
                          const Text('登入成功！',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 30.0,
                              )),
                          SizedBox(
                            width: 120.0,
                            height: 40.0,
                            child: RaisedButton(
                              color: Colors.lightBlue[800],
                              textColor: Colors.white,
                              child: const Text('完成',
                                  style: const TextStyle(fontSize: 18.0)),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ]
                      : [
                          // failed
                          const Text('登入失敗！',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 30.0,
                              )),
                          SizedBox(
                            width: 120.0,
                            height: 40.0,
                            child: RaisedButton(
                              color: Colors.lightBlue[800],
                              textColor: Colors.white,
                              child: const Text('重新輸入',
                                  style: const TextStyle(fontSize: 18.0)),
                              onPressed: () {
                                setState(() {
                                  _username.text = '';
                                  _password.text = '';
                                  _status = LoginStatus.initial;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 120.0,
                            height: 40.0,
                            child: RaisedButton(
                              color: Colors.red[800],
                              textColor: Colors.white,
                              child: const Text('關閉',
                                  style: const TextStyle(fontSize: 18.0)),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ]));
}
