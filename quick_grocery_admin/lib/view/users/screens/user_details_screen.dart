import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/core/responsive/admin_layout_widgets.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/home/screens/home_screen.dart';
import 'package:quick_grocery_admin/view/orders/screens/order_details_screen.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:quick_grocery_admin/view/users/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({super.key, required this.user});
  final CustomerModel user;

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  @override
  void initState() {
    Provider.of<UserService>(context, listen: false).getAddress(widget.user.id);
    Provider.of<UserService>(context, listen: false).getOrders(widget.user.id);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFAF0),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              AdminResponsiveRow(
                breakpoint: 900,
                children: [
                  SizedBox(
                    height: 210,
                    child: WrapperWidget(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade300,
                            ),
                            child: widget.user.image != ''
                                ? Image.network(widget.user.image)
                                : null,
                          ),
                          AppSpacing.w20,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.user.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              NamedFieldWidget(
                                label: 'Contact',
                                value: widget.user.phoneNumber,
                              ),
                              NamedFieldWidget(
                                label: 'Email',
                                value: widget.user.email,
                              ),
                              NamedFieldWidget(
                                label: 'Joined Date',
                                value: DateFormat("MMM d, y").format(
                                  DateTime.parse(widget.user.createdDate),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  WrapperWidget(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saved address',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppSpacing.h10,
                          SizedBox(
                            height: 150,
                            child: Consumer<UserService>(
                              builder: (context, p, _) {
                                if (p.addresses == null) {
                                  return SizedBox(
                                    child: LinearProgressIndicator(
                                      minHeight: 1,
                                    ),
                                  );
                                }
                                return ListView.builder(
                                  itemCount: p.addresses!.length,
                                  scrollDirection: Axis.horizontal,
                                  shrinkWrap: true,
                                  itemBuilder: (context, i) {
                                    return Container(
                                      padding: EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.grey.shade100,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.addresses![i].type,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text('Name: ${p.addresses![i].name}'),
                                          Text(
                                            'Phone: ${p.addresses![i].mobile}',
                                          ),
                                          Text('City: ${p.addresses![i].area}'),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              AppSpacing.h20,
              WrapperWidget(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Orders',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            autofocus: false,
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              prefixIcon: Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  Icons.arrow_forward,
                                  color: AppColor.primary,
                                ), // Search button icon
                                onPressed: () {},
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (value) {},
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.h10,
                    Divider(color: Colors.grey.shade300),
                    AppSpacing.h10,
                    Consumer<UserService>(
                      builder: (context, p, _) {
                        if (p.orders == null) {
                          return SizedBox();
                        }
                        return DataTable(
                          columnSpacing:
                              MediaQuery.of(context).size.width * .15,
                          dataRowHeight: 70,
                          columns: const [
                            DataColumn(
                              label: Text(
                                'SL',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Order ID	',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Total',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Order Status',
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
                          rows: List.generate(p.orders!.length, (index) {
                            return DataRow(
                              cells: [
                                DataCell(Text((index + 1).toString())),
                                DataCell(Text(p.orders![index].id)),
                                DataCell(
                                  Text(
                                    "₹${p.orders![index].getTotalAmount().toStringAsFixed(0)}",
                                  ),
                                ),
                                DataCell(Text(p.orders![index].orderStatus)),
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
                                                  OrderDetailsScreen(
                                                    order: p.orders![index],
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {},
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
