import 'package:appgiaohang/config/config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeService {
  StripeService._();
  static final StripeService instance = StripeService._();

  Future<bool> makePayment(int amount) async {
    try {
      String? paymentIntentClientSecret =
          await _createPaymentIntent(amount, "vnd");
      if (paymentIntentClientSecret == null) return false;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: "Food Delivery",
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      print('Payment sheet presented');
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<String?> _createPaymentIntent(int amount, String currency) async {
    try {
      final Dio dio = Dio();
      Map<String, dynamic> data = {
        "amount": amount.toString(),
        "currency": currency,
      };
      var response = await dio.post(
        "https://api.stripe.com/v1/payment_intents",
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            "Authorization":
                "Bearer ${Config.stripeSecretshableKey}",
            "Content-Type": 'application/x-www-form-urlencoded'
          },
        ),
      );
      return response.data["client_secret"];
    } catch (e) {
      print(e);
      return null;
    }
  }
}
