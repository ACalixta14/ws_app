enum ServiceType {
  hauling('Hauling'),
  wood('Wood'),
  clean('Clean'),
  mixed('Mixed'),
  drywall('Drywall'),
  miscellaneous('Misc');

  final String label;

  const ServiceType(this.label);
}


extension ServiceTypeExtension on ServiceType {
  String get label {
    switch (this) {
      case ServiceType.hauling:
        return 'Hauling';
      case ServiceType.wood:
        return 'Wood';
      case ServiceType.clean:
        return 'Clean';
      case ServiceType.mixed:
        return 'Mixed';
      case ServiceType.drywall:
        return 'Drywall';
      case ServiceType.miscellaneous:
        return 'Miscellaneous';
    }
  }

  double? get defaultPrice {
    switch (this) {
      case ServiceType.hauling:
        return 80;
      case ServiceType.wood:
        return 130;
      case ServiceType.clean:
        return 150;
      case ServiceType.mixed:
        return 190;
      case ServiceType.drywall:
        return 250;
      case ServiceType.miscellaneous:
        return null; // manual
    }
  }
}
