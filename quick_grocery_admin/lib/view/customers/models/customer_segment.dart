/// Sidebar list views for customers.
enum CustomerSegment { allCustomers, activeUsers, blockedUsers, newUsers }

extension CustomerSegmentX on CustomerSegment {
  static CustomerSegment? fromRoute(String route) {
    switch (route) {
      case 'All Customers':
        return CustomerSegment.allCustomers;
      case 'Active Users':
        return CustomerSegment.activeUsers;
      case 'Blocked Users':
        return CustomerSegment.blockedUsers;
      case 'New Users':
        return CustomerSegment.newUsers;
      default:
        return null;
    }
  }

  String get title {
    switch (this) {
      case CustomerSegment.allCustomers:
        return 'All Customers';
      case CustomerSegment.activeUsers:
        return 'Active Users';
      case CustomerSegment.blockedUsers:
        return 'Blocked Users';
      case CustomerSegment.newUsers:
        return 'New Users';
    }
  }
}
