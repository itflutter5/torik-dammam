String? validatePostFields({
  required String? category,
  required String title,
  required String description,
  required String price,
  required String? unit,
  required String storeNumber,
  required int photoCount,
}) {
  if (category == null || category.trim().isEmpty) return 'Select a category';
  if (photoCount < 1) return 'Add at least one photo';
  if (title.trim().length < 3 || title.trim().length > 150) {
    return 'Enter a title with 3 to 150 characters';
  }
  if (description.trim().length < 10 || description.trim().length > 5000) {
    return 'Enter a description with 10 to 5000 characters';
  }
  final amount = double.tryParse(price.trim());
  if (amount == null || !amount.isFinite || amount < 0 || amount > 9999999999) {
    return 'Enter a valid price or salary';
  }
  final usesSalary = category == 'Need Worker' || category == 'Need Job';
  if (!usesSalary && !['Ton', 'kg', 'pics'].contains(unit)) return 'Select a unit';
  if (!RegExp(r'^\d{1,4}$').hasMatch(storeNumber)) {
    return 'Store number must contain 1 to 4 digits';
  }
  return null;
}
