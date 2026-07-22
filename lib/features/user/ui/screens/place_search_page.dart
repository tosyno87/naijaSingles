import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/data/repo/user_location_repo.dart';

/// Full-screen place search using safe HTTP Places Autocomplete.
/// Pops a [PlaceSuggestion] on tap, or null if cancelled.
class PlaceSearchPage extends StatefulWidget {
  const PlaceSearchPage({super.key});

  @override
  State<PlaceSearchPage> createState() => _PlaceSearchPageState();
}

class _PlaceSearchPageState extends State<PlaceSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final UserLocationReporistoryImpl _repo = UserLocationReporistoryImpl();
  Timer? _debounce;
  List<PlaceSuggestion> _results = const <PlaceSuggestion>[];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_search(value));
    });
  }

  Future<void> _search(String input) async {
    final String query = input.trim();
    if (query.length < 2) {
      if (!mounted) return;
      setState(() {
        _results = const <PlaceSuggestion>[];
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final PlaceAutocompleteResult result =
        await _repo.autocompletePlaces(query);
    if (!mounted) return;
    setState(() {
      _results = result.suggestions;
      _loading = false;
      if (result.isDenied) {
        _error =
            'Place search blocked by Google API key restrictions. '
            'Add GOOGLE_MAPS_WEB_API_KEY (Places + Geocoding APIs, '
            'no iOS/Android app restriction), then hot restart.';
      } else if (!result.isOk) {
        _error = (result.errorMessage?.isNotEmpty ?? false)
            ? 'Place search failed (${result.status}): ${result.errorMessage}'
            : 'Place search failed (${result.status}).';
      } else if (result.suggestions.isEmpty) {
        _error = 'No places found. Try a different search.';
      } else {
        _error = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF6E5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Search for a place',
          style: GoogleFonts.montserrat(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'City, neighborhood, or address',
                hintStyle: GoogleFonts.montserrat(color: Colors.black45),
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(color: AppColors.primaryGreen),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(color: AppColors.primaryGreen),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(
                    color: AppColors.primaryGreen,
                    width: 2,
                  ),
                ),
              ),
              style: GoogleFonts.montserrat(fontSize: 16),
            ),
          ),
          if (_loading)
            const LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.primaryGreen,
            ),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error ??
                            'Start typing to search for a city or address.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final PlaceSuggestion item = _results[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.place_outlined,
                          color: AppColors.primaryGreen,
                        ),
                        title: Text(
                          item.description,
                          style: GoogleFonts.montserrat(fontSize: 15),
                        ),
                        onTap: () => Navigator.of(context).pop(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
