import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/view/users/services/user_service.dart';
import 'package:quick_grocery_admin/view/users/screens/user_details_screen.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    Provider.of<UserService>(context, listen: false).fetchUsers();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFFAF0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    WrapperWidget(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sort by Joining Date',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppSpacing.h10,
                          GestureDetector(
                            onTap: () async {
                              DateTimeRange? picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                                initialDateRange: _selectedDateRange,
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedDateRange = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(10),
                              width: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedDateRange == null
                                        ? "No date selected"
                                        : "${_selectedDateRange!.start.toLocal()} → ${_selectedDateRange!.end.toLocal()}",
                                  ),
                                  Icon(Icons.date_range, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.h20,
                    WrapperWidget(
                      child: Column(
                        children: [
                          LayoutBuilder(
                            builder: (context, c) {
                              final narrow = c.maxWidth < 560;
                              if (narrow) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Customers',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    AppSpacing.h10,
                                    TextField(
                                      autofocus: false,
                                      decoration: InputDecoration(
                                        hintText: 'Search...',
                                        prefixIcon: Icon(Icons.search),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        Provider.of<UserService>(
                                          context,
                                          listen: false,
                                        ).searchUsers(value);
                                      },
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Customers',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  AppSpacing.w10,
                                  SizedBox(
                                    width: (c.maxWidth * 0.45)
                                        .clamp(200.0, 400.0),
                                    child: TextField(
                                      autofocus: false,
                                      decoration: InputDecoration(
                                        hintText: 'Search...',
                                        prefixIcon: Icon(Icons.search),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        Provider.of<UserService>(
                                          context,
                                          listen: false,
                                        ).searchUsers(value);
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          AppSpacing.h10,
                          Divider(color: Colors.grey.shade300),
                          AppSpacing.h10,
                          Center(child: CustomerTable()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserService>(
      builder: (context, userService, _) {
        if (userService.filteredCustomers.isEmpty) {
          return LinearProgressIndicator();
        }
        return LayoutBuilder(
          builder: (context, c) {
            final colSpace = (c.maxWidth * 0.04).clamp(8.0, 28.0);
            final dt = DataTable(
              columnSpacing: colSpace,
              dataRowHeight: 70,
              columns: const [
            DataColumn(
              label: Text('SL', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text(
                'Customer Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Contact Info',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Total Order',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Block / Unblock',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Action',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: List.generate(userService.filteredCustomers.length, (index) {
            var customer = userService.filteredCustomers[index];
            return DataRow(
              cells: [
                DataCell(Text((index + 1).toString())),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: customer.image != ''
                              ? NetworkImage(customer.image)
                              : null,
                          child: customer.image.isEmpty
                              ? Icon(Icons.person, size: 20)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            customer.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    customer.phoneNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DataCell(Text("0")),
                DataCell(
                  Switch(
                    value: customer.isBlocked,
                    onChanged: (value) {
                      userService.toggleChange(index);
                    },
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.visibility_outlined,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  UserDetailsScreen(user: customer),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
            );
            return adminScrollableDataTable(
              viewportWidth: c.maxWidth,
              dataTable: dt,
            );
          },
        );
      },
    );
  }
}
