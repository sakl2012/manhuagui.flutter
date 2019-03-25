import 'package:flutter/material.dart';
import 'package:simple_auth/simple_auth.dart';
import 'package:simple_auth_flutter/simple_auth_flutter.dart';

import 'sub_router.dart';
import '../list_top_bar.dart';
import '../../store.dart';
import '../../models.dart';
import '../../api/sync.dart';

class RouteConfiguration extends StatefulWidget {
  static final router = SubRouter(
    'settings',
    Icons.settings,
    () => RouteConfiguration(),
  );

  @override
  _RouteConfigurationState createState() => _RouteConfigurationState();
}

class _RouteConfigurationState extends State<RouteConfiguration> {
  static bool _isBlocked(final Filter filter) =>
      globals.blacklistSet.contains(filter.link);

  @override
  initState() {
    super.initState();
    SimpleAuthFlutter.init(context);
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TopBarFrame(),
          Expanded(
            child: ListView(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.fromLTRB(18.0, 0.0, 0.0, 4.0),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.orange)),
                  ),
                  child: const Text('黑名單', style: TextStyle(fontSize: 24.0)),
                ),
                Container(
                  padding: const EdgeInsets.all(15.0),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.brown, width: 2.0)),
                  ),
                  child: Column(
                    //crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: globals.metaData.comicFilterGroupList
                        .map(
                          (grp) => Wrap(
                                spacing: 8.0,
                                runSpacing: -10.0,
                                children: grp.filters
                                    .map((filter) => _BlacklistButton(
                                          filter,
                                          blocked: _isBlocked(filter),
                                          onPressed: () {
                                            setState(() {
                                              if (_isBlocked(filter)) {
                                                globals.blacklistSet
                                                    .remove(filter.link);
                                              } else {
                                                globals.blacklistSet
                                                    .add(filter.link);
                                              }
                                              globals.save();
                                            });
                                          },
                                        ))
                                    .toList(),
                              ),
                        )
                        .toList(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(18.0, 4.0, 0.0, 4.0),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.orange)),
                  ),
                  child: const Text('其他', style: TextStyle(fontSize: 24.0)),
                ),
                Container(
                  padding: const EdgeInsets.all(5.0),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.brown, width: 2.0)),
                  ),
                  child: Wrap(
                    children: [
                      RaisedButton(
                        color: Colors.lightBlue[800],
                        child: const Text('暫存',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                            )),
                        onPressed: () async {
                          var cleanning = false;
                          await showDialog<void>(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => SimpleDialog(
                                  title: const Text('清除暫存'),
                                  children: [
                                    cleanning
                                        ? const Text('清除中...')
                                        : RaisedButton(
                                            onPressed: () async {
                                              setState(() {
                                                cleanning = true;
                                              });
                                              await globals.cleanCacheManager();
                                              setState(() {
                                                cleanning = false;
                                              });
                                            },
                                            child: const Text('清理'),
                                          ),
                                    RaisedButton(
                                      onPressed: cleanning
                                          ? null
                                          : () {
                                              Navigator.pop(context);
                                            },
                                      child: const Text('關閉'),
                                    ),
                                  ],
                                ),
                          );
                        },
                      ),
                      Container(width: 10.0),
                      RaisedButton(
                        color: Colors.lightBlue[800],
                        child: const Text('同步...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                            )),
                        onPressed: () {
                          GoogleDriverSyncManager().syncData();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      );
}

class _BlacklistButton extends StatelessWidget {
  _BlacklistButton(
    this.filter, {
    @required this.blocked,
    @required this.onPressed,
  });

  final Filter filter;
  final bool blocked;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => RawMaterialButton(
        constraints: const BoxConstraints(minWidth: 45.0),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: blocked ? Colors.red[900] : Colors.green,
            width: 2.0,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(9.0)),
        ),
        fillColor: blocked ? Colors.red : Colors.white,
        padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 4.0),
        child: Text(filter.title,
            style: TextStyle(
              fontSize: 14.0,
              color: blocked ? Colors.black : Colors.green[900],
            )),
        onPressed: onPressed,
      );
}
