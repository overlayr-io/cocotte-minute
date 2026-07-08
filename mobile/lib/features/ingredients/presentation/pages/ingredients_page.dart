import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/error_view.dart';
import '../../data/ingredients_repository.dart';
import '../../domain/ingredient.dart';
import '../bloc/ingredients_list_bloc.dart';
import '../widgets/ingredient_form_sheet.dart';
import '../widgets/unit_selector.dart';
import 'ingredient_detail_page.dart';

/// Écran "Mes ingrédients" : onglets mes ingrédients / catalogue système.
class IngredientsPage extends StatelessWidget {
  const IngredientsPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const IngredientsPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          IngredientsListBloc(repository: sl<IngredientsRepository>())
            ..add(const IngredientsRequested()),
      child: const _IngredientsView(),
    );
  }
}

class _IngredientsView extends StatefulWidget {
  const _IngredientsView();

  @override
  State<_IngredientsView> createState() => _IngredientsViewState();
}

class _IngredientsViewState extends State<_IngredientsView> {
  int _tab = 0; // 0 = mes ingrédients, 1 = catalogue
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Ingredient> _filter(List<Ingredient> items) {
    if (_query.isEmpty) return items;
    final q = _query.toLowerCase();
    return items.where((i) => i.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _openDetail(String id) async {
    final result = await Navigator.of(context).push(IngredientDetailPage.route(id));
    if (!mounted) return;
    if (result != null) {
      context.read<IngredientsListBloc>().add(const IngredientsRequested());
    }
  }

  Future<void> _create() async {
    final draft = await showCreateIngredientSheet(context);
    if (!mounted || draft == null) return;
    context.read<IngredientsListBloc>().add(
          IngredientCreated(
            name: draft.name,
            unit: draft.unit,
            imageUrl: draft.imageUrl,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ingredientsTitle)),
      body: BlocConsumer<IngredientsListBloc, IngredientsListState>(
        listenWhen: (_, curr) => curr is IngredientsListActionFailure,
        listener: (context, state) {
          if (state is IngredientsListActionFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          return switch (state) {
            IngredientsListError(:final message) => ErrorView(
                message: message,
                onRetry: () => context
                    .read<IngredientsListBloc>()
                    .add(const IngredientsRequested()),
              ),
            IngredientsListLoaded() => _buildContent(context, state, l10n),
            _ => const Center(child: CircularProgressIndicator()),
          };
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    IngredientsListLoaded state,
    AppLocalizations l10n,
  ) {
    final isMine = _tab == 0;
    final items = _filter(isMine ? state.mine : state.system);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
          child: Column(
            children: [
              _Segmented(
                index: _tab,
                labels: [l10n.ingredientsTabMine, l10n.ingredientsTabCatalog],
                onChanged: (i) => setState(() => _tab = i),
              ),
              const SizedBox(height: 14),
              _SearchField(
                controller: _searchController,
                hint: isMine
                    ? l10n.ingredientsSearchHint
                    : l10n.ingredientsCatalogSearchHint,
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? _EmptyState(
                  message: _query.isNotEmpty
                      ? l10n.ingredientsNoSearchResult
                      : (isMine
                          ? l10n.ingredientsEmptyMine
                          : l10n.ingredientsEmptyCatalog),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                  children: [
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: isMine
                            ? _MineTile(
                                ingredient: item,
                                onTap: () => _openDetail(item.id),
                              )
                            : _SystemTile(
                                ingredient: item,
                                busy: state.busyId == item.id,
                                onImport: () => context
                                    .read<IngredientsListBloc>()
                                    .add(IngredientSystemImported(item.id)),
                              ),
                      ),
                    if (isMine) ...[
                      const SizedBox(height: 2),
                      _DashedButton(
                        label: l10n.ingredientsCreateCta,
                        onTap: _create,
                      ),
                    ] else
                      _ImportInfo(text: l10n.ingredientsImportInfo),
                  ],
                ),
        ),
        if (isMine && items.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: _DashedButton(label: l10n.ingredientsCreateCta, onTap: _create),
          ),
      ],
    );
  }
}

// --- tiles & atoms ---------------------------------------------------------

class _IngredientAvatar extends StatelessWidget {
  const _IngredientAvatar({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(14),
        image: imageUrl != null
            ? DecorationImage(
                image: cachedImageProvider(context, imageUrl!, logicalWidth: 52),
                fit: BoxFit.cover)
            : null,
      ),
      child: imageUrl == null
          ? const Icon(Icons.eco_outlined, color: AppColors.primary)
          : null,
    );
  }
}

class _UnitPill extends StatelessWidget {
  const _UnitPill(this.unit);

  final IngredientUnit unit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        unitLabel(l10n, unit),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _SystemBadge extends StatelessWidget {
  const _SystemBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EAD6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        l10n.ingredientBadgeSystem,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF8A7A4E),
        ),
      ),
    );
  }
}

class _MineTile extends StatelessWidget {
  const _MineTile({required this.ingredient, required this.onTap});

  final Ingredient ingredient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _IngredientAvatar(imageUrl: ingredient.imageUrl),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ingredient.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _UnitPill(ingredient.unit),
                        if (ingredient.isImported) ...[
                          const SizedBox(width: 6),
                          const _SystemBadge(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 22, color: Color(0xFFCBC7BB)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemTile extends StatelessWidget {
  const _SystemTile({
    required this.ingredient,
    required this.busy,
    required this.onImport,
  });

  final Ingredient ingredient;
  final bool busy;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _IngredientAvatar(imageUrl: ingredient.imageUrl),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                _UnitPill(ingredient.unit),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (ingredient.alreadyImported)
            Row(
              children: [
                const Icon(Icons.check_rounded, size: 16, color: Color(0xFF3F7D3A)),
                const SizedBox(width: 4),
                Text(
                  l10n.ingredientsAlreadyImported,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3F7D3A),
                  ),
                ),
              ],
            )
          else
            OutlinedButton(
              onPressed: busy ? null : onImport,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: busy
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.download_rounded, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          l10n.ingredientsImport,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
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

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.index,
    required this.labels,
    required this.onChanged,
  });

  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.pill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: i == index ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: i == index
                        ? [
                            BoxShadow(
                              color: AppColors.textPrimary.withValues(alpha: 0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: i == index
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.card,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _DashedButton extends StatelessWidget {
  const _DashedButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: Color(0xFFC4BEAD), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _ImportInfo extends StatelessWidget {
  const _ImportInfo({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EAD6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF8A7A4E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A7A4E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
      ),
    );
  }
}
