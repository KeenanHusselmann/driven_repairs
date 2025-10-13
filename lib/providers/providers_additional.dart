import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

class DeviceProvider extends ChangeNotifier {
  final DeviceRepository _repository = DeviceRepository();

  List<Device> _devices = [];
  Device? _selectedDevice;
  bool _isLoading = false;

  List<Device> get devices => _devices;
  Device? get selectedDevice => _selectedDevice;
  bool get isLoading => _isLoading;

  Future<void> loadDevices({String? customerId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _devices = await _repository.getAll(customerId: customerId);
    } catch (e) {
      debugPrint('Error loading devices: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDevice(String deviceId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedDevice = await _repository.getById(deviceId);
    } catch (e) {
      debugPrint('Error loading device: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createDevice(Device device) async {
    try {
      final id = await _repository.create(device);
      await loadDevices();
      return id;
    } catch (e) {
      debugPrint('Error creating device: $e');
      return null;
    }
  }

  Future<bool> updateDevice(Device device) async {
    try {
      await _repository.update(device);
      if (_selectedDevice?.id == device.id) {
        _selectedDevice = device;
      }
      await loadDevices();
      return true;
    } catch (e) {
      debugPrint('Error updating device: $e');
      return false;
    }
  }

  Future<bool> deleteDevice(String deviceId) async {
    try {
      await _repository.delete(deviceId);
      _devices.removeWhere((device) => device.id == deviceId);
      if (_selectedDevice?.id == deviceId) {
        _selectedDevice = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting device: $e');
      return false;
    }
  }

  void clearSelection() {
    _selectedDevice = null;
    notifyListeners();
  }
}

class TechnicianProvider extends ChangeNotifier {
  final TechnicianRepository _repository = TechnicianRepository();

  List<Technician> _technicians = [];
  Technician? _selectedTechnician;
  bool _isLoading = false;

  List<Technician> get technicians => _technicians;
  Technician? get selectedTechnician => _selectedTechnician;
  bool get isLoading => _isLoading;

  Future<void> loadTechnicians() async {
    _isLoading = true;
    notifyListeners();

    try {
      _technicians = await _repository.getAll();
    } catch (e) {
      debugPrint('Error loading technicians: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTechnician(String technicianId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedTechnician = await _repository.getById(technicianId);
    } catch (e) {
      debugPrint('Error loading technician: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createTechnician(Technician technician) async {
    try {
      final id = await _repository.create(technician);
      await loadTechnicians();
      return id;
    } catch (e) {
      debugPrint('Error creating technician: $e');
      return null;
    }
  }

  Future<bool> updateTechnician(Technician technician) async {
    try {
      await _repository.update(technician);
      if (_selectedTechnician?.id == technician.id) {
        _selectedTechnician = technician;
      }
      await loadTechnicians();
      return true;
    } catch (e) {
      debugPrint('Error updating technician: $e');
      return false;
    }
  }

  Future<bool> deleteTechnician(String technicianId) async {
    try {
      await _repository.delete(technicianId);
      _technicians.removeWhere((tech) => tech.id == technicianId);
      if (_selectedTechnician?.id == technicianId) {
        _selectedTechnician = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting technician: $e');
      return false;
    }
  }

  void clearSelection() {
    _selectedTechnician = null;
    notifyListeners();
  }
}

class PartProvider extends ChangeNotifier {
  final PartRepository _repository = PartRepository();

  List<Part> _parts = [];
  Part? _selectedPart;
  bool _isLoading = false;

  List<Part> get parts => _parts;
  Part? get selectedPart => _selectedPart;
  bool get isLoading => _isLoading;

  Future<void> loadParts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _parts = await _repository.getAll();
    } catch (e) {
      debugPrint('Error loading parts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPart(String partId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedPart = await _repository.getById(partId);
    } catch (e) {
      debugPrint('Error loading part: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createPart(Part part) async {
    try {
      final id = await _repository.create(part);
      await loadParts();
      return id;
    } catch (e) {
      debugPrint('Error creating part: $e');
      return null;
    }
  }

  Future<bool> updatePart(Part part) async {
    try {
      await _repository.update(part);
      if (_selectedPart?.id == part.id) {
        _selectedPart = part;
      }
      await loadParts();
      return true;
    } catch (e) {
      debugPrint('Error updating part: $e');
      return false;
    }
  }

  Future<bool> deletePart(String partId) async {
    try {
      await _repository.delete(partId);
      _parts.removeWhere((part) => part.id == partId);
      if (_selectedPart?.id == partId) {
        _selectedPart = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting part: $e');
      return false;
    }
  }

  void clearSelection() {
    _selectedPart = null;
    notifyListeners();
  }
}
