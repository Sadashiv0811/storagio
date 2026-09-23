class AppValidators {
  AppValidators._(); // Private constructor (prevents instantiation)

  // ---------------- EMAIL ----------------
  // Valid
  // test@example.com, user.name@domain.com
  // Invalid
  // plainaddress, user@domain. , user@@domain.com
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }

    return null;
  }

  // ---------------- PASSWORD ----------------
  // Valid
  // Strong@123, Hello_2024, Pass#Word9
  // Invalid
  // password123, PASSWORD123, Passwrd
  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    final password = value.trim();

    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }

    // At least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Include at least one lowercase letter';
    }

    // At least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Include at least one uppercase letter';
    }

    // At least one number
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Include at least one number';
    }

    // At least one allowed special character
    if (!RegExp(r'[_+\?#@\-]').hasMatch(password)) {
      return 'Include at least one symbol (_ + ? # @ -)';
    }

    return null;
  }

  // ---------------- FULL NAME ----------------
  // Valid
  // John Doe, Alice, Rahul Sharma
  // Invalid
  // Jo, John123, John_Doe
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }

    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }

    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value.trim())) {
      return 'Only letters and spaces allowed';
    }

    return null;
  }

  // ---------------- ROOM, ITEM, LOCATION NAME ----------------
  // Allows alphabets, space, numbers
  static String? otherNames(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (value.trim().length < 3) {
      return '$fieldName must be at least 3 characters';
    }

    if (!RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(value.trim())) {
      return 'Only letters, numbers and spaces allowed';
    }

    return null;
  }

  // ---------------- MESSAGE ----------------
  static String? message(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Message is required';
    }

    if (value.trim().length < 20) {
      return 'Message must be at least 20 characters';
    }

    if (value.trim().length > 1000) {
      return 'Message cannot exceed 1000 characters';
    }

    return null;
  }

  // ---------------- QUANTITY ----------------
  static String? quantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter current quantity";
    }

    final quantity = double.tryParse(value);

    if (quantity == null) {
      return "Enter a valid number";
    }

    if (quantity < 0) {
      return "Current quantity cannot be negative";
    }

    return null;
  }
}
