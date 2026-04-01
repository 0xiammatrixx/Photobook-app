import 'package:flutter/material.dart';
import 'package:mobile_frontend/providers/ratecard_provider.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:mobile_frontend/features/client_dashboard/BookScreen/book.dart';
import 'package:mobile_frontend/features/creative_dashboard/BookingsPage/bookingspage.dart';
import 'package:mobile_frontend/services/profileservice.dart';
import 'package:provider/provider.dart';

class RateCardPage extends StatefulWidget {
  final bool isOwner;
  final String businessName;
  final String? avatarUrl;
  final List<dynamic> rateCard;
  final double? rating;
  final String? creativeId;

  const RateCardPage({
    Key? key,
    required this.isOwner,
    required this.businessName,
    this.rating = 0,
    this.creativeId,
    this.avatarUrl,
    this.rateCard = const [],
  }) : super(key: key);

  @override
  State<RateCardPage> createState() => _RateCardPageState();
}

class _RateCardPageState extends State<RateCardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRateCard());
  }

  Future<void> _loadRateCard() async {
    final token = context.read<UserProvider>().token;
    if (token == null) return;
    await context.read<RateCardProvider>().loadMyRateCard(token: token);
  }

  bool addingNew = false;
  final TextEditingController _serviceCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();

  Future<void> _addService() async {
    final service = _serviceCtrl.text.trim();
    final qty = _qtyCtrl.text.trim();
    final price = _priceCtrl.text.trim();

    if (service.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in at least Service')),
      );
      return;
    }

    try {
      final token = context.read<UserProvider>().token!;
      final success = await context.read<RateCardProvider>().addItem(
        token: token,
        item: RateCardItem(
          id: '',
          serviceName: service,
          quantityLabel: qty,
          pricingMode: price.isEmpty ? 'contact' : 'fixed',
          pricingAmount: price.isEmpty ? null : double.tryParse(price),
        ),
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Service added successfully")),
        );
        setState(() {
          addingNew = false;
          _serviceCtrl.clear();
          _qtyCtrl.clear();
          _priceCtrl.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Failed to add: $e")));
    }
  }

  Future<void> _editService(
    BuildContext context,
    int index,
    RateCardItem item,
  ) async {
    final serviceCtrl = TextEditingController(text: item.serviceName);
    final qtyCtrl = TextEditingController(text: item.quantityLabel);
    final priceCtrl = TextEditingController(
      text: item.pricingAmount?.toStringAsFixed(0) ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Edit Service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: serviceCtrl,
              cursorColor: Colors.black,
              decoration: InputDecoration(
                labelText: 'Service',
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFF7A33)),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Qty',
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFF7A33)),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price',
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFF7A33)),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF047418),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final token = context.read<UserProvider>().token!;
              final price = priceCtrl.text.trim();

              final updatedItem = RateCardItem(
                id: item.id,
                serviceName: serviceCtrl.text.trim(),
                quantityLabel: qtyCtrl.text.trim(),
                pricingMode: price.isEmpty ? 'contact' : 'fixed',
                pricingAmount: price.isEmpty ? null : double.tryParse(price),
                currencyCode: item.currencyCode,
                sortOrder: item.sortOrder,
              );

              final success = await context.read<RateCardProvider>().editItem(
                token: token,
                itemId: item.id,
                item: updatedItem,
              );

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? "✅ Service updated" : "❌ Update failed",
                    ),
                  ),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteService(BuildContext context, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Service'),
        content: const Text('Are you sure you want to delete this service?'),
        actions: [
          TextButton(
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final token = context.read<UserProvider>().token!;
      final item = context.read<RateCardProvider>().services[index];
      await context.read<RateCardProvider>().deleteItem(
        token: token,
        itemId: item.id,
      );
    }
  }

  Widget _buildHeaderCell(String title, String tooltip) {
    final iconKey = GlobalKey();

    return Expanded(
      flex: title == "Service" ? 4 : (title == "Qty" ? 2 : 3),
      child: Row(
        mainAxisAlignment: title == "Pricing"
            ? MainAxisAlignment.end
            : (title == "Qty"
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start),
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            key: iconKey,
            onTap: () {
              final renderBox =
                  iconKey.currentContext?.findRenderObject() as RenderBox?;
              final overlay =
                  Overlay.of(context).context.findRenderObject() as RenderBox?;
              if (renderBox == null || overlay == null) return;

              final screenWidth = MediaQuery.of(context).size.width;
              final target = renderBox.localToGlobal(
                Offset.zero,
                ancestor: overlay,
              );
              const tooltipWidth = 220.0;
              double left = target.dx - 40;
              double top = target.dy - 45;

              // 🧠 Keep tooltip within screen bounds
              if (left < 8) left = 8;
              if (left + tooltipWidth > screenWidth - 8) {
                left = screenWidth - tooltipWidth - 8;
              }

              final entry = OverlayEntry(
                builder: (context) => Positioned(
                  left: left,
                  top: top,
                  child: Material(
                    color: Colors.transparent,
                    child: AnimatedOpacity(
                      opacity: 1,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        width: tooltipWidth,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          tooltip,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );

              Overlay.of(context).insert(entry);
              Future.delayed(
                const Duration(seconds: 2),
              ).then((_) => entry.remove());
            },
            child: const Icon(Icons.info_outline, size: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = List.of(context.watch<RateCardProvider>().services)
      ..sort((a, b) {
        if (a.pricingMode == 'contact') return 1;
        if (b.pricingMode == 'contact') return -1;
        final double priceA = a.pricingAmount ?? double.infinity;
        final double priceB = b.pricingAmount ?? double.infinity;
        return priceA.compareTo(priceB);
      });

    final imageWidget = widget.avatarUrl != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              widget.avatarUrl!,
              width: 117,
              height: 103,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                "assets/profileplaceholder.png",
                width: 117,
                height: 103,
              ),
            ),
          )
        : Image.asset("assets/profileplaceholder.png", width: 117, height: 103);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: widget.isOwner
            ? Text(
                'My Rate Card',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              )
            : Text(
                "${widget.businessName}${widget.businessName.endsWith('s') ? "'" : "'s"} Rate Card",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photographer Info
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: const Color(0xFFF5F9F6),
                ),
                padding: const EdgeInsets.only(
                  right: 16,
                  left: 16,
                  bottom: 16,
                  top: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    imageWidget,
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.businessName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: List.generate(
                                  5,
                                  (index) => Icon(
                                    Icons.star,
                                    color: Colors.orange,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!widget.isOwner)
                          Column(
                            children: [
                              SizedBox(
                                height: 31,
                                width: 83,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.zero,
                                    backgroundColor: const Color(0xFFFF7A33),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BookingPage(
                                          creativeId: widget.creativeId!,
                                          name: widget.businessName,
                                          avatarUrl: widget.avatarUrl ?? '',
                                          rating: widget.rating ?? 0,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Book Now",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 5),
                              SizedBox(
                                height: 31,
                                width: 83,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: BorderSide(color: Color(0xFF047418)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () {},
                                  child: const Text(
                                    "Message",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // 🧾 Rate Card Table Container
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F9F6),
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height:
                    MediaQuery.of(context).size.height *
                    0.55, // keeps nice layout height
                child: Column(
                  children: [
                    // 🔹 Header Row (fixed)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 4.0,
                      ),
                      child: widget.isOwner
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildHeaderCell(
                                  "Service",
                                  "What service do you offer?",
                                ),
                                _buildHeaderCell(
                                  "Qty",
                                  "What is the maximum amount of people this service is limited to?",
                                ),
                                _buildHeaderCell(
                                  "Pricing",
                                  "Your price or rate for the service.",
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildHeaderCell(
                                  "Service",
                                  "The service being offered",
                                ),
                                _buildHeaderCell(
                                  "Qty",
                                  "The maximum amount of people this service is limited to",
                                ),
                                _buildHeaderCell(
                                  "Pricing",
                                  "The price or rate for the service",
                                ),
                              ],
                            ),
                    ),

                    const Divider(thickness: 1.2),

                    if (services.isEmpty)
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.22,
                      ),
                    // 🔹 Scrollable list of services
                    services.isEmpty && widget.isOwner
                        ? Center(
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.7,
                              child: Text(
                                'No service has been added, add services below!',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : (services.isEmpty && !widget.isOwner
                              ? Center(
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.7,
                                    child: Text(
                                      textAlign: TextAlign.center,
                                      'Looks like this creative has not added any services yet. You can chat with them privately!',
                                    ),
                                  ),
                                )
                              : Expanded(
                                  child: ListView.builder(
                                    itemCount: services.length,
                                    itemBuilder: (context, index) {
                                      final item = services[index];
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: Color(0xFFF5F9F6),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 4,
                                              child: Text(
                                                item.serviceName,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 3,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                item.quantityLabel,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      item.pricingMode ==
                                                              'contact'
                                                          ? "Contact Creative"
                                                          : item.pricingAmount
                                                                    ?.toStringAsFixed(
                                                                      0,
                                                                    ) ??
                                                                '',
                                                      textAlign:
                                                          TextAlign.right,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            item.pricingMode ==
                                                                'contact'
                                                            ? const Color(
                                                                0xFF047418,
                                                              )
                                                            : Colors.black,
                                                        decoration:
                                                            item.pricingMode ==
                                                                'contact'
                                                            ? TextDecoration
                                                                  .underline
                                                            : TextDecoration
                                                                  .none,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (widget
                                                      .isOwner) // 👈 Only show for owner
                                                    PopupMenuButton<String>(
                                                      color: Colors.white,
                                                      icon: const Icon(
                                                        Icons.more_vert,
                                                        size: 18,
                                                        color: Colors.black54,
                                                      ),
                                                      onSelected: (value) {
                                                        // In the PopupMenuButton onSelected:
                                                        if (value == 'edit') {
                                                          _editService(
                                                            context,
                                                            index,
                                                            item,
                                                          );
                                                        } else if (value ==
                                                            'delete') {
                                                          _deleteService(
                                                            context,
                                                            index,
                                                          );
                                                        }
                                                      },
                                                      itemBuilder: (context) => [
                                                        const PopupMenuItem(
                                                          value: 'edit',
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons.edit,
                                                                size: 18,
                                                                color: Colors
                                                                    .black54,
                                                              ),
                                                              SizedBox(
                                                                width: 8,
                                                              ),
                                                              Text('Edit'),
                                                            ],
                                                          ),
                                                        ),
                                                        const PopupMenuItem(
                                                          value: 'delete',
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons.delete,
                                                                size: 18,
                                                                color: Colors
                                                                    .redAccent,
                                                              ),
                                                              SizedBox(
                                                                width: 8,
                                                              ),
                                                              Text('Delete'),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                )),

                    // 🔹 Add Service Section (fixed bottom)
                    if (widget.isOwner) ...[
                      const SizedBox(height: 8),
                      if (!addingNew)
                        GestureDetector(
                          onTap: () => setState(() => addingNew = true),
                          child: const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              "Add Service",
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                color: Color(0xFF047418),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      if (addingNew) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Add a new service",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => addingNew = false),
                              child: const Icon(
                                Icons.close,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: TextField(
                                controller: _serviceCtrl,
                                cursorColor: Colors.black,
                                cursorRadius: Radius.zero,
                                decoration: const InputDecoration(
                                  labelText: "Service",
                                  labelStyle: TextStyle(color: Colors.black),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFE0E0E0),
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFFF7A33),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _qtyCtrl,
                                cursorColor: Colors.black,
                                cursorRadius: Radius.zero,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Qty (Optional)",
                                  labelStyle: TextStyle(color: Colors.black),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFE0E0E0),
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFFF7A33),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _priceCtrl,
                                cursorColor: Colors.black,
                                cursorRadius: Radius.zero,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Price (optional)",
                                  labelStyle: TextStyle(color: Colors.black),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFE0E0E0),
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFFF7A33),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _addService,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF047418),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              "Add",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
