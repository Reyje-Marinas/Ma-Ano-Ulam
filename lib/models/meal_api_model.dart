class MealApiModel {
  final String id;
  final String name;
  final String imageUrl;
  final String? category;
  final String? area;
  final String? instructions;
  final String? youtubeUrl;
  final List<MealIngredient> ingredients;

  MealApiModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.category,
    this.area,
    this.instructions,
    this.youtubeUrl,
    this.ingredients = const [],
  });

  factory MealApiModel.fromJson(Map<String, dynamic> json) {
    return MealApiModel(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? '',
      imageUrl: json['strMealThumb'] ?? '',
      category: json['strCategory'],
      area: json['strArea'],
      instructions: json['strInstructions'],
      youtubeUrl: json['strYoutube'],
      ingredients: _extractIngredients(json),
    );
  }

  static List<MealIngredient> _extractIngredients(Map<String, dynamic> json) {
    final ingredients = <MealIngredient>[];

    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];
      final measure = json['strMeasure$i'];

      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients.add(
          MealIngredient(
            name: ingredient.toString().trim(),
            measure: measure?.toString().trim() ?? '',
          ),
        );
      }
    }

    return ingredients;
  }
}

class MealIngredient {
  final String name;
  final String measure;

  MealIngredient({
    required this.name,
    required this.measure,
  });
}