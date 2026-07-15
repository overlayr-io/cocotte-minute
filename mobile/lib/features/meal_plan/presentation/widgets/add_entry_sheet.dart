import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../recipes/data/recipes_repository.dart';
import '../../../recipes/domain/recipe.dart';
import 'meal_entry_visuals.dart';

/// Choix fait dans la sheet « Ajouter au créneau » (écrans 2a/2c).
sealed class AddEntryChoice {
  const AddEntryChoice();
}

class AddRecipeChoice extends AddEntryChoice {
  const AddRecipeChoice(this.recipe);

  final RecipeSummary recipe;
}

class AddEatingOutChoice extends AddEntryChoice {
  const AddEatingOutChoice();
}

class AddNoteChoice extends AddEntryChoice {
  const AddNoteChoice(this.text);

  final String text;
}

/// Sheet de choix pour un créneau : recherche de recette, « Manger dehors »
/// ou note libre. [slotLabel] : « Lundi 6 · Matin ».
Future<AddEntryChoice?> showAddEntrySheet(
  BuildContext context, {
  required String slotLabel,
}) {
  return showModalBottomSheet<AddEntryChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddEntrySheet(slotLabel: slotLabel),
  );
}

class _AddEntrySheet extends StatefulWidget {
  const _AddEntrySheet({required this.slotLabel});

  final String slotLabel;

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _searchController = TextEditingController();
  final _noteController = TextEditingController();

  List<RecipeSummary>? _recipes;
  bool _loadFailed = false;
  bool _noteMode = false;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    try {
      final recipes = await sl<RecipesRepository>().fetchMine();
      if (mounted) setState(() => _recipes = recipes);
    } on Object {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sheet = Container(
      height: _noteMode ? null : MediaQuery.sizeOf(context).height * 0.78,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: _noteMode ? _buildNoteMode(context) : _buildListMode(context),
      ),
    );
    // En mode note, laisse le clavier pousser la sheet.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: sheet,
    );
  }

  Widget _handle() => Center(
    child: Container(
      width: 44,
      height: 5,
      margin: const EdgeInsets.only(top: 12, bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFDAD5C8),
        borderRadius: BorderRadius.circular(999),
      ),
    ),
  );

  Widget _kicker(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
      color: kPlanningKicker,
    ),
  );

  // --- Mode liste (2a) ------------------------------------------------------

  Widget _buildListMode(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = _searchController.text.trim().toLowerCase();
    final recipes = (_recipes ?? const <RecipeSummary>[])
        .where((r) => query.isEmpty || r.name.toLowerCase().contains(query))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _handle(),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _kicker(widget.slotLabel),
                        const SizedBox(height: 3),
                        Text(
                          l10n.planningAddSheetTitle,
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 21,
                            letterSpacing: -0.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _CircleButton(
                    icon: Icons.close,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _OptionButton(
                      tint: kEatingOutTint,
                      iconTint: const Color(0xFFDCE7F1),
                      fg: kEatingOutFg,
                      border: const Color(0xFFD8E2EE),
                      icon: Icons.restaurant,
                      label: l10n.planningEatingOut,
                      labelColor: const Color(0xFF2F4A63),
                      onTap: () =>
                          Navigator.of(context).pop(const AddEatingOutChoice()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _OptionButton(
                      tint: const Color(0xFFF7EFE0),
                      iconTint: const Color(0xFFEFE1C6),
                      fg: kNoteFg,
                      border: const Color(0xFFEBDCBF),
                      icon: Icons.edit_outlined,
                      label: l10n.planningNoteSheetTitle,
                      labelColor: const Color(0xFF8A5A12),
                      onTap: () => setState(() => _noteMode = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE3DECF), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                    const SizedBox(width: 9),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: l10n.planningSearchHint,
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loadFailed
              ? Center(
                  child: Text(
                    l10n.planningNoRecipeFound,
                    style: const TextStyle(color: Color(0xFFA79F8B), fontSize: 13.5),
                  ),
                )
              : _recipes == null
              ? const Center(child: CircularProgressIndicator())
              : recipes.isEmpty
              ? Center(
                  child: Text(
                    l10n.planningNoRecipeFound,
                    style: const TextStyle(color: Color(0xFFA79F8B), fontSize: 13.5),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: recipes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _RecipeRow(recipe: recipes[index]),
                ),
        ),
      ],
    );
  }

  // --- Mode note (2c) -------------------------------------------------------

  Widget _buildNoteMode(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quicks = [
      l10n.planningNoteQuickPasta,
      l10n.planningNoteQuickLeftovers,
      l10n.planningNoteQuickPizza,
      l10n.planningNoteQuickSandwich,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _handle(),
          Row(
            children: [
              _CircleButton(
                icon: Icons.chevron_left,
                onTap: () => setState(() => _noteMode = false),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kicker(widget.slotLabel),
                  const SizedBox(height: 2),
                  Text(
                    l10n.planningNoteSheetTitle,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 21,
                      letterSpacing: -0.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.planningNoteBody,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: Color(0xFF8A8574),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    autofocus: true,
                    maxLength: 160,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: l10n.planningNoteHint,
                      border: InputBorder.none,
                      isDense: true,
                      counterText: '',
                    ),
                    style: const TextStyle(fontSize: 15),
                    onSubmitted: (_) => _submitNote(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final quick in quicks)
                GestureDetector(
                  onTap: () => setState(() => _noteController.text = quick),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE3DECF)),
                    ),
                    child: Text(
                      quick,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5B6470),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _noteController.text.trim().isEmpty ? null : _submitNote,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                l10n.planningNoteCta,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitNote() {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(AddNoteChoice(text));
  }
}

/// Libellé beige des kickers de sheet (maquette).
const kPlanningKicker = Color(0xFF9A927E);

class _RecipeRow extends StatelessWidget {
  const _RecipeRow({required this.recipe});

  final RecipeSummary recipe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = recipe.prepTime + recipe.cookTime + recipe.restTime;
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(AddRecipeChoice(recipe)),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: recipe.photoUrl != null
                  ? AppNetworkImage(recipe.photoUrl!, width: 50, height: 50)
                  : Container(
                      width: 50,
                      height: 50,
                      color: AppColors.primaryTint,
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${l10n.recipeServingsShort(recipe.servings)} · ${l10n.searchMinutesShort(total)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 17, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.tint,
    required this.iconTint,
    required this.fg,
    required this.border,
    required this.icon,
    required this.label,
    required this.labelColor,
    required this.onTap,
  });

  final Color tint;
  final Color iconTint;
  final Color fg;
  final Color border;
  final IconData icon;
  final String label;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconTint,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: fg),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  height: 1.12,
                  color: labelColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF8A8574)),
      ),
    );
  }
}
