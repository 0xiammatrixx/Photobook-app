import 'package:flutter/material.dart';
import 'package:mobile_frontend/features/shared/offer_message_payload.dart';
import 'package:mobile_frontend/features/shared/offer_sent_screen.dart';
import 'package:provider/provider.dart';
import 'package:mobile_frontend/providers/chat_provider.dart';
import 'package:mobile_frontend/services/offer_service.dart';

const _orange = Color(0xFFFF7A33);
const _panelBg = Color(0xFFF5F9F6);
const _borderColor = Color(0xFFD8DED9);

/// "Send Custom Offer" screen — creative side.
/// Push with the client's user id + conversation id so the offer can be
/// attached to the right chat and the right recipient.
class SendCustomOfferScreen extends StatefulWidget {
  final String token;
  final String conversationId;
  final String recipientId;
  final String recipientName;

  const SendCustomOfferScreen({
    super.key,
    required this.token,
    required this.conversationId,
    required this.recipientId,
    required this.recipientName,
  });

  @override
  State<SendCustomOfferScreen> createState() => _SendCustomOfferScreenState();
}

class _SendCustomOfferScreenState extends State<SendCustomOfferScreen> {
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
  final _newItemController = TextEditingController();
  final _serviceNameController = TextEditingController(text: 'Custom Package');
  final _locationTextController = TextEditingController();

  final List<String> _whatsIncluded = [];
  String? _validFor; // "24hrs" | "48hrs" | "72hrs" | "1 week" (UI only for now)
  bool _showSessionDetails = false;
  bool _sending = false;

  static const _validForOptions = ['24hrs', '48hrs', '72hrs', '1 week'];

  DateTime? get _computedExpiresAt {
    if (_validFor == null) return null;
    final now = DateTime.now();
    switch (_validFor) {
      case '24hrs':
        return now.add(const Duration(hours: 24));
      case '48hrs':
        return now.add(const Duration(hours: 48));
      case '72hrs':
        return now.add(const Duration(hours: 72));
      case '1 week':
        return now.add(const Duration(days: 7));
    }
    return null;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    _newItemController.dispose();
    _serviceNameController.dispose();
    _locationTextController.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _newItemController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _whatsIncluded.add(text);
      _newItemController.clear();
    });
  }

  Future<void> _submit() async {
    // ignore: avoid_print
    print('Sending offer to recipientId="${widget.recipientId}"');
    final priceText = _priceController.text.trim().replaceAll(',', '');
    final price = num.tryParse(priceText);

    if (price == null || price <= 0) {
      _showSnack('Enter a valid price');
      return;
    }
    if (_whatsIncluded.isEmpty) {
      _showSnack('Add at least one item to "What\'s Included"');
      return;
    }

    // "Valid For" is sent as a real expiresAt now that we know the API
    // returns (and, per this request, accepts) that field.
    final expiresAt = _computedExpiresAt;
    final note = _noteController.text.trim();

    setState(() => _sending = true);
    try {
      final offer = await OfferService().createOffer(
        token: widget.token,
        sentTo: widget.recipientId,
        serviceName: _serviceNameController.text.trim().isEmpty
            ? 'Custom Package'
            : _serviceNameController.text.trim(),
        pricingAmount: price,
        pricingMode: 'fixed',
        currencyCode: 'NGN',
        description: note.isEmpty ? null : note,
        whatsIncluded: _whatsIncluded,
        locationText: _locationTextController.text.trim().isEmpty
            ? null
            : _locationTextController.text.trim(),
        expiresAt: expiresAt,
      );

      // Drop the offer into the chat as its own bubble, the same way
      // _sendRateCard() posts the rate card as a message. Use `price`
      // (what the user actually typed) rather than offer.pricingAmount —
      // if the backend's create-offer response is ever wrapped or shaped
      // differently than expected, this keeps the bubble showing the
      // right number regardless. Prefer offer.expiresAt (what the server
      // actually stored) over our local computation, falling back to the
      // local one if the server didn't echo it back.
      final messagePayload = OfferMessagePayload(
        offerId: offer.id,
        price: price,
        currencyCode: 'NGN',
        pricingMode: 'fixed',
        whatsIncluded: _whatsIncluded,
        expiresAt: offer.expiresAt ?? expiresAt,
        validFor: _validFor,
        note: note.isEmpty ? null : note,
      );

      if (mounted) {
        context.read<ChatProvider>().sendMessage(
              token: widget.token,
              conversationId: widget.conversationId,
              content: messagePayload.encodeAsMessage(),
            );
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OfferSentScreen(
            offer: offer,
            recipientName: widget.recipientName,
            validFor: _validFor,
          ),
        ),
      );
    } catch (e) {
      _showSnack('$e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: Color(0xFFF0F0F0),
            child: Icon(Icons.arrow_back, color: Colors.black, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Send Custom Offer',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _panelBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Price (₦)'),
                      const SizedBox(height: 8),
                      _textField(
                        controller: _priceController,
                        hint: 'Enter amount',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'This is the total amount the client will pay.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      _label("What's Included"),
                      const SizedBox(height: 8),
                      _addItemRow(),
                      const SizedBox(height: 8),
                      ..._whatsIncluded.map(_includedItemRow),
                      const SizedBox(height: 20),

                      _label('Note to Client (Optional)'),
                      const SizedBox(height: 8),
                      _textField(
                        controller: _noteController,
                        hint:
                            'Add a note for the client, such as a limited-time offer, special details, or a friendly message.',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 20),

                      _label('Valid For'),
                      const SizedBox(height: 8),
                      _validForDropdown(),
                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () => setState(
                            () => _showSessionDetails = !_showSessionDetails),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                        ),
                        child: Text(
                          _showSessionDetails
                              ? 'Hide session details'
                              : 'Add session details (optional)',
                          style: const TextStyle(
                            color: _orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_showSessionDetails) ...[
                        const SizedBox(height: 12),
                        _label('Service Name'),
                        const SizedBox(height: 8),
                        _textField(
                          controller: _serviceNameController,
                          hint: 'e.g. Corporate Photography Package',
                        ),
                        const SizedBox(height: 16),
                        _label('Location'),
                        const SizedBox(height: 8),
                        _textField(
                          controller: _locationTextController,
                          hint: 'e.g. Victoria Island',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _sending ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Send Offer',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _orange),
        ),
      ),
    );
  }

  Widget _addItemRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _newItemController,
            style: const TextStyle(fontSize: 14, color: _orange),
            onSubmitted: (_) => _addItem(),
            decoration: InputDecoration(
              hintText: '+ Add Item',
              hintStyle: const TextStyle(
                color: _orange,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _orange),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _orange),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _orange, width: 1.5),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: _addItem,
          icon: const Icon(Icons.add_circle, color: _orange),
        ),
      ],
    );
  }

  Widget _includedItemRow(String item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(item, style: const TextStyle(fontSize: 14)),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 18),
              onPressed: () => setState(() => _whatsIncluded.remove(item)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _validForDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _validFor,
          isExpanded: true,
          hint: const Text(
            'Select a time limit for this offer',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          icon: const Icon(Icons.keyboard_arrow_down),
          items: _validForOptions
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (v) => setState(() => _validFor = v),
        ),
      ),
    );
  }
}