class BillingDetails {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String country;
  final String postalCode;
  final String state;

  BillingDetails({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.address = "NA",
    required this.city,
    this.country = "EG",
    this.postalCode = "NA",
    required this.state,
  });

  /// Converts the object to a JSON map compatible with the Paymob API.
  Map<String, dynamic> toJson() {
    return {
      "first_name": firstName,
      "last_name": lastName,
      "email": email,
      "phone_number": phone,
      "street": address,
      "city": city,
      "country": country,
      "postal_code": postalCode,
      "state": state,
      // These are often marked as "NA" if not applicable for digital goods
      "apartment": "NA",
      "floor": "NA",
      "building": "NA",
    };
  }
}