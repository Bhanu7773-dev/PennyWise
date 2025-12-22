import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';
import '../models/category.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final Set<String> _expandedCategories = {};
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    var topLevelCategories = provider.topLevelCategories;

    if (_searchQuery.isNotEmpty) {
      topLevelCategories = topLevelCategories.where((cat) {
        return cat.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search categories...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text(
                'Manage Categories',
                style: TextStyle(color: Colors.white),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F111A),
              const Color(0xFF1A1F38),
              const Color(0xFF0F111A),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: topLevelCategories.length,
                onReorder: (oldIndex, newIndex) {
                  provider.reorderCategories(oldIndex, newIndex);
                },
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      final double elevation = Tween<double>(begin: 0, end: 6)
                          .animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOut,
                            ),
                          )
                          .value;
                      return Material(
                        elevation: elevation,
                        color: Colors.transparent,
                        shadowColor: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                        child: child,
                      );
                    },
                    child: child,
                  );
                },
                itemBuilder: (context, index) {
                  final category = topLevelCategories[index];
                  final isExpanded = _expandedCategories.contains(category.id);
                  final subcategories = provider.getSubcategories(category.id);
                  final hasSubcategories = subcategories.isNotEmpty;

                  return Column(
                    key: Key(category.id),
                    children: [
                      // Parent Category
                      _buildCategoryTile(
                        category: category,
                        provider: provider,
                        index: index,
                        isExpanded: isExpanded,
                        hasSubcategories: hasSubcategories,
                        onExpand: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedCategories.remove(category.id);
                            } else {
                              _expandedCategories.add(category.id);
                            }
                          });
                        },
                        onAddSubcategory: () => _showAddSubcategoryDialog(
                          context,
                          provider,
                          category,
                        ),
                      ),

                      // Subcategories (when expanded)
                      if (isExpanded && hasSubcategories)
                        ...subcategories.asMap().entries.map((entry) {
                          final subIndex = entry.key;
                          final subcategory = entry.value;
                          return _buildSubcategoryTile(
                            subcategory: subcategory,
                            provider: provider,
                            parentColor: category.color,
                            isLast: subIndex == subcategories.length - 1,
                          );
                        }),

                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            ),

            // Add New Category Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showAddCategoryDialog(context, provider),
                  icon: const Icon(Icons.add, color: AppTheme.primary),
                  label: const Text(
                    'Add New Category',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile({
    required Category category,
    required MoneyProvider provider,
    required int index,
    required bool isExpanded,
    required bool hasSubcategories,
    required VoidCallback onExpand,
    required VoidCallback onAddSubcategory,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExpanded
            ? category.color.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? category.color.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(category.icon, color: category.color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasSubcategories)
                  Text(
                    '${provider.getSubcategories(category.id).length} subcategories',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          // Add subcategory button
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: category.color.withValues(alpha: 0.7),
            ),
            onPressed: onAddSubcategory,
            tooltip: 'Add subcategory',
          ),
          // Expand/collapse button
          GestureDetector(
            onTap: hasSubcategories ? onExpand : onAddSubcategory,
            child: AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                hasSubcategories
                    ? Icons.keyboard_arrow_down
                    : Icons.chevron_right,
                color: hasSubcategories
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
          if (category.isCustom)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () => _confirmDelete(context, provider, category),
            ),
          ReorderableDragStartListener(
            index: index,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.drag_handle,
                color: Colors.white.withValues(alpha: 0.5),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryTile({
    required Category subcategory,
    required MoneyProvider provider,
    required Color parentColor,
    required bool isLast,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 24, top: 8),
      child: Row(
        children: [
          // Connector line
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 28,
                  color: parentColor.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: subcategory.color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      subcategory.icon,
                      color: subcategory.color,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      subcategory.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                    onPressed: () =>
                        _confirmDelete(context, provider, subcategory),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.1, end: 0),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    MoneyProvider provider,
    Category category,
  ) {
    final isParent = category.hasSubcategories;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Delete Category?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          isParent
              ? 'Are you sure you want to delete "${category.name}" and all its subcategories?'
              : 'Are you sure you want to delete "${category.name}"?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteCategory(category.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, MoneyProvider provider) {
    _showCategoryDialog(
      context: context,
      title: 'New Category',
      onSave: (name, icon, color) {
        provider.addCategory(name, icon, color);
      },
    );
  }

  void _showAddSubcategoryDialog(
    BuildContext context,
    MoneyProvider provider,
    Category parentCategory,
  ) {
    _showCategoryDialog(
      context: context,
      title: 'New Subcategory',
      subtitle: 'Under ${parentCategory.name}',
      defaultColor: parentCategory.color,
      onSave: (name, icon, color) {
        provider.addSubcategory(parentCategory.id, name, icon, color);
        // Auto-expand parent after adding subcategory
        setState(() {
          _expandedCategories.add(parentCategory.id);
        });
      },
    );
  }

  void _showCategoryDialog({
    required BuildContext context,
    required String title,
    String? subtitle,
    Color? defaultColor,
    required Function(String name, IconData icon, Color color) onSave,
  }) {
    final nameController = TextEditingController();
    IconData selectedIcon = Icons.category;
    Color selectedColor = defaultColor ?? Colors.blue;

    final availableIcons = [
      Icons.shopping_bag,
      Icons.restaurant,
      Icons.directions_car,
      Icons.flight,
      Icons.movie,
      Icons.sports_esports,
      Icons.fitness_center,
      Icons.medical_services,
      Icons.school,
      Icons.work,
      Icons.home,
      Icons.pets,
      Icons.local_cafe,
      Icons.local_bar,
      Icons.local_pizza,
      Icons.phone_android,
      Icons.book,
      Icons.laptop,
      Icons.headphones,
      Icons.music_note,
      Icons.brush,
      Icons.camera_alt,
      Icons.card_giftcard,
      Icons.child_care,
      Icons.cleaning_services,
      Icons.cloud,
      Icons.coffee,
      Icons.construction,
      Icons.credit_card,
      Icons.directions_bike,
      Icons.eco,
      Icons.electric_bolt,
      Icons.emoji_events,
      Icons.fastfood,
      Icons.favorite,
      Icons.forest,
      Icons.games,
      Icons.grass,
      Icons.handyman,
      Icons.ice_skating,
      Icons.iron,
      Icons.kitchen,
      Icons.light,
      Icons.liquor,
      Icons.local_gas_station,
      Icons.local_grocery_store,
      Icons.local_hospital,
      Icons.local_laundry_service,
      Icons.local_library,
      Icons.local_mall,
      Icons.local_movies,
      Icons.local_parking,
      Icons.local_pharmacy,
      Icons.local_shipping,
      Icons.local_taxi,
      Icons.luggage,
      Icons.lunch_dining,
      Icons.mail,
      Icons.man,
      Icons.menu_book,
      Icons.money,
      Icons.monitor,
      Icons.mosque,
      Icons.nightlife,
      Icons.outdoor_grill,
      Icons.palette,
      Icons.park,
      Icons.payments,
      Icons.pedal_bike,
      Icons.person,
      Icons.piano,
      Icons.pool,
      Icons.power,
      Icons.print,
      Icons.router,
      Icons.savings,
      Icons.self_improvement,
      Icons.sell,
      Icons.shower,
      Icons.smoke_free,
      Icons.snowboarding,
      Icons.spa,
      Icons.sports,
      Icons.sports_bar,
      Icons.sports_basketball,
      Icons.sports_football,
      Icons.sports_soccer,
      Icons.sports_tennis,
      Icons.store,
      Icons.subscriptions,
      Icons.surfing,
      Icons.theater_comedy,
      Icons.train,
      Icons.vaccines,
      Icons.videogame_asset,
      Icons.water_drop,
      Icons.wifi,
      Icons.woman,
      Icons.yard,
    ];

    final availableColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
      Colors.lime,
      Colors.deepOrange,
      Colors.lightBlue,
      Colors.deepPurple,
      Colors.brown,
      Colors.blueGrey,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white)),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      labelStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Select Icon',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: availableIcons.length,
                      itemBuilder: (context, index) {
                        final icon = availableIcons[index];
                        final isSelected = selectedIcon == icon;
                        return GestureDetector(
                          onTap: () => setState(() => selectedIcon = icon),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? selectedColor
                                  : Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: Colors.white, size: 18),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Select Color',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: availableColors.map((color) {
                      final isSelected = selectedColor.value == color.value;
                      return GestureDetector(
                        onTap: () => setState(() => selectedColor = color),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  onSave(nameController.text, selectedIcon, selectedColor);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
