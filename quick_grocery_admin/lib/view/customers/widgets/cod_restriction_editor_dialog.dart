import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:quick_grocery_admin/model/cod_payment_restriction.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/customers/services/cod_restriction_admin_service.dart';

/// Dialog / bottom sheet to enable/disable/temporarily restrict COD for a user.
Future<bool?> showCodRestrictionEditor({
  required BuildContext context,
  required String userId,
  required String userName,
  CodPaymentRestriction? current,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => _CodRestrictionEditorDialog(
      userId: userId,
      userName: userName,
      current: current ?? CodPaymentRestriction.enabled,
    ),
  );
}

class _CodRestrictionEditorDialog extends StatefulWidget {
  const _CodRestrictionEditorDialog({
    required this.userId,
    required this.userName,
    required this.current,
  });

  final String userId;
  final String userName;
  final CodPaymentRestriction current;

  @override
  State<_CodRestrictionEditorDialog> createState() =>
      _CodRestrictionEditorDialogState();
}

class _CodRestrictionEditorDialogState
    extends State<_CodRestrictionEditorDialog> {
  late CodRestrictionType _type;
  final _reason = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  bool _saving = false;
  String? _error;
  final _svc = CodRestrictionAdminService();

  @override
  void initState() {
    super.initState();
    final c = widget.current;
    _type = c.badge == CodRestrictionBadge.enabled
        ? CodRestrictionType.none
        : c.codRestrictionType == CodRestrictionType.none
            ? CodRestrictionType.permanent
            : c.codRestrictionType;
    _reason.text = c.codRestrictionReason;
    _notes.text = c.codRestrictionNotes;
    _start = c.codRestrictionStart ?? DateTime.now();
    _end = c.codRestrictionEnd ??
        DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _reason.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_type == CodRestrictionType.none) {
        await _svc.removeForUser(widget.userId);
      } else {
        if (_reason.text.trim().isEmpty) {
          setState(() {
            _error = 'Reason is required.';
            _saving = false;
          });
          return;
        }
        await _svc.updateForUser(
          userId: widget.userId,
          type: _type,
          reason: _reason.text.trim(),
          notes: _notes.text.trim(),
          start: _start,
          end: _type == CodRestrictionType.temporary ? _end : null,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _error = e.message ?? e.code;
        _saving = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  Future<void> _pickDate({required bool isEnd}) async {
    final initial = isEnd ? (_end ?? DateTime.now()) : (_start ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    final merged = DateTime(
      picked.year,
      picked.month,
      picked.day,
      time?.hour ?? initial.hour,
      time?.minute ?? initial.minute,
    );
    setState(() {
      if (isEnd) {
        _end = merged;
      } else {
        _start = merged;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, y · HH:mm');
    return AlertDialog(
      title: Text(
        'COD Payment Restriction',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.userName.isEmpty ? widget.userId : widget.userName,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Restriction type',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('✅ Enable COD'),
                    selected: _type == CodRestrictionType.none,
                    onSelected: (_) =>
                        setState(() => _type = CodRestrictionType.none),
                  ),
                  ChoiceChip(
                    label: const Text('⏳ Temporary disable'),
                    selected: _type == CodRestrictionType.temporary,
                    onSelected: (_) =>
                        setState(() => _type = CodRestrictionType.temporary),
                  ),
                  ChoiceChip(
                    label: const Text('🚫 Permanent disable'),
                    selected: _type == CodRestrictionType.permanent,
                    onSelected: (_) =>
                        setState(() => _type = CodRestrictionType.permanent),
                  ),
                ],
              ),
              if (_type != CodRestrictionType.none) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _reason,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Reason *',
                    border: OutlineInputBorder(),
                    hintText: 'Fake orders / repeated cancellations / fraud…',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notes,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Internal admin notes',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start date'),
                  subtitle: Text(fmt.format(_start ?? DateTime.now())),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _pickDate(isEnd: false),
                ),
                if (_type == CodRestrictionType.temporary)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('End date *'),
                    subtitle: Text(
                      _end == null ? 'Select end date' : fmt.format(_end!),
                    ),
                    trailing: const Icon(Icons.event),
                    onTap: () => _pickDate(isEnd: true),
                  ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: AppColor.primary),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _type == CodRestrictionType.none
                      ? 'Enable COD'
                      : 'Save restriction',
                ),
        ),
      ],
    );
  }
}
