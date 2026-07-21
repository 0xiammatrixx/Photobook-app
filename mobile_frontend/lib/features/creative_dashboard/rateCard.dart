import 'package:flutter/material.dart';
import 'package:mobile_frontend/features/client_dashboard/BookScreen/book.dart';
import 'package:mobile_frontend/features/shared/chat_conversation_screen.dart';
import 'package:mobile_frontend/providers/chat_provider.dart';
import 'package:mobile_frontend/providers/ratecard_provider.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:provider/provider.dart';

class RateCardPage extends StatefulWidget {
  final bool isOwner;
  final String businessName;
  final String? avatarUrl;
  final List<dynamic> rateCard;
  final double? rating;
  final String? creativeId;
  final String description;
  final List<String>? categories;
  final List<String>? whatsIncluded;
  final String deliveryTime;
  final int? quantityMax;
  final String currencyCode;
  final int sortOrder;

  const RateCardPage({
    Key? key,
    required this.isOwner,
    required this.businessName,
    this.description = '',
    this.categories,
    this.whatsIncluded,
    this.deliveryTime = '',
    this.quantityMax, 
    this.currencyCode = 'NGN', 
    this.sortOrder = 0, 
    this.rating = 0,
    this.creativeId,
    this.avatarUrl,
    this.rateCard = const [],
  }) : super(key: key);

  @override
  State<RateCardPage> createState() => _RateCardPageState();
}

class _RateCardPageState extends State<RateCardPage> {
  int? _expandedIndex;

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

  Future<void> _startConversation(BuildContext context) async {
    final token = context.read<UserProvider>().token;
    if (token == null || widget.creativeId == null) return;
    try {
      final result = await context.read<ChatProvider>().createConversation(
        token: token,
        participantId: widget.creativeId!,
      );
      final conversationId = result['id'] ?? result['conversation']?['id'];
      if (conversationId != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatConversationScreen(
              conversationId: conversationId,
              title: widget.businessName,
              avatarUrl: widget.avatarUrl,
              isCreative: false, 
              recipientId: widget.creativeId!,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open chat: $e')));
    }
  }

  IconData _iconFor(int index) {
    switch (index) {
      case 0:
        return Icons.camera_alt_outlined;
      case 1:
        return Icons.star_border;
      default:
        return Icons.diamond_outlined;
    }
  }

  Color _iconColorFor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFF4CAF50);
      case 1:
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF9C27B0);
    }
  }

  String _formatPrice(double? amount) {
    if (amount == null) return 'Contact';
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}k';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final services = List.of(context.watch<RateCardProvider>().services)
      ..sort((a, b) {
        final priceA = a.pricingAmount ?? double.infinity;
        final priceB = b.pricingAmount ?? double.infinity;
        return priceA.compareTo(priceB);
      });

    final rating = widget.rating ?? 0;
    final avatarUrl = widget.avatarUrl;

    final categories = services.expand((e) => e.categories).toSet().toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
          ),
        ),
        title: Text(
          widget.isOwner
              ? 'My Rate Card'
              : "${widget.businessName}${widget.businessName.endsWith('s') ? "'" : "'s"} Rate Card",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile card ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: avatarUrl != null
                      ? Image.network(
                          avatarUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.businessName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: Color(0xFFFF7A33),
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < rating.round()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.orange,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Categories chips (hardcoded sample)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: categories.map((c) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(c),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: const [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 12,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '243 shoots completed',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          SizedBox(width: 8),
                          Text('|', style: TextStyle(color: Colors.grey)),
                          SizedBox(width: 8),
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Based in Abuja',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Client actions (not owner)
            if (!widget.isOwner) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A33),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingPage(
                            creativeId: widget.creativeId!,
                            name: widget.businessName,
                            avatarUrl: widget.avatarUrl ?? '',
                            rating: rating,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Book Now',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF047418)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _startConversation(context),
                      child: const Text(
                        'Message',
                        style: TextStyle(color: Colors.black, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // ── Empty state ──
            if (services.isEmpty && widget.isOwner)
              _EmptyState(onAdd: () => _showAddPackageSheet(context)),

            if (services.isEmpty && !widget.isOwner)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'This creative hasn\'t added any packages yet.\nChat with them to discuss pricing.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ),

            // ── Package list ──
            if (services.isNotEmpty) ...[
              ...List.generate(services.length, (index) {
                final item = services[index];
                final isExpanded = _expandedIndex == index;
                final inclusions = item.whatsIncluded;
                final delivery = item.deliveryTime;

                return _PackageCard(
                  index: index,
                  item: item,
                  isExpanded: isExpanded,
                  inclusions: inclusions,
                  deliveryTime: delivery,
                  icon: _iconFor(index),
                  iconColor: _iconColorFor(index),
                  priceLabel: _formatPrice(item.pricingAmount),
                  isOwner: widget.isOwner,
                  onTap: () => setState(
                    () => _expandedIndex = isExpanded ? null : index,
                  ),
                  onEdit: () => _showAddPackageSheet(
                    context,
                    existing: item,
                    index: index,
                  ),
                  onDelete: () => _deletePackage(context, index),
                );
              }),

              // Add another package (owner only)
              if (widget.isOwner)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFF7A33)),
                        foregroundColor: const Color(0xFFFF7A33),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _showAddPackageSheet(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Add Package',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.person, color: Colors.grey, size: 40),
  );

  Future<void> _deletePackage(BuildContext context, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Package'),
        content: const Text('Are you sure you want to delete this package?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
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
    if (confirm == true && mounted) {
      final token = context.read<UserProvider>().token!;
      final item = context.read<RateCardProvider>().services[index];
      await context.read<RateCardProvider>().deleteItem(
        token: token,
        itemId: item.id,
      );
      setState(() {
        if (_expandedIndex == index) _expandedIndex = null;
      });
    }
  }

  void _showAddPackageSheet(
    BuildContext context, {
    RateCardItem? existing,
    int? index,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddPackageSheet(
        existing: existing,
        onSave: (item) async {
          final token = context.read<UserProvider>().token!;
          bool success;
          if (existing != null && existing.id.isNotEmpty) {
            success = await context.read<RateCardProvider>().editItem(
              token: token,
              itemId: existing.id,
              item: item,
            );
          } else {
            success = await context.read<RateCardProvider>().addItem(
              token: token,
              item: item,
            );
          }
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  existing != null ? '✅ Package updated' : '✅ Package added',
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

// ── Package Card ──────────────────────────────────────────────────────────────

class _PackageCard extends StatelessWidget {
  final int index;
  final RateCardItem item;
  final bool isExpanded;
  final List<String> inclusions;
  final String deliveryTime;
  final IconData icon;
  final Color iconColor;
  final String priceLabel;
  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PackageCard({
    required this.index,
    required this.item,
    required this.isExpanded,
    required this.inclusions,
    required this.deliveryTime,
    required this.icon,
    required this.iconColor,
    required this.priceLabel,
    required this.isOwner,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header row ──
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.serviceName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.quantityLabel.isNotEmpty
                              ? item.quantityLabel
                              : item.description.isNotEmpty
                              ? item.description
                              : item.quantityLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.pricingMode == 'contact' ? 'Contact' : priceLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded content ──
          if (isExpanded) ...[
            Divider(height: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "What's Included",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...inclusions.map(
                    (inc) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF047418),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(inc, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      if (item.deliveryTime.isNotEmpty)
                        Text(
                          'Delivery Time - $deliveryTime',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  if (isOwner) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: onDelete,
                            child: const Text('Delete'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF7A33),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: onEdit,
                            child: const Text(
                              'Edit',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Text(
              "Let's set you up :)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first package to start receiving\nbookings from clients.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A33),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onAdd,
              child: const Text(
                'Add First Package',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add/Edit Package Sheet ────────────────────────────────────────────────────

class _AddPackageSheet extends StatefulWidget {
  final RateCardItem? existing;
  final Function(RateCardItem) onSave;

  const _AddPackageSheet({this.existing, required this.onSave});

  @override
  State<_AddPackageSheet> createState() => _AddPackageSheetState();
}

class _AddPackageSheetState extends State<_AddPackageSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _itemCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(); // ✅ missing
  final _quantityMaxCtrl = TextEditingController(); // ✅ missing
  final _deliveryCtrl = TextEditingController(); // ✅ missing
  String? _selectedCategory;
  String _pricingMode = 'fixed';
  List<String> _inclusions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.serviceName;
      _priceCtrl.text =
          widget.existing!.pricingAmount?.toStringAsFixed(0) ?? '';
      _descCtrl.text = widget.existing!.description;
      _quantityCtrl.text = widget.existing!.quantityLabel;
      _quantityMaxCtrl.text = widget.existing!.quantityMax?.toString() ?? '';
      _deliveryCtrl.text = widget.existing!.deliveryTime;
      _inclusions = List.from(widget.existing!.whatsIncluded);
      _pricingMode = widget.existing!.pricingMode;
      _selectedCategory = widget.existing!.categories.isNotEmpty
          ? widget.existing!.categories.first
          : null;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _itemCtrl.dispose();
    _quantityCtrl.dispose(); // ✅
    _quantityMaxCtrl.dispose(); // ✅
    _deliveryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Package name is required')));
      return;
    }
    setState(() => _loading = true);
    final item = RateCardItem(
      id: widget.existing?.id ?? '',

      serviceName: _nameCtrl.text,

      pricingAmount: double.tryParse(_priceCtrl.text),

      pricingMode: _pricingMode,

      quantityLabel: _quantityCtrl.text,

      quantityMax: int.tryParse(_quantityMaxCtrl.text),

      currencyCode: "NGN",

      sortOrder: widget.existing?.sortOrder ?? 1,

      categories: [
        if (_selectedCategory != null) _selectedCategory!.toLowerCase(),
      ],

      description: _descCtrl.text,

      whatsIncluded: _inclusions,

      deliveryTime: _deliveryCtrl.text,
    );
    await widget.onSave(item);
    setState(() => _loading = false);
    if (mounted) Navigator.pop(context);
  }

  final List<String> _kCategories = [
    'Wedding',
    'Birthday',
    'Corporate',
    'Portrait',
    'Fashion',
    'Product',
    'Events',
    'Editorial',
    'Headshots',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Add a Rate Card',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Create packages and pricing to let clients easily book or request your services',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            _label('Package Name'),
            _field(_nameCtrl, hint: 'e.g Basic Package'),
            const SizedBox(height: 16),

            _label('Category'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  hint: const Text(
                    'Select a category',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  items: _kCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                ),
              ),
            ),
            const SizedBox(height: 16),

            _label('Price (₦)'),
            _field(
              _priceCtrl,
              hint: 'Enter amount',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            _label('Description'),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Briefly describe what this package is best for...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFFF7A33)),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const Text(
                  "What's Included",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Text(
                  '(Add key deliverables in this package)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Add item input
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFF7A33)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Text(
                    '+ ',
                    style: TextStyle(
                      color: Color(0xFFFF7A33),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _itemCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Add Item',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (v) {
                        if (v.trim().isNotEmpty) {
                          setState(() {
                            _inclusions.add(v.trim());
                            _itemCtrl.clear();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Inclusion chips
            ..._inclusions.map(
              (inc) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(inc, style: const TextStyle(fontSize: 13)),
                    GestureDetector(
                      onTap: () => setState(() => _inclusions.remove(inc)),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A33),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.existing != null
                            ? 'Save Changes'
                            : 'Add First Package',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );

  Widget _field(
    TextEditingController ctrl, {
    String? hint,
    TextInputType? keyboardType,
  }) => TextField(
    controller: ctrl,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFF7A33)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    ),
  );
}
