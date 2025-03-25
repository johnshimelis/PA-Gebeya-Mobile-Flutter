import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:laza/extensions/context_extension.dart';
import 'package:laza/components/colors.dart';
import 'package:laza/components/laza_icons.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: const SearchAppBar(),
      body: SafeArea(
        child: Center(
          child: Text(
            'Search through the store',
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.7), // Adapts to theme
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SearchAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    const inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      borderSide: BorderSide(width: 0, color: Colors.transparent),
    );

    // Determine the hint and icon color based on the theme
    final hintColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white // White in dark theme
        : ColorConstant.manatee; // Default color in light theme

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          Theme.of(context).appBarTheme.systemOverlayStyle!, // Adapts to theme
      child: Container(
        alignment: Alignment.bottomLeft,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor, // Adapts to theme
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
                        color: Theme.of(context).cardColor, // Adapts to theme
                        shape: const CircleBorder(),
                      ),
                      child: Icon(
                        Icons.arrow_back_outlined,
                        color: Theme.of(context)
                            .iconTheme
                            .color, // Adapts to theme
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
                      controller: TextEditingController(),
                      autofocus: true,
                      decoration: InputDecoration(
                        filled: true,
                        hintText: 'Search ...',
                        contentPadding: EdgeInsets.zero,
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: inputBorder,
                        hintStyle: TextStyle(
                          color: hintColor, // Use the determined hint color
                        ),
                        fillColor:
                            Theme.of(context).cardColor, // Adapts to theme
                        prefixIcon: Icon(
                          LazaIcons.search,
                          color: hintColor, // Use the determined hint color
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color, // Adapts to theme
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
                    onTap: () {},
                    child: Ink(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: ColorConstant
                            .primary, // Primary color remains constant
                        borderRadius:
                            const BorderRadius.all(Radius.circular(50.0)),
                      ),
                      child: const Icon(
                        LazaIcons.voice,
                        color: Colors.white, // White icon for contrast
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
