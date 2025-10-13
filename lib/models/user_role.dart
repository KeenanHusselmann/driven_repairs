enum UserRole {
  admin('ADMIN'),
  technician('TECHNICIAN'),
  sales('SALES'),
  accountant('ACCOUNTANT');

  const UserRole(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.technician:
        return 'Technician';
      case UserRole.sales:
        return 'Sales Representative';
      case UserRole.accountant:
        return 'Accountant';
    }
  }

  List<Permission> get permissions {
    switch (this) {
      case UserRole.admin:
        return Permission.values; // All permissions
      case UserRole.technician:
        return [
          Permission.viewTickets,
          Permission.editTickets,
          Permission.createTickets,
          Permission.viewCustomers,
          Permission.viewDevices,
          Permission.editDevices,
          Permission.viewParts,
          Permission.editParts,
          // Reports removed from technician
        ];
      case UserRole.sales:
        return [
          Permission.viewCustomers,
          Permission.editCustomers,
          Permission.createCustomers,
          // Tickets and devices removed from sales
          // Reports removed from sales
        ];
      case UserRole.accountant:
        return [
          Permission.viewCustomers,
          // Parts and tickets removed from accountant
          Permission.viewReports,
          Permission.viewSalesReports,
          Permission.viewFinancialReports,
          Permission.manageBilling,
          Permission.viewSettings,
        ];
    }
  }
}

enum Permission {
  // Customer permissions
  viewCustomers,
  createCustomers,
  editCustomers,
  deleteCustomers,

  // Ticket permissions
  viewTickets,
  createTickets,
  editTickets,
  deleteTickets,
  assignTickets,

  // Device permissions
  viewDevices,
  createDevices,
  editDevices,
  deleteDevices,

  // Parts permissions
  viewParts,
  createParts,
  editParts,
  deleteParts,

  // User management
  viewUsers,
  createUsers,
  editUsers,
  deleteUsers,

  // System permissions
  viewReports,
  viewSettings,
  editSettings,
  viewAuditLogs,

  // Technician specific
  updateTicketStatus,
  addTicketNotes,

  // Sales specific
  createQuotes,
  viewSalesReports,

  // Accountant specific
  viewFinancialReports,
  manageBilling,
}

enum UserStatus {
  active('ACTIVE'),
  inactive('INACTIVE'),
  suspended('SUSPENDED');

  const UserStatus(this.value);
  final String value;
}
