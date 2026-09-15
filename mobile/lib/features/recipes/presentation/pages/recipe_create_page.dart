import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/premium/premium_limit_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/image_upload_picker.dart';
import '../../../categories/data/categories_repository.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/widgets/category_drilldown_picker.dart';
import '../../../categories/presentation/widgets/category_path.dart';
import '../../data/recipe_image_search_repository.dart';
import '../../data/recipes_repository.dart';
import '../../domain/recipe.dart';
import '../widgets/servings_stepper.dart';

/// Nombre minimal de caractères saisis avant de lancer une recherche d'image
/// (évite une requête sur "T", "Ta", etc.).
const int _kMinQueryLength = 3;

/// Écran de création (maquette 1d) : flow minimal — photo (optionnelle),
/// nom (obligatoire), toggle « recette de base » décidé dès la création.
/// Renvoie la [RecipeSummary] créée pour rediriger vers sa fiche.
class RecipeCreatePage extends StatefulWidget {
  const RecipeCreatePage({super.key});

  static Route<RecipeSummary> route() {
    return MaterialPageRoute<RecipeSummary>(builder: (_) => const RecipeCreatePage());
  }

  @override
  State<RecipeCreatePage> createState() => _RecipeCreatePageState();
}

class _RecipeCreatePageState extends State<RecipeCreatePage> {
  final _nameController = TextEditingController();
  final _repository = sl<RecipesRepository>();
  final _imageSearch = sl<RecipeImageSearchRepository>();
  final Future<List<Category>> _categoriesFuture =
      sl<CategoriesRepository>().fetchMine();
  String? _photoUrl;
  String? _photoAuthorName;
  String? _photoAuthorUrl;
  bool _isBase = false;
  int _servings = kDefaultServings;
  Set<String> _categoryIds = {};
  bool _showNameError = false;
  bool _submitting = false;

  Timer? _searchDebounce;
  List<ImageSuggestion> _suggestions = [];
  bool _searchingImages = false;

  Future<void> _pickFolders() async {
    final result = await showCategoryDrilldownPicker(
      context,
      initiallySelected: _categoryIds,
    );
    if (result != null) setState(() => _categoryIds = result);
  }

  /// Débounce la recherche de suggestions d'image sur le nom saisi (#4) —
  /// jamais lancée si une photo a déjà été choisie manuellement.
  void _onNameChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();
    if (query.length < _kMinQueryLength) {
      setState(() => _suggestions = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (_photoUrl != null || !mounted) return;
      setState(() => _searchingImages = true);
      final results = await _imageSearch.search(query);
      if (!mounted) return;
      setState(() {
        _searchingImages = false;
        _suggestions = results;
      });
    });
  }

  /// Choisit une suggestion : hotlink direct (jamais uploadée/réhébergée) +
  /// attribution photographe conservée pour affichage sur la fiche. Déclenche
  /// aussitôt le comptage officiel de téléchargement (condition d'accès
  /// production de l'API Unsplash) — best-effort, jamais bloquant.
  void _pickSuggestion(ImageSuggestion suggestion) {
    setState(() {
      _photoUrl = suggestion.fullUrl;
      _photoAuthorName = suggestion.authorName;
      _photoAuthorUrl = suggestion.authorUrl;
      _suggestions = [];
    });
    unawaited(_imageSearch.trackDownload(suggestion.downloadLocation));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _showNameError = true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final created = await _repository.create(
        name: name,
        photoUrl: _photoUrl,
        photoAuthorName: _photoAuthorName,
        photoAuthorUrl: _photoAuthorUrl,
        isBase: _isBase,
        servings: _servings,
        categoryIds: _categoryIds.toList(),
      );
      if (mounted) Navigator.of(context).pop(created);
    } on RecipesRepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      // Limite freemium (5 recettes de base max) : feuille d'upsell au lieu
      // du message d'erreur brut.
      final premiumLimit = e.premiumLimit;
      if (premiumLimit != null) {
        showPremiumLimitSheet(context, error: premiumLimit);
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(l10n.recipeCreateTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
        children: [
          ImageUploadPicker(
            // Nouvelle instance quand `_photoUrl` change de source externe
            // (suggestion choisie) : le widget ne relit `initialUrl` qu'à
            // sa création.
            key: ValueKey(_photoUrl),
            folder: 'recipes',
            shape: ImageUploadShape.card,
            size: 172,
            borderRadius: 22,
            cropAspect: ImageCropAspect.ratio4x3,
            initialUrl: _photoUrl,
            onUploaded: (url) => setState(() {
              _photoUrl = url;
              // Photo personnelle envoyée manuellement : jamais d'attribution
              // Unsplash conservée dessus.
              _photoAuthorName = null;
              _photoAuthorUrl = null;
              _suggestions = [];
            }),
            placeholder: _PhotoPicker(l10n: l10n),
          ),
          if (_photoUrl == null && (_searchingImages || _suggestions.isNotEmpty)) ...[
            const SizedBox(height: 14),
            _ImageSuggestions(
              l10n: l10n,
              query: _nameController.text.trim(),
              loading: _searchingImages,
              suggestions: _suggestions,
              onPick: _pickSuggestion,
            ),
          ],
          const SizedBox(height: 22),
          _FieldLabel(label: l10n.recipeFieldName, required: true),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              if (_showNameError) setState(() => _showNameError = false);
              _onNameChanged(value);
            },
            decoration: InputDecoration(
              hintText: l10n.recipeNameHint,
              errorText: _showNameError ? l10n.recipeNameRequired : null,
              filled: true,
              fillColor: AppColors.card,
              enabledBorder: _border(AppColors.border),
              focusedBorder: _border(AppColors.primary),
              errorBorder: _border(AppColors.danger),
              focusedErrorBorder: _border(AppColors.danger),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.recipeNameHelper,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 22),
          _FieldLabel(label: l10n.recipeFieldServings, required: true),
          const SizedBox(height: 8),
          ServingsStepper(
            value: _servings,
            onChanged: (v) => setState(() => _servings = v),
          ),
          const SizedBox(height: 22),
          _FieldLabel(label: l10n.recipeFieldFolders),
          const SizedBox(height: 8),
          _FoldersField(
            categoriesFuture: _categoriesFuture,
            selectedIds: _categoryIds,
            onTap: _pickFolders,
          ),
          const SizedBox(height: 22),
          _BaseToggleCard(
            value: _isBase,
            onChanged: (v) => setState(() => _isBase = v),
            l10n: l10n,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(22, 8, 22, 20),
        child: SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.recipeCreateAction,
                        style: const TextStyle(
                            fontSize: 16.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 9),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: color, width: 1.5),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // Placeholder visuel (maquette 1d) affiché tant qu'aucune photo n'est
    // choisie ; le tap/upload est géré par ImageUploadPicker qui l'enveloppe.
    return Container(
      height: 172,
      decoration: BoxDecoration(
        color: AppColors.pill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD8D4C8),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.photo_camera_outlined,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.recipePhotoTitle,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.recipePhotoHint,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _BaseToggleCard extends StatelessWidget {
  const _BaseToggleCard({
    required this.value,
    required this.onChanged,
    required this.l10n,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.link_rounded,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.recipeBaseToggleTitle,
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w700,
                          fontSize: 16.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        l10n.recipeBaseToggleSubtitle,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: AppColors.primary,
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: const Color(0xFFF7FAF5),
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.recipeBaseToggleHint,
                    style: const TextStyle(
                        fontSize: 13, height: 1.5, color: Color(0xFF5A6B4E)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Suggestions d'image (#4) basées sur le nom saisi : aucun upload, seule
/// l'URL Unsplash choisie est envoyée à la création.
class _ImageSuggestions extends StatelessWidget {
  const _ImageSuggestions({
    required this.l10n,
    required this.query,
    required this.loading,
    required this.suggestions,
    required this.onPick,
  });

  final AppLocalizations l10n;
  final String query;
  final bool loading;
  final List<ImageSuggestion> suggestions;
  final ValueChanged<ImageSuggestion> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recipeImageSuggestionsLabel(query),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Color(0xFFA79F8B),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 84,
          child: loading
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final suggestion = suggestions[i];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onPick(suggestion),
                        borderRadius: BorderRadius.circular(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            suggestion.thumbUrl,
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox(width: 84),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l10n.recipeImageSuggestionsAttribution,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}

/// Champ « Dossiers » : bouton ouvrant le sélecteur en drill-down (#2), avec
/// les dossiers déjà choisis affichés en puces (chemin complet).
class _FoldersField extends StatelessWidget {
  const _FoldersField({
    required this.categoriesFuture,
    required this.selectedIds,
    required this.onTap,
  });

  final Future<List<Category>> categoriesFuture;
  final Set<String> selectedIds;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          child: selectedIds.isEmpty
              ? Row(
                  children: [
                    const Icon(Icons.folder_open_rounded,
                        size: 20, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.recipeFoldersFieldEmpty,
                        style: const TextStyle(
                            fontSize: 14.5, color: AppColors.textMuted),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        size: 20, color: AppColors.textMuted),
                  ],
                )
              : FutureBuilder<List<Category>>(
                  future: categoriesFuture,
                  builder: (context, snapshot) {
                    final all = snapshot.data ?? const <Category>[];
                    final byId = {for (final c in all) c.id: c};
                    final selected = selectedIds
                        .map((id) => byId[id])
                        .whereType<Category>()
                        .toList();
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final folder in selected)
                          Chip(
                            avatar: const Icon(Icons.folder_outlined,
                                size: 16, color: AppColors.primary),
                            label: Text(categoryPath(folder, all)),
                            backgroundColor: AppColors.primaryTint,
                            side: BorderSide.none,
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        if (required)
          const Text(' *', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
