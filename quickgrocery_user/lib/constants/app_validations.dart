class AppValidations {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Please enter an email address.';
    }
    RegExp emailRegex = RegExp(
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  static String? validatePassword(String? email) {
    if (email == null) {
      return 'Password is required';
    }
    if (email.length < 8) {
      return 'Atleast 8 characters required';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null) {
      return 'name is required';
    }
    if (value.isEmpty) {
      return 'name is required';
    }

    return null;
  }

  static String? validateMobile(String? value) {
    if (value == null) {
      return 'phone number is required';
    }
    if (value.length < 10) {
      return 'Enter valid mobile number';
    }

    return null;
  }

  static String? validateHouse(String? value) {
    if (value == null) {
      return 'Address is required';
    }
    if (value.isEmpty) {
      return 'Address is required';
    }
    return null;
  }

  static String? validateArea(String? value) {
    if (value == null) {
      return 'Area or road name is required';
    }
    if (value.isEmpty) {
      return 'Area or road name is required';
    }

    return null;
  }
}
