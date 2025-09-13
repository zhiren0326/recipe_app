import 'package:flutter/material.dart';

class RecipeBundle {
  final int id;
  final int chefs;
  final int recipes;
  final String title;
  final String description;

  final Color color;

  RecipeBundle({
    required this.id,
    required this.chefs,
    required this.recipes,
    required this.title,
    required this.description,

    required this.color,
  });
}

// Demo list
List<RecipeBundle> recipeBundles = [
  RecipeBundle(
    id: 1,
    chefs: 16,
    recipes: 95,
    title: "Cook Something New Everyday",
    description: "New and tasty recipes every time",
    color: const Color(0xFFD82D40),
  ),
  RecipeBundle(
    id: 2,
    chefs: 8,
    recipes: 26,
    title: "Best of 2025",
    description: "Cook recipes for special occasions",

    color: const Color(0xFF90AF17),
  ),
  RecipeBundle(
    id: 3,
    chefs: 10,
    recipes: 43,
    title: "Food Court",
    description: "What your favorite food dish make now",

    color: const Color(0xFF2DBBD8),
  ),
];