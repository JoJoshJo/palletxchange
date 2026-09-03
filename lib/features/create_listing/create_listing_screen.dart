import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_wordmark.dart';
import '../../data/providers.dart';
import '../../models/enums.dart';
import '../../models/listing.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key, this.initial});

  /// When provided, the form edits this listing instead of creating a new one.
  final Listing? initial;

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _quantity = TextEditingController();
  final _minOrder = TextEditingController(text: '1');
  final _price = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController(text: 'Atlanta');
  final _state = TextEditingController(text: 'GA');
  final _zip = TextEditingController();
  final _notes = TextEditingController();

  PalletType _type = PalletType.standardWooden;
  PalletSize _size = PalletSize.s48x40;
  PalletCondition _condition = PalletCondition.usedGood;

  bool _isFree = false;
  bool _pickup = true;
  bool _delivery = false;
  bool _exchange = false;
  bool _forklift = false;
  bool _loadingDock = false;
  bool _stackable = true;
  bool _active = true;

  bool _saving = false;

  static const int _maxPhotos = 5;
  final _picker = ImagePicker();
  final List<XFile> _photos = [];
  final List<String> _existingPhotoUrls = [];

  bool get _isEdit => widget.initial != null;
  int get _photoCount => _existingPhotoUrls.length + _photos.length;

  @override
  void initState() {
    super.initState();
    final l = widget.initial;
    if (l == null) return;
    _title.text = l.title;
    _type = l.palletType;
    _size = l.palletSize;
    _condition = l.condition;
    _quantity.text = '${l.quantityAvailable}';
    _minOrder.text = '${l.minOrderQuantity}';
    _price.text = l.isFree ? '' : l.pricePerPallet.toString();
    _isFree = l.isFree;
    _exchange = l.exchangeAllowed;
    _pickup = l.pickupAvailable;
    _delivery = l.deliveryAvailable;
    _forklift = l.forkliftAvailable;
    _loadingDock = l.loadingDockAvailable;
    _stackable = l.stackable;
    _active = l.status == ListingStatus.active;
    _address.text = l.address ?? '';
    _city.text = l.city ?? 'Atlanta';
    _state.text = l.state ?? 'GA';
    _zip.text = l.zip ?? '';
    _notes.text = l.notes ?? '';
    _existingPhotoUrls.addAll(l.photos);
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _quantity,
      _minOrder,
      _price,
      _address,
      _city,
      _state,
      _zip,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const BrandWordmark()),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              _isEdit ? 'Edit listing' : 'New listing',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isEdit
                  ? 'Update the details of your listing.'
                  : 'List pallets for nearby businesses to buy.',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),

            // ── Pallet ──
            _Section(
              title: 'Pallet',
              icon: Icons.inventory_2_outlined,
              children: [
                _field(
                  label: 'Title',
                  controller: _title,
                  hint: 'e.g. Grade-A 48x40 GMA pallets',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
                ),
                _dropdown<PalletType>(
                  label: 'Type',
                  value: _type,
                  options: PalletType.values,
                  optionLabel: (t) => t.label,
                  onChanged: (v) => setState(() => _type = v!),
                ),
                _dropdown<PalletSize>(
                  label: 'Size',
                  value: _size,
                  options: PalletSize.values,
                  optionLabel: (s) => s.label,
                  onChanged: (v) => setState(() => _size = v!),
                ),
                _dropdown<PalletCondition>(
                  label: 'Condition',
                  value: _condition,
                  options: PalletCondition.values,
                  optionLabel: (c) => c.label,
                  onChanged: (v) => setState(() => _condition = v!),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        label: 'Quantity available',
                        controller: _quantity,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: _requiredInt,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        label: 'Min order',
                        controller: _minOrder,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: _requiredInt,
                      ),
                    ),
                  ],
                ),
                _switchTile(
                  'Give away for free',
                  _isFree,
                  (v) => setState(() => _isFree = v),
                ),
                if (!_isFree)
                  _field(
                    label: 'Price per pallet (USD)',
                    controller: _price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (v) {
                      if (_isFree) return null;
                      final d = double.tryParse(v ?? '');
                      if (d == null || d <= 0) return 'Enter a price';
                      return null;
                    },
                  ),
              ],
            ),

            // ── Location ──
            _Section(
              title: 'Location',
              icon: Icons.place_outlined,
              children: [
                _field(
                  label: 'Street address',
                  controller: _address,
                  hint: 'Shown to a buyer only after a deal opens',
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _field(label: 'City', controller: _city),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(label: 'State', controller: _state),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        label: 'ZIP',
                        controller: _zip,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ── Options ──
            _Section(
              title: 'Options',
              icon: Icons.tune,
              children: [
                _switchTile('Pickup available', _pickup,
                    (v) => setState(() => _pickup = v)),
                _switchTile('Delivery available', _delivery,
                    (v) => setState(() => _delivery = v)),
                _switchTile('Exchange allowed', _exchange,
                    (v) => setState(() => _exchange = v)),
                _switchTile('Forklift on site', _forklift,
                    (v) => setState(() => _forklift = v)),
                _switchTile('Loading dock', _loadingDock,
                    (v) => setState(() => _loadingDock = v)),
                _switchTile('Stackable', _stackable,
                    (v) => setState(() => _stackable = v)),
                const Divider(height: 24),
                _switchTile(
                  'Active (visible in marketplace)',
                  _active,
                  (v) => setState(() => _active = v),
                ),
                _field(
                  label: 'Notes',
                  controller: _notes,
                  maxLines: 3,
                  hint: 'Anything a buyer should know',
                ),
              ],
            ),

            // ── Photos ──
            _Section(
              title: 'Photos',
              icon: Icons.photo_camera_outlined,
              children: [
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        _photoCount + (_photoCount < _maxPhotos ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      // [existing URLs...] [new files...] [add tile]
                      if (i < _existingPhotoUrls.length) {
                        return _PhotoThumb(
                          url: _existingPhotoUrls[i],
                          onRemove: _saving
                              ? null
                              : () => setState(
                                  () => _existingPhotoUrls.removeAt(i)),
                        );
                      }
                      final ni = i - _existingPhotoUrls.length;
                      if (ni < _photos.length) {
                        return _PhotoThumb(
                          file: _photos[ni],
                          onRemove: _saving
                              ? null
                              : () => setState(() => _photos.removeAt(ni)),
                        );
                      }
                      return _AddPhotoTile(onTap: _saving ? null : _pickPhoto);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add up to $_maxPhotos photos. The first is the cover.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),

            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.onDark,
                      ),
                    )
                  : Text(_isEdit ? 'Save changes' : 'Publish listing'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 75, // compress before upload
      );
      if (picked != null && mounted) {
        setState(() => _photos.add(picked));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open the camera/gallery")),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    // Keep existing photos, then upload any newly picked ones.
    final photoUrls = <String>[..._existingPhotoUrls];
    try {
      final storage = ref.read(storageRepositoryProvider);
      for (final x in _photos) {
        final bytes = await x.readAsBytes();
        final ext = x.name.contains('.') ? x.name.split('.').last : 'jpg';
        final url = await storage.uploadListingPhoto(
          bytes: bytes,
          fileExtension: ext.toLowerCase(),
          contentType: _contentTypeFor(ext),
        );
        photoUrls.add(url);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't upload photos — try again")),
      );
      return;
    }

    final me = ref.read(currentProfileProvider).value;
    final listing = Listing(
      id: widget.initial?.id ?? 'pending',
      sellerId: widget.initial?.sellerId ?? me?.id ?? 'me',
      photos: photoUrls,
      title: _title.text.trim(),
      palletType: _type,
      palletSize: _size,
      condition: _condition,
      quantityAvailable: int.tryParse(_quantity.text) ?? 0,
      minOrderQuantity: int.tryParse(_minOrder.text) ?? 1,
      pricePerPallet: _isFree ? 0 : (double.tryParse(_price.text) ?? 0),
      isFree: _isFree,
      exchangeAllowed: _exchange,
      pickupAvailable: _pickup,
      deliveryAvailable: _delivery,
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      zip: _zip.text.trim().isEmpty ? null : _zip.text.trim(),
      loadingDockAvailable: _loadingDock,
      forkliftAvailable: _forklift,
      stackable: _stackable,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      status: _active ? ListingStatus.active : ListingStatus.unavailable,
    );

    try {
      final repo = ref.read(listingRepositoryProvider);
      if (_isEdit) {
        await repo.updateListing(listing);
        ref.invalidate(marketplaceListingsProvider);
        ref.invalidate(listingByIdProvider(listing.id));
        ref.invalidate(sellerActiveListingsProvider(listing.sellerId));
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Listing updated')));
        context.pop();
        return;
      }
      await repo.createListing(listing);
      ref.invalidate(marketplaceListingsProvider);
      if (!mounted) return;
      // Reset the form so the previous entry can't linger or be re-submitted.
      _resetForm();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Listing posted')),
        );
      context.go('/browse');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't publish — try again")),
      );
    }
  }

  /// Clears every field back to its default after a successful post.
  void _resetForm() {
    _formKey.currentState?.reset();
    _title.clear();
    _quantity.clear();
    _minOrder.text = '1';
    _price.clear();
    _address.clear();
    _city.text = 'Atlanta';
    _state.text = 'GA';
    _zip.clear();
    _notes.clear();
    setState(() {
      _type = PalletType.standardWooden;
      _size = PalletSize.s48x40;
      _condition = PalletCondition.usedGood;
      _isFree = false;
      _pickup = true;
      _delivery = false;
      _exchange = false;
      _forklift = false;
      _loadingDock = false;
      _stackable = true;
      _active = true;
      _photos.clear();
      _saving = false;
    });
  }

  String _contentTypeFor(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  String? _requiredInt(String? v) {
    final n = int.tryParse(v ?? '');
    if (n == null || n <= 0) return 'Required';
    return null;
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> options,
    required String Function(T) optionLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          DropdownButtonFormField<T>(
            initialValue: value,
            isExpanded: true,
            items: options
                .map((o) => DropdownMenuItem<T>(
                      value: o,
                      child: Text(optionLabel(o)),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      activeThumbColor: AppColors.orange,
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.orange),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                size: 26, color: AppColors.textMuted),
            SizedBox(height: 4),
            Text('Add', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({this.file, this.url, required this.onRemove});

  final XFile? file;
  final String? url;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: url != null
              ? Image.network(
                  url!,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 96,
                    height: 96,
                    color: AppColors.surface,
                    child: const Icon(Icons.broken_image_outlined,
                        color: AppColors.textMuted),
                  ),
                )
              : Image.file(
                  File(file!.path),
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 15, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
