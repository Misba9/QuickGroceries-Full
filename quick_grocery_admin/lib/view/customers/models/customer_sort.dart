/// Sortable customer table columns.
enum CustomerSortField { name, orders, spend, lastActive }

extension CustomerSortFieldX on CustomerSortField {
  String get label {
    switch (this) {
      case CustomerSortField.name:
        return 'User name';
      case CustomerSortField.orders:
        return 'Total Orders';
      case CustomerSortField.spend:
        return 'Total Spend';
      case CustomerSortField.lastActive:
        return 'Last Active';
    }
  }

  bool get defaultAscending {
    switch (this) {
      case CustomerSortField.name:
      case CustomerSortField.orders:
      case CustomerSortField.spend:
        return true;
      case CustomerSortField.lastActive:
        return false;
    }
  }

  String hintFor(bool ascending) {
    switch (this) {
      case CustomerSortField.name:
        return ascending ? 'A to Z' : 'Z to A';
      case CustomerSortField.orders:
      case CustomerSortField.spend:
        return ascending ? 'Low to High' : 'High to Low';
      case CustomerSortField.lastActive:
        return ascending ? 'Oldest' : 'Most Recent';
    }
  }
}
