import 'package:flutter/material.dart';
import 'package:cthree/core/models/deliverable_model.dart';
import 'package:cthree/core/api/deliverable_repository.dart';

class DeliverableProvider extends ChangeNotifier {
  final DeliverableRepository _repo = DeliverableRepository();
  final Map<String, DeliverableModel?> _deliverables = {};
  bool _isLoading = false;
  Map<String, DeliverableModel?> get deliverables => _deliverables;
  List<DeliverableModel?> get allDeliverables => _deliverables.values.toList();
  bool get isLoading => _isLoading;

  Future<void> fetchAll() async {
    _isLoading = true;
    notifyListeners();

    final results = await _repo.getDeliverables();

    if (results != null) {
      _deliverables.clear();
      for (var d in results) {
        _deliverables[d.id] = d;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchOne(String id) async {
    final result = await _repo.getIndvDeliverable(id);

    if (result != null) {
      _deliverables[id] = result;
      notifyListeners();
    }
  }
}