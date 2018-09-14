import 'dart:async';
import 'package:flutter/material.dart';

import './side_bar.dart';
import '../progressing.dart';
import '../filter_dialog.dart';
import '../comic_list_top_bar.dart';
import '../comic_cover_row.dart';
import '../../store.dart';
import '../../models.dart';
import '../../routes.dart';

typedef ComicFilterSelected = void Function(String filter, String order);

class ComicList extends StatefulWidget {
  ComicList(this.router) :
    this.filterSelector = globals.metaData.createComicSelector(
      order: pathOrderMap[router.path],
      blacklist: globals.blacklistSet
    );

  final SubRouter router;
  final FilterSelector filterSelector;

  static const Map<String, String> pathOrderMap = {
    'comic_category': 'index',
    'comic_rank':     'view',
    'comic_update':   'update',
  };

  @override
  _ComicListState createState() => _ComicListState(router.label, filterSelector);
}

class _ComicListState extends State<ComicList> {
  _ComicListState(this.title, this.filterSelector);

  final String title;
  final FilterSelector filterSelector;
  bool _pinned = false, _blacklistEnabled = true, _fetching = false, _indicator = false;
  List<ComicCover> comics = [];
  Set<int> bookIds = Set();
  ScrollController _scroller = ScrollController();

  Future<void> _showFilterDialog({ bool forceRefresh = false }) async {
    final filters = Map<String, String>.from(filterSelector.filters);

    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SimpleDialog(
        title: DialogTopBar(
          title, _pinned,
          onPinChanged: (bool pinned) {
            _pinned = pinned;
          },
        ),
        children: [
          DialogBody(
            filterSelector.meta.filterGroups,
            filters,
            onSelectedFilter: () {
              if (_pinned) return;
              Navigator.pop(context, null);
            },
            blacklist: filterSelector.blacklist,
          ),
        ],
      ),
    );

    final oldFilterPath = filterSelector.filterPath;
    filters.forEach((group, link) {
      filterSelector.selectFilter(link: link, group: group);
    });
    if (oldFilterPath == filterSelector.filterPath && !forceRefresh) return;

    _refresh();
  }

  Future<void> _refresh({ bool indicator = true }) async {
    if (_fetching || !mounted) return;
    setState(() {
      _indicator = indicator;
      filterSelector.page = 1;
      comics.clear();
      bookIds.clear();
      _fetching = true;
    });
    await _fetchNextPage();
  }

  void _nextPage() async {
    if (_fetching || !mounted) return;
    setState(() {
      _fetching = true;
    });
    _fetchNextPage();
  }

  void _scrollToTop() {
    _scroller.animateTo(
      0.1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
    );
  }

  bool _notInBlacklist(ComicCover cover) =>
    cover.tagSet == null || filterSelector.blacklist.intersection(cover.tagSet).isEmpty;

  Future<void> _fetchNextPage() async {
    final doc = await filterSelector.fetchDom();

    if (!mounted) return;
    filterSelector.page += filterSelector.page;
    final covers = ComicCover.parseDesktop(doc)
      .where((c) => !bookIds.contains(c.bookId)).toList();
    await globals.db?.updateCovers(covers);

    if (!mounted) return;
    setState(() {
      _fetching = false;
      comics.addAll(covers);
      bookIds.addAll(covers.map((c) => c.bookId));
    });
  }

  Widget _buildCoverList() {
    final covers = _blacklistEnabled ? comics.where(_notInBlacklist).toList() : comics;
    final count = covers.length;
    return ListView.builder(
      controller: _scroller,
      itemCount: count + 1,
      padding: const EdgeInsets.all(0.0),
      itemBuilder: (_, i) => i == count ?
        Progressing(visible: _indicator && _fetching) :
        ((cover) =>
          ComicCoverRow(
            cover,
            onComicPressed: () {
              Routes.navigateComic(context, cover);
            },
            onAuthorPressed: (authorLink) {
              Routes.navigateAuthor(context, authorLink);
            },
          )
        )(covers[i]),
    );
  }

  void _quickSelectFilter(Duration _) async {
    await _showFilterDialog(forceRefresh: true);
    _pinned = true;
  }

  void _switchBlacklist() {
    setState(() {
      _blacklistEnabled = !_blacklistEnabled;
    });
  }

  static const _NEXT_THRESH_HOLD = 2500.0; // > 10 items

  @override
  void initState() {
    super.initState();
    _scroller.addListener(() {
      if (_scroller.position.pixels + _NEXT_THRESH_HOLD > _scroller.position.maxScrollExtent) {
        _nextPage();
      }
    });
    filterSelector.filters.clear();
    WidgetsBinding.instance.addPostFrameCallback(_quickSelectFilter);
  }

  @override
  void dispose() {
    _scroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      ComicListTopBar(
        enabledBlacklist: _blacklistEnabled,
        filtersTitle: filterSelector.meta.filterGroups
          .map((grp) => filterSelector.filters[grp.key])
          .where((s) => s != null)
          .map((link) => filterSelector.meta.linkTitleMap[link])
          .join(', '),
        onPressedScrollTop: _scrollToTop,
        onPressedFilters: _showFilterDialog,
        onPressedBlacklist: _switchBlacklist,
        onPressedRefresh: _refresh,
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: () => _refresh(indicator: false),
          child: _buildCoverList(),
        ),
      ),
    ],
  );
}
