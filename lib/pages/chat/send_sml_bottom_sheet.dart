import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jsonld2cards/util/conversion.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:matrix/msc_extensions/extension_sml_events/sml_room_extension.dart';

class SendSmlBottomSheet extends StatefulWidget {
  final Room room;
  const SendSmlBottomSheet({required this.room, super.key});

  @override
  State<SendSmlBottomSheet> createState() => _SendSmlBottomSheetState();
}

class _SendSmlBottomSheetState extends State<SendSmlBottomSheet> {
  final TextEditingController _smlBodyController = TextEditingController();
  final TextEditingController _fallbackTextController = TextEditingController();
  final bool _allowMultipleAnswers = false;
  final List<TextEditingController> _answers = [
    TextEditingController(),
    TextEditingController(),
  ];
  final PollKind _pollKind = PollKind.disclosed;

  bool _canCreate = false;

  bool isLoading = false;

  String? _txid;

  void _createSmlEvent() async {
    try {
      _txid ??= widget.room.client.generateUniqueTransactionId();
      await widget.room.sendSml(
        markup: tryDecode(_smlBodyController.text),
        fallback: _fallbackTextController.text.trim(),
        txid: _txid,
      );
      Navigator.of(context).pop();
    } catch (e, s) {
      Logs().w('Unable to send sml message', e, s);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toLocalizedString(context))));
    }
  }

  void _updateCanCreate([dynamic _]) {
    final text = _smlBodyController.text;
    final newCanCreate =
        text.trim().isNotEmpty && tryDecode(text) != null;
    if (_canCreate != newCanCreate) {
      setState(() {
        _canCreate = newCanCreate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: CloseButton(onPressed: Navigator.of(context).pop),
        title: Text(L10n.of(context).sendSml),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        children: [
          TextField(
            controller: _fallbackTextController,
            minLines: 1,
            maxLines: 3,
            onChanged: _updateCanCreate,
            decoration: InputDecoration(
              hintText: L10n.of(context).fallbackText,
              counter: const SizedBox.shrink(),
            ),
          ),
          TextField(
            controller: _smlBodyController,
            minLines: 10,
            maxLines: 15,
            onChanged: _updateCanCreate,
            decoration: InputDecoration(
              hintText: L10n.of(context).jsonLdData,
              counter: const SizedBox.shrink(),
            ),
          ),
          const Divider(height: 32),
          ElevatedButton(
            onPressed: !isLoading && _canCreate ? _createSmlEvent : null,
            child: isLoading
                ? const LinearProgressIndicator()
                : Text(L10n.of(context).sendSml),
          ),
        ],
      ),
    );
  }
}
