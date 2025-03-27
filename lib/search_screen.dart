import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:laza/extensions/context_extension.dart';
import 'package:laza/components/colors.dart';
import 'package:laza/components/laza_icons.dart';

class SearchScreen extends StatefulWidget {
  final String searchQuery;

  const SearchScreen({
    super.key,
    required this.searchQuery,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _searchController;
  late String _currentQuery;

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.searchQuery;
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: SearchAppBar(
        searchController: _searchController,
        initialQuery: widget.searchQuery,
        onSearch: (query) {
          setState(() {
            _currentQuery = query;
          });
          // Add your search logic here
        },
      ),
      body: SafeArea(
        child: _currentQuery.isEmpty
            ? Center(
                child: Text(
                  'Search through the store',
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.7),
                    fontSize: 20,
                  ),
                ),
              )
            : _buildSearchResults(),
      ),
    );
  }

  Widget _buildSearchResults() {
    // Implement your search results list here
    return ListView(
      children: [
        // Your search results items would go here
        // Example:
        ListTile(
          title: Text("Results for '$_currentQuery'"),
        ),
      ],
    );
  }
}

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final String initialQuery;
  final Function(String) onSearch;

  const SearchAppBar({
    super.key,
    required this.searchController,
    required this.initialQuery,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    const inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      borderSide: BorderSide(width: 0, color: Colors.transparent),
    );

    final hintColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : ColorConstant.manatee;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).appBarTheme.systemOverlayStyle!,
      child: Container(
        alignment: Alignment.bottomLeft,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
          child: Row(
            children: [
              // Back Button
              Hero(
                tag: 'search_back',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                    onTap: () => Navigator.pop(context),
                    child: Ink(
                      width: 45,
                      height: 45,
                      decoration: ShapeDecoration(
                        color: Theme.of(context).cardColor,
                        shape: const CircleBorder(),
                      ),
                      child: Icon(
                        Icons.arrow_back_outlined,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),

              // Search TextField
              Expanded(
                child: Hero(
                  tag: 'search',
                  child: Material(
                    color: Colors.transparent,
                    child: TextField(
                      controller: searchController,
                      autofocus: initialQuery.isEmpty,
                      onSubmitted: onSearch,
                      decoration: InputDecoration(
                        filled: true,
                        hintText: 'Search ...',
                        contentPadding: EdgeInsets.zero,
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: inputBorder,
                        hintStyle: TextStyle(color: hintColor),
                        fillColor: Theme.of(context).cardColor,
                        prefixIcon: Icon(
                          LazaIcons.search,
                          color: hintColor,
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),

              // Voice Button
              Hero(
                tag: 'voice',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                    onTap: () {
                      // Implement voice search here
                    },
                    child: Ink(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: ColorConstant.primary,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(50.0)),
                      ),
                      child: const Icon(
                        LazaIcons.voice,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
